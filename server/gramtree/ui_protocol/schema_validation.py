"""按 `app/assets/contracts/ui_protocol/` 里的 JSON Schema 校验页面描述和组件数据。

这个目录是两端共用的契约（见 `docs/adr/0005-界面描述协议共享契约.md`），服务端和 App
都只读它、不各写一份；放在 `app/assets/` 下面是因为 Flutter 测试的 asset bundle 对
转义包根目录的 `../` 路径处理不稳定，服务端从这里往上读没有类似限制。这里只做
“文件系统读取 + jsonschema 校验”，不认识具体协议版本或组件类型有多少种——版本、组件
登记在 `gramtree.ui_protocol.components`。
"""

import functools
import json
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator
from jsonschema.exceptions import ValidationError

CONTRACTS_ROOT = (
    Path(__file__).resolve().parents[3] / "app" / "assets" / "contracts" / "ui_protocol"
)
SCHEMA_ROOT = CONTRACTS_ROOT / "schema"
SAMPLES_ROOT = CONTRACTS_ROOT / "samples"


class SchemaValidationFailed(Exception):
    """页面描述或组件数据不符合 Schema。`path` 是出错字段的 JSON Pointer 风格路径。"""

    def __init__(self, message: str, path: str = ""):
        super().__init__(message)
        self.message = message
        self.path = path


@functools.cache
def _load_validator(schema_path: Path) -> Draft202012Validator:
    with schema_path.open("r", encoding="utf-8") as f:
        schema = json.load(f)
    Draft202012Validator.check_schema(schema)
    return Draft202012Validator(schema)


def resolve_schema_major_dir(protocol: str) -> str | None:
    """协议版本号（例如 "1.3"）映射到信封 Schema 目录名（例如 "1.0"）：每个大版本一个
    "<major>.0" 起点目录，小版本增量不新建目录（见 docs/adr/0005）。格式不对（不是
    "整数.整数"）或者这个大版本压根没有对应目录时返回 `None`，调用方按"不认识的大版本"
    （`unknown_major`，SPEC-009.1 #79）处理。"""
    parts = protocol.split(".")
    if len(parts) != 2 or not parts[0].isdigit() or not parts[1].isdigit():
        return None
    major_dir = f"{parts[0]}.0"
    if not (SCHEMA_ROOT / major_dir).is_dir():
        return None
    return major_dir


def page_description_schema_path(protocol_major: str) -> Path:
    """`protocol_major` 例如 "1.0"（协议信封 Schema 目前按大版本起点建目录）。"""
    return SCHEMA_ROOT / protocol_major / "page_description.schema.json"


def component_schema_path(protocol_major: str, component_type: str) -> Path:
    return SCHEMA_ROOT / protocol_major / "components" / f"{component_type}.schema.json"


def _validate(schema_path: Path, instance: Any) -> None:
    if not schema_path.is_file():
        raise SchemaValidationFailed(f"Schema 文件不存在：{schema_path}")
    validator = _load_validator(schema_path)
    errors = sorted(validator.iter_errors(instance), key=lambda e: list(e.absolute_path))
    if errors:
        first: ValidationError = errors[0]
        path = "/".join(str(p) for p in first.absolute_path)
        raise SchemaValidationFailed(first.message, path)


def validate_page_description(protocol_major: str, description: dict[str, Any]) -> None:
    """按协议信封 Schema 校验整份页面描述（不含逐组件的 data 校验，见
    [validate_component_data]）。"""
    _validate(page_description_schema_path(protocol_major), description)


def validate_component_data(protocol_major: str, component_type: str, data: dict[str, Any]) -> None:
    """按该组件类型登记的 Schema 校验 `data` 字段。"""
    _validate(component_schema_path(protocol_major, component_type), data)


def load_sample(*parts: str) -> dict[str, Any]:
    """读 `contracts/ui_protocol/samples/` 下的共用测试样例，例如
    `load_sample("valid", "today_default.json")`。"""
    path = SAMPLES_ROOT.joinpath(*parts)
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)
