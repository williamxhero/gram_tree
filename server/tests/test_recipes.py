"""SPEC-002.2 server behavior through the public HTTP API only."""

import base64
import io

from PIL import Image

from tests.accounts_support import Api, bearer
from tests.test_conventions import assert_error_shape


def recipe_input(name: str = "宫保鸡丁") -> dict:
    return {
        "dish_name": name,
        "dish_aliases": ["宫保鸡丁（家常）"],
        "snapshot": {
            "format_version": 1,
            "servings": 2,
            "total_time_seconds": 0,
            "active_time_seconds": 0,
            "difficulty": "easy",
            "dish_type": "炒",
            "tags": ["下饭"],
            "ingredients": [
                {
                    "id": "chicken",
                    "display_name": "鸡腿肉",
                    "quantity": 300,
                    "unit": "g",
                    "preparation": "切 1.5 厘米丁",
                    "group": "主料",
                    "optional": False,
                    "functional": False,
                    "scaling_mode": "proportional",
                },
                {
                    "id": "pepper",
                    "display_name": "干辣椒",
                    "quantity": 3,
                    "unit": "个",
                    "group": "调味",
                    "optional": True,
                    "replacement": "辣椒面",
                    "functional": False,
                    "scaling_mode": "round",
                },
            ],
            "steps": [
                {
                    "id": "marinate",
                    "action": "腌",
                    "instruction": "鸡腿肉加盐腌制",
                    "ingredient_ids": ["chicken"],
                    "duration_seconds": 900,
                    "unattended": True,
                    "heat": None,
                    "temperature_celsius": None,
                    "cookware": "碗",
                    "doneness": "入味",
                    "depends_on": [],
                    "notes": "提前准备",
                    "why": "让肉更入味",
                },
                {
                    "id": "cook",
                    "action": "炒",
                    "instruction": "大火炒至表面变白",
                    "ingredient_ids": ["chicken", "pepper"],
                    "duration_seconds": 120,
                    "unattended": False,
                    "heat": "大火",
                    "temperature_celsius": None,
                    "cookware": "炒锅",
                    "doneness": "表面变白",
                    "depends_on": ["marinate"],
                    "notes": "快速翻炒",
                    "why": "高温使表面快速定型",
                },
            ],
        },
        "change_note": "我的第一版",
    }


def _create(api: Api, email: str = "author@example.com") -> tuple[dict, dict[str, str]]:
    tokens = api.login(email)
    headers = bearer(tokens)
    response = api.client.post("/v1/recipes", json=recipe_input(), headers=headers)
    assert response.status_code == 201, response.text
    return response.json(), headers


def test_author_can_save_read_list_and_delete_private_recipe(api: Api) -> None:
    saved, headers = _create(api)
    recipe_id = saved["id"]
    snapshot = saved["version"]["snapshot"]
    assert saved["dish"]["name"] == "宫保鸡丁"
    assert saved["dish"]["aliases"] == ["宫保鸡丁（家常）"]
    assert saved["visibility"] == "private"
    assert saved["version"]["version_number"] == 1
    assert saved["version"]["previous_version_id"] is None
    assert snapshot["ingredients"][0]["base_quantity"] == 300
    assert snapshot["ingredients"][0]["base_unit"] == "g"
    assert snapshot["steps"][1]["ingredient_ids"] == ["chicken", "pepper"]
    assert saved["version"]["derived"]["total_time_seconds"] == 1020
    assert saved["version"]["derived"]["active_time_seconds"] == 120
    assert saved["version"]["derived"]["cookware"] == ["炒锅", "碗"]

    read = api.client.get(f"/v1/recipes/{recipe_id}", headers=headers)
    assert read.status_code == 200
    assert read.json() == saved
    listed = api.client.get("/v1/recipes", headers=headers).json()
    assert [item["id"] for item in listed["items"]] == [recipe_id]
    assert listed["items"][0]["total_time_seconds"] == 1020

    version_id = saved["version"]["id"]
    assert (
        api.client.get(f"/v1/recipes/{recipe_id}/versions/{version_id}", headers=headers).json()
        == saved
    )
    assert (
        api.client.patch(
            f"/v1/recipes/{recipe_id}/versions/{version_id}",
            json={"snapshot": {}},
            headers=headers,
        ).status_code
        == 405
    )

    assert api.client.delete(f"/v1/recipes/{recipe_id}", headers=headers).status_code == 204
    assert api.client.get(f"/v1/recipes/{recipe_id}", headers=headers).status_code == 404
    assert api.client.get("/v1/recipes", headers=headers).json()["items"] == []


def test_private_recipe_is_isolated_between_accounts(api: Api) -> None:
    saved, author_headers = _create(api)
    other = bearer(api.login("other@example.com"))
    recipe_id = saved["id"]
    for method in ("get", "delete"):
        response = getattr(api.client, method)(f"/v1/recipes/{recipe_id}", headers=other)
        assert_error_shape(response, 404, "not_found")
    response = api.client.get("/v1/recipes", headers=other)
    assert response.status_code == 200 and response.json()["items"] == []
    assert api.client.get(f"/v1/recipes/{recipe_id}", headers=author_headers).status_code == 200


def test_versions_are_immutable_and_history_can_branch_from_old_version(api: Api) -> None:
    saved, headers = _create(api)
    recipe_id = saved["id"]
    first_id = saved["version"]["id"]
    changed = recipe_input()
    changed["snapshot"]["servings"] = 4
    changed["snapshot"]["ingredients"][0]["quantity"] = 600
    changed["change_note"] = "加倍份量"
    second_response = api.client.post(
        f"/v1/recipes/{recipe_id}/versions", json=changed, headers=headers
    )
    assert second_response.status_code == 201, second_response.text
    second = second_response.json()
    assert second["version"]["version_number"] == 2
    assert second["version"]["previous_version_id"] == first_id
    assert any(op["intent"] == "作者手动修改" for op in second["version"]["edit_operations"])
    first = api.client.get(f"/v1/recipes/{recipe_id}/versions/{first_id}", headers=headers).json()
    assert first["version"]["version_number"] == 1
    assert first["version"]["snapshot"]["servings"] == 2
    assert (
        api.client.put(
            f"/v1/recipes/{recipe_id}/versions/{first_id}",
            json={"snapshot": changed["snapshot"]},
            headers=headers,
        ).status_code
        == 405
    )
    history = api.client.get(f"/v1/recipes/{recipe_id}/versions", headers=headers).json()
    assert [item["version_number"] for item in history["items"]] == [2, 1]

    branch = recipe_input()
    branch["snapshot"]["servings"] = 3
    branch["change_note"] = "从第一版重新开始"
    response = api.client.post(f"/v1/recipes/{recipe_id}/versions", json=branch, headers=headers)
    assert response.status_code == 201
    assert response.json()["version"]["version_number"] == 3
    assert response.json()["version"]["previous_version_id"] == second["version"]["id"]


def test_invalid_references_and_dependency_cycles_are_rejected(api: Api) -> None:
    tokens = api.login("validator@example.com")
    headers = bearer(tokens)
    body = recipe_input()
    body["snapshot"]["steps"][1]["ingredient_ids"] = ["missing"]
    response = api.client.post("/v1/recipes", json=body, headers=headers)
    error = assert_error_shape(response, 422, "invalid_recipe")
    assert "ingredient_ids" in (error["detail"] or "")

    body = recipe_input()
    body["snapshot"]["steps"][0]["depends_on"] = ["cook"]
    body["snapshot"]["steps"][1]["depends_on"] = ["marinate"]
    response = api.client.post("/v1/recipes", json=body, headers=headers)
    assert_error_shape(response, 422, "invalid_recipe")


def test_image_upload_strips_metadata_and_uses_signed_private_url(api: Api, tmp_path) -> None:
    saved, headers = _create(api, "photo@example.com")
    image = Image.new("RGB", (3000, 1000), (180, 80, 40))
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=95)
    encoded = base64.b64encode(buffer.getvalue()).decode()
    response = api.client.post(
        f"/v1/recipes/{saved['id']}/images",
        json={"content_base64": encoded, "content_type": "image/jpeg", "filename": "dish.jpg"},
        headers=headers,
    )
    assert response.status_code == 201, response.text
    image_out = response.json()
    assert image_out["width"] == 2048
    assert image_out["url"].startswith("/v1/recipes/")
    assert "signature=" in image_out["url"]
    detail = api.client.get(f"/v1/recipes/{saved['id']}", headers=headers).json()
    assert len(detail["version"]["images"]) == 1
    file_response = api.client.get(image_out["url"])
    assert file_response.status_code == 200
    assert file_response.headers["content-type"] == "image/jpeg"
    assert b"GPS" not in file_response.content
