"""开发和测试环境才挂载的辅助接口：查询当前登录用户已入库的事件条数。

只用于端到端测试确认"服务端每条事件只收到一次"（SPEC-010.1 票 7：安卓模拟器离线
补传、网页版端到端）——只回一个数字，不回事件内容，也不回具体记录的任何字段，不是
票 1 定下的"事件表没有对外可读明细接口"这条规矩的例外。正式环境不挂载，也不进
OpenAPI 描述，写法照抄 `gramtree.accounts.dev`。

内部实现直接调用票 3 已经有的 `gramtree.events.queries.query_events`，不另开一条
查询路径。
"""

import uuid

from fastapi import APIRouter, Query
from sqlalchemy import func, select

from gramtree.accounts.deps import CurrentAuth
from gramtree.accounts.models import User, UserStatus
from gramtree.core.errors import ApiError, NotFound
from gramtree.deps import SessionDep, SettingsDep
from gramtree.events.models import Event
from gramtree.events.queries import query_events
from gramtree.events.sync_models import WriteFactOutbox, WriteReceipt
from gramtree.taste_profiles import allergies
from gramtree.taste_profiles.models import (
    FamilyMember,
    OwnerAllergies,
    TasteProfile,
    TasteProfileChange,
)

router = APIRouter(prefix="/dev/events", include_in_schema=False)


@router.get("/count")
def count_events(
    auth: CurrentAuth,
    session: SessionDep,
    event_type: str = Query(),
    version: int | None = Query(default=None, description="不给就统计这个类型的所有版本"),
    device_id: str | None = Query(default=None, description="不给就不按设备过滤"),
) -> dict[str, int]:
    events = query_events(
        session,
        user_id=auth.user.id,
        event_type=event_type,
        version=version,
    )
    if device_id is not None:
        events = [e for e in events if e.device_id == device_id]
    return {"count": len(events)}


@router.get("/taste-profile-storage")
def taste_profile_storage(
    auth: CurrentAuth,
    session: SessionDep,
    settings: SettingsDep,
    owner_id: uuid.UUID | None = None,
    include_sensitive: bool = False,
) -> dict[str, int | bool]:
    """Test-only aggregates: prove metadata minimization and actual account purge.

    Never expose values, history, event payloads, or identifiers. Active accounts
    can only inspect their own storage. A logged-in test observer may inspect a
    deleted tombstone's counts so purge verification does not require SQL tests
    or accepting revoked credentials. This route is absent from OpenAPI/prod.
    """
    if settings.env != "test":
        raise NotFound()
    owner = owner_id or auth.user.id
    if owner != auth.user.id:
        status = session.scalar(select(User.status).where(User.id == owner))
        if status != UserStatus.deleted:
            raise NotFound()
    change_rows = list(
        session.scalars(select(TasteProfileChange).where(TasteProfileChange.owner_id == owner))
    )
    changes = {row.id for row in change_rows}
    members = list(session.scalars(select(FamilyMember).where(FamilyMember.owner_id == owner)))
    owner_allergies = session.get(OwnerAllergies, owner)
    sensitive_changes = [
        row
        for row in change_rows
        if row.field == "allergies" or row.field.startswith("family_members.")
    ]
    current_encrypted = history_encrypted = True
    try:
        for member in members:
            allergies.decrypt(settings, owner, f"member:{member.id}:current", member.ciphertext)
        if owner_allergies:
            allergies.decrypt(settings, owner, "current", owner_allergies.ciphertext)
    except ApiError:
        current_encrypted = False
    try:
        for change in sensitive_changes:
            if set(change.old_value) != {"encrypted"} or set(change.new_value) != {"encrypted"}:
                history_encrypted = False
                break
            allergies.change_values(settings, owner, change)
    except (ApiError, ValueError, KeyError, TypeError):
        history_encrypted = False
    events = list(session.scalars(select(Event).where(Event.user_id == owner)))
    taste_events = [event for event in events if event.event_type == "taste_profile.changed"]
    result: dict[str, int | bool] = {
        "profiles": session.scalar(
            select(func.count()).select_from(TasteProfile).where(TasteProfile.owner_id == owner)
        )
        or 0,
        "changes": len(changes),
        "events": len(events),
        "taste_events": len(taste_events),
        "metadata_only": all(
            event.content == {}
            and event.correlation == {"taste_profile_change_id": str(event.id)}
            and event.id in changes
            for event in taste_events
        ),
    }
    if include_sensitive:
        receipts = list(session.scalars(select(WriteReceipt).where(WriteReceipt.owner_id == owner)))
        outbox = list(
            session.scalars(select(WriteFactOutbox).where(WriteFactOutbox.owner_id == owner))
        )
        event_ids = {str(event.id) for event in events}

        def orphan_event(value: dict | None) -> bool:
            return bool(
                value
                and value.get("resource_type") == "experience.event"
                and value.get("resource_id") not in event_ids
            )

        result.update(
            sync_receipts=len(receipts),
            sync_outbox=len(outbox),
            sync_dependency_ids=sum(len(row.dependencies) for row in receipts),
            sync_orphan_event_results=sum(orphan_event(row.result) for row in receipts),
            sync_orphan_event_facts=sum(orphan_event(fact) for row in outbox for fact in row.facts),
            family_members=len(members),
            family_changes=sum(row.field.startswith("family_members") for row in change_rows),
            owner_allergies=int(owner_allergies is not None),
            sensitive_changes=len(sensitive_changes),
            family_current_encrypted=current_encrypted,
            sensitive_changes_encrypted=history_encrypted,
        )
    return result
