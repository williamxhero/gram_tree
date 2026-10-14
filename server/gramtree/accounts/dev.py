"""开发和测试环境才挂载的辅助接口：读出最近发给某个邮箱的验证码。

端到端测试（网页版、安卓模拟器）用它代替收邮件。正式环境不挂载，也不进 OpenAPI 描述。
"""

import re
import uuid

from fastapi import APIRouter, Query
from sqlalchemy import func, select

from gramtree.accounts.deps import CurrentAuth, MailerDep
from gramtree.accounts.mailer import MemoryMailSender
from gramtree.accounts.models import User, UserStatus
from gramtree.core.errors import NotFound
from gramtree.deps import SessionDep, SettingsDep

router = APIRouter(prefix="/dev", include_in_schema=False)


@router.get("/latest-email-code")
def latest_email_code(mailer: MailerDep, email: str = Query()) -> dict[str, str]:
    if not isinstance(mailer, MemoryMailSender):
        raise NotFound("mail backend is not memory")
    mail = mailer.latest_to(email.strip().lower())
    match = re.search(r"\b(\d{6})\b", mail.body) if mail else None
    if match is None:
        raise NotFound("no code sent to this address")
    return {"code": match.group(1)}


@router.get("/deletion-storage")
def deletion_storage(
    auth: CurrentAuth,
    session: SessionDep,
    settings: SettingsDep,
    owner_id: uuid.UUID | None = None,
) -> dict:
    """Test-only counts and allowlisted aggregates, never personal payloads.

    Mirrors the existing taste-profile-storage observer: another active account
    cannot inspect live accounts, but can verify a completed erasure tombstone.
    """
    from gramtree.accounts.deletion_models import (
        AccountDeletion,
        AnonymousCookingStatistic,
        CookingStatisticDedup,
        PendingObjectErasure,
    )
    from gramtree.ai.models import AICall, GenerationRequest, RecipeModification
    from gramtree.analytics.models import AnalyticsEvent
    from gramtree.events.models import Event
    from gramtree.events.sync_models import WriteFactOutbox, WriteReceipt
    from gramtree.exports.models import ExportJob
    from gramtree.recipes.import_models import RecipeImport
    from gramtree.recipes.measure_models import PersonalMeasure
    from gramtree.recipes.models import Recipe, RecipeImageStaging, RecipeSaveOutbox
    from gramtree.records.models import CookingRecord
    from gramtree.taste_profiles.learning_models import TasteChangeFact
    from gramtree.taste_profiles.models import FamilyMember, TasteProfile

    if settings.env != "test":
        raise NotFound()
    owner = owner_id or auth.user.id
    if (
        owner != auth.user.id
        and session.scalar(select(User.status).where(User.id == owner)) != UserStatus.deleted
    ):
        raise NotFound()
    owned = (
        (Recipe, Recipe.owner_id),
        (CookingRecord, CookingRecord.owner_id),
        (RecipeImport, RecipeImport.owner_id),
        (RecipeImageStaging, RecipeImageStaging.owner_id),
        (RecipeSaveOutbox, RecipeSaveOutbox.owner_id),
        (Event, Event.user_id),
        (AnalyticsEvent, AnalyticsEvent.user_id),
        (WriteReceipt, WriteReceipt.owner_id),
        (WriteFactOutbox, WriteFactOutbox.owner_id),
        (TasteProfile, TasteProfile.owner_id),
        (FamilyMember, FamilyMember.owner_id),
        (PersonalMeasure, PersonalMeasure.owner_id),
        (TasteChangeFact, TasteChangeFact.owner_id),
        (AICall, AICall.user_id),
        (GenerationRequest, GenerationRequest.user_id),
        (RecipeModification, RecipeModification.user_id),
        (CookingStatisticDedup, CookingStatisticDedup.owner_id),
        (ExportJob, ExportJob.owner_id),
    )
    counts = {
        model.__tablename__: session.scalar(
            select(func.count()).select_from(model).where(column == owner)
        )
        for model, column in owned
    }
    job = session.get(AccountDeletion, owner)
    stats = list(session.scalars(select(AnonymousCookingStatistic)))
    return {
        "owned_counts": counts,
        "steps": job.steps if job else {},
        "completed_at": job.completed_at.isoformat() if job and job.completed_at else None,
        "due_at": job.due_at.isoformat() if job else None,
        "pending_objects": session.scalar(select(func.count()).select_from(PendingObjectErasure)),
        "anonymous_statistics": [
            {
                "recipe_version_id": str(row.recipe_version_id),
                "week": row.week.isoformat(),
                "dimensions": row.dimensions,
                "contributions": row.contributions,
            }
            for row in stats
        ],
    }
