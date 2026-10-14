"""External recipe import tests exercise the authenticated HTTP boundary."""

import hashlib
import json
from pathlib import Path
from unittest.mock import patch

import httpx
import pytest

from tests.accounts_support import Api, bearer
from tests.test_ai_recipes import CORPUS, configure

TEXT = "宫保鸡丁\n食材：鸡腿肉 300 克、盐 2 克。做法：鸡肉切丁，炒熟。"


def import_payload(text: str = TEXT, *, url: str | None = None, images=None) -> dict:
    return {
        "text": text if url is None and images is None else "",
        "intent": {
            "dish_name": "从用户提供的外部内容中提取菜谱",
            "servings": None,
            "taste": [],
            "restrictions": [],
            "cookware": [],
        },
        "source_url": url,
        "source_platform": "unknown" if url is None else "127.0.0.1",
        "source_note": None,
        "images_base64": images or [],
    }


def _record_import(replay_dir: Path, payload: dict) -> None:
    raw = json.dumps(
        {"capability": "recipe_import", "prompt_version": "one-line-v1", "input": payload},
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    key = hashlib.sha256(raw.encode()).hexdigest()
    output = {"draft": CORPUS["valid"], "field_states": {"dish_name": "recognized"}}
    replay_dir.joinpath(key + ".json").write_text(
        json.dumps({"output": output, "usage": CORPUS["usage"]}, ensure_ascii=False),
        encoding="utf-8",
    )


@pytest.fixture
def import_api(monkeypatch, tmp_path: Path, api: Api) -> tuple[Api, Path]:
    monkeypatch.setenv("GRAMTREE_AI_MODE", "replay")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    api.client.app.state.settings.ai_mode = "replay"
    api.client.app.state.settings.ai_replay_dir = str(tmp_path)
    configure(
        "ai.models",
        {
            "small": {"provider": "replay", "model": "small"},
            "large": {"provider": "replay", "model": "large"},
            "vector": {"provider": "replay", "model": "vector"},
        },
    )
    return api, tmp_path


def test_text_import_saves_private_recipe_and_owner_only_original(import_api) -> None:
    api, replay_dir = import_api
    payload = import_payload()
    _record_import(replay_dir, payload)
    headers = bearer(api.login("recipe-import@example.com"))

    response = api.client.post("/v1/recipe-imports", headers=headers, json={"text": TEXT})

    assert response.status_code == 200, response.text
    result = response.json()
    assert result["status"] == "partial"
    assert result["recipe"]["visibility"] == "private"
    assert result["recipe"]["version"]["ai_assisted"] is True
    snapshot = result["recipe"]["version"]["snapshot"]
    assert snapshot["source"]["kind"] == "imported"
    assert TEXT not in json.dumps(snapshot, ensure_ascii=False)
    original = api.client.get(f"/v1/recipe-imports/{result['import_id']}/original", headers=headers)
    assert original.json()["original_text"] == TEXT
    other = bearer(api.login("other-recipe-import@example.com"))
    assert (
        api.client.get(
            f"/v1/recipe-imports/{result['import_id']}/original", headers=other
        ).status_code
        == 404
    )


def test_link_import_rejects_redirects_and_reports_login_needed(api: Api) -> None:
    headers = bearer(api.login("recipe-import-link@example.com"))

    class LoginPage:
        def __call__(self, *args, **kwargs):
            return self

        def __enter__(self):
            return httpx.Response(401)

        def __exit__(self, *args):
            return False

    with patch("gramtree.recipes.imports.httpx.stream", LoginPage()):
        response = api.client.post(
            "/v1/recipe-imports", headers=headers, json={"url": "http://127.0.0.1/recipe"}
        )

    assert response.status_code == 200
    assert response.json()["reason"] == "login_required"
    assert "粘贴页面文字" in response.json()["next_step"]


def test_image_import_caps_count_and_cleans_temp_files(import_api) -> None:
    api, replay_dir = import_api
    from gramtree.recipes.imports import MAX_IMAGES

    headers = bearer(api.login("recipe-import-images@example.com"))
    too_many = api.client.post(
        "/v1/recipe-imports",
        headers=headers,
        json={"images_base64": ["/9j/" + "A" * 100 for _ in range(MAX_IMAGES + 1)]},
    )
    assert too_many.status_code == 422

    image = "/9j/" + "A" * 100
    payload = import_payload(images=[image])
    _record_import(replay_dir, payload)
    response = api.client.post(
        "/v1/recipe-imports", headers=headers, json={"images_base64": [image]}
    )
    assert response.status_code == 200, response.text
    assert response.json()["status"] == "partial"
    assert response.json()["recipe"]["version"]["snapshot"].get("images", []) == []


def test_ai_quota_exhaustion_is_a_stable_failure(import_api) -> None:
    api, replay_dir = import_api
    _record_import(replay_dir, import_payload())
    configure("ai.policies", {"recipe_import": {"daily_limit": 0}})
    headers = bearer(api.login("recipe-import-quota@example.com"))

    response = api.client.post("/v1/recipe-imports", headers=headers, json={"text": TEXT})

    assert response.status_code == 200
    assert response.json()["status"] == "failed"
    assert response.json()["reason"] == "daily_quota"
    assert api.client.get("/v1/recipes", headers=headers).json()["items"] == []
