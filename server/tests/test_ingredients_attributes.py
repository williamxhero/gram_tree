"""测试食材详细属性（票 #97）。

按 TDD 流程：先写失败的测试，再实现让它通过。测试只通过 CLI 导入 + HTTP 接口读取，
不直接访问数据库（遵守"只测外部行为"原则）。
"""

import json
import uuid
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from gramtree.ingredients.importer import import_directory


@pytest.fixture
def test_data_dir(tmp_path: Path) -> Path:
    """创建临时测试数据目录。"""
    return tmp_path / "test_ingredients"


def test_flavor_profiles_import_and_read(test_data_dir: Path, engine, client):
    """味型贡献：七项（咸甜酸辣鲜麻油），每项 0～3 强度，带来源和校对状态。"""
    test_data_dir.mkdir()
    ingredient_id = str(uuid.uuid4())

    # 数据文件包含完整味型信息
    (test_data_dir / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "测试味型"}), encoding="utf-8"
    )
    (test_data_dir / "test.json").write_text(
        json.dumps([
            {
                "id": ingredient_id,
                "standard_name": "生抽",
                "pinyin": "shengchou",
                "pinyin_initials": "sc",
                "category": "调料",
                "flavor_profiles": {
                    "salty": {"strength": 3, "source": "manual", "verified": True},
                    "sweet": {"strength": 0, "source": "manual", "verified": True},
                    "sour": {"strength": 0, "source": "manual", "verified": True},
                    "spicy": {"strength": 0, "source": "manual", "verified": True},
                    "umami": {"strength": 2, "source": "manual", "verified": True},
                    "numbing": {"strength": 0, "source": "manual", "verified": True},
                    "oily": {"strength": 0, "source": "manual", "verified": True}
                }
            }
        ]), encoding="utf-8"
    )

    # 导入
    with Session(engine) as db_session:
        result = import_directory(db_session, test_data_dir)
        assert result["added"] == 1

    # HTTP 读取
    response = client.get(f"/v1/ingredients/{ingredient_id}")
    assert response.status_code == 200
    data = response.json()

    # 验证味型数据
    assert "flavor_profiles" in data
    flavors = data["flavor_profiles"]
    assert flavors["salty"]["strength"] == 3
    assert flavors["salty"]["verified"] is True
    assert flavors["umami"]["strength"] == 2
    assert flavors["sweet"]["strength"] == 0


def test_flavor_strength_validation(test_data_dir: Path, engine):
    """味型强度只能 0～3，超出范围时导入失败。"""
    test_data_dir.mkdir()
    ingredient_id = str(uuid.uuid4())

    (test_data_dir / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "测试"}), encoding="utf-8"
    )
    (test_data_dir / "test.json").write_text(
        json.dumps([
            {
                "id": ingredient_id,
                "standard_name": "测试",
                "pinyin": "test",
                "pinyin_initials": "t",
                "category": "其他",
                "flavor_profiles": {
                    "salty": {"strength": 5, "source": "manual", "verified": False}  # 非法强度
                }
            }
        ]), encoding="utf-8"
    )

    # 导入应该失败
    from gramtree.ingredients.importer import IngredientImportError
    with Session(engine) as db_session:
        with pytest.raises(IngredientImportError, match="strength"):
            import_directory(db_session, test_data_dir)


def test_functional_ingredient_and_scaling(test_data_dir: Path, engine, client):
    """功能性食材标记和默认缩放方式（linear/fixed/stepped）。"""
    test_data_dir.mkdir()
    ingredient_id = str(uuid.uuid4())

    (test_data_dir / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "测试功能性食材"}), encoding="utf-8"
    )
    (test_data_dir / "test.json").write_text(
        json.dumps([
            {
                "id": ingredient_id,
                "standard_name": "盐",
                "pinyin": "yan",
                "pinyin_initials": "y",
                "category": "调料",
                "is_functional": {"value": True, "source": "manual", "verified": True},
                "default_scaling": {"value": "fixed", "source": "manual", "verified": True}
            }
        ]), encoding="utf-8"
    )

    with Session(engine) as db_session:
        result = import_directory(db_session, test_data_dir)
        assert result["added"] == 1

    response = client.get(f"/v1/ingredients/{ingredient_id}")
    assert response.status_code == 200
    data = response.json()

    assert data["is_functional"]["value"] is True
    assert data["is_functional"]["verified"] is True
    assert data["default_scaling"]["value"] == "fixed"
    assert data["default_scaling"]["verified"] is True


def test_scaling_method_validation(test_data_dir: Path, engine):
    """缩放方式只能是 linear/fixed/stepped 之一。"""
    test_data_dir.mkdir()
    ingredient_id = str(uuid.uuid4())

    (test_data_dir / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "测试"}), encoding="utf-8"
    )
    (test_data_dir / "test.json").write_text(
        json.dumps([
            {
                "id": ingredient_id,
                "standard_name": "测试",
                "pinyin": "test",
                "pinyin_initials": "t",
                "category": "其他",
                "default_scaling": {"value": "invalid_method", "source": "manual", "verified": False}
            }
        ]), encoding="utf-8"
    )

    from gramtree.ingredients.importer import IngredientImportError
    with Session(engine) as db_session:
        with pytest.raises(IngredientImportError, match="scaling"):
            import_directory(db_session, test_data_dir)


def test_unit_conversions(test_data_dir: Path, engine, client):
    """单位换算：密度（g/ml）、个体重量（g）、计数单位（个/瓣/根/片）。"""
    test_data_dir.mkdir()
    ingredient_id = str(uuid.uuid4())

    (test_data_dir / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "测试单位换算"}), encoding="utf-8"
    )
    (test_data_dir / "test.json").write_text(
        json.dumps([
            {
                "id": ingredient_id,
                "standard_name": "鸡蛋",
                "pinyin": "jidan",
                "pinyin_initials": "jd",
                "category": "蛋奶",
                "density_g_ml": {"value": 1.03, "source": "manual", "verified": True},
                "individual_weight_g": {"value": 50.0, "source": "manual", "verified": True},
                "counting_units": [
                    {"unit": "个", "count": 1, "source": "manual", "verified": True},
                    {"unit": "打", "count": 12, "source": "manual", "verified": True}
                ]
            }
        ]), encoding="utf-8"
    )

    with Session(engine) as db_session:
        result = import_directory(db_session, test_data_dir)
        assert result["added"] == 1

    response = client.get(f"/v1/ingredients/{ingredient_id}")
    assert response.status_code == 200
    data = response.json()

    assert data["density_g_ml"]["value"] == 1.03
    assert data["individual_weight_g"]["value"] == 50.0
    assert len(data["counting_units"]) == 2
    units_by_name = {cu["unit"]: cu for cu in data["counting_units"]}
    assert units_by_name["个"]["count"] == 1
    assert units_by_name["打"]["count"] == 12


def test_allergens(test_data_dir: Path, engine, client):
    """过敏原：GB 7718 八类，可多选。"""
    test_data_dir.mkdir()
    ingredient_id = str(uuid.uuid4())

    (test_data_dir / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "测试过敏原"}), encoding="utf-8"
    )
    (test_data_dir / "test.json").write_text(
        json.dumps([
            {
                "id": ingredient_id,
                "standard_name": "花生酱",
                "pinyin": "huashengjiang",
                "pinyin_initials": "hsj",
                "category": "调料",
                "allergens": [
                    {"allergen_class": "peanuts", "source": "manual", "verified": True},
                    {"allergen_class": "tree_nuts", "source": "ai_estimate", "verified": False}
                ]
            }
        ]), encoding="utf-8"
    )

    with Session(engine) as db_session:
        result = import_directory(db_session, test_data_dir)
        assert result["added"] == 1

    response = client.get(f"/v1/ingredients/{ingredient_id}")
    assert response.status_code == 200
    data = response.json()

    assert len(data["allergens"]) == 2
    allergen_classes = {a["allergen_class"]: a for a in data["allergens"]}
    assert allergen_classes["peanuts"]["verified"] is True
    assert allergen_classes["tree_nuts"]["verified"] is False


def test_allergen_class_validation(test_data_dir: Path, engine):
    """过敏原类别必须是 GB 7718 登记的八类之一。"""
    test_data_dir.mkdir()
    ingredient_id = str(uuid.uuid4())

    (test_data_dir / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "测试"}), encoding="utf-8"
    )
    (test_data_dir / "test.json").write_text(
        json.dumps([
            {
                "id": ingredient_id,
                "standard_name": "测试",
                "pinyin": "test",
                "pinyin_initials": "t",
                "category": "其他",
                "allergens": [
                    {"allergen_class": "invalid_allergen", "source": "manual", "verified": False}
                ]
            }
        ]), encoding="utf-8"
    )

    from gramtree.ingredients.importer import IngredientImportError
    with Session(engine) as db_session:
        with pytest.raises(IngredientImportError, match="allergen_class"):
            import_directory(db_session, test_data_dir)


def test_nutrition_per_100g(test_data_dir: Path, engine, client):
    """营养成分：每 100g 的能量、蛋白质、脂肪、碳水、钠。"""
    test_data_dir.mkdir()
    ingredient_id = str(uuid.uuid4())

    (test_data_dir / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "测试营养成分"}), encoding="utf-8"
    )
    (test_data_dir / "test.json").write_text(
        json.dumps([
            {
                "id": ingredient_id,
                "standard_name": "鸡胸肉",
                "pinyin": "jixiongrou",
                "pinyin_initials": "jxr",
                "category": "肉禽",
                "nutrition_per_100g": {
                    "energy_kj": {"value": 490.0, "source": "manual", "verified": True},
                    "protein_g": {"value": 23.3, "source": "manual", "verified": True},
                    "fat_g": {"value": 1.2, "source": "manual", "verified": True},
                    "carbohydrate_g": {"value": 0.0, "source": "manual", "verified": True},
                    "sodium_mg": {"value": 65.0, "source": "ai_estimate", "verified": False}
                }
            }
        ]), encoding="utf-8"
    )

    with Session(engine) as db_session:
        result = import_directory(db_session, test_data_dir)
        assert result["added"] == 1

    response = client.get(f"/v1/ingredients/{ingredient_id}")
    assert response.status_code == 200
    data = response.json()

    nutrition = data["nutrition_per_100g"]
    assert nutrition["energy_kj"]["value"] == 490.0
    assert nutrition["protein_g"]["value"] == 23.3
    assert nutrition["sodium_mg"]["verified"] is False  # AI 估算未校对


def test_purchase_units_and_storage(test_data_dir: Path, engine, client):
    """购买单位（袋/盒/瓶）、存储方式（常温/冷藏/冷冻）、常备调料标记。"""
    test_data_dir.mkdir()
    ingredient_id = str(uuid.uuid4())

    (test_data_dir / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "测试购买和存储"}), encoding="utf-8"
    )
    (test_data_dir / "test.json").write_text(
        json.dumps([
            {
                "id": ingredient_id,
                "standard_name": "牛奶",
                "pinyin": "niunai",
                "pinyin_initials": "nn",
                "category": "蛋奶",
                "is_staple_condiment": {"value": False, "source": "manual", "verified": True},
                "supermarket_zone": {"value": "冷藏柜", "source": "manual", "verified": True},
                "purchase_units": [
                    {"unit": "盒", "approx_weight_g": 250.0, "source": "manual", "verified": True},
                    {"unit": "瓶", "approx_weight_g": 1000.0, "source": "manual", "verified": True}
                ],
                "storage": [
                    {"method": "refrigerated", "days": 7, "source": "manual", "verified": True}
                ]
            }
        ]), encoding="utf-8"
    )

    with Session(engine) as db_session:
        result = import_directory(db_session, test_data_dir)
        assert result["added"] == 1

    response = client.get(f"/v1/ingredients/{ingredient_id}")
    assert response.status_code == 200
    data = response.json()

    assert data["is_staple_condiment"]["value"] is False
    assert data["supermarket_zone"]["value"] == "冷藏柜"
    assert len(data["purchase_units"]) == 2
    assert len(data["storage"]) == 1
    assert data["storage"][0]["method"] == "refrigerated"
    assert data["storage"][0]["days"] == 7


def test_storage_method_validation(test_data_dir: Path, engine):
    """存储方式只能是 room_temp/refrigerated/frozen 之一。"""
    test_data_dir.mkdir()
    ingredient_id = str(uuid.uuid4())

    (test_data_dir / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "测试"}), encoding="utf-8"
    )
    (test_data_dir / "test.json").write_text(
        json.dumps([
            {
                "id": ingredient_id,
                "standard_name": "测试",
                "pinyin": "test",
                "pinyin_initials": "t",
                "category": "其他",
                "storage": [
                    {"method": "invalid_storage", "days": 7, "source": "manual", "verified": False}
                ]
            }
        ]), encoding="utf-8"
    )

    from gramtree.ingredients.importer import IngredientImportError
    with Session(engine) as db_session:
        with pytest.raises(IngredientImportError, match="method"):
            import_directory(db_session, test_data_dir)


def test_version_change_on_attribute_modification(test_data_dir: Path, engine):
    """属性变化时更新食材版本号。"""
    test_data_dir.mkdir()
    ingredient_id = str(uuid.uuid4())

    # 版本 1.0.0：初始数据
    (test_data_dir / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "初始版本"}), encoding="utf-8"
    )
    (test_data_dir / "test.json").write_text(
        json.dumps([
            {
                "id": ingredient_id,
                "standard_name": "测试食材",
                "pinyin": "test",
                "pinyin_initials": "t",
                "category": "其他",
                "is_functional": {"value": False, "source": "manual", "verified": True}
            }
        ]), encoding="utf-8"
    )

    with Session(engine) as db_session:
        import_directory(db_session, test_data_dir)

    # 版本 1.1.0：修改属性
    (test_data_dir / "manifest.json").write_text(
        json.dumps({"version": "1.1.0", "changelog": "更新功能性标记"}), encoding="utf-8"
    )
    (test_data_dir / "test.json").write_text(
        json.dumps([
            {
                "id": ingredient_id,
                "standard_name": "测试食材",
                "pinyin": "test",
                "pinyin_initials": "t",
                "category": "其他",
                "is_functional": {"value": True, "source": "manual", "verified": True}  # 改了
            }
        ]), encoding="utf-8"
    )

    with Session(engine) as db_session:
        result = import_directory(db_session, test_data_dir)
        assert result["changed"] == 1
