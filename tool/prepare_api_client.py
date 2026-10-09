"""Prepare a disposable OpenAPI input for dart-dio 7.16.0.

api/openapi.json stays the authoritative FastAPI 3.1 contract. The generator's
inline resolver otherwise turns described/titled nullable primitives into empty
Dart classes and flattens object|string unions into object-only models.
"""

import json
import sys
from pathlib import Path
from typing import Any


def client_schema(value: Any) -> Any:
    if isinstance(value, list):
        return [client_schema(item) for item in value]
    if not isinstance(value, dict):
        return value
    result = {key: client_schema(item) for key, item in value.items()}
    if result.get("$ref") == "#/components/schemas/JsonValue":
        # Finite modification values keep their JSON type on the wire. Dart has
        # no recursive JSON union; the server validates each registered field.
        return {}
    variants = result.get("anyOf")
    if not isinstance(variants, list) or {"type": "null"} not in variants:
        return result
    non_null = [item for item in variants if item != {"type": "null"}]
    if len(non_null) == 1:
        item = non_null[0]
        if "type" in item:
            # JSON Schema type arrays express the same nullable primitive while
            # bypassing the generator's incorrect inline composed-model path.
            result.pop("anyOf")
            result.update(item)
            result["type"] = [item["type"], "null"]
            if "enum" in result and None not in result["enum"]:
                result["enum"] = [*result["enum"], None]
        elif "$ref" in item:
            # OpenAPI Generator handles a nullable reference when written in
            # the OpenAPI 3.0-compatible form, but treats anyOf[ref, null] as
            # a titled inline model.
            result.pop("anyOf")
            result.pop("title", None)
            result.update(item)
            result["nullable"] = True
    elif len(non_null) > 1 and all(
        item.get("type") in {"string", "number", "integer", "boolean"}
        for item in non_null
    ):
        # Scalar parameter unions have no Dart class representation. Keep their
        # exact JSON values as Object?; the canonical server schema still limits
        # the allowed scalar types instead of accepting arbitrary object patches.
        result.pop("anyOf")
        result.pop("title", None)
    elif len(non_null) == 2 and any("$ref" in item for item in non_null):
        # Dart has no native object|string union. Expose its JSON wire values as
        # Object? instead of silently discarding the string arm. The canonical
        # schema and server still validate the complete referenced object shape.
        types = ["object" if "$ref" in item else item.get("type") for item in non_null]
        if set(types) == {"object", "string"}:
            result.pop("anyOf")
            result["type"] = ["object", "string", "null"]
    return result


def project_schema(schema: dict[str, Any]) -> dict[str, Any]:
    projected = client_schema(schema)
    properties = projected.get("properties")
    if not isinstance(properties, dict):
        return projected
    required = list(projected.get("required", []))
    for name, property_schema in properties.items():
        if (
            name not in required
            and isinstance(property_schema, dict)
            and ("enum" in property_schema or "const" in property_schema)
            and "default" in property_schema
        ):
            # dart-dio 7.16 emits an invalid `const Enum._(...)` default for
            # nullable enum properties. The server-side default remains in the
            # canonical schema; requiring the field in the client projection
            # keeps the generated Dart constructor valid and callers send the
            # same wire value explicitly.
            required.append(name)
            property_schema.pop("default", None)
    if required:
        projected["required"] = required
    return projected


def main() -> None:
    source, target = (Path(arg) for arg in sys.argv[1:])
    document = json.loads(source.read_text(encoding="utf-8"))
    for name, schema in document["components"]["schemas"].items():
        if name.startswith(
            (
                "Recipe",
                "Modification",
                "ChangeExplanation",
                "Cooking",
                "IngredientPreference",
                "Allerg",
            )
        ) or name in {"NutritionEstimate", "ValueSource", "TasteProfilePatch"}:
            document["components"]["schemas"][name] = project_schema(schema)
    document["components"]["schemas"].pop("JsonValue", None)
    target.write_text(
        json.dumps(document, ensure_ascii=False, sort_keys=True), encoding="utf-8"
    )


if __name__ == "__main__":
    main()
