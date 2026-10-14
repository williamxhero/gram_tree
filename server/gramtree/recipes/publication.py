"""Authoritative automatic publication and a single exact-version read boundary.

All state transitions and experience facts use the caller's database transaction.
The append-only events table is the durable handoff consumed by existing workers;
publication never depends on a client event or a successful Redis call.
"""

from __future__ import annotations

import uuid
from typing import Any, cast

from sqlalchemy import or_, select, tuple_
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from gramtree.accounts.models import RealNameStatus, User
from gramtree.core.errors import ApiError, NotFound
from gramtree.core.pagination import check_limit, decode_cursor, encode_cursor
from gramtree.core.time import utcnow
from gramtree.events.service import append_server_event
from gramtree.recipes import food_safety, reproducibility
from gramtree.recipes.models import (
    Dish,
    Recipe,
    RecipePublication,
    RecipePublicationLicense,
    RecipePublicationNotice,
    RecipeVersion,
)
from gramtree.recipes.publication_schemas import (
    PublicationCondition,
    PublicationNotificationAck,
    PublicationNotificationOut,
    PublicationNotifications,
    PublicationPanel,
)
from gramtree.recipes.schemas import RecipeSnapshot
from gramtree.records.models import CookingRecord
from gramtree.runtime_config import service as config
from gramtree.settings import Settings, get_settings

LICENSE = "菜谱内容按 CC BY-NC-SA 4.0 共享；成品图版权归上传者。"
PUBLIC_STATES = ("published", "pending_verification")


def _settings(session: Session) -> Settings:
    return session.info.get("settings") or get_settings()


def public_enabled(session: Session) -> bool:
    return bool(config.get(session, "feature.public_recipes"))


def _lock_owner(session: Session, owner_id: uuid.UUID) -> None:
    """Acquire the author lock before any recipe lock in publication transactions."""
    session.scalar(select(User.id).where(User.id == owner_id).with_for_update())


def _projection(session: Session, version: RecipeVersion) -> RecipePublication:
    row = session.get(RecipePublication, version.id)
    if row is None:
        row = RecipePublication(version_id=version.id, state="draft")
        session.add(row)
        session.flush()
    return row


def state(session: Session, version: RecipeVersion) -> str:
    row = session.get(RecipePublication, version.id)
    return row.state if row is not None else "draft"


def _risk(session: Session, recipe: Recipe, version: RecipeVersion):
    dish = session.get(Dish, recipe.dish_id)
    if dish is None:
        raise NotFound()
    title, descriptions = food_safety.version_safety_input(session, version, dish)
    return food_safety.check(
        session,
        RecipeSnapshot.model_validate(version.snapshot),
        title,
        descriptions=descriptions,
    )


def _gates(
    session: Session, recipe: Recipe, version: RecipeVersion, row: RecipePublication | None
) -> tuple[list[PublicationCondition], bool, str]:
    result = reproducibility.check(RecipeSnapshot.model_validate(version.snapshot))
    missing: list[PublicationCondition] = []
    if result.state != "reproducible":
        missing.append(
            PublicationCondition(
                code="incomplete",
                label=f"还有 {result.remaining_count} 处需要确定",
                action="resolve_fields",
                remaining_count=result.remaining_count,
            )
        )
    safety = _risk(session, recipe, version)
    if safety.high_risk and (
        row is None or row.risk_confirmed_rules_version != safety.rules_version
    ):
        missing.append(
            PublicationCondition(
                code="risk_confirmation",
                label="高风险菜公开前需要确认风险提示",
                action="confirm_risk",
            )
        )
    if not safety.can_save:
        missing.append(
            PublicationCondition(
                code="moderation",
                label="内容需要改写后再审核",
                action="review",
            )
        )
    author = session.get(User, recipe.owner_id)
    if config.get(session, "publication.require_real_name") and (
        author is None or author.real_name_status != RealNameStatus.verified
    ):
        missing.append(
            PublicationCondition(
                code="real_name",
                label="公开内容需要先完成实名",
                action="verify_identity",
            )
        )
    return missing, safety.high_risk, "high" if safety.high_risk else "standard"


def before_publication_review(
    session: Session, recipe: Recipe, version: RecipeVersion, *, level: str
) -> bool:
    """SPEC-008.2 seam: synchronous pass-through until moderation is connected."""
    return True


def readable_version(
    session: Session,
    viewer: User | uuid.UUID,
    recipe_id: uuid.UUID,
    version_id: uuid.UUID | None = None,
) -> tuple[Recipe, RecipeVersion]:
    viewer_id = viewer.id if isinstance(viewer, User) else viewer
    recipe = session.get(Recipe, recipe_id)
    if recipe is None:
        raise NotFound()
    if recipe.owner_id == viewer_id:
        version = session.get(RecipeVersion, version_id or recipe.current_version_id)
        if version is None or version.recipe_id != recipe.id:
            raise NotFound()
        return recipe, version
    if recipe.withdrawn or not public_enabled(session):
        raise NotFound()
    query = (
        select(RecipeVersion)
        .join(RecipePublication, RecipePublication.version_id == RecipeVersion.id)
        .where(
            RecipeVersion.recipe_id == recipe.id,
            RecipePublication.state.in_(PUBLIC_STATES),
        )
    )
    if version_id is not None:
        query = query.where(RecipeVersion.id == version_id)
    versions = session.scalars(query.order_by(RecipeVersion.version_number.desc()))
    for version in versions:
        row = session.get(RecipePublication, version.id)
        missing, _, level = _gates(session, recipe, version, row)
        if not missing and before_publication_review(session, recipe, version, level=level):
            return recipe, version
    raise NotFound()


def trusted_record(record: CookingRecord) -> bool:
    return (
        record.source == "cooking_session"
        and record.verification == "cooking_mode"
        and record.counts_as_cooked
        and record.source_context.get("server_completed") is True
        and not record.source_context.get("skipped_steps")
    )


def _author_record(session: Session, recipe: Recipe, version: RecipeVersion):
    records = session.scalars(
        select(CookingRecord)
        .where(
            CookingRecord.owner_id == recipe.owner_id,
            CookingRecord.recipe_id == recipe.id,
            CookingRecord.recipe_version_id == version.id,
            CookingRecord.source == "cooking_session",
            CookingRecord.verification == "cooking_mode",
        )
        .order_by(CookingRecord.created_at.desc())
    )
    return next((record for record in records if trusted_record(record)), None)


def append_event(
    session: Session,
    owner_id: uuid.UUID,
    event_type: str,
    recipe: Recipe,
    version: RecipeVersion | None,
    content: dict[str, Any],
) -> None:
    """Reliable same-transaction event delivery; callers lock the transition row."""
    correlation = {"recipe_version_id": str(version.id)} if version else {}
    if content.get("verification_record_id"):
        correlation["cooking_record_id"] = content["verification_record_id"]
    append_server_event(
        session, owner_id, event_type, {"recipe_id": str(recipe.id), **content}, correlation
    )


def check_version(
    session: Session, settings: Settings, recipe: Recipe, version: RecipeVersion
) -> RecipePublication:
    """Evaluate all save paths after trusted derivation callbacks, before commit."""
    row = _projection(session, version)
    # Public transition evidence is immutable; later reads/restore still apply
    # current safety and identity gates at the common read boundary.
    if row.state in PUBLIC_STATES:
        return row
    missing, high_risk, level = _gates(session, recipe, version, row)
    record = _author_record(session, recipe, version)
    if record is None and row.derived_record_id is not None:
        derived_record = session.get(CookingRecord, row.derived_record_id)
        if (
            derived_record
            and derived_record.owner_id == recipe.owner_id
            and trusted_record(derived_record)
        ):
            record = derived_record
    # Publication proof is immutable. Choose the latest actual execution, not
    # first publication time or upload time (an older offline record may arrive late).
    candidates = session.execute(
        select(RecipeVersion, CookingRecord)
        .join(RecipePublication, RecipePublication.version_id == RecipeVersion.id)
        .join(
            CookingRecord,
            or_(
                CookingRecord.recipe_version_id == RecipeVersion.id,
                CookingRecord.id == RecipePublication.derived_record_id,
            ),
        )
        .where(
            RecipeVersion.recipe_id == recipe.id,
            RecipeVersion.version_number < version.version_number,
            RecipePublication.state == "published",
            CookingRecord.source == "cooking_session",
            CookingRecord.verification == "cooking_mode",
        )
        .order_by(
            CookingRecord.occurred_at.desc(),
            CookingRecord.created_at.desc(),
            RecipeVersion.version_number.desc(),
        )
    )
    baseline = next((item for item in candidates if trusted_record(item[1])), None)
    if baseline is not None:
        from gramtree.recipes.full_comparison import compare_full

        author = session.get(User, recipe.owner_id)
        if author is None:
            raise NotFound()
        base, base_record = baseline
        comparison = compare_full(session, author, recipe.id, base.id, version.id, commit=False)
        row.baseline_version_id = base.id
        row.baseline_record_id = base_record.id
        row.cumulative_conclusion = comparison.conclusion
        row.rules_version = comparison.rules_version
    waived = baseline is not None and row.cumulative_conclusion != "significant"
    if record is None and not waived:
        again = baseline is not None
        missing.append(
            PublicationCondition(
                code="cook_again" if again else "not_cooked",
                label="需要再做一次" if again else "做过后会自动公开",
                action="start_cooking",
            )
        )
    row.review_level = level
    row.eligibility = {
        "reproducible": not any(item.code == "incomplete" for item in missing),
        "high_risk": high_risk,
        "risk_confirmed": not any(item.code == "risk_confirmation" for item in missing),
        "real_name_eligible": not any(item.code == "real_name" for item in missing),
        "verification_record_id": str(record.id) if record else None,
        "reverification_waived": waived and record is None,
        "missing": [item.model_dump(mode="json") for item in missing],
    }
    if missing or not before_publication_review(session, recipe, version, level=level):
        return row
    if row.state == "draft":
        now = utcnow()
        row.state = "published" if record else "pending_verification"
        row.published_at = now
        if record is not None:
            row.verification_record_id = record.id
            row.verified_at = now
        recipe.ever_public = True
        recipe.visibility = "public"
        dish = session.get(Dish, recipe.dish_id)
        session.add(
            RecipePublicationNotice(
                owner_id=recipe.owner_id,
                recipe_id=recipe.id,
                version_id=version.id,
                version_number=version.version_number,
                title=dish.name if dish else "菜谱",
            )
        )
        # A unique account receipt makes concurrent first publications idempotent
        # without taking an author lock after a recipe lock.
        session.execute(
            insert(RecipePublicationLicense)
            .values(owner_id=recipe.owner_id)
            .on_conflict_do_nothing(index_elements=[RecipePublicationLicense.owner_id])
        )
        append_event(
            session,
            recipe.owner_id,
            "recipe.version_published",
            recipe,
            version,
            {
                "version_id": str(version.id),
                "state": row.state,
                "verification_record_id": str(record.id) if record else None,
                "baseline_version_id": str(row.baseline_version_id)
                if row.baseline_version_id
                else None,
                "baseline_record_id": str(row.baseline_record_id)
                if row.baseline_record_id
                else None,
                "conclusion": row.cumulative_conclusion,
                "rules_version": row.rules_version,
                "eligibility": row.eligibility,
                "review_level": level,
            },
        )
    session.flush()
    return row


def record_completed(session: Session, settings: Settings, record: CookingRecord) -> None:
    if not trusted_record(record) or record.recipe_version_id is None:
        return
    version = session.get(RecipeVersion, record.recipe_version_id)
    if version is None or version.recipe_id != record.recipe_id:
        return
    _lock_owner(session, record.owner_id)
    recipe = session.scalar(select(Recipe).where(Recipe.id == version.recipe_id).with_for_update())
    if recipe is None:
        return
    row = _projection(session, version)
    if row.state == "pending_verification":
        row.state = "published"
        row.verification_record_id = record.id
        row.verified_at = utcnow()
        append_event(
            session,
            record.owner_id,
            "recipe.pending_verification_cleared",
            recipe,
            version,
            {
                "version_id": str(version.id),
                "verification_record_id": str(record.id),
                "baseline_version_id": str(row.baseline_version_id)
                if row.baseline_version_id
                else None,
                "conclusion": row.cumulative_conclusion,
                "rules_version": row.rules_version,
            },
        )
    elif record.owner_id == recipe.owner_id:
        check_version(session, settings, recipe, version)
    # A completed version is the new cumulative baseline. Re-evaluate newer drafts
    # so risk/identity fixes or cooking an old version don't need another edit.
    for draft in session.scalars(
        select(RecipeVersion)
        .where(
            RecipeVersion.recipe_id == recipe.id,
            RecipeVersion.version_number > version.version_number,
        )
        .order_by(RecipeVersion.version_number)
    ):
        check_version(session, settings, recipe, draft)
    session.flush()


def trusted_record_derivation(
    session: Session,
    record: CookingRecord,
    target_version: RecipeVersion,
    expected_snapshot: RecipeSnapshot | dict[str, Any] | None = None,
) -> None:
    """Only server save callbacks may bind a verified execution to a new version."""
    recipe = session.get(Recipe, target_version.recipe_id)
    persisted = session.get(CookingRecord, record.id)
    executed = record.source_context.get("executed_snapshot")
    if (
        recipe is None
        or persisted is None
        or record.owner_id != recipe.owner_id
        or not trusted_record(record)
        or record.source_context.get("derivation_available") is not True
        or not executed
        or (
            recipe.source_version_id != record.recipe_version_id
            if recipe.id != record.recipe_id
            else target_version.base_version_id != record.recipe_version_id
        )
    ):
        raise ApiError(422, "invalid_publication_proof", "这条记录不能证明新版本做过")
    expected = RecipeSnapshot.model_validate(expected_snapshot or executed)
    actual = RecipeSnapshot.model_validate(target_version.snapshot)
    # Expected is computed by the trusted records save path, not accepted in a
    # public request. Normalized amount/provenance metadata can differ on save.
    fields = {"base_quantity", "base_unit", "quantity_source", "flavor_source", "functional_source"}

    def execution(value: RecipeSnapshot):
        data = value.model_dump(mode="json")
        for item in data["ingredients"]:
            for key in fields:
                item.pop(key, None)
        return data

    if execution(expected) != execution(actual):
        raise ApiError(422, "invalid_publication_proof", "新版本与实际做过的内容不一致")
    _projection(session, target_version).derived_record_id = record.id


def panel(
    session: Session, owner: User, recipe_id: uuid.UUID, version_id: uuid.UUID | None = None
) -> PublicationPanel:
    from gramtree.recipes.service import _owned_version

    _lock_owner(session, owner.id)
    recipe, version = _owned_version(session, owner, recipe_id, version_id)
    session.scalar(select(Recipe).where(Recipe.id == recipe.id).with_for_update())
    row = check_version(session, _settings(session), recipe, version)
    session.commit()
    return PublicationPanel(
        state="withdrawn" if recipe.withdrawn else cast(Any, row.state),
        ever_public=recipe.ever_public,
        missing=[
            PublicationCondition.model_validate(item) for item in row.eligibility.get("missing", [])
        ],
        baseline_version_id=row.baseline_version_id,
        cumulative_conclusion=row.cumulative_conclusion,
        rules_version=row.rules_version,
        high_risk=row.eligibility.get("high_risk", False),
        review_level=cast(Any, row.review_level),
    )


def confirm_risk(session: Session, owner: User, recipe_id: uuid.UUID, version_id: uuid.UUID):
    from gramtree.recipes import service

    _lock_owner(session, owner.id)
    recipe, version = service._owned_version(session, owner, recipe_id, version_id)
    session.scalar(select(Recipe).where(Recipe.id == recipe.id).with_for_update())
    _projection(session, version).risk_confirmed_rules_version = _risk(
        session, recipe, version
    ).rules_version
    check_version(session, _settings(session), recipe, version)
    session.commit()
    return service._detail(session, _settings(session), recipe, version)


def set_withdrawn(session: Session, owner: User, recipe_id: uuid.UUID, withdrawn: bool):
    from gramtree.recipes import service

    _lock_owner(session, owner.id)
    recipe = session.scalar(
        select(Recipe).where(Recipe.id == recipe_id, Recipe.owner_id == owner.id).with_for_update()
    )
    if recipe is None:
        raise NotFound()
    if not recipe.ever_public:
        raise ApiError(409, "never_published", "从未公开的草稿可以删除，无需下架")
    if recipe.withdrawn != withdrawn:
        recipe.withdrawn = withdrawn
        recipe.lifecycle_sequence += 1
        append_event(
            session,
            owner.id,
            "recipe.withdrawn" if withdrawn else "recipe.restored",
            recipe,
            None,
            {
                "actor_id": str(owner.id),
                "sequence": recipe.lifecycle_sequence,
            },
        )
    session.commit()
    return service._detail(session, _settings(session), recipe)


def notifications(
    session: Session, owner: User, *, cursor: str | None, limit: int
) -> PublicationNotifications:
    check_limit(limit, int(config.get(session, "api.page_size_max")))
    query = select(RecipePublicationNotice).where(
        RecipePublicationNotice.owner_id == owner.id, RecipePublicationNotice.seen_at.is_(None)
    )
    if cursor:
        created_at, notice_id = decode_cursor(cursor)
        query = query.where(
            tuple_(RecipePublicationNotice.created_at, RecipePublicationNotice.id)
            > tuple_(created_at, notice_id)
        )
    rows = list(
        session.scalars(
            query.order_by(RecipePublicationNotice.created_at, RecipePublicationNotice.id).limit(
                limit + 1
            )
        )
    )
    next_cursor = (
        encode_cursor(rows[limit - 1].created_at, rows[limit - 1].id) if len(rows) > limit else None
    )
    rows = rows[:limit]
    license_row = session.get(RecipePublicationLicense, owner.id)
    return PublicationNotifications(
        items=[
            PublicationNotificationOut(
                id=row.id,
                recipe_id=row.recipe_id,
                version_id=row.version_id,
                version_number=row.version_number,
                title=row.title,
                message=f"{row.title}第 {row.version_number} 版已公开",
            )
            for row in rows
        ],
        next_cursor=next_cursor,
        license_notice=LICENSE if license_row is not None and license_row.seen_at is None else None,
    )


def acknowledge(session: Session, owner: User, body: PublicationNotificationAck) -> None:
    for row in session.scalars(
        select(RecipePublicationNotice).where(
            RecipePublicationNotice.owner_id == owner.id,
            RecipePublicationNotice.id.in_(body.notification_ids),
        )
    ):
        row.seen_at = row.seen_at or utcnow()
    if body.license_seen:
        row = session.get(RecipePublicationLicense, owner.id)
        if row is not None:
            row.seen_at = row.seen_at or utcnow()
    session.commit()
