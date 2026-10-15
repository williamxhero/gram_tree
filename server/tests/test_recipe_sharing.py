"""#261 public HTTP behavior, guarded by approved-current-version metadata."""

import json
import subprocess
import uuid
from concurrent.futures import ThreadPoolExecutor

import pytest

from gramtree.cli import main as cli
from tests.accounts_support import Api, bearer
from tests.test_recipes import _image_payload, recipe_input


def _command(*args: str) -> None:
    result = subprocess.run(["gramtree", *args], capture_output=True, text=True)
    assert result.returncode == 0, result.stderr


def _configure(key: str, value: str) -> None:
    _command("config", "set", key, value, "--by", "test", "--reason", "sharing acceptance")


def _seed_state(recipe_id: str, visibility: str = "public", *, approved: bool = True) -> None:
    _command(
        "recipes",
        "seed-sharing-state",
        recipe_id,
        "--visibility",
        visibility,
        "--by",
        "test",
        "--reason",
        "public approval fixture",
        *(["--approved"] if approved else []),
    )


def _make_public(
    _client, recipe_id: str, _headers: dict[str, str], *, approved: bool = True
) -> None:
    _seed_state(recipe_id, approved=approved)
    _configure("feature.public_recipes", "true")
    _configure("sharing.public_base_url", "https://share.example.test")
    _configure("sharing.complaint_contact", "rights@example.test")
    _configure("sharing.download_url", "https://example.test/app")


def _recipe(api: Api, email: str = "sharing@example.com"):
    headers = bearer(api.login(email))
    body = recipe_input("分享测试菜")
    body["snapshot"]["description"] = "一段可公开的简介"
    created = api.client.post("/v1/recipes", headers=headers, json=body)
    assert created.status_code == 201, created.text
    return created.json(), headers


def test_share_requires_public_approval_and_feature_flag(api: Api) -> None:
    saved, owner = _recipe(api)
    path = f"/v1/recipes/{saved['id']}/share"
    response = api.client.post(path, headers=owner)
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "not_found"

    _make_public(api.client, saved["id"], owner, approved=False)
    denied = api.client.post(path, headers=owner)
    assert denied.status_code == 404
    assert denied.json()["error"]["code"] == "not_found"

    _make_public(api.client, saved["id"], owner)
    outsider = bearer(api.login("sharing-outsider@example.com"))
    shared = api.client.post(path, headers=outsider)
    assert shared.status_code == 201, shared.text
    assert api.client.post(path, headers=owner).json() == shared.json()
    preview = api.client.get(f"/v1/recipes/{saved['id']}/share-preview", headers=outsider)
    assert preview.status_code == 200, preview.text
    assert set(preview.json()) == {
        "title",
        "description",
        "nickname",
        "image_url",
        "license",
        "photo_rights",
    }
    assert api.client.post(path).status_code == 401


def test_share_page_releases_only_allowlisted_projection_and_unavailable_is_uniform(
    api: Api,
) -> None:
    saved, owner = _recipe(api)
    _make_public(api.client, saved["id"], owner)
    created = api.client.post(f"/v1/recipes/{saved['id']}/share", headers=owner)
    assert created.status_code == 201, created.text
    link = created.json()
    assert set(link) == {"share_id", "url", "app_path"}
    assert len(link["share_id"]) == 43
    assert link["share_id"] not in saved["id"]
    assert link["url"] == f"https://share.example.test/s/{link['share_id']}"
    assert link["app_path"] == f"/recipes/{saved['id']}"

    page = api.client.get(f"/s/{link['share_id']}")
    assert page.status_code == 200
    html = page.text
    for expected in (
        "og:title",
        "og:description",
        "分享测试菜",
        "一段可公开的简介",
        "作者：",
        "CC BY-NC-SA 4.0",
        "照片版权归上传者所有",
        "在 App 里看完整菜谱",
    ):
        assert expected in html
    for forbidden in (
        "鸡腿肉",
        "干辣椒",
        "鸡腿肉加盐腌制",
        "大火炒至表面变白",
        "ingredient",
        "reproducibility",
        "taste_profile",
    ):
        assert forbidden not in html

    _seed_state(saved["id"], approved=False)
    unavailable = api.client.get(f"/s/{link['share_id']}")
    assert unavailable.status_code == 404
    assert unavailable.text == api.client.get("/s/does-not-exist").text
    assert "recipe" not in unavailable.text.lower()


def test_share_preview_robots_complaints_and_download(api: Api) -> None:
    saved, owner = _recipe(api, "sharing-pages@example.com")
    _make_public(api.client, saved["id"], owner)
    link = api.client.post(f"/v1/recipes/{saved['id']}/share", headers=owner).json()
    preview = api.client.get(f"/v1/recipes/{saved['id']}/share-preview", headers=owner)
    assert preview.status_code == 200, preview.text
    assert set(preview.json()) == {
        "title",
        "description",
        "nickname",
        "image_url",
        "license",
        "photo_rights",
    }
    robots = api.client.get("/robots.txt")
    assert robots.status_code == 200
    assert "User-agent: GPTBot\nDisallow: /" in robots.text
    assert "User-agent: ClaudeBot\nDisallow: /" in robots.text
    assert api.client.get("/complaints").status_code == 200
    assert "rights@example.test" in api.client.get("/complaints").text
    assert "https://example.test/app" in api.client.get("/download").text
    assert api.client.get(f"/s/{link['share_id']}/image").status_code == 404


@pytest.mark.parametrize("state", ["private", "removed", "unapproved", "flag_off"])
def test_all_unavailable_share_states_have_identical_html_and_resolver(
    api: Api, state: str
) -> None:
    saved, owner = _recipe(api)
    _make_public(api.client, saved["id"], owner)
    link = api.client.post(f"/v1/recipes/{saved['id']}/share", headers=owner).json()
    if state == "flag_off":
        _configure("feature.public_recipes", "false")
    else:
        _seed_state(
            saved["id"],
            "public" if state == "unapproved" else state,
            approved=state != "unapproved",
        )
    response = api.client.get(f"/s/{link['share_id']}")
    missing = api.client.get("/s/" + "x" * 43)
    assert response.status_code == missing.status_code == 404
    assert response.text == missing.text and response.headers["Cache-Control"] == "no-store"
    resolver = api.client.get(f"/v1/shares/{link['share_id']}")
    assert resolver.status_code == 404 and resolver.json()["error"]["code"] == "not_found"
    assert api.client.get(f"/s/{link['share_id']}/image").status_code == 404
    outsider = bearer(api.login("unavailable-share-reader@example.com"))
    for viewer in (owner, outsider):
        denied = api.client.post(f"/v1/recipes/{saved['id']}/share", headers=viewer)
        assert denied.status_code == 404 and denied.json()["error"]["code"] == "not_found"
        assert (
            api.client.get(f"/v1/recipes/{saved['id']}/share-preview", headers=viewer).status_code
            == 404
        )


def test_share_resolves_opaque_id_to_one_authorized_version_not_private_history(api: Api) -> None:
    saved, owner = _recipe(api)
    first_version = saved["version"]["id"]
    current = api.client.post(
        f"/v1/recipes/{saved['id']}/versions",
        headers=owner,
        json={"snapshot": saved["version"]["snapshot"], "change_note": "新版"},
    )
    assert current.status_code == 201, current.text
    _make_public(api.client, saved["id"], owner)
    path = f"/v1/recipes/{saved['id']}/share"
    link = api.client.post(path, headers=owner).json()
    assert api.client.post(path, headers=owner).json() == link
    resolved = api.client.get(f"/v1/shares/{link['share_id']}")
    assert resolved.status_code == 200
    assert resolved.json() == {
        "share_id": link["share_id"],
        "recipe_id": saved["id"],
        "app_path": f"/recipes/{saved['id']}",
    }
    outsider = bearer(api.login("share-reader@example.com"))
    detail = api.client.get(
        resolved.json()["app_path"].replace("/recipes", "/v1/recipes"), headers=outsider
    )
    assert detail.status_code == 200, detail.text
    assert detail.json()["version"]["id"] == current.json()["version"]["id"]
    assert (
        detail.json()["default_servings"] is None and detail.json()["taste_profile_version"] is None
    )
    assert (
        api.client.get(
            f"/v1/recipes/{saved['id']}/versions/{first_version}", headers=outsider
        ).status_code
        == 404
    )
    assert (
        api.client.get(f"/v1/recipes/{saved['id']}/versions", headers=outsider).status_code == 404
    )
    assert api.client.get(f"/v1/recipes/{saved['id']}").status_code == 401
    # Saving a new version invalidates approval; old link cannot resurrect the old snapshot.
    changed = api.client.post(
        f"/v1/recipes/{saved['id']}/versions",
        headers=owner,
        json={"snapshot": saved["version"]["snapshot"], "change_note": "尚未批准"},
    )
    assert changed.status_code == 201, changed.text
    assert api.client.get(f"/v1/shares/{link['share_id']}").status_code == 404
    assert api.client.get(f"/v1/recipes/{saved['id']}", headers=outsider).status_code == 404
    assert api.client.post(path, headers=outsider).status_code == 404
    assert (
        api.client.get(f"/v1/recipes/{saved['id']}/share-preview", headers=outsider).status_code
        == 404
    )


def test_share_rejects_inactive_author_for_public_readers(api: Api) -> None:
    saved, owner = _recipe(api)
    _make_public(api.client, saved["id"], owner)
    outsider = bearer(api.login("inactive-author-reader@example.com"))
    path = f"/v1/recipes/{saved['id']}/share"
    link = api.client.post(path, headers=outsider)
    assert link.status_code == 201, link.text
    assert api.send_code("sharing@example.com", "reauth", headers=owner).status_code == 200
    assert (
        api.client.post(
            "/v1/auth/reauth/email",
            headers=owner,
            json={"email": "sharing@example.com", "code": api.latest_code("sharing@example.com")},
        ).status_code
        == 204
    )
    assert api.client.post("/v1/me/deletion", headers=owner).status_code == 202
    assert api.client.post(path, headers=outsider).status_code == 404
    assert (
        api.client.get(f"/v1/recipes/{saved['id']}/share-preview", headers=outsider).status_code
        == 404
    )
    assert api.client.get(f"/v1/shares/{link.json()['share_id']}").status_code == 404
    assert api.client.get(f"/s/{link.json()['share_id']}/image").status_code == 404


def test_share_image_og_metadata_escape_and_random_id(api: Api) -> None:
    saved, owner = _recipe(api)
    upload = api.client.post(
        f"/v1/recipes/{saved['id']}/images", headers=owner, json=_image_payload()
    )
    assert upload.status_code == 201, upload.text
    _make_public(api.client, saved["id"], owner)
    first = api.client.post(f"/v1/recipes/{saved['id']}/share", headers=owner).json()
    other, other_owner = _recipe(api, "other-share-author@example.com")
    _make_public(api.client, other["id"], other_owner)
    second = api.client.post(f"/v1/recipes/{other['id']}/share", headers=other_owner).json()
    assert first["share_id"] != second["share_id"] and len(second["share_id"]) == 43
    page = api.client.get(f"/s/{first['share_id']}")
    assert 'property="og:image"' in page.text
    assert f"https://share.example.test/s/{first['share_id']}/image" in page.text
    assert f'href="https://share.example.test/s/{first["share_id"]}"' in page.text
    image = api.client.get(f"/s/{first['share_id']}/image")
    assert image.status_code == 200 and image.headers["content-type"].startswith("image/")
    assert image.headers["X-Content-Type-Options"] == "nosniff"
    assert image.headers["Cache-Control"] == "no-store"


def test_share_crawlers_configuration_ip_limits_and_access_log(api: Api, capsys) -> None:
    saved, owner = _recipe(api)
    _make_public(api.client, saved["id"], owner)
    link = api.client.post(f"/v1/recipes/{saved['id']}/share", headers=owner).json()
    _configure("sharing.ai_crawlers", '{"values":["ExampleTrainingBot"]}')
    assert "User-agent: ExampleTrainingBot\nDisallow: /" in api.client.get("/robots.txt").text
    denied = api.client.get(
        f"/s/{link['share_id']}", headers={"User-Agent": "ExampleTrainingBot/1.0"}
    )
    assert denied.status_code == 403 and saved["dish"]["name"] not in denied.text
    assert "ingredients" not in denied.text
    _configure("rate.detail.ip_per_minute", "1")
    # Move into the next quota minute without resetting any counters.
    api.clock.advance(seconds=61)
    request_id = str(uuid.uuid4())
    assert (
        api.client.get(f"/s/{link['share_id']}", headers={"X-Request-ID": request_id}).status_code
        == 200
    )
    limited = api.client.get(f"/v1/shares/{link['share_id']}")
    assert limited.status_code == 429 and int(limited.headers["Retry-After"]) > 0
    assert cli(["access-logs", "list", "--request-id", request_id]) == 0
    logs = json.loads(capsys.readouterr().out)
    assert len(logs) == 1 and logs[0]["endpoint"] == "/s/{share_id}"
    assert logs[0]["status_code"] == 200 and logs[0]["content_ids"]
    assert saved["dish"]["name"] not in json.dumps(logs)


def test_public_rights_complaint_is_pending_private_bounded_and_reviewable(
    api: Api, capsys
) -> None:
    contact, message = (
        "rights-owner@example.com",
        "My copyright is infringed by this public recipe.",
    )
    request_id = str(uuid.uuid4())
    response = api.client.post(
        "/complaints",
        data={"contact": contact, "message": message, "share_id": "missing-share"},
        headers={"X-Request-ID": request_id},
    )
    assert response.status_code == 201, response.text
    assert contact not in response.text and message not in response.text
    assert cli(["share-complaints", "list"]) == 0
    queue = json.loads(capsys.readouterr().out)
    assert len(queue) == 1 and queue[0]["status"] == "pending"
    assert queue[0]["contact"] == contact and queue[0]["message"] == message
    assert queue[0]["share_id"] == "missing-share"
    assert api.client.get("/v1/share-complaints").status_code == 404
    assert cli(["access-logs", "list", "--request-id", request_id]) == 0
    logs = json.loads(capsys.readouterr().out)
    assert contact not in json.dumps(logs) and message not in json.dumps(logs)
    assert (
        cli(
            [
                "share-complaints",
                "review",
                queue[0]["id"],
                "--status",
                "reviewed",
                "--by",
                "rights-team",
            ]
        )
        == 0
    )
    capsys.readouterr()
    assert cli(["share-complaints", "list"]) == 0
    assert json.loads(capsys.readouterr().out) == []
    assert cli(["share-complaints", "list", "--status", "reviewed"]) == 0
    reviewed = json.loads(capsys.readouterr().out)[0]
    assert reviewed["reviewed_at"] and reviewed["reviewed_by"] == "rights-team"
    for payload in (
        {"contact": "not-email", "message": message},
        {"contact": contact, "message": "x" * 4001},
    ):
        rejected = api.client.post("/complaints", data=payload)
        assert rejected.status_code == 422
        assert contact not in rejected.text and message not in rejected.text
    attachment = api.client.post(
        "/complaints", content=b"file", headers={"Content-Type": "application/octet-stream"}
    )
    assert attachment.status_code == 415
    excessive = api.client.post(
        "/complaints",
        content=b"x" * 16385,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    assert excessive.status_code == 413
    accepted = api.client.post(
        "/v1/shares/missing-share/complaints", json={"contact": contact, "message": message}
    )
    assert accepted.status_code == 201 and accepted.json() == {"accepted": True}
    _configure("rate.write.ip_per_minute", "1")
    api.clock.advance(seconds=61)
    assert (
        api.client.post("/complaints", data={"contact": contact, "message": message}).status_code
        == 201
    )
    limited = api.client.post("/complaints", data={"contact": contact, "message": message})
    assert limited.status_code == 429 and int(limited.headers["Retry-After"]) > 0


def test_public_detail_redacts_private_edit_evidence_and_notes(api: Api) -> None:
    saved, owner = _recipe(api)
    snapshot = saved["version"]["snapshot"]
    snapshot["ingredients"][0]["display_name"] = "公开食材"
    snapshot["steps"][0]["instruction"] = "公开腌制说明"
    changed = api.client.post(
        f"/v1/recipes/{saved['id']}/versions",
        headers=owner,
        json={"snapshot": snapshot, "change_note": "private-history-note"},
    )
    assert changed.status_code == 201, changed.text
    owned = changed.json()["version"]
    assert owned["edit_operations"]
    assert "鸡腿肉" in json.dumps(owned["edit_operations"], ensure_ascii=False)
    _make_public(api.client, saved["id"], owner)
    outsider = bearer(api.login("projection-reader@example.com"))
    for path in (
        f"/v1/recipes/{saved['id']}",
        f"/v1/recipes/{saved['id']}/versions/{owned['id']}",
    ):
        response = api.client.get(path, headers=outsider)
        assert response.status_code == 200, response.text
        version = response.json()["version"]
        assert version["edit_operations"] == [] and version["change_note"] == ""
        assert version["previous_version_id"] is None and version["base_version_id"] is None
        assert "private-history-note" not in response.text
        assert "鸡腿肉" not in response.text and "鸡腿肉加盐腌制" not in response.text


def test_concurrent_first_share_issuance_returns_one_stable_link(api: Api) -> None:
    saved, owner = _recipe(api)
    _make_public(api.client, saved["id"], owner)
    path = f"/v1/recipes/{saved['id']}/share"
    with ThreadPoolExecutor(max_workers=6) as pool:
        responses = list(pool.map(lambda _: api.client.post(path, headers=owner), range(6)))
    assert all(response.status_code == 201 for response in responses)
    links = [response.json() for response in responses]
    assert all(link == links[0] for link in links)
    assert api.client.get(f"/v1/shares/{links[0]['share_id']}").status_code == 200
