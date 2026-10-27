"""Disposable owner-scoped Redis cache with database-derived dependencies."""

import hashlib
import json
import logging
import uuid
from typing import cast

from pydantic import ValidationError
from redis import Redis, RedisError
from sqlalchemy import text
from sqlalchemy.orm import Session

from gramtree.dietary_history.models import DietaryRange
from gramtree.dietary_history.schemas import DietaryPeriod, DietaryStatisticsOut

logger = logging.getLogger(__name__)
PREFIX = "dietary:statistics"

# xmin is PostgreSQL's row revision. Hash all row identities/revisions, not just
# count/max(created_at): deleting an older row or appending a backdated record
# must invalidate too. No writer hooks are needed, including durable sync paths.
# Only hashes leave the database. Shared catalogue/resolver changes also matter.
_DEPENDENCIES = text("""
SELECT md5(coalesce(string_agg(part, ',' ORDER BY part), '')) FROM (
    SELECT 'record:' || id::text || ':' || xmin::text AS part
    FROM cooking_records WHERE owner_id = :owner
    UNION ALL
    SELECT 'revision:' || id::text || ':' || xmin::text
    FROM cooking_record_revisions WHERE owner_id = :owner
    UNION ALL
    SELECT 'version:' || v.id::text || ':' || v.xmin::text
    FROM recipe_versions v WHERE EXISTS (
        SELECT 1 FROM cooking_records r
        WHERE r.owner_id = :owner AND r.recipe_version_id = v.id
    )
    UNION ALL
    SELECT 'recipe:' || p.id::text || ':' || p.xmin::text
    FROM recipes p WHERE EXISTS (
        SELECT 1 FROM cooking_records r JOIN recipe_versions v ON r.recipe_version_id = v.id
        WHERE r.owner_id = :owner AND v.recipe_id = p.id
    )
    UNION ALL
    SELECT 'ingredient:' || id::text || ':' || xmin::text FROM ingredients
    UNION ALL
    SELECT 'dish:' || id::text || ':' || xmin::text FROM dishes
    UNION ALL
    SELECT 'alias:' || id::text || ':' || xmin::text FROM dish_aliases
) AS dependencies
""")


def cache_key(
    session: Session, owner: uuid.UUID, period: DietaryPeriod, bounds: DietaryRange
) -> str:
    revision = session.scalar(_DEPENDENCIES, {"owner": owner})
    fingerprint = hashlib.sha256(
        json.dumps(
            [
                "v1",
                period,
                bounds.timezone,
                str(bounds.local_start),
                str(bounds.local_end),
                revision,
            ]
        ).encode()
    ).hexdigest()
    return f"{PREFIX}:{owner}:{fingerprint}"


def get(client: Redis, key: str) -> DietaryStatisticsOut | None:
    try:
        raw = cast("bytes | None", client.get(key))
        return DietaryStatisticsOut.model_validate_json(raw) if raw is not None else None
    except (RedisError, ValidationError, ValueError):
        logger.warning("Dietary statistics cache unavailable or invalid; recomputing")
        return None


def set_(client: Redis, key: str, result: DietaryStatisticsOut) -> None:
    try:
        client.set(key, result.model_dump_json(), ex=3600)
    except RedisError:
        logger.warning("Dietary statistics cache unavailable; skipping write")
