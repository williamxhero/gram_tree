"""Account and single-entity erasure for the domains present in this checkout.

Public publication/social prerequisites are not present. Never silently erase a
public recipe as if either advertised public-recipe policy were implemented.
"""

import hashlib
import json
import uuid
from datetime import UTC, timedelta

from redis import Redis
from redis.exceptions import RedisError
from sqlalchemy import delete, select, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from gramtree.accounts.deletion_models import (
    AnonymousCookingStatistic,
    CookingStatisticDedup,
    PendingObjectErasure,
)
from gramtree.ai.models import AICall, GenerationRequest, RecipeModification
from gramtree.analytics.models import AnalyticsEvent
from gramtree.core.errors import ApiError
from gramtree.events.field_adjudication import FieldEntity, FieldHistory
from gramtree.events.models import Event
from gramtree.events.sync_models import WriteFactOutbox, WriteReceipt
from gramtree.recipes.import_models import RecipeImport
from gramtree.recipes.measure_models import PersonalMeasure
from gramtree.recipes.models import (
    Recipe,
    RecipeImage,
    RecipeImageStaging,
    RecipeSaveOutbox,
    RecipeVersion,
)
from gramtree.recipes.storage import make_recipe_storage
from gramtree.records.models import CookingRecord, CookingRecordRevision
from gramtree.settings import Settings
from gramtree.taste_profiles.learning_models import TasteChangeFact
from gramtree.taste_profiles.models import TasteProfile, TasteProfileChange
from gramtree.taste_profiles.schemas import FLAVOR_KEYS

_LEVELS = frozenset({"much_less", "less", "standard", "more", "much_more"})


def public_recipes(session: Session, owner_id: uuid.UUID) -> list[Recipe]:
    return list(
        session.scalars(
            select(Recipe).where(Recipe.owner_id == owner_id, Recipe.visibility == "public")
        )
    )


def require_supported_recipes(session: Session, owner_id: uuid.UUID) -> None:
    if public_recipes(session, owner_id):
        raise ApiError(409, "public_deletion_unavailable", "公开菜谱注销暂不可用，请稍后重试")


def _dimensions(session: Session, row: CookingRecord) -> dict:
    rating = None
    revisions = session.scalars(
        select(CookingRecordRevision)
        .where(CookingRecordRevision.record_id == row.id, CookingRecordRevision.field == "rating")
        .order_by(CookingRecordRevision.revision.desc())
        .limit(1)
    )
    for revision in revisions:
        score = revision.value.get("score")
        if type(score) is int and 1 <= score <= 5:
            rating = score
    raw = row.taste_summary.get("flavors", {})
    flavors = {
        key: raw[key]["level"]
        for key in FLAVOR_KEYS
        if isinstance(raw, dict)
        and isinstance(raw.get(key), dict)
        and raw[key].get("level") in _LEVELS
    }
    return {
        "rating": rating,
        # There is no standard tag registry in this checkout. Freeform tags are
        # deliberately not copied into anonymous statistics.
        "standard_tags": [],
        "verification": row.verification
        if row.verification in {"unverified", "cooking_mode"}
        else "unverified",
        "taste_levels": flavors,
    }


def preserve_statistics(session: Session, rows: list[CookingRecord]) -> None:
    """Latest record per owner/version; no raw event, fingerprint or ID survives."""
    latest: dict[tuple[uuid.UUID, uuid.UUID], CookingRecord] = {}
    for row in sorted(rows, key=lambda item: (item.occurred_at, str(item.id))):
        if row.recipe_version_id is not None:
            latest[row.owner_id, row.recipe_version_id] = row
    for (owner, version), row in latest.items():
        fresh = session.execute(
            insert(CookingStatisticDedup)
            .values(owner_id=owner, recipe_version_id=version)
            .on_conflict_do_nothing()
            .returning(CookingStatisticDedup.owner_id)
        ).scalar_one_or_none()
        if fresh is None:
            continue
        at = row.occurred_at.astimezone(UTC)
        week = (at - timedelta(days=at.weekday())).date()
        dimensions = _dimensions(session, row)
        canonical = json.dumps([str(version), week.isoformat(), dimensions], sort_keys=True)
        bucket = hashlib.sha256(canonical.encode()).hexdigest()
        session.execute(
            insert(AnonymousCookingStatistic)
            .values(
                bucket=bucket,
                recipe_version_id=version,
                week=week,
                dimensions=dimensions,
                contributions=1,
            )
            .on_conflict_do_update(
                index_elements=[AnonymousCookingStatistic.bucket],
                set_={"contributions": AnonymousCookingStatistic.contributions + 1},
            )
        )


def erase_record(session: Session, row: CookingRecord) -> None:
    preserve_statistics(session, [row])
    session.execute(
        delete(Event).where(
            Event.user_id == row.owner_id,
            Event.correlation["cooking_record_id"].astext == str(row.id),
        )
    )
    # Strip attributable evidence pointers without reverting learned taste.
    for change in session.scalars(
        select(TasteProfileChange).where(TasteProfileChange.owner_id == row.owner_id)
    ):
        if str(row.id) in change.source_record_ids:
            change.source_record_ids = [
                item for item in change.source_record_ids if item != str(row.id)
            ]
    _erase_receipts(session, row.owner_id, {str(row.id)}, "cooking.record")
    session.delete(row)  # Revisions, attribution and learning signals cascade.


def _erase_receipts(
    session: Session,
    owner: uuid.UUID,
    ids: set[str],
    resource_type: str,
    recipe_id: uuid.UUID | None = None,
) -> None:
    receipts = list(session.scalars(select(WriteReceipt).where(WriteReceipt.owner_id == owner)))
    for receipt in receipts:
        result = receipt.result or {}
        confirmed = (
            result.get("resource_type") == resource_type and result.get("resource_id") in ids
        )
        conflict = (
            recipe_id is not None
            and receipt.write_type == "recipe_version.save"
            and result.get("recipe_id") == str(recipe_id)
        )
        if confirmed or conflict:
            session.execute(
                delete(WriteFactOutbox).where(WriteFactOutbox.write_id == receipt.write_id)
            )
            # Retain a content-free terminal receipt so retry cannot recreate
            # erased content or return cached private/conflicting snapshots.
            receipt.status = "failed"
            receipt.reason_code = "resource_deleted"
            receipt.result = None
            receipt.dependencies = []


def queue_objects(session: Session, keys: list[str]) -> None:
    for key in keys:
        session.execute(
            insert(PendingObjectErasure).values(storage_key=key).on_conflict_do_nothing()
        )


def erase_owner_caches(settings: Settings, owner: uuid.UUID) -> None:
    # Clear only the owner's content caches, never another user's counters or
    # global caches. A backend outage must keep account erasure retryable.
    try:
        with Redis.from_url(
            settings.redis_url, socket_connect_timeout=5, socket_timeout=5
        ) as redis:
            for pattern in (
                f"ui:composition_cache:{owner}:*",
                f"personalized:replacement:v1:{owner}:*",
                f"personalized:equipment:v1:{owner}:*",
            ):
                for key in redis.scan_iter(match=pattern, count=100):
                    redis.delete(key)
    except RedisError as exc:
        raise ApiError(503, "erasure_unavailable", "删除暂未完成，请稍后重试") from exc


def drain_objects(session: Session, settings: Settings) -> None:
    storage = make_recipe_storage(settings)
    for row in session.scalars(select(PendingObjectErasure).with_for_update()):
        storage.delete(row.storage_key)
        session.delete(row)
    session.commit()


def erase_recipe(session: Session, recipe: Recipe) -> None:
    if recipe.visibility != "private":
        raise ApiError(409, "recipe_not_private", "只能删除未公开的本人菜谱")
    versions = list(
        session.scalars(select(RecipeVersion.id).where(RecipeVersion.recipe_id == recipe.id))
    )
    # Baseline has no public lineage. Fail closed on unexpected foreign pointers
    # rather than damage another account's source relationship.
    dependent = session.scalar(
        select(Recipe.id)
        .where(
            Recipe.owner_id != recipe.owner_id,
            (Recipe.root_recipe_id == recipe.id) | Recipe.source_version_id.in_(versions),
        )
        .limit(1)
    )
    if dependent is not None:
        raise ApiError(409, "recipe_has_lineage", "菜谱存在来源关系，暂不能删除")
    records = list(
        session.scalars(
            select(CookingRecord).where(
                CookingRecord.owner_id == recipe.owner_id,
                CookingRecord.recipe_version_id.in_(versions),
            )
        )
    )
    preserve_statistics(session, records)
    keys = list(
        session.scalars(select(RecipeImage.storage_key).where(RecipeImage.recipe_id == recipe.id))
    )
    queue_objects(session, keys)
    session.execute(delete(RecipeSaveOutbox).where(RecipeSaveOutbox.recipe_id == recipe.id))
    session.execute(
        delete(RecipeImport).where(
            RecipeImport.owner_id == recipe.owner_id, RecipeImport.recipe_id == recipe.id
        )
    )
    session.execute(
        delete(Event).where(
            Event.user_id == recipe.owner_id,
            Event.correlation["recipe_version_id"].astext.in_([str(v) for v in versions]),
        )
    )
    _erase_receipts(
        session,
        recipe.owner_id,
        {str(version) for version in versions},
        "recipe.version",
        recipe.id,
    )
    session.execute(
        update(Recipe)
        .where(Recipe.id == recipe.id)
        .values(current_version_id=None, source_version_id=None, root_recipe_id=None)
    )
    session.execute(
        update(RecipeVersion)
        .where(RecipeVersion.recipe_id == recipe.id)
        .values(previous_version_id=None, base_version_id=None)
    )
    session.execute(delete(RecipeVersion).where(RecipeVersion.recipe_id == recipe.id))
    session.delete(recipe)


def erase_private_domains(session: Session, owner: uuid.UUID) -> None:
    """Delete every implemented owner domain; other users' frozen history stays."""
    require_supported_recipes(session, owner)
    records = list(session.scalars(select(CookingRecord).where(CookingRecord.owner_id == owner)))
    preserve_statistics(session, records)
    recipes = list(session.scalars(select(Recipe).where(Recipe.owner_id == owner)))
    for recipe in recipes:
        erase_recipe(session, recipe)
    staging = list(
        session.scalars(
            select(RecipeImageStaging.storage_key).where(RecipeImageStaging.owner_id == owner)
        )
    )
    queue_objects(session, staging)
    # Explicit list: adding a new personal domain must extend erasure as well as
    # export. Retaining the User tombstone means FK cascades alone are not enough.
    for model, column in (
        (WriteFactOutbox, WriteFactOutbox.owner_id),
        (WriteReceipt, WriteReceipt.owner_id),
        (Event, Event.user_id),
        (AnalyticsEvent, AnalyticsEvent.user_id),
        (FieldHistory, FieldHistory.owner_id),
        (FieldEntity, FieldEntity.owner_id),
        (PersonalMeasure, PersonalMeasure.owner_id),
        (CookingRecord, CookingRecord.owner_id),
        (TasteChangeFact, TasteChangeFact.owner_id),
        (TasteProfile, TasteProfile.owner_id),
        (RecipeImageStaging, RecipeImageStaging.owner_id),
        (RecipeSaveOutbox, RecipeSaveOutbox.owner_id),
        (RecipeImport, RecipeImport.owner_id),
        (RecipeModification, RecipeModification.user_id),
        (GenerationRequest, GenerationRequest.user_id),
        (AICall, AICall.user_id),
        (CookingStatisticDedup, CookingStatisticDedup.owner_id),
    ):
        session.execute(delete(model).where(column == owner))
    session.flush()
