"""SPEC-009.1 票 7（#83）：组合缓存——服务端按用户/页面类型/场景/依赖版本缓存组合
结果，依赖版本变化时缓存自然失效。设计说明见 `gramtree.ui_protocol.cache` 模块
顶部的文档；App 端离线用本机缓存的部分在 App 测试里（`composition_cache_test.dart`）。
"""

import uuid

import pytest
import redis
from redis import Redis
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from gramtree.cli import main as cli
from gramtree.core.time import utcnow
from gramtree.events.models import Event
from gramtree.ui_protocol import cache, service
from gramtree.ui_protocol.protocol import CacheInfo, PageDescription
from tests.accounts_support import Api, bearer
from tests.conftest import TEST_REDIS_URL
from tests.test_ui_protocol import _compose


def _redis() -> Redis:
    return Redis.from_url(TEST_REDIS_URL)


def _composition_events(engine: Engine) -> list[Event]:
    with Session(engine) as session:
        rows = (
            session.query(Event)
            .filter(Event.event_type == "ui.composition_shown")
            .order_by(Event.received_at)
            .all()
        )
        session.expunge_all()
        return rows


def _set_test_dependency_version(value: str) -> None:
    assert (
        cli(
            [
                "config",
                "set",
                service.TEST_DEPENDENCY_VERSION_CONFIG_KEY,
                value,
                "--by",
                "test",
                "--reason",
                "SPEC-009.1 #83 测试",
            ]
        )
        == 0
    )


# —— 依赖没变时命中缓存：同一份描述、同一个 composition_id，不多写"组合展示"事件 ——
# （这两条在 test_ui_protocol.py 里也测了——那是"每次组合都会发生什么"的回归测试，
# 这里补一层"是不是真的走了缓存路径"的针对性验证：直接检查 Redis 里确实存了一份
# 序列化好的描述。）


def test_compose_result_is_cached_when_dependencies_unchanged(api: Api, engine: Engine) -> None:
    tokens = api.login("cache-hit-user@example.com")

    first = _compose(api, tokens).json()
    second = _compose(api, tokens).json()

    assert first["composition_id"] == second["composition_id"]
    assert first["components"] == second["components"]
    assert len(_composition_events(engine)) == 1

    with Session(engine) as session:
        me = api.client.get("/v1/me", headers=bearer(tokens))
        user_id = uuid.UUID(me.json()["id"])
        depends_on = service.dependency_versions("today", session)
    key = cache.cache_key(user_id, "today", "default", depends_on)
    cached = cache.get(_redis(), key)
    assert cached is not None
    assert str(cached.composition_id) == first["composition_id"]


# —— 依赖变化后（测试用依赖维度）缓存失效，再次请求得到新结果 ——


def test_cache_invalidates_when_test_dependency_version_changes(api: Api, engine: Engine) -> None:
    tokens = api.login("cache-invalidate-user@example.com")

    _set_test_dependency_version("v0")
    first = _compose(api, tokens).json()

    # 同一个测试依赖版本再请求一次：还是命中缓存，同一个 composition_id（先确认
    # "没变就不变"，再确认下面"变了就变"，两条放在一个测试里更能说明问题——如果
    # 缓存机制本身不工作，这一步就会先失败）。
    unchanged = _compose(api, tokens).json()
    assert unchanged["composition_id"] == first["composition_id"]

    # 模拟"依赖数据变了"：改一下测试依赖版本配置（不需要真的接上菜谱版本这些业务
    # 依赖——这个配置项本来就是为了在它们接上之前，先证明"依赖版本变了 -> 缓存 key
    # 变了 -> 查不到旧缓存 -> 自然重新计算"这条链路成立）。
    _set_test_dependency_version("v1")
    changed = _compose(api, tokens).json()
    assert changed["composition_id"] != first["composition_id"]

    events = _composition_events(engine)
    # 第一次请求写一条事件，第二次命中缓存不写，第三次（依赖变了，重新组合）再写
    # 一条，一共两条。
    assert len(events) == 2
    ids = {e.correlation["ui_composition_id"] for e in events}
    assert ids == {first["composition_id"], changed["composition_id"]}


def test_cache_key_changes_when_test_dependency_version_changes(engine: Engine) -> None:
    """比上一个测试更直接：不经过 HTTP，直接验证
    `service.dependency_versions()` 算出来的依赖版本、进而 `cache.cache_key()`
    算出来的 key，会随配置改变——这是"缓存失效不需要额外代码"这条设计能立住的
    根本原因。"""
    user_id = uuid.uuid4()
    with Session(engine) as session:
        _set_test_dependency_version("a")
        depends_on_a = service.dependency_versions("today", session)
        _set_test_dependency_version("b")
        depends_on_b = service.dependency_versions("today", session)

    assert depends_on_a != depends_on_b
    key_a = cache.cache_key(user_id, "today", "default", depends_on_a)
    key_b = cache.cache_key(user_id, "today", "default", depends_on_b)
    assert key_a != key_b


# —— 场景是 key 的一个独立维度（今天页目前没有真实场景差异，用假场景值验证机制本身）——


def test_cache_key_differs_by_scenario() -> None:
    user_id = uuid.uuid4()
    depends_on = {"plan": "v0"}
    key_a = cache.cache_key(user_id, "today", "scenario_a", depends_on)
    key_b = cache.cache_key(user_id, "today", "scenario_b", depends_on)
    assert key_a != key_b


def test_cache_key_differs_by_user_and_page_type() -> None:
    depends_on = {"plan": "v0"}
    key_1 = cache.cache_key(uuid.uuid4(), "today", "default", depends_on)
    key_2 = cache.cache_key(uuid.uuid4(), "today", "default", depends_on)
    key_3 = cache.cache_key(uuid.UUID(int=0), "today", "default", depends_on)
    key_4 = cache.cache_key(uuid.UUID(int=0), "other_page", "default", depends_on)
    assert len({key_1, key_2, key_3, key_4}) == 4


# —— 命中缓存不应该多写一条"组合展示"事件（票面原话，单独测一遍） ——


def test_cache_hit_does_not_record_a_composition_shown_event(api: Api, engine: Engine) -> None:
    tokens = api.login("cache-no-duplicate-event-user@example.com")
    _compose(api, tokens)
    assert len(_composition_events(engine)) == 1

    _compose(api, tokens)
    _compose(api, tokens)
    assert len(_composition_events(engine)) == 1


# —— 兜底描述（ttl_s=0）不会被缓存：连续两次都出问题，各自记一条兜底事件 ——


def test_fallback_descriptions_are_not_cached(
    api: Api, engine: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    tokens = api.login("cache-skips-fallback-user@example.com")

    def _fail(supported_components: set[str], **_: object) -> None:
        raise RuntimeError("组合模块炸了")

    monkeypatch.setitem(service.COMPOSERS, "today", _fail)
    first = _compose(api, tokens).json()
    second = _compose(api, tokens).json()

    assert first["fallback"] == {"reason_code": "server_error"}
    assert second["fallback"] == {"reason_code": "server_error"}
    # 兜底描述不缓存，所以两次请求都真的重新跑了一遍组合流程（都触发了 _fail，都
    # 各自留下一条兜底事件），而不是第二次直接命中第一次缓存下来的兜底结果。
    events = _composition_events(engine)
    assert len(events) == 2
    assert all(e.content["is_fallback"] is True for e in events)


# —— Redis 不可用时，get()/set_() 各自退化成"没命中"/"放弃写入"，不让异常往上冒 ——


class _BrokenRedis:
    """模拟 Redis 连不上：`get`/`set` 都抛 `redis.RedisError`，和真的断线时
    `redis-py` 抛出的异常类型一致。"""

    def get(self, *_args: object, **_kwargs: object) -> None:
        raise redis.RedisError("redis down (模拟)")

    def set(self, *_args: object, **_kwargs: object) -> None:
        raise redis.RedisError("redis down (模拟)")


def _sample_description() -> PageDescription:
    return PageDescription(
        protocol="1.0",
        page_type="today",
        composition_id=uuid.uuid4(),
        generated_at=utcnow(),
        cache=CacheInfo(depends_on={"plan": "v0"}, ttl_s=600),
        components=[],
    )


def test_cache_get_degrades_to_a_miss_when_redis_is_unavailable() -> None:
    assert cache.get(_BrokenRedis(), "some-key") is None  # type: ignore[arg-type]


def test_cache_set_silently_skips_writing_when_redis_is_unavailable() -> None:
    # 不抛异常即通过：写入失败时静默放弃，接口本身不受影响。
    cache.set_(_BrokenRedis(), "some-key", _sample_description())  # type: ignore[arg-type]
