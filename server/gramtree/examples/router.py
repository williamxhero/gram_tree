"""示例接口，只在非正式环境挂载。

后面的子 SPEC 照这里的写法做：
- 请求里的 ID 用 IdV4，客户端生成，服务端按 ID 去重（同一个 ID 再提交返回已有记录）
- 时间用 Timestamp，带时区
- 列表用 Page + page_params + 游标
- 出错抛 ApiError 的子类，不自己拼错误响应
"""

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Response
from pydantic import BaseModel, Field
from sqlalchemy import select, tuple_
from sqlalchemy.dialects.postgresql import insert as pg_insert

from gramtree.core.errors import ERROR_RESPONSES, ErrorResponse, NotFound
from gramtree.core.ids import IdV4
from gramtree.core.pagination import (
    Page,
    PageParams,
    check_limit,
    decode_cursor,
    encode_cursor,
    page_params,
)
from gramtree.core.time import Timestamp, utcnow
from gramtree.deps import SessionDep
from gramtree.examples.models import Sample, TaskHeartbeat
from gramtree.runtime_config import service as config

router = APIRouter(prefix="/examples", tags=["examples"])

PageDep = Annotated[PageParams, Depends(page_params)]


class SampleCreate(BaseModel):
    id: IdV4 = Field(description="客户端生成的 UUID v4")
    title: str = Field(min_length=1, max_length=200)


class SampleOut(BaseModel):
    id: uuid.UUID
    title: str
    created_at: Timestamp


class HeartbeatOut(BaseModel):
    id: uuid.UUID
    source: str
    created_at: Timestamp


class TaskAccepted(BaseModel):
    task_id: str


def _sample_out(row: Sample) -> SampleOut:
    return SampleOut(id=row.id, title=row.title, created_at=row.created_at)


@router.put(
    "/samples",
    response_model=SampleOut,
    responses={**ERROR_RESPONSES, 201: {"model": SampleOut, "description": "新建"}},
    summary="创建示例（同一个 ID 重复提交返回已有记录）",
)
def put_sample(body: SampleCreate, session: SessionDep, response: Response) -> SampleOut:
    # 并发重复提交同一个 ID 时也不能报错：插入冲突就读回已有记录
    inserted = session.execute(
        pg_insert(Sample)
        .values(id=body.id, title=body.title, created_at=utcnow())
        .on_conflict_do_nothing(index_elements=[Sample.id])
        .returning(Sample.id)
    ).first()
    session.commit()
    if inserted is not None:
        response.status_code = 201
    row = session.get(Sample, body.id)
    assert row is not None
    return _sample_out(row)


@router.get(
    "/samples/{sample_id}",
    response_model=SampleOut,
    responses={**ERROR_RESPONSES, 404: {"model": ErrorResponse, "description": "不存在"}},
    summary="读取一条示例",
)
def get_sample(sample_id: IdV4, session: SessionDep) -> SampleOut:
    row = session.get(Sample, sample_id)
    if row is None:
        raise NotFound(f"sample {sample_id} 不存在")
    return _sample_out(row)


@router.get(
    "/samples",
    response_model=Page[SampleOut],
    responses=ERROR_RESPONSES,
    summary="示例列表（游标分页，新的在前）",
)
def list_samples(session: SessionDep, page: PageDep) -> Page[SampleOut]:
    check_limit(page.limit, config.get(session, "api.page_size_max"))
    stmt = select(Sample).order_by(Sample.created_at.desc(), Sample.id.desc())
    if page.cursor:
        created_at, id_ = decode_cursor(page.cursor)
        stmt = stmt.where(tuple_(Sample.created_at, Sample.id) < tuple_(created_at, id_))
    rows = list(session.scalars(stmt.limit(page.limit + 1)))
    next_cursor = None
    if len(rows) > page.limit:
        rows = rows[: page.limit]
        next_cursor = encode_cursor(rows[-1].created_at, rows[-1].id)
    return Page[SampleOut](items=[_sample_out(r) for r in rows], next_cursor=next_cursor)


@router.get(
    "/boom",
    responses=ERROR_RESPONSES,
    summary="故意抛出未处理异常，用来测试统一错误格式",
)
def boom() -> None:
    raise RuntimeError("示例：未处理的异常")


@router.post(
    "/heartbeats",
    response_model=TaskAccepted,
    status_code=202,
    responses=ERROR_RESPONSES,
    summary="触发示例后台任务",
)
def trigger_heartbeat() -> TaskAccepted:
    from gramtree.tasks.jobs import record_heartbeat

    result = record_heartbeat.delay("api")
    return TaskAccepted(task_id=result.id)


@router.get(
    "/heartbeats",
    response_model=list[HeartbeatOut],
    responses=ERROR_RESPONSES,
    summary="示例后台任务写下的记录（最近 20 条）",
)
def list_heartbeats(session: SessionDep) -> list[HeartbeatOut]:
    stmt = select(TaskHeartbeat).order_by(TaskHeartbeat.created_at.desc()).limit(20)
    return [
        HeartbeatOut(id=r.id, source=r.source, created_at=r.created_at)
        for r in session.scalars(stmt)
    ]
