"""Tests for the no-database ingredient data validator (issue #104)."""

import copy
import json
from pathlib import Path

import pytest

from gramtree.cli import main as cli
from gramtree.ingredients.attributes import GB_ALLERGENS
from gramtree.ingredients.importer import validate_directory

SEED = Path(__file__).parent.parent / "data" / "ingredients"
UUID_A = "00000000-0000-4000-8000-000000000101"
UUID_B = "00000000-0000-4000-8000-000000000102"


def _record(
    id_: str = UUID_A,
    name: str = "测试食材",
    *,
    aliases: list[str] | None = None,
    attributes: dict[str, object] | None = None,
    merged_into: str | None = None,
) -> dict[str, object]:
    record: dict[str, object] = {
        "id": id_,
        "standard_name": name,
        "aliases": aliases or [],
        "pinyin": "ceshi",
        "pinyin_initials": "cs",
        "category": "调料",
    }
    if attributes is not None:
        record["attributes"] = attributes
    if merged_into is not None:
        record["merged_into"] = merged_into
    return record


def _allergen_attribute(value: list[str] | None = None) -> dict[str, object]:
    return {
        "value": value if value is not None else list(GB_ALLERGENS),
        "source": "测试来源",
        "status": "verified",
    }


def _write(directory: Path, records: list[dict[str, object]]) -> Path:
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "测试"}, ensure_ascii=False),
        encoding="utf-8",
    )
    (directory / "调料.json").write_text(
        json.dumps(records, ensure_ascii=False),
        encoding="utf-8",
    )
    return directory


def _assert_rejected(directory: Path, capsys: pytest.CaptureFixture[str], *expected: str) -> None:
    assert cli(["ingredients", "validate", str(directory)]) == 1
    error = capsys.readouterr().err
    for part in expected:
        assert part in error


def test_seed_library_validates_without_database() -> None:
    """The complete repository data passes the validator without opening a DB."""
    validate_directory(SEED)


def test_identity_only_record_does_not_need_every_optional_attribute(tmp_path: Path) -> None:
    directory = _write(
        tmp_path,
        [_record(attributes={"allergens": _allergen_attribute()})],
    )

    validate_directory(directory)


def test_validator_reports_missing_identity_field(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    record = _record()
    del record["standard_name"]
    _assert_rejected(_write(tmp_path, [record]), capsys, "调料.json", "第 1 条", "standard_name")


def test_validator_reports_non_v4_identity_id(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    record = _record(id_="00000000-0000-1000-8000-000000000101")
    _assert_rejected(_write(tmp_path, [record]), capsys, "调料.json", "测试食材", "id")


def test_validator_reports_missing_attribute_source(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    record = _record(
        attributes={"density": {"value": 1.0, "status": "verified"}},
    )
    _assert_rejected(_write(tmp_path, [record]), capsys, "调料.json", "测试食材", "density.source")


def test_validator_reports_unregistered_allergen(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    record = _record(attributes={"allergens": _allergen_attribute(["小麦"])})
    _assert_rejected(_write(tmp_path, [record]), capsys, "调料.json", "测试食材", "allergens")


def test_validator_reports_unregistered_unit(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    record = _record(
        attributes={
            "count_units": {
                "value": [{"unit": "坨", "grams": 10}],
                "source": "测试来源",
                "status": "verified",
            }
        }
    )
    _assert_rejected(_write(tmp_path, [record]), capsys, "调料.json", "测试食材", "count_units")


def test_validator_reports_duplicate_alias(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    records = [_record(aliases=["共用"]), _record(UUID_B, "另一食材", aliases=["共用"])]
    _assert_rejected(_write(tmp_path, records), capsys, "调料.json", "另一食材", "aliases")


def test_validator_reports_deleted_id_against_baseline(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    baseline = _write(
        tmp_path / "baseline",
        [_record(), _record(UUID_B, "历史食材")],
    )
    current = _write(
        tmp_path / "current",
        [_record(attributes={"allergens": _allergen_attribute()})],
    )

    assert (
        cli(
            [
                "ingredients",
                "validate",
                str(current),
                "--baseline-dir",
                str(baseline),
            ]
        )
        == 1
    )
    error = capsys.readouterr().err
    assert "调料.json" in error
    assert "历史食材" in error
    assert "id" in error


def test_validator_reports_missing_merge_target(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    record = _record(merged_into=UUID_B)
    _assert_rejected(_write(tmp_path, [record]), capsys, "调料.json", "测试食材", "merged_into")


@pytest.mark.parametrize(
    "records",
    [
        [
            _record(merged_into=UUID_B),
            _record(UUID_B, "另一食材", merged_into=UUID_A),
        ],
        [
            _record(merged_into=UUID_B),
            _record(UUID_B, "另一食材", merged_into="00000000-0000-4000-8000-000000000103"),
            _record("00000000-0000-4000-8000-000000000103", "终点"),
        ],
    ],
    ids=["cycle", "merge_chain"],
)
def test_validator_reports_merge_cycles_and_chains(
    tmp_path: Path,
    capsys: pytest.CaptureFixture[str],
    records: list[dict[str, object]],
) -> None:
    _assert_rejected(_write(tmp_path, records), capsys, "调料.json", "merged_into")


def test_validator_requires_all_eight_gb_allergen_categories(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    record = _record(attributes={"allergens": _allergen_attribute(list(GB_ALLERGENS[:7]))})
    _assert_rejected(_write(tmp_path, [record]), capsys, "attributes.allergens", GB_ALLERGENS[7])


def test_validator_accepts_explicit_ambiguous_alias(tmp_path: Path) -> None:
    directory = _write(
        tmp_path,
        [
            _record(aliases=["共用"], attributes={"allergens": _allergen_attribute()}),
            _record(UUID_B, "另一食材", aliases=["共用"]),
        ],
    )
    manifest = json.loads((directory / "manifest.json").read_text(encoding="utf-8"))
    manifest["ambiguous_names"] = ["共用"]
    (directory / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False), encoding="utf-8"
    )

    validate_directory(directory)


def test_validator_does_not_mutate_input(tmp_path: Path) -> None:
    records = [_record(attributes={"allergens": _allergen_attribute()})]
    before = copy.deepcopy(records)
    validate_directory(_write(tmp_path, records))
    assert records == before
