"""Data portability through authenticated HTTP, ZIP downloads and the operator CLI."""

import io
import json
import os
import subprocess
import sys
from pathlib import Path
from urllib.parse import parse_qs, urlencode, urlsplit, urlunsplit
from zipfile import ZipFile

from tests.accounts_support import Api, bearer
from tests.test_recipes import recipe_input

SERVER = Path(__file__).resolve().parents[1]


def reauth(api: Api, tokens: dict, email: str) -> None:
    response = api.send_code(email, purpose="reauth", headers=bearer(tokens))
    assert response.status_code == 200, response.text
    response = api.client.post(
        "/v1/auth/reauth/email",
        headers=bearer(tokens),
        json={"email": email, "code": api.latest_code(email)},
    )
    assert response.status_code == 204, response.text


def run_exports(api: Api, action: str = "run") -> dict:
    result = subprocess.run(
        [sys.executable, "-m", "gramtree.exports", action, "--as-of", api.clock.now.isoformat()],
        cwd=SERVER,
        env=os.environ.copy(),
        capture_output=True,
        text=True,
        encoding="utf-8",
        timeout=30,
    )
    assert result.returncode == 0, result.stderr
    return json.loads(result.stdout)


def archive(api: Api, tokens: dict, job_id: str) -> dict:
    response = api.client.get(f"/v1/me/exports/{job_id}", headers=bearer(tokens))
    assert response.status_code == 200, response.text
    job = response.json()
    assert job["status"] == "completed", job
    response = api.client.get(job["download_url"], headers=bearer(tokens))
    assert response.status_code == 200, response.text
    assert response.headers["cache-control"] == "no-store"
    with ZipFile(io.BytesIO(response.content)) as zipped:
        return {
            name: json.loads(zipped.read(name))
            for name in zipped.namelist()
            if name.endswith(".json")
        }


def test_export_requires_reauth_and_download_never_bypasses_owner_auth(api: Api) -> None:
    assert api.client.post("/v1/me/exports").status_code == 401
    email = "export-owner@example.com"
    owner = api.login(email)
    assert api.client.post("/v1/me/exports", headers=bearer(owner)).status_code == 403
    reauth(api, owner, email)
    recipe = api.client.post("/v1/recipes", json=recipe_input(), headers=bearer(owner))
    assert recipe.status_code == 201, recipe.text
    recipe_id = recipe.json()["id"]
    recipe_detail = api.client.get(f"/v1/recipes/{recipe_id}", headers=bearer(owner)).json()
    record = api.client.post(
        "/v1/records",
        headers=bearer(owner),
        json={
            "client_id": "0d3c35da-57d3-4b3c-94a4-9f9a7d3f6b01",
            "recipe_id": recipe_id,
            "recipe_version_id": recipe_detail["version"]["id"],
            "dish_name": "宫保鸡丁",
        },
    )
    assert record.status_code == 201, record.text
    revision = api.client.post(
        f"/v1/records/{record.json()['id']}/revisions",
        headers=bearer(owner),
        json={
            "revision_id": "9d6c4bfb-3f6c-4a1a-bf95-f7b1ea0da8b2",
            "field": "rating",
            "value": {"score": 5},
        },
    )
    assert revision.status_code == 201, revision.text
    job = api.client.post("/v1/me/exports", headers=bearer(owner))
    assert job.status_code == 202, job.text
    job_id = job.json()["id"]
    run_exports(api)
    exported = archive(api, owner, job_id)
    assert exported["account.json"]["format_version"] == 1
    assert exported["recipes.json"]["items"][0]["id"] == recipe.json()["id"]
    assert exported["recipe_versions.json"]["items"][0]["snapshot"]["servings"] == 2
    assert exported["recipe_versions.json"]["items"][0]["reproducibility"]
    assert exported["cooking_record_revisions.json"]["items"][0]["value"]["score"] == 5
    url = api.client.get(f"/v1/me/exports/{job_id}", headers=bearer(owner)).json()["download_url"]
    assert url.startswith("/v1/me/exports/")
    assert api.client.get(url).status_code == 401
    foreign = api.login("export-foreign@example.com")
    assert api.client.get(f"/v1/me/exports/{job_id}", headers=bearer(foreign)).status_code == 404
    assert api.client.get(url, headers=bearer(foreign)).status_code == 404
    parsed = urlsplit(url)
    query = parse_qs(parsed.query)
    query["signature"] = [
        query["signature"][0][:-1] + ("0" if query["signature"][0][-1] != "0" else "1")
    ]
    tampered = urlunsplit(parsed._replace(query=urlencode(query, doseq=True)))
    assert api.client.get(tampered, headers=bearer(owner)).status_code == 403
    assert api.client.get(url + "x", headers=bearer(owner)).status_code == 422
    assert api.client.get("/data-export-format").status_code == 200
