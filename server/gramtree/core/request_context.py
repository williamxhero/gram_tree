import uuid
from contextvars import ContextVar

REQUEST_ID_HEADER = "X-Request-ID"

_request_id: ContextVar[str | None] = ContextVar("request_id", default=None)


def get_request_id() -> str | None:
    return _request_id.get()


def set_request_id(value: str | None) -> None:
    _request_id.set(value)


def accept_or_new(incoming: str | None) -> str:
    """客户端可以自带请求编号（方便端到端排查），格式不对就重新生成。"""
    if incoming:
        try:
            return str(uuid.UUID(incoming))
        except ValueError:
            pass
    return str(uuid.uuid4())
