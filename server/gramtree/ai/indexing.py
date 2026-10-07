"""Durable embedding work; model failure never blocks saving or keyword retrieval."""

import uuid
from datetime import timedelta
from typing import Any

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from gramtree.ai import gateway
from gramtree.ai.models import GenerationLog, GenerationRequest, RecipeEmbedding
from gramtree.core.time import utcnow
from gramtree.recipes.models import Dish, Recipe, RecipeVersion
from gramtree.runtime_config import service as config
from gramtree.settings import Settings


def enqueue(session: Session, recipe: Recipe, version: RecipeVersion) -> None:
    dish = session.get(Dish, recipe.dish_id)
    snapshot = version.snapshot
    text = " ".join(
        [
            dish.name if dish else "",
            *[i["display_name"] for i in snapshot["ingredients"]],
            *[s.get("action") or s["instruction"] for s in snapshot["steps"]],
        ]
    )
    session.add(RecipeEmbedding(version_id=version.id, text=text))


def run(session: Session, settings: Settings, limit: int = 100) -> dict[str, int]:
    completed = failed = 0
    for _ in range(limit):
        row = session.scalar(
            select(RecipeEmbedding)
            .where(
                (RecipeEmbedding.status == "pending")
                | (
                    (RecipeEmbedding.status == "running")
                    & (RecipeEmbedding.updated_at < utcnow() - timedelta(minutes=5))
                )
            )
            .order_by(RecipeEmbedding.updated_at)
            .with_for_update(skip_locked=True)
            .limit(1)
        )
        if row is None:
            break
        version = session.get(RecipeVersion, row.version_id)
        recipe = session.get(Recipe, version.recipe_id) if version else None
        if recipe is None:
            session.delete(row)
            session.commit()
            continue
        row.status = "running"
        row.attempts += 1
        row.updated_at = utcnow()
        session.commit()
        try:
            model, _ = gateway.route(session, "embedding")
            raw = gateway.call(
                session,
                settings,
                recipe.owner_id,
                "embedding",
                {"text": row.text},
                uuid.uuid4(),
                content_id=row.version_id,
            )
            row.vector = gateway.embedding(raw)
            row.model = model.model
            row.status = "ready"
            completed += 1
        except (gateway.Unavailable, ValueError, TypeError):
            row.status = "pending"
            failed += 1
        row.updated_at = utcnow()
        session.commit()
        if failed:
            break  # Avoid spinning on an unavailable provider or exhausted budget.
    return {"completed": completed, "failed": failed}


def purge(session: Session) -> dict[str, Any]:
    cutoff = utcnow() - timedelta(days=int(config.get(session, "ai.log_retention_days")))
    logs = len(
        list(
            session.scalars(
                delete(GenerationLog)
                .where(GenerationLog.created_at < cutoff)
                .returning(GenerationLog.id)
            )
        )
    )
    requests = len(
        list(
            session.scalars(
                delete(GenerationRequest)
                .where(GenerationRequest.created_at < cutoff)
                .returning(GenerationRequest.id)
            )
        )
    )
    session.commit()
    return {"logs": logs, "requests": requests}
