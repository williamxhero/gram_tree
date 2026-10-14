"""#259: response contracts at the OpenAPI and authenticated HTTP boundaries."""

from typing import Any

from gramtree.main import create_app
from tests.accounts_support import Api, bearer
from tests.conftest import make_settings
from tests.test_recipes import recipe_input

# These are storage/learning fields, never a client's recipe projection.
FORBIDDEN = {
    "experience",
    "experience_layer",
    "experience_events",
    "experience_aggregates",
    "posterior",
    "posterior_parameters",
    "risk_score",
    "subject_key_hash",
    "storage_key",
    "design_document",
    "private_design",
    "signing_secret_hash",
}
CARD_FIELDS = {
    "id",
    "dish",
    "visibility",
    "version_number",
    "servings",
    "difficulty",
    "total_time_seconds",
    "active_time_seconds",
    "updated_at",
}
HISTORY_FIELDS = {
    "id",
    "version_number",
    "previous_version_id",
    "base_version_id",
    "conclusion",
    "rules_version",
    "change_note",
    "ai_assisted",
    "created_at",
}
PREVIEW_FIELDS = {
    "title",
    "description",
    "nickname",
    "image_url",
    "license",
    "photo_rights",
}


def _assert_no_learning_fields(value: Any) -> None:
    if isinstance(value, dict):
        assert FORBIDDEN.isdisjoint(value), FORBIDDEN.intersection(value)
        for child in value.values():
            _assert_no_learning_fields(child)
    elif isinstance(value, list):
        for child in value:
            _assert_no_learning_fields(child)


def _schema_keys(node: dict, schemas: dict, seen: set[str] | None = None) -> set[str]:
    seen = set() if seen is None else seen
    keys = set(node.get("properties", {}))
    ref = node.get("$ref")
    if ref and ref not in seen:
        seen.add(ref)
        keys |= _schema_keys(schemas[ref.rsplit("/", 1)[-1]], schemas, seen)
    for child in node.values():
        if isinstance(child, dict):
            keys |= _schema_keys(child, schemas, seen)
        elif isinstance(child, list):
            for entry in child:
                if isinstance(entry, dict):
                    keys |= _schema_keys(entry, schemas, seen)
    return keys


def test_openapi_public_and_existing_recipe_projections_are_bounded() -> None:
    spec = create_app(make_settings()).openapi()
    schemas = spec["components"]["schemas"]
    assert set(schemas["RecipeListItem"]["properties"]) == CARD_FIELDS
    assert set(schemas["RecipeVersionSummary"]["properties"]) == HISTORY_FIELDS
    assert set(schemas["RecipeComparisonCandidate"]["properties"]) == (
        HISTORY_FIELDS | {"recipe_id", "author"}
    )
    assert set(schemas["PublicRecipeProjection"]["properties"]) == PREVIEW_FIELDS
    assert schemas["PublicRecipeProjection"]["additionalProperties"] is False
    assert set(schemas["RecipeList"]["properties"]) == {"items", "next_cursor"}
    assert set(schemas["RecipeVersionHistory"]["properties"]) == {"items", "next_cursor"}
    detail = schemas["RecipeDetail"]["properties"]
    assert detail["version"]["$ref"].endswith("/RecipeVersionOut")
    assert "versions" not in detail and "tree" not in detail
    # Traverse every registered success schema, including future routes: a new
    # response leaking learning storage must fail without updating a route list.
    for path, operations in spec["paths"].items():
        for operation in operations.values():
            if not isinstance(operation, dict):
                continue
            for code, response in operation.get("responses", {}).items():
                if not str(code).startswith("2"):
                    continue
                for media in response.get("content", {}).values():
                    keys = _schema_keys(media.get("schema", {}), schemas)
                    assert FORBIDDEN.isdisjoint(keys), (path, FORBIDDEN.intersection(keys))
    for name in (
        "RecipeListItem",
        "RecipeVersionSummary",
        "RecipeComparisonCandidate",
        "SimilarRecipe",
    ):
        assert {"ingredients", "steps", "snapshot", "versions", "tree"}.isdisjoint(
            _schema_keys(schemas[name], schemas)
        )


def test_http_lists_history_and_single_version_preserve_owner_boundary(api: Api) -> None:
    headers = bearer(api.login("projection-owner@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input())
    assert created.status_code == 201, created.text
    first = created.json()
    snapshot = first["version"]["snapshot"]
    snapshot["ingredients"][0]["quantity"] = 320
    saved = api.client.post(
        f"/v1/recipes/{first['id']}/versions",
        headers=headers,
        json={"snapshot": snapshot, "change_note": "第二版"},
    )
    assert saved.status_code == 201, saved.text
    current = saved.json()
    listed = api.client.get("/v1/recipes", headers=headers)
    assert listed.status_code == 200, listed.text
    assert set(listed.json()["items"][0]) == CARD_FIELDS
    history = api.client.get(
        f"/v1/recipes/{first['id']}/versions", headers=headers, params={"limit": 1}
    )
    assert history.status_code == 200, history.text
    assert len(history.json()["items"]) == 1
    assert set(history.json()["items"][0]) == HISTORY_FIELDS
    assert history.json()["next_cursor"]
    candidates = api.client.get(f"/v1/recipes/{first['id']}/comparison-candidates", headers=headers)
    assert candidates.status_code == 200, candidates.text
    assert all(
        set(item) == HISTORY_FIELDS | {"recipe_id", "author"} for item in candidates.json()["items"]
    )
    paths = [
        f"/v1/recipes/{first['id']}",
        f"/v1/recipes/{first['id']}/versions/{first['version']['id']}",
        f"/v1/recipes/{first['id']}/versions/{current['version']['id']}",
    ]
    expected = [current["version"]["id"], first["version"]["id"], current["version"]["id"]]
    for path, version_id in zip(paths, expected, strict=True):
        response = api.client.get(path, headers=headers)
        assert response.status_code == 200, response.text
        assert response.json()["version"]["id"] == version_id
        assert "versions" not in response.json()
        _assert_no_learning_fields(response.json())
    for response in (listed, history, candidates):
        _assert_no_learning_fields(response.json())
    other_headers = bearer(api.login("projection-other@example.com"))
    for path in [
        *paths,
        f"/v1/recipes/{first['id']}/versions",
        f"/v1/recipes/{first['id']}/comparison-candidates",
    ]:
        denied = api.client.get(path, headers=other_headers)
        assert denied.status_code == 404, denied.text
        assert first["dish"]["name"] not in denied.text
    assert api.client.get("/v1/recipes", headers=other_headers).json()["items"] == []
