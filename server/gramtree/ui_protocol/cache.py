"""组合结果缓存（SPEC-009.1 票 7，#83）：让页面快、离线也能用，且不显示过期内容。

见 `router.compose()` 里的整体说明：命中缓存不是"重新组合"，不写新的"组合展示"
事件，也不重新跑一遍实验分组——这两件事本来就只在"服务端刚刚决定了下发什么"的
那一刻才该发生，命中缓存时服务端什么决定都没做，只是把上一次的决定又发了一遍。

存储用 Redis（项目已有，`gramtree.deps.RedisDep`），抄的是
`gramtree.events.metrics`/`gramtree.accounts.service._rate_limit` 已经在用的
"`redis.Redis` 直接传进来，键手工拼前缀"的用法，不引入新的存储方式。

## 缓存 key 设计

维度：用户 ID + 页面类型 + 场景 + 依赖版本。

- 用户 ID、页面类型：组合结果本来就是"这个用户在这个页面类型上看到什么"，天然要
  按这两个分。
- 场景：这张票"场景"还没有真实业务含义（按场景选择内容是 SPEC-009.2 #34 的事），
  这里先留一个参数位，调用方（目前是 `router.compose()`）传一个占位值；这个模块
  自己的单元测试（`test_ui_composition_cache.py`）用假的场景值验证"场景是 key 的
  一个独立维度"这条机制本身——场景不同，key 就不同，缓存天然不会串。
- 依赖版本（`PageDescription.cache.depends_on`，一个 `dict[str, str]`，键值对
  个数和名字都不固定，以后每接入一项业务依赖就多一对）：这是这份缓存能不能继续
  用的核心判断，见下面"失效怎么做到的"。

依赖版本字典不直接拼进 Redis key（可能很长、可能出现 Redis key 不方便使用的
字符），做法是把字典按键排序后拼成一个规范字符串（`"k1=v1&k2=v2"`），取其 sha256
摘要的前 16 位十六进制字符作为 key 的最后一段。用摘要不是为了"隐藏"依赖版本
（Redis key 本来就不对外可见），只是为了让 key 的长度和字符集稳定。

## 失效怎么做到的

"依赖数据变化时让依赖它们的缓存失效"在这个设计里**不需要一段专门的"失效"代码**：
依赖版本本身就是 key 的一部分，某个依赖版本变了，算出来的 key 就跟着变，用新 key
去查，天然查不到旧 key 对应的缓存，直接落到"没命中，重新计算"——这就是"失效"在
这里的全部含义。旧 key 对应的缓存条目不会被主动删除，但它带着 `ttl_s`（来自
`CacheInfo.ttl_s`，`redis.set(..., ex=ttl_s)`）自然过期，不会无限堆积。

这条思路是否成立，靠 `server/tests/test_ui_composition_cache.py` 里的
`test_cache_invalidates_when_test_dependency_version_changes` 验证：请求一次拿到
`composition_id`，改一下测试依赖版本配置（`ui.cache.test_dependency_version`，
`gramtree.ui_protocol.service.TEST_DEPENDENCY_VERSION_CONFIG_KEY`，模拟"依赖数据
变了"），再请求一次，断言拿到不同的 `composition_id`。这个测试通过，说明"key 包含
依赖版本"这条思路本身就能让缓存正确失效，**不需要**额外实现一个主动删除某个 key
的 `invalidate()` 入口——如果以后这条思路被证明不够用（比如需要在依赖版本还没变
之前，提前把某个用户的缓存清掉），再在这个模块加一个 `invalidate(redis, key)`，
现在加了也没有测试覆盖，属于没用到的代码。

## Redis 不可用时怎么办

缓存是性能优化，不是正确性的一部分：Redis 不可用时，`get()`/`set_()` 捕获
`redis.RedisError`，记一条 warning 日志，`get()` 当成"没命中"处理，`set_()`
直接放弃写入——两种情况下都退回到"每次都重新走完整组合流程"，也就是这张票之前
（#77～#84）的行为，不会因为 Redis 挂了就让组合接口本身出问题（"出任何问题都不能
卡住做饭"，SPEC-009.1 一贯的原则）。
"""

import hashlib
import logging
import uuid
from collections.abc import Mapping
from typing import cast

import redis
from redis import Redis

from gramtree.ui_protocol.protocol import PageDescription

logger = logging.getLogger("gramtree.ui_protocol.cache")

_PREFIX = "ui:composition_cache"


def _dependency_fingerprint(depends_on: Mapping[str, str]) -> str:
    parts = []
    for key in sorted(depends_on):
        value = depends_on[key]
        # 目前所有依赖版本的取值都是固定字符串（配置项、写死的占位版本号、摘要），
        # 不会包含这两个分隔符；断言留着是为了以后接入真实依赖版本时，一旦有人不
        # 小心传了包含 "&"/"=" 的原始值，能在测试/开发期间尽早发现，而不是悄悄
        # 生成一个可能和别的依赖组合冲突的 key。
        assert "&" not in key and "=" not in key, f"依赖版本的 key 不能包含 &/=：{key}"
        assert "&" not in value and "=" not in value, f"依赖版本的值不能包含 &/=：{value}"
        parts.append(f"{key}={value}")
    canonical = "&".join(parts)
    return hashlib.sha256(canonical.encode()).hexdigest()[:16]


def cache_key(
    user_id: uuid.UUID,
    page_type: str,
    scenario: str,
    depends_on: Mapping[str, str],
) -> str:
    return f"{_PREFIX}:{user_id}:{page_type}:{scenario}:{_dependency_fingerprint(depends_on)}"


def get(client: Redis, key: str) -> PageDescription | None:
    """查缓存；没命中（含 Redis 不可用、值读不出来）一律返回 `None`，调用方当成
    "没有可用缓存，走完整组合流程"处理。"""
    try:
        raw = cast("bytes | None", client.get(key))
    except redis.RedisError:
        logger.warning("查组合缓存时 Redis 不可用，按未命中处理：%s", key)
        return None
    if raw is None:
        return None
    try:
        return PageDescription.model_validate_json(raw)
    except Exception:
        # 缓存里的值解析不出来（协议改了、数据损坏……）：当成未命中处理，不能让一条
        # 坏掉的缓存记录卡住组合接口。
        logger.warning("组合缓存里的值解析失败，按未命中处理：%s", key)
        return None


def set_(client: Redis, key: str, description: PageDescription) -> None:
    """写缓存。`ttl_s<=0`（目前只有 `build_fallback_description()` 产出的兜底
    描述会这样）表示这份结果不值得缓存——兜底描述本来就是"这次没能正常组合"，缓存
    下来下次命中反而会一直下发兜底，见 `router.compose()`。"""
    ttl = description.cache.ttl_s
    if ttl <= 0:
        return
    try:
        client.set(key, description.model_dump_json(), ex=ttl)
    except redis.RedisError:
        logger.warning("写组合缓存时 Redis 不可用，跳过：%s", key)
