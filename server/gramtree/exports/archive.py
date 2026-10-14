"""Explicit personal-entity allowlist. Never iterate all owner-bearing database tables.

Internal logs, caches, trust and aggregate tables are deliberately not portable.
The sensitive-store boundary is unchanged: encrypted family/allergy values are
not copied or decrypted here. The manifest makes that limitation explicit.
"""

import json
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any
from zipfile import ZIP_DEFLATED, ZipFile

from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.accounts.models import Consent, Identity, User
from gramtree.ai.models import GenerationRequest, RecipeModification
from gramtree.events.models import Event
from gramtree.events.registry import BY_KEY
from gramtree.recipes import imports
from gramtree.recipes.import_models import RecipeImport
from gramtree.recipes.measure_models import PersonalMeasure
from gramtree.recipes.models import (
    Dish,
    Recipe,
    RecipeImage,
    RecipeImageStaging,
    RecipeQuantification,
    RecipeVersion,
)
from gramtree.recipes.storage import make_recipe_storage
from gramtree.records.models import CookingRecord, CookingRecordRevision
from gramtree.settings import Settings
from gramtree.taste_profiles.models import TasteProfile, TasteProfileChange

FORMAT_VERSION = 1
UNAVAILABLE_ENTITIES = {
    "family_members": "Sensitive export authorization is not defined by the existing boundary.",
    "allergies": "Existing sensitive-data contract excludes export, including encrypted history.",
    "inventory": "No persisted server entity in this release.",
    "shopping_lists": "No persisted server entity in this release.",
    "prices": "No persisted server entity in this release.",
    "menus": "No persisted server entity in this release.",
    "plans": "No persisted server entity in this release.",
    "suggestions": "No persisted social suggestion entity in this release.",
    "favorites": "No persisted server entity in this release.",
    "likes": "No persisted server entity in this release.",
    "blocks": "No persisted server entity in this release.",
    "public_feedback": (
        "No persisted public feedback entity in this release; personal revisions included."
    ),
    "cooking_photos": (
        "No persisted cooking-photo entity in this release; recipe photos included."
    ),
    "recommendations": (
        "No persisted recommendation entity in this release; registered events included."
    ),
    "local_unsynced_drafts": (
        "Client-local recipe drafts and pending offline writes are not on the server."
    ),
}
# Defense in depth for old arbitrary JSON snapshots and future event payloads.
# Counts in user recipes (e.g. servings) are not aggregate people/signal counts.
INTERNAL_KEYS = frozenset(
    {
        "trust",
        "trust_score",
        "trust_level",
        "risk",
        "risk_score",
        "risk_flags",
        "score",
        "scores",
        "count",
        "counts",
        "people_count",
        "user_count",
        "sample_count",
        "rating_count",
        "cooked_count",
        "aggregate",
        "aggregates",
        "internal_score",
        "content_fingerprint",
        "device_time_suspicious",
        "audit_log",
        "access_log",
        "source_recipe",
        "source_recipe_snapshot",
        "source_snapshot",
    }
)


def portable(value: Any) -> Any:
    if isinstance(value, dict):
        return {key: portable(item) for key, item in value.items() if key not in INTERNAL_KEYS}
    if isinstance(value, list):
        return [portable(item) for item in value]
    if isinstance(value, (uuid.UUID, datetime)):
        return str(value) if isinstance(value, uuid.UUID) else value.isoformat()
    return value


def fields(row: Any, names: str) -> dict[str, Any]:
    return portable({name: getattr(row, name) for name in names.split()})


def source_reference(session: Session, version_id: uuid.UUID | None) -> dict | None:
    if version_id is None:
        return None
    version = session.get(RecipeVersion, version_id)
    if version is None:
        return None
    recipe = session.get(Recipe, version.recipe_id)
    if recipe is None:
        return None
    author = session.get(User, recipe.owner_id)
    dish = session.get(Dish, recipe.dish_id)
    return {
        "nickname": author.nickname if author else "已注销用户",
        "title": dish.name if dish else "",
        "version": version.version_number,
        "link": f"/recipes/{recipe.id}/versions/{version.id}",
    }


def build(session: Session, settings: Settings, owner: User, path: Path, now: datetime) -> None:
    owner_id = owner.id
    entities: dict[str, list[dict[str, Any]]] = {}
    entities["account"] = [fields(owner, "id nickname timezone phone real_name_status created_at")]
    entities["identities"] = [
        fields(row, "id kind email created_at")
        for row in session.scalars(select(Identity).where(Identity.user_id == owner_id))
    ]
    entities["consents"] = [
        fields(row, "id kind version action occurred_at received_at device_id")
        for row in session.scalars(select(Consent).where(Consent.user_id == owner_id))
    ]
    recipes = list(session.scalars(select(Recipe).where(Recipe.owner_id == owner_id)))
    entities["recipes"] = []
    for recipe in recipes:
        dish = session.get(Dish, recipe.dish_id)
        entities["recipes"].append(
            {
                **fields(
                    recipe,
                    "id dish_id visibility current_version_id source_version_id "
                    "root_recipe_id created_at updated_at",
                ),
                "title": dish.name if dish else "",
                "source": source_reference(session, recipe.source_version_id),
            }
        )
    recipe_ids = [row.id for row in recipes]
    entities["recipe_versions"] = [
        fields(
            row,
            "id recipe_id version_number previous_version_id base_version_id conclusion "
            "rules_version snapshot derived reproducibility safety_at_save safety_current "
            "safety_rules_version safety_context edit_operations change_note "
            "ai_assisted created_at",
        )
        for row in session.scalars(
            select(RecipeVersion).where(RecipeVersion.recipe_id.in_(recipe_ids))
        )
    ]
    entities["quantification_suggestions"] = [
        {
            **fields(
                row, "id recipe_id base_version_id proposals decisions saved_version_id created_at"
            ),
            "ai_assisted": True,
        }
        for row in session.scalars(
            select(RecipeQuantification).where(RecipeQuantification.recipe_id.in_(recipe_ids))
        )
    ]
    entities["cooking_records"] = [
        fields(
            row,
            "id client_id recipe_id recipe_version_id dish_name source verification "
            "counts_as_cooked meal occurred_at snapshot adjustments source_context "
            "taste_summary co_diner_ids created_at",
        )
        for row in session.scalars(select(CookingRecord).where(CookingRecord.owner_id == owner_id))
    ]
    entities["cooking_record_revisions"] = [
        fields(row, "id record_id revision_id revision field value note created_at")
        for row in session.scalars(
            select(CookingRecordRevision).where(CookingRecordRevision.owner_id == owner_id)
        )
    ]
    entities["taste_profiles"] = [
        fields(
            row,
            "id version flavors local_cuisines ingredient_preferences "
            "cooking_constraints locked_fields created_at updated_at",
        )
        for row in session.scalars(select(TasteProfile).where(TasteProfile.owner_id == owner_id))
    ]
    entities["taste_profile_changes"] = []
    for row in session.scalars(
        select(TasteProfileChange).where(TasteProfileChange.owner_id == owner_id)
    ):
        value = fields(
            row,
            "id profile_id version field reason source status origin source_record_ids "
            "locked_fields effective_at effective_version reverted_at created_at",
        )
        if row.field == "allergies" or row.field.startswith("family_members"):
            value["values_withheld"] = "sensitive_export_not_authorized"
        else:
            value.update(fields(row, "old_value new_value"))
        entities["taste_profile_changes"].append(value)
    entities["personal_measures"] = [
        fields(row, "id name kind capacity_ml created_at updated_at deleted_at")
        for row in session.scalars(
            select(PersonalMeasure).where(PersonalMeasure.owner_id == owner_id)
        )
    ]
    entities["ai_generation_drafts"] = [
        {
            **fields(
                row, "id text intent questions draft saved_recipe_id selected_recipe_id created_at"
            ),
            "ai_assisted": True,
        }
        for row in session.scalars(
            select(GenerationRequest).where(GenerationRequest.user_id == owner_id)
        )
    ]
    entities["ai_modification_suggestions"] = [
        {
            **fields(
                row,
                "id recipe_id base_version_id generation_request_id request proposal "
                "decisions revision saved_version_id confirmation created_at",
            ),
            "ai_assisted": True,
        }
        for row in session.scalars(
            select(RecipeModification).where(RecipeModification.user_id == owner_id)
        )
    ]
    # Do not include baseline: it can be a full snapshot of somebody else's recipe.
    entities["recipe_imports"] = [
        {
            **fields(
                row,
                "id recipe_id mode source_url source_platform status reason "
                "field_states created_at",
            ),
            "original_text": imports._decrypt(settings, row),
        }
        for row in session.scalars(select(RecipeImport).where(RecipeImport.owner_id == owner_id))
    ]
    entities["events"] = []
    for event in session.scalars(select(Event).where(Event.user_id == owner_id)):
        spec = BY_KEY.get((event.event_type, event.type_version))
        if spec is None or not spec.exportable:
            continue
        value = fields(
            event,
            "id event_type type_version device_id device_time app_version correlation received_at",
        )
        # Registry schemas strip historical extra keys rather than trusting arbitrary JSON.
        content = (
            spec.content_schema.model_validate(event.content).model_dump(mode="json")
            if spec.content_schema
            else event.content
        )
        value["content"] = portable(content)
        entities["events"].append(value)

    images = list(session.scalars(select(RecipeImage).where(RecipeImage.recipe_id.in_(recipe_ids))))
    images += list(
        session.scalars(select(RecipeImageStaging).where(RecipeImageStaging.owner_id == owner_id))
    )
    storage = make_recipe_storage(settings)
    entities["photos"] = []
    with ZipFile(path, "w", compression=ZIP_DEFLATED) as archive:
        for image in images:
            extension = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"}.get(
                image.content_type, "img"
            )
            filename = f"photos/{image.id}.{extension}"
            # Stored upload bytes are already EXIF-stripped; never re-encode the original.
            archive.writestr(filename, storage.get(image.storage_key))
            entities["photos"].append(
                {
                    **fields(image, "id content_type byte_size width height created_at"),
                    "path": filename,
                    "recipe_id": str(image.recipe_id) if isinstance(image, RecipeImage) else None,
                    "version_id": str(image.version_id) if isinstance(image, RecipeImage) else None,
                    "staged": isinstance(image, RecipeImageStaging),
                }
            )
        for entity, items in entities.items():
            archive.writestr(
                f"{entity}.json",
                json.dumps(
                    {
                        "format_version": FORMAT_VERSION,
                        "entity": entity,
                        "items": items,
                    },
                    ensure_ascii=False,
                    sort_keys=True,
                ),
            )
        archive.writestr(
            "manifest.json",
            json.dumps(
                {
                    "format_version": FORMAT_VERSION,
                    "exported_at": now.isoformat(),
                    "owner_id": str(owner_id),
                    "format_documentation": "/data-export-format",
                    "supported_entities": sorted(entities),
                    "unavailable_entities": UNAVAILABLE_ENTITIES,
                    "scope": "supported_server_entities_only",
                    "complete_spec47_export": False,
                    "excluded": [
                        "foreign_content",
                        "trust_and_risk",
                        "internal_aggregates",
                        "audit_and_access_logs",
                        "credentials",
                        "sensitive_encrypted_values",
                    ],
                },
                ensure_ascii=False,
                sort_keys=True,
            ),
        )
