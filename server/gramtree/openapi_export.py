"""导出给客户端用的 OpenAPI 描述。

按正式环境的设置导出，所以示例接口不会进入客户端。输出稳定（键排序），方便 CI 比较。
FastAPI/Pydantic 2 emits nullable primitives as ``anyOf: [T, null]``. OpenAPI
Generator's Dart backend treats optional titled primitives as empty model classes;
normalize the equivalent OpenAPI 3.0 ``nullable`` spelling at the contract boundary.
"""

import json
from typing import Any

from gramtree.main import create_app
from gramtree.settings import Settings


def _normalize_nullable(value: Any) -> Any:
    if isinstance(value, list):
        return [_normalize_nullable(item) for item in value]
    if not isinstance(value, dict):
        return value
    normalized = {key: _normalize_nullable(item) for key, item in value.items()}
    variants = normalized.get("anyOf")
    if isinstance(variants, list) and len(variants) == 2:
        nulls = [item for item in variants if item == {"type": "null"}]
        others = [item for item in variants if item != {"type": "null"}]
        if len(nulls) == 1 and len(others) == 1:
            replacement = dict(others[0])
            replacement["nullable"] = True
            for key in ("title", "description"):
                if key in normalized and key not in replacement:
                    replacement[key] = normalized[key]
            return replacement
    return normalized


def export() -> str:
    app = create_app(
        Settings(
            env="prod",
            auth_secret="export-only-" + "x" * 32,
            image_signing_secret="export-only-image-" + "x" * 32,
            mail_backend="smtp",
            recipe_storage_backend="s3",
            recipe_s3_bucket="openapi-export-only",
            recipe_s3_access_key_id="export-only",
            recipe_s3_secret_access_key="export-only",
        )
    )
    document = app.openapi()
    schemas = document.get("components", {}).get("schemas", {})
    for name, schema in list(schemas.items()):
        if name.startswith("Recipe") or name in {"NutritionEstimate", "ValueSource"}:
            schemas[name] = _normalize_nullable(schema)
    return json.dumps(document, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
