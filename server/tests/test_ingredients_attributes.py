"""食材详细属性（ticket #97，SPEC-002.1）。

只通过外部接口测试：命令行导入（`gramtree ingredients import`）+ HTTP 读取。
"""

import copy
import json
from pathlib import Path
from typing import Any

import pytest
from fastapi.testclient import TestClient

from gramtree.cli import main as cli

FIXTURES = Path(__file__).parent / "data" / "ingredients"
SEED = Path(__file__).parent.parent / "data" / "ingredients"

FULL_ID = "00000000-0000-4000-8000-000000000101"
OTHER_ID = "00000000-0000-4000-8000-000000000102"

AI = {"source": "AI 起草、待核对", "status": "ai_draft"}
CHECKED = {"source": "人工整理", "status": "verified"}

FULL_ATTRIBUTES: dict[str, Any] = {
    "flavor": {"value": {"salty": 3, "umami": 2}, **CHECKED},
    "functional": {"value": False, **AI},
    "scaling": {"value": "线性", **AI},
    "base_unit": {"value": "毫升", **CHECKED},
    "density": {"value": 1.15, **AI},
    "count_units": {"value": [{"unit": "片", "grams": 5}], **AI},
    "allergens": {"value": ["大豆", "含麸质的谷物"], **CHECKED},
    "nutrition": {
        "value": {"energy_kcal": 63, "protein_g": 5.6, "sodium_mg": 5757},
        "source": "USDA FoodData Central（测试用）",
        "status": "verified",
    },
    "purchase_units": {"value": [{"name": "瓶", "grams": 580}, {"name": "袋", "grams": 400}], **AI},
    "market_zone": {"value": "粮油调味", **AI},
    "storage": {"value": [{"method": "常温", "days": 180}, {"method": "冷藏", "days": 365}], **AI},
    "pantry_staple": {"value": True, **CHECKED},
}

EST = {"source": "AI 起草、待核对", "status": "ai_draft", "estimate": True}
OK = {"source": "人工整理", "status": "verified", "estimate": False}

# 按 #97 期望的接口输出，逐项手写：没写的味型是 0，没写的营养项是 null
FULL_EXPECTED: dict[str, Any] = {
    "flavor": {
        "value": {
            "salty": 3,
            "sweet": 0,
            "sour": 0,
            "spicy": 0,
            "umami": 2,
            "numbing": 0,
            "oily": 0,
        },
        **OK,
    },
    "functional": {"value": False, **EST},
    "scaling": {"value": "线性", **EST},
    "base_unit": {"value": "毫升", **OK},
    "density": {"value": 1.15, **EST},
    "count_units": {"value": [{"unit": "片", "grams": 5.0}], **EST},
    "allergens": {"value": ["大豆", "含麸质的谷物"], **OK},
    "nutrition": {
        "value": {
            "energy_kcal": 63.0,
            "protein_g": 5.6,
            "fat_g": None,
            "carbohydrate_g": None,
            "sodium_mg": 5757.0,
        },
        "source": "USDA FoodData Central（测试用）",
        "status": "verified",
        "estimate": False,
    },
    "purchase_units": {
        "value": [{"name": "瓶", "grams": 580.0}, {"name": "袋", "grams": 400.0}],
        **EST,
    },
    "market_zone": {"value": "粮油调味", **EST},
    "storage": {
        "value": [{"method": "常温", "days": 180}, {"method": "冷藏", "days": 365}],
        **EST,
    },
    "pantry_staple": {"value": True, **OK},
}

ALL_NULL = dict.fromkeys(FULL_EXPECTED)


def _record(id_: str, name: str, pinyin: str, attributes: dict[str, Any] | None = None) -> dict:
    record: dict[str, Any] = {
        "id": id_,
        "standard_name": name,
        "aliases": [],
        "pinyin": pinyin,
        "pinyin_initials": pinyin[0],
        "category": "调料",
    }
    if attributes is not None:
        record["attributes"] = attributes
    return record


def _write(directory: Path, version: str, records: list[dict]) -> Path:
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "manifest.json").write_text(
        json.dumps({"version": version, "changelog": "测试"}), encoding="utf-8"
    )
    (directory / "data.json").write_text(json.dumps(records, ensure_ascii=False), encoding="utf-8")
    return directory


def _import(directory: Path) -> int:
    return cli(["ingredients", "import", str(directory)])


def _attributes(client: TestClient, id_: str) -> dict[str, Any]:
    resp = client.get(f"/v1/ingredients/{id_}")
    assert resp.status_code == 200
    return resp.json()["attributes"]


def test_full_attributes_read_back(client: TestClient, tmp_path: Path) -> None:
    """数据文件里写的全部属性，按 ID 读取时原样返回，并带来源、校对状态和估算标记。"""
    _write(tmp_path, "1.0.0", [_record(FULL_ID, "测试酱油", "ceshijiangyou", FULL_ATTRIBUTES)])
    assert _import(tmp_path) == 0

    assert _attributes(client, FULL_ID) == FULL_EXPECTED


def test_identity_only_records_still_import(client: TestClient) -> None:
    """只有身份信息的旧数据照样能导入，属性全是 null。"""
    assert _import(FIXTURES) == 0

    assert _attributes(client, "00000000-0000-4000-8000-000000000001") == ALL_NULL


def test_estimate_marker_follows_verification(client: TestClient, tmp_path: Path) -> None:
    """同一种食材里，未校对的字段标为估算，人工校对过的不标。"""
    attrs = {
        "density": {"value": 1.2, "source": "AI 起草", "status": "ai_draft"},
        "base_unit": {"value": "克", "source": "人工核对", "status": "verified"},
    }
    _write(tmp_path, "1.0.0", [_record(FULL_ID, "测试醋", "ceshicu", attrs)])
    assert _import(tmp_path) == 0

    got = _attributes(client, FULL_ID)
    assert got["density"]["estimate"] is True
    assert got["base_unit"]["estimate"] is False
    assert got["nutrition"] is None


INVALID_CASES = [
    ("flavor", {"value": {"salty": 4}, **AI}, "flavor"),
    ("flavor", {"value": {"sweet": -1}, **AI}, "flavor"),
    ("flavor", {"value": {"bitter": 1}, **AI}, "flavor"),
    ("flavor", {"value": {"salty": 1.5}, **AI}, "flavor"),
    ("allergens", {"value": ["小麦"], **AI}, "过敏原分类“小麦”没有登记"),
    ("allergens", {"value": ["大豆", "大豆"], **AI}, "重复"),
    ("scaling", {"value": "按比例", **AI}, "缩放方式“按比例”没有登记"),
    ("base_unit", {"value": "斤", **AI}, "基础单位“斤”没有登记"),
    ("market_zone", {"value": "生鲜", **AI}, "超市分区“生鲜”没有登记"),
    ("storage", {"value": [{"method": "阴凉", "days": 3}], **AI}, "存放方式“阴凉”没有登记"),
    ("storage", {"value": [{"method": "冷藏", "days": 0}], **AI}, "storage"),
    ("density", {"value": 0, **AI}, "density"),
    ("density", {"value": -1.0, **AI}, "density"),
    ("count_units", {"value": [{"unit": "坨", "grams": 10}], **AI}, "计数单位“坨”没有登记"),
    ("count_units", {"value": [{"unit": "个", "grams": 0}], **AI}, "count_units"),
    ("purchase_units", {"value": [{"name": "盒", "grams": -5}], **AI}, "purchase_units"),
    ("nutrition", {"value": {"fat_g": -1}, **AI}, "nutrition"),
    ("functional", {"value": "是", **AI}, "functional"),
    ("density", {"value": 1.0, "status": "ai_draft"}, "有值却缺少来源"),
    ("density", {"value": 1.0, "source": "", "status": "ai_draft"}, "density.source"),
    ("density", {"value": 1.0, "source": "AI"}, "density.status"),
    ("density", {"value": 1.0, "source": "AI", "status": "checked"}, "density.status"),
    ("color", {"value": "红", **AI}, "color"),
]


@pytest.mark.parametrize(("field", "attr", "expected"), INVALID_CASES)
def test_invalid_attribute_rejects_whole_import(
    client: TestClient,
    tmp_path: Path,
    capsys: pytest.CaptureFixture[str],
    field: str,
    attr: dict,
    expected: str,
) -> None:
    """不合格的属性值让整次导入失败，错误里指出哪条、哪个字段，一条都不写。"""
    records = [
        _record(OTHER_ID, "测试好食材", "ceshihao", {"density": {"value": 1.0, **AI}}),
        _record(FULL_ID, "测试坏食材", "ceshihuai", {field: attr}),
    ]
    _write(tmp_path, "1.0.0", records)

    assert _import(tmp_path) == 1

    err = capsys.readouterr().err
    assert "第 2 条" in err
    assert "测试坏食材" in err
    assert f"attributes.{field}" in err
    assert expected in err
    assert client.get(f"/v1/ingredients/{OTHER_ID}").status_code == 404


def _two_records(attrs: dict[str, Any]) -> list[dict]:
    return [
        _record(FULL_ID, "测试酱油", "ceshijiangyou", attrs),
        _record(OTHER_ID, "测试盐", "ceshiyan", {"pantry_staple": {"value": True, **AI}}),
    ]


def _versions(client: TestClient) -> tuple[str, str]:
    a = client.get(f"/v1/ingredients/{FULL_ID}").json()["version"]
    b = client.get(f"/v1/ingredients/{OTHER_ID}").json()["version"]
    return a, b


def test_attribute_value_change_bumps_version(
    client: TestClient, tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    """只改了属性的食材，版本号变成新版本；没改的保持原版本。"""
    assert _import(_write(tmp_path / "v1", "1.0.0", _two_records(FULL_ATTRIBUTES))) == 0

    changed = copy.deepcopy(FULL_ATTRIBUTES)
    changed["density"]["value"] = 1.2
    capsys.readouterr()
    assert _import(_write(tmp_path / "v2", "1.1.0", _two_records(changed))) == 0

    assert "内容有变化 1 种" in capsys.readouterr().out
    assert _versions(client) == ("1.1.0", "1.0.0")
    assert _attributes(client, FULL_ID)["density"]["value"] == 1.2


def test_verification_change_bumps_version(client: TestClient, tmp_path: Path) -> None:
    """值没变、只是改成人工校对过，也算内容变化（估算标记跟着变）。"""
    assert _import(_write(tmp_path / "v1", "1.0.0", _two_records(FULL_ATTRIBUTES))) == 0

    changed = copy.deepcopy(FULL_ATTRIBUTES)
    changed["density"] = {"value": 1.15, "source": "人工称量", "status": "verified"}
    assert _import(_write(tmp_path / "v2", "1.1.0", _two_records(changed))) == 0

    assert _versions(client) == ("1.1.0", "1.0.0")
    assert _attributes(client, FULL_ID)["density"]["estimate"] is False


def test_removed_attribute_bumps_version(client: TestClient, tmp_path: Path) -> None:
    """数据文件里删掉的属性，读取时变回 null，版本号也更新。"""
    assert _import(_write(tmp_path / "v1", "1.0.0", _two_records(FULL_ATTRIBUTES))) == 0

    changed = copy.deepcopy(FULL_ATTRIBUTES)
    del changed["allergens"]
    assert _import(_write(tmp_path / "v2", "1.1.0", _two_records(changed))) == 0

    assert _versions(client) == ("1.1.0", "1.0.0")
    assert _attributes(client, FULL_ID)["allergens"] is None


def test_unchanged_attributes_keep_version(
    client: TestClient, tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    """属性没变（整数和小数写法不同也算没变）时，新版本导入不改版本号。"""
    assert _import(_write(tmp_path / "v1", "1.0.0", _two_records(FULL_ATTRIBUTES))) == 0

    same = copy.deepcopy(FULL_ATTRIBUTES)
    same["count_units"]["value"] = [{"unit": "片", "grams": 5.0}]
    capsys.readouterr()
    assert _import(_write(tmp_path / "v2", "1.1.0", _two_records(same))) == 0

    assert "内容有变化 0 种" in capsys.readouterr().out
    assert _versions(client) == ("1.0.0", "1.0.0")


def test_seed_library_imports_with_attributes(client: TestClient) -> None:
    """仓库里的正式种子数据能导入；带了属性的种子食材按估算返回。"""
    assert _import(SEED) == 0

    soy = _attributes(client, "06cf20af-aebb-4693-b673-e8f4b5a1845c")  # 生抽
    assert soy["flavor"]["value"]["salty"] == 3
    assert soy["flavor"]["estimate"] is True
    assert set(soy["allergens"]["value"]) == {"大豆", "含麸质的谷物"}
    assert soy["pantry_staple"]["value"] is True
