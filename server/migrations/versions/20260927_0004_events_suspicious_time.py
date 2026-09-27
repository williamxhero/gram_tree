"""事件设备时间可疑标记 + 内部查询索引（SPEC-010.1 票 3）

Revision ID: 0004
Revises: 0003
Create Date: 2026-09-27
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0004"
down_revision: str | None = "0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "events",
        sa.Column(
            "device_time_suspicious",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
    )
    # 内部查询（gramtree.events.queries）按用户、类型、分析用时间过滤/排序最常见，
    # 加一个复合索引；GIN 索引让按关联 ID 的包含查询（correlation @> {...}）能走索引。
    op.create_index(
        "ix_events_user_id_event_type_received_at",
        "events",
        ["user_id", "event_type", "received_at"],
        unique=False,
    )
    op.create_index(
        "ix_events_correlation_gin",
        "events",
        ["correlation"],
        unique=False,
        postgresql_using="gin",
    )


def downgrade() -> None:
    op.drop_index("ix_events_correlation_gin", table_name="events")
    op.drop_index("ix_events_user_id_event_type_received_at", table_name="events")
    op.drop_column("events", "device_time_suspicious")
