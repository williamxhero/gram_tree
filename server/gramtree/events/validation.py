"""按登记表逐条校验上传的事件，脏数据在这里被拒收（SPEC-010.1 票 2）。

只做校验、不落库、不联网、不写日志——校验结果只用来决定这一条事件是被接收还是被
拒收，拒收原因是"程序可判断的代码 + 一句人话说明"，**绝不把事件内容原样带回**：
`invalid_content` 的说明只包含 pydantic 报错的字段路径和错误类型，不包含字段的值。
"""

import uuid
from dataclasses import dataclass

from pydantic import ValidationError

from gramtree.events.registry import BY_KEY, KNOWN_EVENT_TYPES

# "unknown_event_type" | "unsupported_version" | "invalid_content" | "invalid_correlation_id"
RejectionCode = str


@dataclass(frozen=True)
class Rejection:
    code: RejectionCode
    message: str


def _is_uuid_v4(value: str) -> bool:
    try:
        parsed = uuid.UUID(value)
    except (ValueError, AttributeError, TypeError):
        return False
    return parsed.version == 4


def _bad_correlation_field(correlation: dict[str, str | None]) -> str | None:
    for field, value in correlation.items():
        if value is None:
            continue
        if not _is_uuid_v4(value):
            return field
    return None


def _summarize_content_error(exc: ValidationError) -> str:
    parts = []
    for err in exc.errors():
        loc = ".".join(str(p) for p in err.get("loc", ())) or "content"
        parts.append(f"{loc}: {err.get('type')}")
    return "content 不符合登记表要求 —— " + ("; ".join(parts) or "字段不合法")


def validate_event(
    event_type: str,
    type_version: int,
    correlation: dict[str, str | None],
    content: dict[str, object],
) -> Rejection | None:
    """校验一条事件，合格返回 None，不合格返回拒收原因。"""
    spec = BY_KEY.get((event_type, type_version))
    if spec is None:
        if event_type in KNOWN_EVENT_TYPES:
            return Rejection(
                "unsupported_version",
                f"{event_type} 没有登记版本 {type_version}，或者这个版本已经停止支持",
            )
        return Rejection("unknown_event_type", f"事件类型未登记：{event_type}")

    if not spec.supported:
        return Rejection(
            "unsupported_version",
            f"{event_type} v{type_version} 已经停止支持，请升级客户端到更新的版本",
        )

    bad_field = _bad_correlation_field(correlation)
    if bad_field is not None:
        return Rejection("invalid_correlation_id", f"关联 ID 格式不对：{bad_field}")

    if spec.content_schema is not None:
        try:
            spec.content_schema.model_validate(content)
        except ValidationError as exc:
            return Rejection("invalid_content", _summarize_content_error(exc))

    return None
