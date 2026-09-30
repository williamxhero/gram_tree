"""食材库增量同步和批量读取（ticket #101）。"""

import copy
import json
from pathlib import Path
from typing import Any

from fastapi.testclient import TestClient

from gramtree.cli import main as cli
from tests.test_conventions import assert_error_shape

A = "00000000-0000-4000-8000-000000000201"
B = "00000000-0000-4000-8000-000000000202"
C = "00000000-0000-4000-8000-000000000203"
MISSING = "00000000-0000-4000-8000-ffffffffffff"


AI_DENSITY = {"value": 1.0, "source": "测试估算", "status": "ai_draft"}


def _record(id_: str, name: str, pinyin: str, **extra: Any) -> dict[str, Any]:
    record: dict[str, Any] = {
        "id": id_,
        "standard_name": name,
        "aliases": [],
        "pinyin": pinyin,
        "pinyin_initials": "".join(part[0] for part in pinyin.split("-")),
        "category": "调料",
    }
    record.update(extra)
    return record


def _write(directory: Path, version: str, records: list[dict[str, Any]], changelog: str) -> Path:
    directory.mkdir()
    (directory / "manifest.json").write_text(
        json.dumps({"version": version, "changelog": changelog}), encoding="utf-8"
    )
    (directory / "data.json").write_text(json.dumps(records), encoding="utf-8")
    return directory


def _import(directory: Path) -> int:
    return cli(["ingredients", "import", str(directory)])


def _library_at(version: str, records: list[dict[str, Any]], tmp_path: Path, name: str) -> Path:
    return _write(tmp_path / name, version, records, f"发布 {version}")


def test_changes_returns_full_interval_and_numeric_versions(
    client: TestClient, tmp_path: Path
) -> None:
    """三次发布覆盖 2.9→2.10 的数字排序、新增后修改、合并和完整变更说明。"""
    baseline = [
        _record(A, "食材甲", "shicaijia", attributes={"density": AI_DENSITY}),
        _record(B, "食材乙", "shicaiyi"),
    ]
    v29 = _library_at("2.9.0", baseline, tmp_path, "v29")
    assert _import(v29) == 0

    v210_records = copy.deepcopy(baseline)
    v210_records[0]["standard_name"] = "食材甲改名"
    v210_records.append(_record(C, "食材丙", "shicaibing"))
    v210 = _library_at("2.10.0", v210_records, tmp_path, "v210")
    assert _import(v210) == 0

    v211_records = copy.deepcopy(v210_records)
    v211_records[1]["standard_name"] = "食材乙旧名"
    v211_records[1]["aliases"] = ["旧乙"]
    v211_records[1]["merged_into"] = A
    v211_records[2]["attributes"] = {"density": AI_DENSITY | {"value": 1.2}}
    v211 = _library_at("2.11.0", v211_records, tmp_path, "v211")
    assert _import(v211) == 0

    full = client.get("/v1/ingredients/changes")
    assert full.status_code == 200
    full_data = full.json()
    assert full_data["current_version"] == "2.11.0"
    assert [note["version"] for note in full_data["releases"]] == ["2.9.0", "2.10.0", "2.11.0"]
    assert {item["id"] for item in full_data["added"]} == {A, C}
    assert [{item["from_id"], item["to_id"]} for item in full_data["merged"]] == [{B, A}]
    assert full_data["merged"][0]["identity"]["id"] == B
    assert full_data["merged"][0]["identity"]["standard_name"] == "食材乙旧名"
    assert full_data["merged"][0]["identity"]["aliases"] == ["旧乙"]
    assert full_data["merged"][0]["identity"]["pinyin"] == "shicaiyi"
    assert full_data["modified"] == []
    assert full_data["added"][0]["attributes"]["density"]["estimate"] is True

    since_29 = client.get("/v1/ingredients/changes?since_version=2.9.0")
    assert since_29.status_code == 200
    data_29 = since_29.json()
    assert [note["version"] for note in data_29["releases"]] == ["2.10.0", "2.11.0"]
    assert {item["id"] for item in data_29["added"]} == {C}
    assert {item["id"] for item in data_29["modified"]} == {A}
    assert [{item["from_id"], item["to_id"]} for item in data_29["merged"]] == [{B, A}]
    assert data_29["merged"][0]["identity"]["id"] == B
    assert data_29["merged"][0]["identity"]["standard_name"] == "食材乙旧名"

    since_210 = client.get("/v1/ingredients/changes?since_version=2.10.0")
    assert since_210.status_code == 200
    data_210 = since_210.json()
    assert data_210["added"] == []
    assert {item["id"] for item in data_210["modified"]} == {C}
    assert [{item["from_id"], item["to_id"]} for item in data_210["merged"]] == [{B, A}]
    assert data_210["merged"][0]["identity"]["id"] == B
    assert data_210["merged"][0]["identity"]["standard_name"] == "食材乙旧名"
    assert [note["version"] for note in data_210["releases"]] == ["2.11.0"]

    latest = client.get("/v1/ingredients/changes?since_version=2.11.0")
    assert latest.status_code == 200
    assert latest.json() == {
        "current_version": "2.11.0",
        "added": [],
        "modified": [],
        "merged": [],
        "releases": [],
    }

    assert_error_shape(
        client.get("/v1/ingredients/changes?since_version=99.0.0"),
        404,
        "not_found",
    )


def test_batch_returns_missing_ids_and_merge_provenance(client: TestClient, tmp_path: Path) -> None:
    records = [
        _record(A, "新食材", "xinshicai"),
        _record(B, "旧食材", "jiushicai", merged_into=A),
    ]
    assert _import(_library_at("1.0.0", records, tmp_path, "batch")) == 0

    response = client.post("/v1/ingredients/batch", json={"ids": [B, A, MISSING]})
    assert response.status_code == 200
    data = response.json()
    assert [item["id"] for item in data["items"]] == [A, A]
    assert data["items"][0]["requested_id"] == B
    assert data["items"][1]["requested_id"] is None
    assert data["missing_ids"] == [MISSING]

    invalid = client.get("/v1/ingredients/batch?ids=not-an-id")
    assert_error_shape(invalid, 422, "invalid_request")


def test_import_version_is_immutable_but_same_data_is_idempotent(
    client: TestClient, tmp_path: Path
) -> None:
    original = [_record(A, "原始食材", "yuanshicai")]
    first = _write(tmp_path / "first", "1.0.0", original, "原始说明")
    assert _import(first) == 0

    # Same data is a no-op, and a retry cannot rewrite a release note.
    retry = _write(tmp_path / "retry", "1.0.0", copy.deepcopy(original), "不同说明")
    assert _import(retry) == 0
    notes = client.get("/v1/ingredients/changes").json()["releases"]
    assert notes == [{"version": "1.0.0", "changelog": "原始说明"}]

    changed = [_record(A, "被篡改的食材", "yuanshicai")]
    assert _import(_write(tmp_path / "changed", "1.0.0", changed, "篡改")) == 1
    assert client.get(f"/v1/ingredients/{A}").json()["standard_name"] == "原始食材"

    older = [_record(A, "更旧的食材", "yuanshicai")]
    assert _import(_write(tmp_path / "older", "0.9.0", older, "回退")) == 1
    assert client.get(f"/v1/ingredients/{A}").json()["standard_name"] == "原始食材"


def test_batch_get_matches_post_and_validates_uuid_version(
    client: TestClient, tmp_path: Path
) -> None:
    records = [_record(A, "测试食材", "ceshishicai", attributes={"density": AI_DENSITY})]
    assert _import(_library_at("1.0.0", records, tmp_path, "batch_get")) == 0
    expected = client.post("/v1/ingredients/batch", json={"ids": [A, MISSING]}).json()
    response = client.get("/v1/ingredients/batch", params={"ids": f"{A},{MISSING}"})
    assert response.status_code == 200
    assert response.json() == expected
    assert response.json()["items"][0]["attributes"]["density"]["estimate"] is True

    for invalid_id in ("not-an-id", "00000000-0000-1000-8000-000000000201"):
        assert_error_shape(
            client.get("/v1/ingredients/batch", params={"ids": invalid_id}),
            422,
            "invalid_request",
        )
        assert_error_shape(
            client.post("/v1/ingredients/batch", json={"ids": [invalid_id]}),
            422,
            "invalid_request",
        )

    for empty_ids in ("", ",,", f"{A},"):
        assert_error_shape(
            client.get("/v1/ingredients/batch", params={"ids": empty_ids}),
            422,
            "invalid_request",
        )

    duplicates = client.post("/v1/ingredients/batch", json={"ids": [A, A]})
    assert duplicates.status_code == 200
    assert [item["id"] for item in duplicates.json()["items"]] == [A, A]


def test_unchanged_release_has_notes_without_record_changes(
    client: TestClient, tmp_path: Path
) -> None:
    records = [_record(A, "未改变的食材", "weigaibiandeshicai")]
    assert _import(_library_at("2.9.0", records, tmp_path, "original")) == 0
    same = _library_at("2.10.0", records, tmp_path, "same")
    assert _import(same) == 0
    assert _import(same) == 0
    response = client.get("/v1/ingredients/changes", params={"since_version": "2.9.0"})
    assert response.status_code == 200
    assert response.json() == {
        "current_version": "2.10.0",
        "added": [],
        "modified": [],
        "merged": [],
        "releases": [{"version": "2.10.0", "changelog": "发布 2.10.0"}],
    }
    assert client.get(f"/v1/ingredients/{A}").json()["version"] == "2.9.0"


def test_empty_library_and_invalid_since_version_return_api_errors(client: TestClient) -> None:
    assert_error_shape(client.get("/v1/ingredients/changes"), 404, "not_found")


def test_equivalent_version_cannot_publish_changed_data(client: TestClient, tmp_path: Path) -> None:
    original = [_record(A, "原始食材", "yuanshicaia")]
    assert _import(_library_at("1.0.0", original, tmp_path, "original")) == 0
    changed = [_record(A, "错误食材", "cuowushicai")]
    assert _import(_library_at("01.0.0", changed, tmp_path, "equivalent")) == 1
    assert client.get(f"/v1/ingredients/{A}").json()["standard_name"] == "原始食材"
