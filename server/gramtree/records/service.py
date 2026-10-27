"""Authoritative facts emitted when a cooking record is created."""

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.core.ids import new_id
from gramtree.core.time import utcnow
from gramtree.events.models import Event
from gramtree.events.service import EventInput, _fingerprint
from gramtree.records.models import CookingRecord
from gramtree.records.schemas import CookingRecordCreate


def matches_submission(
    row: CookingRecord,
    body: CookingRecordCreate,
    verification: str,
    source_context: dict,
) -> bool:
    """An append-only client ID may replay, but may not replace saved content."""
    return (
        row.recipe_version_id == body.recipe_version_id
        and (body.recipe_id is None or row.recipe_id == body.recipe_id)
        and row.source == body.source
        and row.dish_name == body.dish_name
        and row.meal == body.meal
        and row.verification == verification
        and row.snapshot == body.snapshot
        and row.adjustments == body.adjustments
        and row.source_context == source_context
        and (body.occurred_at is None or row.occurred_at == body.occurred_at)
        and row.co_diner_ids == [str(item) for item in body.co_diner_ids]
        and row.photos == body.photos
    )


def record_created_event(session: Session, owner: uuid.UUID, row: CookingRecord) -> None:
    """Append the immutable creation fact in the caller's transaction.

    Direct HTTP creation and offline sync share this helper so both paths have
    the same audit fact and retries never create a second event.
    """
    if (
        session.scalar(
            select(Event.id).where(
                Event.user_id == owner,
                Event.event_type == "cooking.record_created",
                Event.correlation["cooking_record_id"].astext == str(row.id),
            )
        )
        is not None
    ):
        return
    now = utcnow()
    item = EventInput(
        id=new_id(),
        event_type="cooking.record_created",
        type_version=1,
        device_id="server",
        device_time=row.occurred_at,
        app_version="server",
        correlation={
            "cooking_record_id": str(row.id),
            **(
                {"recipe_version_id": str(row.recipe_version_id)}
                if row.recipe_version_id is not None
                else {}
            ),
        },
        content={
            "record_id": str(row.id),
            "client_id": str(row.client_id),
            "source": row.source,
            "verification": row.verification,
            "counts_as_cooked": row.counts_as_cooked,
        },
    )
    session.add(
        Event(
            id=item.id,
            user_id=owner,
            event_type=item.event_type,
            type_version=item.type_version,
            device_id=item.device_id,
            device_time=item.device_time,
            app_version=item.app_version,
            correlation=item.correlation,
            content=item.content,
            content_fingerprint=_fingerprint(owner, item),
            received_at=now,
            device_time_suspicious=False,
        )
    )
