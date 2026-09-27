"""读写服务端配置项。

每次读取都查数据库（一张很小的表），所以改完立刻生效，不需要重启或发新版 App。
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.core.time import utcnow
from gramtree.runtime_config.models import ConfigChange, ConfigValue
from gramtree.runtime_config.registry import BY_KEY, ITEMS, ConfigItem


class ConfigError(ValueError):
    pass


@dataclass(frozen=True)
class ChangeRecord:
    key: str
    old_value: Any
    new_value: Any
    changed_by: str
    reason: str
    changed_at: datetime


def item(key: str) -> ConfigItem:
    try:
        return BY_KEY[key]
    except KeyError as exc:
        raise ConfigError(f"没有登记的配置项：{key}") from exc


def parse_value(cfg: ConfigItem, raw: str) -> int | float | bool | str:
    """把命令行传来的字符串转成配置项的类型，并检查取值范围。"""
    value: int | float | bool | str
    try:
        if cfg.type == "int":
            value = int(raw)
        elif cfg.type == "float":
            value = float(raw)
        elif cfg.type == "bool":
            lowered = raw.strip().lower()
            if lowered not in ("true", "false", "1", "0", "on", "off"):
                raise ValueError(raw)
            value = lowered in ("true", "1", "on")
        else:
            value = raw
    except ValueError as exc:
        raise ConfigError(f"{cfg.key} 需要 {cfg.type} 类型的值，收到：{raw}") from exc
    validate(cfg, value)
    return value


def validate(cfg: ConfigItem, value: int | float | bool | str) -> None:
    if cfg.type in ("int", "float") and not isinstance(value, bool):
        number = float(value)
        if cfg.minimum is not None and number < cfg.minimum:
            raise ConfigError(f"{cfg.key} 不能小于 {cfg.minimum}，收到：{value}")
        if cfg.maximum is not None and number > cfg.maximum:
            raise ConfigError(f"{cfg.key} 不能大于 {cfg.maximum}，收到：{value}")
    if cfg.choices is not None and value not in cfg.choices:
        raise ConfigError(f"{cfg.key} 只能是 {' / '.join(cfg.choices)}，收到：{value}")


def get(session: Session, key: str) -> Any:
    cfg = item(key)
    row = session.get(ConfigValue, key)
    return cfg.default if row is None else row.value


def get_all(session: Session) -> dict[str, Any]:
    stored = {row.key: row.value for row in session.scalars(select(ConfigValue))}
    return {cfg.key: stored.get(cfg.key, cfg.default) for cfg in ITEMS}


def set_value(session: Session, key: str, raw: str, changed_by: str, reason: str) -> ChangeRecord:
    cfg = item(key)
    if not changed_by.strip():
        raise ConfigError("必须写明修改人")
    if not reason.strip():
        raise ConfigError("必须写明修改原因")
    new_value = parse_value(cfg, raw)
    old_value = get(session, key)
    now = utcnow()
    row = session.get(ConfigValue, key)
    if row is None:
        session.add(ConfigValue(key=key, value=new_value, updated_at=now))
    else:
        row.value = new_value
        row.updated_at = now
    change = ConfigChange(
        key=key,
        old_value=old_value,
        new_value=new_value,
        changed_by=changed_by,
        reason=reason,
        changed_at=now,
    )
    session.add(change)
    session.commit()
    return ChangeRecord(key, old_value, new_value, changed_by, reason, now)


def history(session: Session, key: str | None = None, limit: int = 50) -> list[ChangeRecord]:
    stmt = select(ConfigChange).order_by(ConfigChange.changed_at.desc()).limit(limit)
    if key is not None:
        item(key)
        stmt = stmt.where(ConfigChange.key == key)
    return [
        ChangeRecord(c.key, c.old_value, c.new_value, c.changed_by, c.reason, c.changed_at)
        for c in session.scalars(stmt)
    ]
