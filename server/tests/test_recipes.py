"""SPEC-002.2 server behavior through the public HTTP API only."""

import base64
import io

from PIL import Image
from PIL.TiffImagePlugin import IFDRational

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


def test_recipe_save_event_is_visible_once_to_its_owner(api: Api) -> None:
    _saved, headers = _create(api, "events@example.com")
    response = api.client.get(
        "/v1/dev/events/count",
        params={"event_type": "recipe.version_saved"},
        headers=headers,
    )
    assert response.status_code == 200
    assert response.json() == {"count": 1}
    other_headers = bearer(api.login("events-other@example.com"))
    other = api.client.get(
        "/v1/dev/events/count",
        params={"event_type": "recipe.version_saved"},
        headers=other_headers,
    )
    assert other.status_code == 200
    assert other.json() == {"count": 0}
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
    changed["snapshot"]["ingredients"][0]["display_name"] = "作者叫法"
    changed["change_note"] = "加倍份量"
    second_response = api.client.post(
        f"/v1/recipes/{recipe_id}/versions", json=changed, headers=headers
    )
    assert second_response.status_code == 201, second_response.text
    second = second_response.json()
    assert second["version"]["version_number"] == 2
    assert second["version"]["previous_version_id"] == first_id
    assert any(op["intent"] == "作者手动修改" for op in second["version"]["edit_operations"])
    assert any(op["type"] == "change_display_name" for op in second["version"]["edit_operations"])
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
    branch["base_version_id"] = first_id
    response = api.client.post(f"/v1/recipes/{recipe_id}/versions", json=branch, headers=headers)
    assert response.status_code == 201
    branched = response.json()
    assert branched["version"]["version_number"] == 3
    assert branched["version"]["previous_version_id"] == second["version"]["id"]
    assert branched["version"]["snapshot"]["servings"] == 3
    assert branched["version"]["snapshot"]["ingredients"][0]["quantity"] == 300


def test_version_history_uses_cursor_pagination(api: Api) -> None:
    saved, headers = _create(api, "history@example.com")
    recipe_id = saved["id"]
    for servings in (3, 4, 5):
        body = recipe_input()
        body["snapshot"]["servings"] = servings
        response = api.client.post(f"/v1/recipes/{recipe_id}/versions", json=body, headers=headers)
        assert response.status_code == 201
    first = api.client.get(f"/v1/recipes/{recipe_id}/versions?limit=2", headers=headers)
    assert first.status_code == 200
    page = first.json()
    assert len(page["items"]) == 2
    assert page["next_cursor"]
    second = api.client.get(
        f"/v1/recipes/{recipe_id}/versions?limit=2&cursor={page['next_cursor']}",
        headers=headers,
    )
    assert second.status_code == 200
    assert len(second.json()["items"]) == 2
    assert {item["version_number"] for item in page["items"]}.isdisjoint(
        {item["version_number"] for item in second.json()["items"]}
    )


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
    body = recipe_input()
    body["snapshot"]["ingredients"][0]["replacement"] = {
        "ingredient_id": "77777777-7777-4777-8777-777777777777",
        "display_name": "不存在的替代品",
        "ratio": 1,
    }
    response = api.client.post("/v1/recipes", json=body, headers=headers)
    error = assert_error_shape(response, 422, "invalid_recipe")
    assert "replacement.ingredient_id" in (error["detail"] or "")


def test_image_upload_strips_metadata_and_uses_signed_private_url(api: Api, tmp_path) -> None:
    saved, headers = _create(api, "photo@example.com")
    image = Image.new("RGB", (3000, 1000), (180, 80, 40))
    buffer = io.BytesIO()
    exif = Image.Exif()
    exif[34853] = {
        1: "N",
        2: (IFDRational(40, 1), IFDRational(0, 1), IFDRational(0, 1)),
        3: "W",
        4: (IFDRational(74, 1), IFDRational(0, 1), IFDRational(0, 1)),
    }
    image.save(buffer, format="JPEG", quality=95, exif=exif)
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
    stored = Image.open(io.BytesIO(file_response.content))
    assert 34853 not in stored.getexif()


def _image_payload(*, gps: bool = False) -> dict[str, str]:
    image = Image.new("RGB", (640, 480), (32, 96, 144))
    buffer = io.BytesIO()
    exif = Image.Exif()
    if gps:
        exif[34853] = {
            1: "N",
            2: (40.0, 0.0, 0.0),
            3: "W",
            4: (74.0, 0.0, 0.0),
        }
    image.save(buffer, format="JPEG", quality=90, exif=exif)
    return {
        "content_base64": base64.b64encode(buffer.getvalue()).decode(),
        "content_type": "image/jpeg",
        "filename": "dish.jpg",
    }


def test_staged_image_attaches_to_create_and_does_not_mutate_old_version(api: Api) -> None:
    _saved, headers = _create(api, "staged-photo@example.com")
    staged = api.client.post("/v1/recipes/images/staging", json=_image_payload(), headers=headers)
    assert staged.status_code == 201, staged.text
    staged_id = staged.json()["id"]
    staged_url = staged.json()["url"]
    assert api.client.get(staged_url).status_code == 200

    body = recipe_input("staged-photo-dish")
    body["image_ids"] = [staged_id]
    created = api.client.post("/v1/recipes", json=body, headers=headers)
    assert created.status_code == 201, created.text
    first = created.json()
    assert len(first["version"]["images"]) == 1

    # Updating a photo creates version 2; version 1 remains unchanged.
    uploaded = api.client.post(
        f"/v1/recipes/{first['id']}/images", json=_image_payload(), headers=headers
    )
    assert uploaded.status_code == 201, uploaded.text
    second = uploaded.json()
    assert second["version_id"] != first["version"]["id"]
    old = api.client.get(
        f"/v1/recipes/{first['id']}/versions/{first['version']['id']}", headers=headers
    ).json()
    current = api.client.get(f"/v1/recipes/{first['id']}", headers=headers).json()
    assert len(old["version"]["images"]) == 1
    assert len(current["version"]["images"]) == 2
    assert current["version"]["version_number"] == 2

    # Continuing from version 1 must branch with version 1's photo identity,
    # not silently copy the current version 2 photo set.
    branch = recipe_input("staged-photo-dish")
    branch["base_version_id"] = first["version"]["id"]
    branched_response = api.client.post(
        f"/v1/recipes/{first['id']}/versions", json=branch, headers=headers
    )
    assert branched_response.status_code == 201, branched_response.text
    branched = branched_response.json()
    assert branched["version"]["version_number"] == 3
    assert len(branched["version"]["images"]) == 1
    assert (
        api.client.get(branched["version"]["images"][0]["url"]).content
        == api.client.get(first["version"]["images"][0]["url"]).content
    )


def test_staged_image_is_owner_scoped(api: Api) -> None:
    _, author_headers = _create(api, "staging-owner@example.com")
    staged = api.client.post(
        "/v1/recipes/images/staging", json=_image_payload(), headers=author_headers
    )
    assert staged.status_code == 201
    other_headers = bearer(api.login("staging-other@example.com"))
    body = recipe_input("other-staging-dish")
    body["image_ids"] = [staged.json()["id"]]
    response = api.client.post("/v1/recipes", json=body, headers=other_headers)
    assert_error_shape(response, 404, "not_found")


def test_corrupt_image_is_rejected_with_safe_error(api: Api) -> None:
    _, headers = _create(api, "corrupt-photo@example.com")
    body = {**_image_payload(), "content_base64": base64.b64encode(b"not an image").decode()}
    response = api.client.post("/v1/recipes/images/staging", json=body, headers=headers)
    error = assert_error_shape(response, 422, "unsafe_image")
    assert error["message"]
