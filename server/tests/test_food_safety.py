"""Food safety acceptance through HTTP and the maintenance CLI only."""

import json
import os
import subprocess
import sys
import time
from pathlib import Path

import pytest
from celery.contrib.testing.worker import start_worker

from gramtree.cli import main as cli
from gramtree.tasks.celery_app import celery_app
from tests.accounts_support import Api, bearer

SERVER = Path(__file__).resolve().parents[1]
RULE_FILE = SERVER / "gramtree/recipes/data/food_safety_rules.json"


def dish(
    ingredient: str, instruction: str = "翻炒", *, title: str = "家常菜", seconds: int = 120
) -> dict:
    return {
        "dish_name": title,
        "snapshot": {
            "servings": 1,
            "ingredients": [
                {"id": "main", "display_name": ingredient, "quantity": 100, "unit": "g"}
            ],
            "steps": [
                {
                    "id": "cook",
                    "instruction": instruction,
                    "ingredient_ids": ["main"],
                    "duration_seconds": seconds,
                }
            ],
        },
    }


def checked(api: Api, body: dict) -> dict:
    headers = bearer(api.login("safety@example.com"))
    response = api.client.post("/v1/recipes/safety/check", json=body, headers=headers)
    assert response.status_code == 200, response.text
    return response.json()["result"]


def hits(result: dict) -> set[str]:
    return {finding["rule_id"] for finding in result["findings"]}


@pytest.mark.parametrize(
    ("ingredient", "instruction", "title", "tags", "rule", "severity"),
    [
        ("鸡肉", "炒 2 分钟", "炒鸡", [], "poultry-cook-through", "warning"),
        ("猪肉", "快炒", "炒肉", [], "pork-cook-through", "warning"),
        ("猪肉末", "炒到变色", "炒肉", [], "ground-pork-cook-through", "warning"),
        ("猪肝", "中心温度 63℃", "炒肝", [], "pork-offal-cook-through", "warning"),
        ("花蛤", "蒸开口", "蒸贝", [], "shellfish-cook", "warning"),
        ("虾", "用酒腌制", "醉虾", [], "raw-seafood", "warning"),
        ("鱼", "生腌", "生腌鱼", [], "raw-seafood", "warning"),
        ("鸡蛋", "混合蛋液不加热", "提拉米苏", [], "raw-egg", "info"),
        ("鸡蛋", "煮成溏心", "溏心蛋", [], "raw-egg", "info"),
        ("蜂蜜", "加入", "辅食", ["辅食"], "infant-honey", "warning"),
        ("生抽", "加入", "儿童菜", ["儿童"], "infant-salt", "warning"),
        ("盐", "加入", "辅食", ["辅食"], "infant-salt", "warning"),
        ("花生米", "加入", "儿童菜", ["儿童"], "toddler-whole-nuts", "warning"),
        ("野生菌", "煮熟", "野生菌", [], "high-risk-wild-mushroom", "high_risk"),
        ("河豚", "煮熟", "河豚", [], "high-risk-pufferfish", "high_risk"),
        ("四季豆", "炒 3 分钟", "炒豆", [], "beans-cook-through", "warning"),
        ("扁豆", "炒 3 分钟", "炒豆", [], "beans-cook-through", "warning"),
        ("鲜黄花菜", "焯水", "黄花菜", [], "fresh-daylily", "warning"),
        ("生豆浆", "假沸后继续煮", "豆浆", [], "soy-milk-boil", "warning"),
        ("发芽土豆", "削皮后炒", "炒土豆", [], "sprouted-potato", "high_risk"),
        ("土豆", "变青的土豆削皮", "炒土豆", [], "sprouted-potato", "high_risk"),
    ],
)
def test_rule_table(
    api: Api,
    ingredient: str,
    instruction: str,
    title: str,
    tags: list[str],
    rule: str,
    severity: str,
) -> None:
    body = dish(ingredient, instruction, title=title)
    body["snapshot"]["tags"] = tags
    result = checked(api, body)
    finding = next(finding for finding in result["findings"] if finding["rule_id"] == rule)
    assert finding["severity"] == severity
    assert finding["ingredient_ids"] == ["main"]
    assert finding["step_ids"] == ["cook"]
    assert finding["basis"] and finding["message"]
    assert result["high_risk"] is (severity == "high_risk")
    assert result["checked_at"] and result["rules_version"]
    assert result["can_save"] is True


@pytest.mark.parametrize(
    ("ingredient", "instruction", "rule"),
    [
        ("鸡肉", "切开确认中心无粉红、汁液清澈", "poultry-cook-through"),
        ("鸡肉", "测量中心温度达到 74°C", "poultry-cook-through"),
        ("猪肉", "确认熟透", "pork-cook-through"),
        ("猪肉末", "测量中心温度达到 71℃", "ground-pork-cook-through"),
        ("四季豆", "炒至彻底做熟", "beans-cook-through"),
        ("花蛤", "煮至开口，丢弃不开口的", "shellfish-cook"),
        ("鲜黄花菜", "焯水，再充分浸泡后弃水", "fresh-daylily"),
        ("生豆浆", "真正煮沸后继续煮", "soy-milk-boil"),
    ],
)
def test_local_satisfaction(api: Api, ingredient: str, instruction: str, rule: str) -> None:
    result = checked(api, dish(ingredient, instruction, seconds=300))
    assert rule not in hits(result)


@pytest.mark.parametrize(
    "instruction",
    [
        "烤箱温度 180℃",
        "中心温度 73℃",
        "不要确认中心无粉红",
        "中心无粉红不一定说明熟透",
        "未达到中心无粉红",
    ],
)
def test_ambient_low_temperature_and_negation_do_not_clear_warning(
    api: Api, instruction: str
) -> None:
    body = dish("鸡肉", instruction)
    body["snapshot"]["steps"][0]["temperature_celsius"] = 180
    assert "poultry-cook-through" in hits(checked(api, body))


@pytest.mark.parametrize(
    "instruction",
    [
        "将生豆浆加热至真正煮沸后继续煮",
        "将生豆浆真正煮沸后继续煮",
        "煮沸豆浆，真正煮沸后继续煮",
        "真正煮沸后继续煮，然后冷却",
    ],
)
def test_soymilk_timer_must_exclude_warmup(api: Api, instruction: str) -> None:
    combined = dish("生豆浆", instruction, seconds=300)
    assert "soy-milk-boil" in hits(checked(api, combined))
    dedicated = dish("生豆浆", "真正煮沸后继续煮", seconds=300)
    assert "soy-milk-boil" not in hits(checked(api, dedicated))


@pytest.mark.parametrize(
    ("instruction", "seconds", "safe"),
    [
        ("真正煮沸后继续煮至少5分钟", 300, True),
        ("真正煮沸后继续煮5分钟。", 300, True),
        ("真正煮沸后继续煮至少5分钟", 240, False),
    ],
)
def test_soymilk_explicit_duration_suffix(
    api: Api, instruction: str, seconds: int, safe: bool
) -> None:
    assert (
        "soy-milk-boil" not in hits(checked(api, dish("生豆浆", instruction, seconds=seconds)))
    ) is safe


def test_evidence_for_other_ingredient_cannot_clear_warning(api: Api) -> None:
    body = dish("鸡腿肉", "炒 2 分钟")
    body["snapshot"]["ingredients"].append(
        {"id": "other", "display_name": "鸡胸肉", "quantity": 100, "unit": "g"}
    )
    body["snapshot"]["steps"].append(
        {"id": "other-cook", "instruction": "中心温度 74℃", "ingredient_ids": ["other"]}
    )
    findings = checked(api, body)["findings"]
    poultry = [finding for finding in findings if finding["rule_id"] == "poultry-cook-through"]
    assert len(poultry) == 1
    assert poultry[0]["ingredient_ids"] == ["main"]
    assert poultry[0]["step_ids"] == ["cook"]


def test_unrelated_preprocessing_does_not_clear_daylily_warning(api: Api) -> None:
    body = dish("鲜黄花菜", "焯水")
    body["snapshot"]["ingredients"].append(
        {"id": "other", "display_name": "木耳", "quantity": 10, "unit": "g"}
    )
    body["snapshot"]["steps"].append(
        {"id": "soak", "instruction": "充分浸泡", "ingredient_ids": ["other"]}
    )
    assert "fresh-daylily" in hits(checked(api, body))
    body["snapshot"]["steps"][1]["ingredient_ids"] = ["main"]
    assert "fresh-daylily" not in hits(checked(api, body))


def test_risky_mode_in_description_triggers_warning(api: Api) -> None:
    body = dish("土豆", "削皮后炒")
    body["snapshot"]["description"] = "使用发芽土豆"
    assert "sprouted-potato" in hits(checked(api, body))


def test_adult_honey_and_fully_cooked_eggs_are_not_infant_or_poultry(api: Api) -> None:
    assert "infant-honey" not in hits(checked(api, dish("蜂蜜", "加入")))
    egg_hits = hits(checked(api, dish("鸡蛋", "完全煮熟")))
    assert "poultry-cook-through" not in egg_hits
    assert "raw-egg" not in egg_hits


def test_allergens_standard_name_and_replacement_attribution(api: Api) -> None:
    assert cli(["ingredients", "import", str(SERVER / "data/ingredients")]) == 0
    body = dish("作者的自定义酱料", "加入")
    item = body["snapshot"]["ingredients"][0]
    item["ingredient_id"] = "06cf20af-aebb-4693-b673-e8f4b5a1845c"
    item["replacement"] = {
        "ingredient_id": "551cfc70-006c-44b5-9168-0b972108a49e",
        "display_name": "磨碎花生",
    }
    result = checked(api, body)
    assert {"大豆", "含麸质的谷物", "花生"} <= set(result["allergens"])
    assert result["allergens_incomplete"] is False
    assert result["replacement_allergens"] == [
        {
            "ingredient_id": "main",
            "display_name": "磨碎花生",
            "allergens": ["花生"],
            "incomplete": False,
        }
    ]
    item["replacement"] = "自制未知酱"
    result = checked(api, body)
    assert result["allergens_incomplete"] is True
    assert result["replacement_allergens"][0]["incomplete"] is True
    assert "花生" not in result["allergens"]
    # Standard names, not author display names, trigger the infant salt rule.
    body["snapshot"]["tags"] = ["辅食"]
    assert "infant-salt" in hits(checked(api, body))


def test_library_category_can_trigger_despite_obscured_names(api: Api, tmp_path: Path) -> None:
    library = tmp_path / "ingredients"
    library.mkdir()
    (library / "manifest.json").write_text(
        json.dumps({"version": "1.0.0", "changelog": "category fixture"}), encoding="utf-8"
    )
    (library / "data.json").write_text(
        json.dumps(
            [
                {
                    "id": "00000000-0000-4000-8000-000000000111",
                    "standard_name": "海产测试甲",
                    "aliases": [],
                    "pinyin": "haichanceshijia",
                    "pinyin_initials": "hccsj",
                    "category": "水产",
                }
            ]
        ),
        encoding="utf-8",
    )
    assert cli(["ingredients", "import", str(library)]) == 0
    body = dish("自定义名称", "生食")
    body["snapshot"]["ingredients"][0]["ingredient_id"] = "00000000-0000-4000-8000-000000000111"
    assert "raw-seafood" in hits(checked(api, body))


@pytest.mark.parametrize(
    "field",
    [
        "dish_name",
        "dish_aliases",
        "change_note",
        "description",
        "step_instruction",
        "step_doneness",
        "step_notes",
        "step_why",
        "ingredient_preparation",
        "replacement_note",
        "source_basis",
        "tag",
    ],
)
def test_claims_in_all_description_fields_block_save(api: Api, field: str) -> None:
    body = dish("土豆", "煮熟")
    snapshot = body["snapshot"]
    if field == "description":
        snapshot["description"] = "降血糖"
    elif field.startswith("step_"):
        snapshot["steps"][0][field[5:]] = "降血糖"
    elif field == "ingredient_preparation":
        snapshot["ingredients"][0]["preparation"] = "降血糖"
    elif field == "replacement_note":
        snapshot["ingredients"][0]["replacement"] = {"display_name": "红薯", "note": "降血糖"}
    elif field == "source_basis":
        snapshot["steps"][0]["duration_source"] = {"source": "author_filled", "basis": "降血糖"}
    elif field == "tag":
        snapshot["tags"] = ["降血糖"]
    elif field == "dish_aliases":
        body[field] = ["降血糖"]
    else:
        body[field] = "降血糖"
    result = checked(api, body)
    assert result["can_save"] is False
    assert "降血糖" in result["prohibited_claims"]
    headers = bearer(api.login("blocked@example.com"))
    response = api.client.post("/v1/recipes", json=body, headers=headers)
    assert response.status_code == 422, response.text
    assert response.json()["error"]["code"] == "prohibited_health_claim"
    assert api.client.get("/v1/recipes", headers=headers).json()["items"] == []


def test_method_tags_and_nutrition_estimates_remain_allowed(api: Api) -> None:
    headers = bearer(api.login("method@example.com"))
    body = dish("土豆", "煮熟")
    body["snapshot"]["tags"] = ["减脂", "控糖", "低脂"]
    response = api.client.post("/v1/recipes", json=body, headers=headers)
    assert response.status_code == 201, response.text
    version = response.json()["version"]
    assert version["safety"]["can_save"] is True
    assert version["derived"]["nutrition_per_serving"]["estimated"] is True


def test_version_save_rechecks_shortened_cooking_and_preserves_original(api: Api) -> None:
    headers = bearer(api.login("versions@example.com"))
    body = dish("生豆浆", "真正煮沸后继续煮", seconds=300)
    response = api.client.post("/v1/recipes", json=body, headers=headers)
    assert response.status_code == 201, response.text
    initial = response.json()
    assert "soy-milk-boil" not in hits(initial["version"]["safety"])
    assert initial["version"]["safety_at_save"] == initial["version"]["safety"]
    body["snapshot"]["steps"][0]["duration_seconds"] = 120
    saved = api.client.post(f"/v1/recipes/{initial['id']}/versions", json=body, headers=headers)
    assert saved.status_code == 201, saved.text
    assert "soy-milk-boil" in hits(saved.json()["version"]["safety"])
    old = api.client.get(
        f"/v1/recipes/{initial['id']}/versions/{initial['version']['id']}", headers=headers
    ).json()
    assert old["version"] == initial["version"]
    body["change_note"] = "治疗"
    rejected = api.client.post(f"/v1/recipes/{initial['id']}/versions", json=body, headers=headers)
    assert rejected.status_code == 422
    history = api.client.get(f"/v1/recipes/{initial['id']}/versions", headers=headers).json()
    assert len(history["items"]) == 2


def command(*args: str, expected: int = 0) -> dict:
    result = subprocess.run(
        [sys.executable, "-m", "gramtree.cli", "recipes", *args],
        cwd=SERVER,
        capture_output=True,
        text=True,
        encoding="utf-8",
        env={**os.environ, "PYTHONIOENCODING": "utf-8"},
        check=False,
    )
    assert result.returncode == expected, result.stderr + result.stdout
    return json.loads(result.stdout)


@pytest.fixture
def deployed_policy(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    path = tmp_path / "safety.json"
    path.write_text(RULE_FILE.read_text(encoding="utf-8"), encoding="utf-8")
    monkeypatch.setenv("GRAMTREE_FOOD_SAFETY_RULES_PATH", str(path))
    return path


def update_policy(path: Path) -> None:
    data = json.loads(path.read_text(encoding="utf-8"))
    data["version"] = "2026.10.2"
    data["prohibited_claims"]["version"] = "2026.10.2"
    for rule in data["rules"]:
        if rule["id"] == "soy-milk-boil":
            rule["satisfied_by"][0]["all"][1]["minimum"] = 360
            rule["message"] = "测试新规则：真正煮沸后继续煮至少 6 分钟"
    path.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")


def saved_soymilk(api: Api) -> tuple[dict, dict[str, str]]:
    headers = bearer(api.login("recheck@example.com"))
    response = api.client.post(
        "/v1/recipes", json=dish("生豆浆", "真正煮沸后继续煮", seconds=300), headers=headers
    )
    assert response.status_code == 201, response.text
    return response.json(), headers


def test_rules_update_idempotent_and_immutable_original(api: Api, deployed_policy: Path) -> None:
    original, headers = saved_soymilk(api)
    update_policy(deployed_policy)
    assert command("safety-validate")["rules_version"] == "2026.10.2"
    result = command("safety-recheck")
    assert result["checked"] == 1 and result["failed"] == 0 and result["remaining"] == 0
    current = api.client.get(f"/v1/recipes/{original['id']}", headers=headers).json()["version"]
    assert current["safety"]["rules_version"] == "2026.10.2"
    assert "soy-milk-boil" in hits(current["safety"])
    assert current["safety_at_save"] == original["version"]["safety_at_save"]
    assert current["snapshot"] == original["version"]["snapshot"]
    assert command("safety-recheck")["checked"] == 0
    status = command("safety-status")
    assert status["counts"] == {"success": 1}
    assert len(status["jobs"]) == 1 and status["jobs"][0]["attempts"] == 1


def test_failed_recheck_retains_old_index_and_recovers_expired_lease(
    api: Api, deployed_policy: Path
) -> None:
    original, headers = saved_soymilk(api)
    update_policy(deployed_policy)
    assert command("safety-recheck", "--limit", "0")["queued"] == 1
    job = command("safety-status")["jobs"][0]
    command("seed-safety-retry", job["id"], "invalid-snapshot")
    result = command("safety-recheck", expected=1)
    assert result["failed"] == 1 and result["checked"] == 0
    status = command("safety-status")
    assert status["counts"] == {"retry": 1}
    assert status["jobs"][0]["last_error"] == "ValidationError"
    assert status["jobs"][0]["attempts"] == 1
    command("seed-safety-retry", job["id"], "repair-snapshot")
    before = api.client.get(f"/v1/recipes/{original['id']}", headers=headers).json()["version"]
    assert before["safety"] == {**original["version"]["safety"], "stale": True}
    assert before["safety_at_save"] == original["version"]["safety_at_save"]
    command("seed-safety-retry", job["id"], "expired-lease")
    recovered = command("safety-recheck")
    assert recovered["checked"] == 1 and recovered["failed"] == 0
    assert command("safety-status")["jobs"][0]["attempts"] == 2


def test_recheck_replays_saved_alias_claim_text(api: Api, deployed_policy: Path) -> None:
    headers = bearer(api.login("alias-recheck@example.com"))
    body = dish("生豆浆", "真正煮沸后继续煮", seconds=300)
    body["dish_aliases"] = ["神奇豆浆"]
    response = api.client.post("/v1/recipes", json=body, headers=headers)
    assert response.status_code == 201, response.text
    policy = json.loads(deployed_policy.read_text(encoding="utf-8"))
    policy["version"] = "2026.10.2"
    policy["prohibited_claims"]["version"] = "2026.10.2"
    policy["prohibited_claims"]["terms"].append("神奇")
    deployed_policy.write_text(json.dumps(policy, ensure_ascii=False), encoding="utf-8")
    result = command("safety-recheck")
    assert result["checked"] == 1 and result["failed"] == 0
    current = api.client.get(f"/v1/recipes/{response.json()['id']}", headers=headers).json()[
        "version"
    ]
    assert current["safety"]["prohibited_claims"] == ["神奇"]
    assert current["safety"]["can_save"] is False
    assert current["safety_at_save"] == response.json()["version"]["safety_at_save"]
    assert current["snapshot"] == response.json()["version"]["snapshot"]


def test_changed_content_requires_new_rule_version(api: Api, deployed_policy: Path) -> None:
    saved_soymilk(api)
    data = json.loads(deployed_policy.read_text(encoding="utf-8"))
    data["rules"][0]["message"] = "changed without version bump"
    deployed_policy.write_text(json.dumps(data), encoding="utf-8")
    response = subprocess.run(
        [sys.executable, "-m", "gramtree.cli", "recipes", "safety-recheck"],
        cwd=SERVER,
        capture_output=True,
        text=True,
        env={**os.environ, "PYTHONIOENCODING": "utf-8"},
    )
    assert response.returncode == 1
    assert command("safety-status")["jobs"] == []


def test_real_celery_rechecks_a_deployed_rules_update(api: Api, deployed_policy: Path) -> None:
    original, headers = saved_soymilk(api)
    update_policy(deployed_policy)
    with start_worker(celery_app, perform_ping_check=False, loglevel="WARNING"):
        submitted = command("safety-recheck", "--enqueue")
        assert submitted["task_id"]
        deadline = time.monotonic() + 30
        status = command("safety-status")
        while status["counts"] != {"success": 1} and time.monotonic() < deadline:
            time.sleep(0.2)
            status = command("safety-status")
        assert status["counts"] == {"success": 1}, status
    version = api.client.get(f"/v1/recipes/{original['id']}", headers=headers).json()["version"]
    assert version["safety"]["rules_version"] == "2026.10.2"
    assert version["safety_at_save"]["rules_version"] == "2026.10.1"
