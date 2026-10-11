"""Deletion boundary for model-derived private artifacts.

Callers retain non-sensitive accounting rows when useful, but remove request and
response bodies before sensitive withdrawal, member deletion, logout, or purge.
"""

import uuid

from sqlalchemy import delete, select, update
from sqlalchemy.orm import Session

from gramtree.ai.models import AICall, GenerationLog, GenerationRequest

_CAPABILITIES = ("intent", "generate", "normalize", "modify", "modify_intent", "explain")


def clear_user_content(session: Session, user_id: uuid.UUID) -> None:
    call_ids = select(AICall.id).where(
        AICall.user_id == user_id, AICall.capability.in_(_CAPABILITIES)
    )
    session.execute(delete(GenerationLog).where(GenerationLog.call_id.in_(call_ids)))
    # Saved recipes are independent records. Unsaved drafts and original request
    # text are cleared in place so a retry cannot resurrect withdrawn context.
    session.execute(
        update(GenerationRequest)
        .where(GenerationRequest.user_id == user_id)
        .values(text="", intent={}, questions=[], draft=None, context_dependency={})
    )


def clear_request_content(session: Session, request_ids: set[uuid.UUID]) -> None:
    if not request_ids:
        return
    call_ids = select(AICall.id).where(AICall.content_id.in_(request_ids))
    session.execute(delete(GenerationLog).where(GenerationLog.call_id.in_(call_ids)))
    session.execute(
        update(GenerationRequest)
        .where(GenerationRequest.id.in_(request_ids))
        .values(text="", intent={}, questions=[], draft=None, context_dependency={})
    )
