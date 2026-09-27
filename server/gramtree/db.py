from collections.abc import Iterator
from datetime import datetime

from sqlalchemy import DateTime, Engine, create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker


class Base(DeclarativeBase):
    # 时间一律带时区，按 UTC 存储
    type_annotation_map = {datetime: DateTime(timezone=True)}  # noqa: RUF012


def make_engine(url: str, connect_timeout: float = 5.0) -> Engine:
    return create_engine(
        url,
        pool_pre_ping=True,
        connect_args={"connect_timeout": max(1, int(connect_timeout))},
    )


def make_session_factory(engine: Engine) -> sessionmaker[Session]:
    return sessionmaker(bind=engine, expire_on_commit=False)


def session_scope(factory: sessionmaker[Session]) -> Iterator[Session]:
    with factory() as session:
        yield session
