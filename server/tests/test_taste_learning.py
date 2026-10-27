"""SPEC-005.3 口味学习与归因：只通过对外 HTTP 接口验证外部行为。

覆盖 #233/#234 归因、#236 学习、#239 变更控制、#241 分菜系局部偏好、
#242 食材建议、#243 存进我的口味、#244 做过后太咸了。
"""

from datetime import UTC, datetime, timedelta

from tests.accounts_support import Api, bearer, new_uuid
from tests.test_sync_writes import envelope, submit


def record_payload(owner: str, **overrides: object) -> dict:
    value = {
        "client_id": new_uuid(),
        "dish_name": "测试宫保鸡丁",
        "source": "external_cooking",
        "verification": "unverified",
        "source_context": {"entry": "manual"},
    }
    value.update(overrides)
    return value


def create(api: Api, tokens: dict, **overrides: object) -> dict:
    response = api.client.post(
        "/v1/records",
        headers=bearer(tokens),
        json=record_payload(tokens["user"]["id"], **overrides),
    )
    assert response.status_code == 201, response.text
    return response.json()


def feedback(api: Api, tokens: dict, record: dict, value: dict) -> dict:
    response = api.client.post(
        f"/v1/records/{record['id']}/revisions",
        headers=bearer(tokens),
        json={"revision_id": new_uuid(), "field": "feedback", "value": value},
    )
    assert response.status_code == 201, response.text
    return response.json()


def run_learning(api: Api, tokens: dict) -> dict:
    response = api.client.post("/v1/me/taste-profile/learning/run", headers=bearer(tokens))
    assert response.status_code == 200, response.text
    return response.json()


def salty(api: Api, tokens: dict) -> float:
    response = api.client.get("/v1/me/taste-profile", headers=bearer(tokens))
    assert response.status_code == 200, response.text
    return response.json()["flavors"]["salty"]["coefficient"]


def test_attribution_asks_then_strong_personal_learning_stays_small_and_idempotent(
    api: Api,
) -> None:
    tokens = api.login("taste-learning-a@example.com")
    record = create(api, tokens)
    feedback(api, tokens, record, {"text": "有点咸", "taste_tags": ["偏咸"]})

    state = api.client.get(f"/v1/records/{record['id']}/attribution", headers=bearer(tokens))
    assert state.status_code == 200
    attribution = state.json()["attribution"]
    assert attribution["verdict"] == "pending"
    assert attribution["asked"] is True
    assert attribution["learning_eligibility"] == "reduced"

    answered = api.client.put(
        f"/v1/records/{record['id']}/attribution",
        headers=bearer(tokens),
        json={"answer": "personal"},
    )
    assert answered.status_code == 200, answered.text
    assert answered.json()["attribution"]["learning_eligibility"] == "strong"
    assert "口味" in answered.json()["reason_text"]

    baseline = salty(api, tokens)
    first = run_learning(api, tokens)
    applied = [row for row in first["applied_changes"] if row["field"] == "flavors.salty"]
    assert len(applied) == 1
    after = applied[0]["new_value"]["coefficient"]
    assert after < baseline
    assert baseline - after <= 0.05 + 1e-9, "一次反馈不得让系数变化超过一个步长"
    assert applied[0]["origin"] == "auto"

    replay = run_learning(api, tokens)
    assert replay["applied_changes"] == [], "同一条记录重复学习不得再次改档案"
    assert salty(api, tokens) == after


def test_repeated_manual_reductions_accumulate_and_rating_weighs_less(api: Api) -> None:
    tokens = api.login("taste-learning-b@example.com")
    for _ in range(4):
        record = create(
            api,
            tokens,
            adjustments=[{"flavor": "spicy", "delta": -1}],
        )
        assert record["adjustments"]
    baseline = api.client.get("/v1/me/taste-profile", headers=bearer(tokens)).json()["flavors"][
        "spicy"
    ]["coefficient"]
    outcome = run_learning(api, tokens)
    spicy = [row for row in outcome["applied_changes"] if row["field"] == "flavors.spicy"]
    assert spicy, "连续四次同向手动改动必须让档案明显变化"
    assert spicy[0]["new_value"]["coefficient"] < baseline

    other = api.login("taste-learning-c@example.com")
    for _ in range(4):
        record = create(api, other)
        feedback(api, other, record, {"taste_tags": ["太辣"]})
    tag_outcome = run_learning(api, other)
    assert tag_outcome["applied_changes"], "同向四次反馈也要能学到"
    manual_delta = spicy[0]["new_value"]["coefficient"]
    tag_delta = next(
        row for row in tag_outcome["applied_changes"] if row["field"] == "flavors.spicy"
    )["new_value"]["coefficient"]
    assert manual_delta - 1.0 < tag_delta - 1.0, "手动改用量应比反馈标签影响更大"


def test_old_signal_decays_and_allergies_never_learned(api: Api) -> None:
    tokens = api.login("taste-learning-d@example.com")
    old_observation = (datetime.now(UTC) - timedelta(days=90)).isoformat()
    record = create(
        api,
        tokens,
        occurred_at=old_observation,
        adjustments=[{"flavor": "salty", "delta": -1}],
    )
    assert record
    outcome = run_learning(api, tokens)
    assert outcome["applied_changes"], "半衰期后的旧信号仍按衰减权重学习"
    delta = 1.0 - outcome["applied_changes"][0]["new_value"]["coefficient"]
    assert 0.02 <= delta <= 0.03, "90 天后的有效权重应约为新信号的一半"

    allergies = api.client.get("/v1/me/taste-profile/allergies", headers=bearer(tokens))
    assert allergies.status_code == 200
    assert allergies.json()["categories"] == []
    assert allergies.json()["ingredients"] == [], "行为绝不产生过敏设置"


def test_local_cuisine_preference_stays_local_but_adds_overall_evidence(api: Api) -> None:
    tokens = api.login("taste-learning-e@example.com")
    for _ in range(4):
        create(
            api,
            tokens,
            adjustments=[{"flavor": "spicy", "delta": 1, "scope": "川菜"}],
        )
    overall_before = salty(api, tokens)
    profile_before = api.client.get("/v1/me/taste-profile", headers=bearer(tokens)).json()
    assert profile_before["local_cuisines"] == []
    outcome = run_learning(api, tokens)
    local = [
        row for row in outcome["applied_changes"] if row["field"].startswith("local_cuisines.")
    ]
    assert local, "带菜系标签的信号必须产生局部偏好"
    assert local[0]["new_value"]["cuisine"] == "川菜"
    profile_after = api.client.get("/v1/me/taste-profile", headers=bearer(tokens)).json()
    assert profile_after["local_cuisines"][0]["cuisine"] == "川菜"
    assert salty(api, tokens) == overall_before, "局部信号不得改总体数值"


def test_repeated_ingredient_removal_only_suggests_until_confirmed(api: Api) -> None:
    tokens = api.login("taste-learning-f@example.com")
    snapshot = {
        "format_version": 1,
        "dish_name": "测试香菜牛肉",
        "ingredients": [{"display_name": "香菜", "disposition": "deleted", "category": "蔬菜"}],
    }
    for _ in range(2):
        create(api, tokens, snapshot=snapshot, adjustments=[{"text": "去掉香菜"}])
    outcome = run_learning(api, tokens)
    pending = outcome["pending_suggestions"]
    assert pending, "多次去掉同一食材必须生成待确认建议"
    assert pending[0]["status"] == "pending"
    before = api.client.get("/v1/me/taste-profile", headers=bearer(tokens)).json()
    assert before["ingredient_preferences"] in ([], None), "确认前不得改变实际偏好"

    confirmed = api.client.post(
        f"/v1/me/taste-profile/changes/{pending[0]['id']}/confirm", headers=bearer(tokens)
    )
    assert confirmed.status_code == 200, confirmed.text
    assert confirmed.json()["status"] == "confirmed"
    after = api.client.get("/v1/me/taste-profile", headers=bearer(tokens)).json()
    assert after["ingredient_preferences"], "确认后才写入不喜欢偏好"

    retry = api.client.post(
        f"/v1/me/taste-profile/changes/{pending[0]['id']}/confirm", headers=bearer(tokens)
    )
    assert retry.status_code == 200
    assert retry.json()["status"] == "confirmed"


def test_same_version_majority_blames_recipe_and_keeps_profile_untouched(api: Api) -> None:
    author = api.login("taste-learning-g@example.com")
    versionless = create(api, author)
    assert versionless
    owner = api.login("taste-learning-h@example.com")
    record = create(api, owner)
    feedback(api, owner, record, {"taste_tags": ["偏咸"]})
    state = api.client.get(f"/v1/records/{record['id']}/attribution", headers=bearer(owner)).json()[
        "attribution"
    ]
    assert state["verdict"] == "pending", "没有同版本他人样本时必须走询问"

    answered = api.client.put(
        f"/v1/records/{record['id']}/attribution",
        headers=bearer(owner),
        json={"answer": "recipe"},
    )
    assert answered.status_code == 200
    attribution = answered.json()["attribution"]
    assert attribution["verdict"] == "recipe"
    assert attribution["learning_eligibility"] == "excluded"
    baseline = salty(api, owner)
    outcome = run_learning(api, owner)
    assert outcome["applied_changes"] == [], "判为菜谱问题不得改档案"
    assert salty(api, owner) == baseline


def test_revert_restores_value_and_blocks_relearning_then_lock_freezes_field(api: Api) -> None:
    tokens = api.login("taste-learning-i@example.com")
    create(api, tokens, adjustments=[{"flavor": "salty", "delta": -1}])
    outcome = run_learning(api, tokens)
    change = next(row for row in outcome["applied_changes"] if row["field"] == "flavors.salty")
    before = change["old_value"]["coefficient"]
    assert change["new_value"]["coefficient"] < before, "学习必须下调咸度"

    reverted = api.client.post(
        f"/v1/me/taste-profile/changes/{change['id']}/revert",
        headers=bearer(tokens),
        params={"source": "monthly_review"},
    )
    assert reverted.status_code == 200, reverted.text
    assert salty(api, tokens) == before, "撤销必须恢复旧值"

    replay = run_learning(api, tokens)
    assert replay["applied_changes"] == [], "撤销后同样的旧信号不得马上学回来"
    assert salty(api, tokens) == before

    lock = api.client.put(
        "/v1/me/taste-profile/locks",
        headers=bearer(tokens),
        json={"field": "flavors.salty", "locked": True},
    )
    assert lock.status_code == 200, lock.text
    create(api, tokens, adjustments=[{"flavor": "salty", "delta": -1}])
    locked_run = run_learning(api, tokens)
    assert locked_run["applied_changes"] == [], "锁定的字段不再自动更新"
    assert salty(api, tokens) == before

    manual = api.client.patch(
        "/v1/me/taste-profile", headers=bearer(tokens), json={"flavors": {"salty": 1.25}}
    )
    assert manual.status_code == 200
    assert salty(api, tokens) == 1.25, "锁定只挡自动更新，不挡手动修改"

    facts = api.client.get("/v1/me/taste-profile/change-facts", headers=bearer(tokens))
    assert facts.status_code == 200
    assert facts.json()["auto_changes"] >= 1
    assert facts.json()["auto_reverted"] == 1


def test_save_to_taste_applies_immediately_and_reports_change(api: Api) -> None:
    tokens = api.login("taste-learning-j@example.com")
    record = create(api, tokens, adjustments=[{"flavor": "spicy", "delta": -1}])
    automation = api.client.get("/v1/me/taste-profile/automation", headers=bearer(tokens))
    assert automation.status_code == 200
    assert automation.json()["save_to_taste"] is True

    before = api.client.get("/v1/me/taste-profile", headers=bearer(tokens)).json()["flavors"][
        "spicy"
    ]["coefficient"]
    saved = api.client.post(
        f"/v1/me/taste-profile/records/{record['id']}/save-to-taste", headers=bearer(tokens)
    )
    assert saved.status_code == 200, saved.text
    rows = saved.json()
    assert rows and rows[0]["origin"] == "explicit_save"
    assert "存进口味" in rows[0]["reason"]
    now = api.client.get("/v1/me/taste-profile", headers=bearer(tokens)).json()["flavors"]["spicy"][
        "coefficient"
    ]
    assert now < before, "显式保存必须立即生效"

    replay = api.client.post(
        f"/v1/me/taste-profile/records/{record['id']}/save-to-taste", headers=bearer(tokens)
    )
    assert replay.status_code == 200
    assert replay.json() == [], "服务端接受后来源不再被普通学习重复应用"
    assert run_learning(api, tokens)["applied_changes"] == []


def test_offline_record_sync_keeps_one_record_and_can_be_attributed(api: Api) -> None:
    tokens = api.login("taste-learning-k@example.com")
    write = envelope(
        tokens["user"]["id"],
        write_type="cooking_record.create",
        payload={
            "record": {
                "client_id": new_uuid(),
                "dish_name": "离线红烧肉",
                "source": "external_cooking",
                "verification": "unverified",
            }
        },
    )
    assert submit(api, tokens, write)[0]["status"] == "confirmed"
    records = api.client.get("/v1/records", headers=bearer(tokens)).json()["items"]
    assert len(records) == 1
    record_id = records[0]["id"]
    feedback(api, tokens, {"id": record_id}, {"taste_tags": ["偏咸"]})
    answered = api.client.put(
        f"/v1/records/{record_id}/attribution",
        headers=bearer(tokens),
        json={"answer": "personal"},
    )
    assert answered.status_code == 200
    outcome = run_learning(api, tokens)
    assert [row for row in outcome["applied_changes"] if row["field"] == "flavors.salty"]
