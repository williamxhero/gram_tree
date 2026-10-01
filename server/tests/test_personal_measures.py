"""Personal measure CRUD and deterministic display conversion through public HTTP."""

import json
from pathlib import Path

import pytest

from tests.accounts_support import Api, bearer
from tests.test_conventions import assert_error_shape

FIXTURE_PATH = Path(__file__).parents[2] / "app" / "assets" / "measure_display_cases.json"
CASES = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))


def test_personal_measures_are_account_scoped_and_syncable(api: Api) -> None:
    owner = bearer(api.login("measures-owner@example.com", device="device-a"))
    other = bearer(api.login("measures-other@example.com", device="device-b"))

    created = api.client.post(
        "/v1/me/measures",
        json={"name": "白瓷勺", "kind": "spoon", "capacity_ml": 12.0},
        headers=owner,
    )
    assert created.status_code == 201, created.text
    measure = created.json()
    assert measure["name"] == "白瓷勺"
    assert measure["kind"] == "spoon"
    assert measure["capacity_ml"] == 12.0

    listed_on_other_device = api.client.get("/v1/me/measures", headers=owner)
    assert listed_on_other_device.status_code == 200
    assert listed_on_other_device.json() == [measure]

    listed_for_other_account = api.client.get("/v1/me/measures", headers=other)
    assert listed_for_other_account.status_code == 200
    assert listed_for_other_account.json() == []

    updated = api.client.patch(
        f"/v1/me/measures/{measure['id']}",
        json={"name": "大白瓷勺", "capacity_ml": 15},
        headers=owner,
    )
    assert updated.status_code == 200, updated.text
    assert updated.json()["name"] == "大白瓷勺"
    assert updated.json()["capacity_ml"] == 15

    hidden = api.client.get(
        f"/v1/me/measures/{measure['id']}",
        headers=other,
    )
    assert_error_shape(hidden, 404, "not_found")

    deleted = api.client.delete(f"/v1/me/measures/{measure['id']}", headers=owner)
    assert deleted.status_code == 204, deleted.text
    assert api.client.get("/v1/me/measures", headers=owner).json() == []


def test_personal_measure_validation_and_duplicate_names(api: Api) -> None:
    headers = bearer(api.login("measures-validation@example.com"))
    for body in (
        {"name": "", "kind": "spoon", "capacity_ml": 10},
        {"name": "勺", "kind": "plate", "capacity_ml": 10},
        {"name": "勺", "kind": "spoon", "capacity_ml": 0},
        {"name": "勺", "kind": "spoon", "capacity_ml": 10001},
    ):
        response = api.client.post("/v1/me/measures", json=body, headers=headers)
        assert_error_shape(response, 422, "invalid_request")

    first = api.client.post(
        "/v1/me/measures",
        json={"name": "同名量具", "kind": "bowl", "capacity_ml": 300},
        headers=headers,
    )
    assert first.status_code == 201, first.text
    duplicate = api.client.post(
        "/v1/me/measures",
        json={"name": "同名量具", "kind": "cup", "capacity_ml": 250},
        headers=headers,
    )
    assert_error_shape(duplicate, 409, "measure_name_taken")


@pytest.mark.parametrize("case", CASES, ids=[case["name"] for case in CASES])
def test_measure_display_matches_shared_fixture(case: dict) -> None:
    # The fixture is consumed by the app and server tests. The HTTP CRUD seam above
    # keeps account data external; this check pins the deterministic display contract.
    from gramtree.recipes.measure_display import display_amount

    actual = display_amount(**case["input"])
    assert actual == case["expected"], case["name"]
