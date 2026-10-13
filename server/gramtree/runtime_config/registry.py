"""服务端配置项登记表。

SPEC-012 参数表里的数值、后面子 SPEC 新增的阈值和额度、以及能力开关，都在这里登记：
key、类型、默认值、取值范围、说明、是否下发给客户端。
数据库只存被改过的值；没改过的用默认值。改值走命令行（gramtree config set），会留历史。
"""

from dataclasses import dataclass
from typing import Any, Literal

# "json" 是 #84 加的：值是一个 dict，形状由取用方（目前只有
# `gramtree.ui_protocol.experiments`）自己再校验一层，这里的登记表和读写入口
# （service.parse_value/validate）不理解它的内部结构，只当成"一个不透明的 JSON 值"
# 存取——`ConfigValue.value` 列本来就是 JSONB，标量和 dict 存起来没有区别，不需要为
# 了这一种情况新开一张表（选型说明见 `gramtree/ui_protocol/experiments.py` 顶部）。
ValueType = Literal["int", "float", "bool", "str", "json"]


@dataclass(frozen=True)
class ConfigItem:
    key: str
    type: ValueType
    default: int | float | bool | str | dict[str, Any]
    description: str
    minimum: float | None = None
    maximum: float | None = None
    choices: tuple[str, ...] | None = None
    # True 表示通过 /v1/client-config 下发给 App
    public: bool = False

    @property
    def is_feature_flag(self) -> bool:
        return self.key.startswith("feature.")


ITEMS: tuple[ConfigItem, ...] = (
    ConfigItem(
        "taste.equipment",
        "json",
        {
            "items": [
                {"id": "wok", "label": "炒锅", "aliases": ["炒菜锅"]},
                {"id": "oven", "label": "烤箱", "aliases": []},
                {"id": "air_fryer", "label": "空气炸锅", "aliases": []},
                {"id": "rice_cooker", "label": "电饭煲", "aliases": ["电饭锅"]},
                {"id": "steamer", "label": "蒸锅", "aliases": []},
                {"id": "saucepan", "label": "汤锅", "aliases": []},
                {"id": "frying_pan", "label": "平底锅", "aliases": ["煎锅"]},
                {"id": "pressure_cooker", "label": "压力锅", "aliases": ["高压锅"]},
                {"id": "microwave", "label": "微波炉", "aliases": []},
            ]
        },
        "做菜约束规范厨具词表及既有自由文本别名；不改写菜谱原文",
    ),
    ConfigItem(
        "taste.scale",
        "json",
        {
            "minimum": 0.5,
            "maximum": 1.5,
            "default": 1.0,
            "levels": [
                {"coefficient": 0.5, "label": "淡很多"},
                {"coefficient": 0.75, "label": "淡一点"},
                {"coefficient": 1.0, "label": "标准"},
                {"coefficient": 1.25, "label": "重一点"},
                {"coefficient": 1.5, "label": "重很多"},
            ],
        },
        "口味系数范围、默认值及五档映射（占位；取用时校验完整形状）",
    ),
    ConfigItem(
        "taste.adjustment_percent",
        "float",
        0.25,
        "味型调整默认幅度；只允许需求约定的 20%、25% 或 30%",
        minimum=0.20,
        maximum=0.30,
    ),
    ConfigItem(
        "taste.learning_weights",
        "json",
        {
            "manual_adjustment": 1.0,
            "feedback_tag": 0.7,
            "explicit_save": 1.0,
            "rating": 0.4,
            "repeat_cook": 0.4,
            "skipped_recommendation": 0.2,
            "favorite": 0.2,
            "feedback_unanswered": 0.3,
        },
        "口味学习各来源权重（手动改用量的仍以 manual_adjustment 计入）",
    ),
    ConfigItem(
        "taste.learning_step",
        "float",
        0.05,
        "单个信号一次最多让系数变化的步长",
        minimum=0.001,
        maximum=0.5,
    ),
    ConfigItem(
        "taste.learning_max_change",
        "float",
        0.1,
        "一次学习运行对同一项系数的最大变化量",
        minimum=0.001,
        maximum=0.5,
    ),
    ConfigItem(
        "taste.confidence_max",
        "float",
        1.0,
        "口味项把握度上限",
        minimum=0.1,
        maximum=1.0,
    ),
    ConfigItem(
        "taste.signal_half_life_days",
        "float",
        90.0,
        "学习信号半衰期（天）",
        minimum=1.0,
        maximum=3650.0,
    ),
    ConfigItem(
        "taste.attribution_min_samples",
        "int",
        3,
        "同一版本判定菜谱问题所需的最少他人做过的样本数",
        minimum=1,
        maximum=1000,
    ),
    ConfigItem(
        "taste.attribution_majority",
        "float",
        0.6,
        "同版本多数派阈值",
        minimum=0.5,
        maximum=1.0,
    ),
    ConfigItem(
        "taste.ingredient_dislike_threshold",
        "float",
        2.0,
        "生成“标为不喜欢”待确认建议所需的去掉/替换证据权重",
        minimum=0.5,
        maximum=100.0,
    ),
    ConfigItem(
        "taste.local_cuisine_threshold",
        "float",
        0.1,
        "局部菜系偏好与总体差异达到此值才生效",
        minimum=0.0,
        maximum=1.0,
    ),
    ConfigItem(
        "feature.taste_auto_learning",
        "bool",
        True,
        "口味自动学习、变更确认与锁定（SPEC-005.3）",
        public=True,
    ),
    ConfigItem(
        "feature.save_to_taste",
        "bool",
        True,
        "记录卡的“存进我的口味”去向（SPEC-005.3）",
        public=True,
    ),
    ConfigItem(
        "ai.routes",
        "json",
        {
            "intent": "small",
            "generate": "large",
            "recipe_import": "large",
            "normalize": "small",
            "embedding": "vector",
            "explain": "large",
            "quantify": "large",
            "batch_advice": "small",
            "comparison": "small",
            "modify_intent": "small",
            "modify": "large",
            "change_explanation": "small",
        },
        "能力到模型档位的路由",
    ),
    ConfigItem(
        "ai.models",
        "json",
        {
            "small": {"provider": "unconfigured", "base_url": "", "model": "small"},
            "large": {"provider": "unconfigured", "base_url": "", "model": "large"},
            "vector": {"provider": "unconfigured", "base_url": "", "model": "vector"},
        },
        "模型地址、名称及每百万 token 的 input_price/output_price（不含密钥）",
    ),
    ConfigItem(
        "ai.policies",
        "json",
        {
            "intent": {"timeout": 15, "retries": 1, "daily_limit": 100},
            "generate": {"timeout": 60, "retries": 1, "daily_limit": 50},
            "recipe_import": {"timeout": 60, "retries": 0, "daily_limit": 50},
            "explain": {"timeout": 30, "retries": 1, "daily_limit": 50},
            "normalize": {"timeout": 15, "retries": 0, "daily_limit": 100},
            "embedding": {"timeout": 15, "retries": 1, "daily_limit": 500},
            "quantify": {"timeout": 60, "retries": 1, "daily_limit": 50},
            "batch_advice": {"timeout": 30, "retries": 0, "daily_limit": 50},
            "comparison": {"timeout": 15, "retries": 0, "daily_limit": 0},
            "modify_intent": {"timeout": 15, "retries": 0, "daily_limit": 50},
            "modify": {"timeout": 60, "retries": 0, "daily_limit": 50},
            "change_explanation": {"timeout": 15, "retries": 0, "daily_limit": 50},
        },
        "每种能力的超时、重试及每日额度（可带 users 覆盖）",
    ),
    ConfigItem("ai.monthly_budget", "float", 1000.0, "平台每月 AI 预算（占位，人民币）", minimum=0),
    ConfigItem("ai.budget_alert_ratio", "float", 0.8, "月预算告警比例", minimum=0, maximum=1),
    ConfigItem("ai.call_reservation", "float", 1.0, "每次调用预算预留额", minimum=0.01),
    ConfigItem(
        "ai.log_retention_days",
        "int",
        90,
        "内部生成日志与未保存请求保留天数",
        minimum=1,
        maximum=3650,
    ),
    # —— 接口约定 ——
    ConfigItem(
        "api.page_size_max",
        "int",
        100,
        "列表接口每页条数上限",
        minimum=1,
        maximum=500,
    ),
    ConfigItem(
        "api.cursor_ttl_seconds",
        "int",
        600,
        "分页游标有效期（秒）",
        minimum=1,
        maximum=86400,
    ),
    ConfigItem(
        "api.cursor_max_pages",
        "int",
        100,
        "单次查询最多可连续翻页的页数",
        minimum=1,
        maximum=10000,
    ),
    # —— 已验证条件占位（SPEC-002.4；判定在 SPEC-007.3 实现） ——
    ConfigItem(
        "recipe.verification_min_distinct_cooks",
        "int",
        5,
        "已验证至少需要的不同做菜用户数（占位，当前不执行判定）",
        minimum=1,
        maximum=10000,
        public=True,
    ),
    ConfigItem(
        "recipe.verification_max_one_sided_feedback_ratio",
        "float",
        0.3,
        "偏咸、偏淡各类反馈比例上限（占位，当前不执行判定）",
        minimum=0,
        maximum=1,
        public=True,
    ),
    # —— 菜谱份数换算（SPEC-002.3） ——
    ConfigItem(
        "recipe.servings_min",
        "int",
        1,
        "份数换算允许的最小目标份数",
        minimum=1,
        maximum=1000,
        public=True,
    ),
    ConfigItem(
        "recipe.servings_max",
        "int",
        20,
        "份数换算允许的最大目标份数",
        minimum=1,
        maximum=1000,
        public=True,
    ),
    ConfigItem(
        "recipe.scaling_round_deviation_threshold",
        "float",
        0.20,
        "阶梯食材取整后与按比例结果相差超过此比例时提示",
        minimum=0.0,
        maximum=1.0,
        public=True,
    ),
    ConfigItem(
        "recipe.scaling_batch_multiplier",
        "float",
        2.0,
        "目标份数达到原份数此倍数时显示分批下锅提示",
        minimum=1.0,
        maximum=10.0,
        public=True,
    ),
    # —— 确定性版本比较（SPEC-002.5） ——
    ConfigItem(
        "recipe.comparison_minor_threshold",
        "float",
        0.20,
        "单条用量/时长微调的严格上界",
        minimum=0,
        maximum=1,
    ),
    ConfigItem(
        "recipe.comparison_main_groups",
        "json",
        {"values": ["主料", "main"]},
        "比较中视为主料的分组；修改留审计历史",
    ),
    ConfigItem(
        "recipe.comparison_heating_actions",
        "json",
        {
            "values": [
                "炒",
                "炸",
                "煎",
                "煮",
                "蒸",
                "烤",
                "炖",
                "焖",
                "焯",
                "stir_fry",
                "deep_fry",
                "fry",
                "boil",
                "steam",
                "bake",
                "roast",
                "simmer",
            ]
        },
        "主料烹饪方法集合中的加热动作",
    ),
    ConfigItem(
        "recipe.comparison_alignment_threshold",
        "float",
        0.35,
        "动作及食材引用的最低确定性步骤相似度",
        minimum=0,
        maximum=1,
    ),
    ConfigItem(
        "recipe.comparison_alignment_margin",
        "float",
        0.05,
        "接近的步骤对齐得分保留不确定",
        minimum=0,
        maximum=1,
    ),
    ConfigItem(
        "recipe.comparison_ai_min_confidence",
        "float",
        0.75,
        "AI 展示辅助对齐的最低把握程度；仅影响独立辅助缓存",
        minimum=0,
        maximum=1,
    ),
    # —— 账号与登录（SPEC-013.2） ——
    ConfigItem(
        "auth.email_code_ttl_minutes",
        "int",
        10,
        "邮箱验证码有效期（分钟）",
        minimum=1,
        maximum=60,
    ),
    ConfigItem(
        "auth.email_code_max_attempts",
        "int",
        5,
        "每个验证码最多尝试次数，超过后要重新获取",
        minimum=1,
        maximum=20,
    ),
    ConfigItem(
        "auth.email_code_resend_seconds",
        "int",
        60,
        "同一邮箱重新发送验证码的间隔（秒）",
        minimum=0,
        maximum=3600,
    ),
    ConfigItem(
        "auth.email_code_daily_limit",
        "int",
        10,
        "每个邮箱、每台设备、每个 IP 每天最多发送验证码的次数",
        minimum=1,
        maximum=1000,
    ),
    ConfigItem(
        "auth.access_token_minutes",
        "int",
        30,
        "访问令牌有效期（分钟）",
        minimum=1,
        maximum=1440,
    ),
    ConfigItem(
        "auth.refresh_token_days",
        "int",
        30,
        "刷新令牌有效期（天），每次续期都换发新的",
        minimum=1,
        maximum=365,
    ),
    ConfigItem(
        "auth.reauth_window_minutes",
        "int",
        10,
        "注销账号等敏感操作要求在多少分钟内重新验证过身份",
        minimum=1,
        maximum=120,
    ),
    ConfigItem(
        "auth.signing_clock_tolerance_seconds",
        "int",
        300,
        "请求签名允许的客户端时钟误差（秒）",
        minimum=1,
        maximum=3600,
    ),
    ConfigItem(
        "auth.signing_nonce_ttl_seconds",
        "int",
        600,
        "请求签名随机数的 Redis 保留时间（秒）",
        minimum=1,
        maximum=86400,
    ),
    ConfigItem(
        "auth.signing_key_grace_seconds",
        "int",
        30,
        "刷新令牌后旧请求签名密钥的过渡时间（秒）",
        minimum=1,
        maximum=300,
    ),
    # —— 接口限流（SPEC-011.2） ——
    *(
        ConfigItem(
            f"rate.{category}.{dimension}_per_{window}",
            "int",
            default,
            f"{category} 接口按{dimension}维度的{window}窗口额度",
            minimum=1,
            maximum=10_000_000,
        )
        for category, default in (
            ("search_list", 120),
            ("detail", 120),
            ("write", 60),
            ("ai", 30),
            ("auth", 30),
            ("captcha", 30),
            ("export", 10),
        )
        for dimension in ("account", "device", "ip")
        for window, default in (("minute", default), ("day", default * 40))
    ),
    *(
        ConfigItem(
            f"rate.detail.{dimension}_distinct_recipes_per_day",
            "int",
            1000,
            f"详情接口按{dimension}维度每天访问不同菜谱的数量上限",
            minimum=1,
            maximum=1_000_000,
        )
        for dimension in ("account", "device", "ip")
    ),
    # —— 规则型机器行为保护（SPEC-011.2） ——
    ConfigItem("risk.enabled", "bool", True, "是否启用机器行为风险规则"),
    ConfigItem(
        "risk.short_window_seconds", "int", 600, "短时行为计数窗口（秒）", minimum=10, maximum=86400
    ),
    ConfigItem(
        "risk.short_request_limit", "int", 1000, "窗口内请求数触发点", minimum=1, maximum=1_000_000
    ),
    ConfigItem(
        "risk.detail_interval_seconds",
        "int",
        2,
        "详情请求视为几乎无停留的间隔（秒）",
        minimum=1,
        maximum=3600,
    ),
    ConfigItem(
        "risk.detail_repeat_limit", "int", 20, "连续快速详情次数触发点", minimum=1, maximum=10000
    ),
    ConfigItem(
        "risk.sequential_limit", "int", 100, "顺序详情访问数量触发点", minimum=1, maximum=100000
    ),
    ConfigItem(
        "risk.uniform_daily_limit",
        "int",
        2000,
        "全天均匀请求数量触发点",
        minimum=1,
        maximum=1_000_000,
    ),
    ConfigItem(
        "risk.uniform_min_span_hours",
        "int",
        12,
        "全天均匀请求至少覆盖的小时数",
        minimum=1,
        maximum=24,
    ),
    ConfigItem(
        "risk.multi_account_limit", "int", 5, "单设备关联账号数触发点", minimum=2, maximum=1000
    ),
    ConfigItem(
        "risk.subnet_new_account_limit",
        "int",
        10,
        "网段窗口内新账号数触发点",
        minimum=1,
        maximum=10000,
    ),
    ConfigItem("risk.captcha_points", "int", 10, "验证码风险分阈值", minimum=1, maximum=100000),
    ConfigItem("risk.throttle_points", "int", 20, "降速风险分阈值", minimum=2, maximum=100000),
    ConfigItem(
        "risk.temporary_block_points", "int", 40, "临时封禁风险分阈值", minimum=3, maximum=100000
    ),
    ConfigItem(
        "risk.permanent_block_points", "int", 80, "人工封禁风险分阈值", minimum=4, maximum=100000
    ),
    ConfigItem("risk.throttle_seconds", "int", 30, "降速持续时间（秒）", minimum=1, maximum=86400),
    ConfigItem(
        "risk.temporary_block_seconds",
        "int",
        900,
        "临时封禁持续时间（秒）",
        minimum=1,
        maximum=604800,
    ),
    ConfigItem(
        "risk.captcha_seconds", "int", 600, "验证码挑战有效期（秒）", minimum=1, maximum=86400
    ),
    ConfigItem(
        "risk.score_ttl_seconds",
        "int",
        86400,
        "风险分滚动保留时间（秒）",
        minimum=60,
        maximum=2_592_000,
    ),
    ConfigItem(
        "risk.retention_seconds",
        "int",
        604800,
        "Redis 处置状态保留时间（秒）",
        minimum=60,
        maximum=2_592_000,
    ),
    ConfigItem("risk.uniform_days", "int", 3, "全天均匀请求观察天数", minimum=1, maximum=30),
    ConfigItem(
        "risk.uniform_bucket_seconds",
        "int",
        3600,
        "均匀请求分桶时长（秒）",
        minimum=1,
        maximum=3600,
    ),
    ConfigItem(
        "risk.uniform_tolerance_percent",
        "int",
        25,
        "均匀请求计数偏差百分比",
        minimum=0,
        maximum=100,
    ),
    ConfigItem(
        "risk.detail_interval_tolerance_ms",
        "int",
        250,
        "详情间隔稳定性容差（毫秒）",
        minimum=0,
        maximum=10000,
    ),
    ConfigItem(
        "risk.security_failure_limit", "int", 5, "签名失败或重放触发次数", minimum=1, maximum=10000
    ),
    ConfigItem(
        "risk.throttle_request_limit", "int", 1, "降速窗口允许请求数", minimum=1, maximum=1000
    ),
    ConfigItem(
        "risk.throttle_window_seconds", "int", 5, "降速窗口长度（秒）", minimum=1, maximum=3600
    ),
    ConfigItem("feature.public_recipes", "bool", False, "是否允许公开菜谱分享", public=True),
    ConfigItem(
        "sharing.ai_crawlers",
        "json",
        {"values": ["GPTBot", "CCBot", "ClaudeBot", "Google-Extended", "Bytespider", "Amazonbot"]},
        "拒绝的 AI 训练爬虫",
    ),
    ConfigItem("sharing.public_base_url", "str", "https://gramtree.app", "分享页 HTTPS 公开基地址"),
    ConfigItem("sharing.download_url", "str", "", "App 下载或测试版地址"),
    ConfigItem("sharing.complaint_contact", "str", "", "侵权投诉联系方式"),
    ConfigItem(
        "ops.access_log_retention_days", "int", 180, "安全访问日志保存天数", minimum=1, maximum=3650
    ),
    ConfigItem(
        "account.nickname_max_length",
        "int",
        20,
        "昵称最多几个字",
        minimum=2,
        maximum=64,
    ),
    ConfigItem(
        "account.deletion_business_days",
        "int",
        15,
        "申请注销后多少个工作日内删除个人数据",
        minimum=1,
        maximum=30,
    ),
    # —— 界面描述协议（SPEC-009.1） ——
    ConfigItem(
        "ui.composition_timeout_ms",
        "int",
        800,
        "App 等 POST /v1/ui/compositions 返回的时限（毫秒），超过就先显示写在 App 里"
        "的标准布局，不一直转圈；出任何问题都不能卡住做饭",
        minimum=100,
        maximum=10_000,
        public=True,
    ),
    ConfigItem(
        "ui.cache.test_dependency_version",
        "str",
        "v0",
        "组合缓存机制验证用的测试依赖版本（SPEC-009.1 #83）：不对应任何真实业务"
        "数据，只用来证明“组合结果按依赖版本缓存，依赖版本变了缓存自然失效、重新"
        "计算”这条链路能跑通——测试改这个值，验证组合接口拿到新的 composition_id。"
        "真实依赖（菜谱版本、口味档案、推荐候选、经验结论）由后续子 SPEC 接上后，"
        "会照 gramtree.ui_protocol.service.dependency_versions() 里的样子，读真实"
        "数据算出版本值，不会再是配置项。不下发给 App（public 默认 False）。",
    ),
    ConfigItem(
        "ui.experiment.today_composition",
        "json",
        {
            "enabled": False,
            "groups": [
                {"name": "control", "ratio": 0.5, "variant": "default"},
                {"name": "more_detail", "ratio": 0.5, "variant": "standard_detail"},
            ],
        },
        "“今天”页组合实验（SPEC-009.1 #84 的测试用实验）：按用户稳定分组，试的是"
        "hint_bar/empty_state 的详略程度；enabled=false（默认）时不生效，组合结果和"
        "没有这个实验时完全一样。形状由 gramtree.ui_protocol.experiments."
        "ExperimentDefinition 校验，不在这里（type=json 的配置项只存不管形状）。"
        "不下发给 App（public 默认 False）——App 不需要知道实验定义，只需要从组合"
        "接口的响应里读 experiment 字段。",
    ),
    # —— 能力开关：关闭时 App 里对应入口不出现（SPEC-009） ——
    ConfigItem(
        "feature.evolution_tree",
        "bool",
        False,
        "进化树入口（阶段二）",
        public=True,
    ),
    ConfigItem(
        "feature.cooking_qa",
        "bool",
        False,
        "做菜中即时问答（阶段二）",
        public=True,
    ),
    ConfigItem(
        "feature.receipt_scan",
        "bool",
        False,
        "拍小票记价格（阶段二）",
        public=True,
    ),
    # —— 可观测性：告警阈值和接收方式 ——
    ConfigItem(
        "ops.alert_window_minutes",
        "int",
        5,
        "计算接口错误率和耗时的时间窗口（分钟）",
        minimum=1,
        maximum=60,
    ),
    ConfigItem(
        "ops.alert_error_rate",
        "float",
        0.05,
        "窗口内 5xx 比例超过此值就告警",
        minimum=0.0,
        maximum=1.0,
    ),
    ConfigItem(
        "ops.alert_p95_ms",
        "int",
        1500,
        "窗口内接口耗时 p95 超过此值（毫秒）就告警",
        minimum=50,
        maximum=60000,
    ),
    ConfigItem(
        "ops.alert_min_requests",
        "int",
        20,
        "窗口内请求数少于此值时不告警，避免小样本误报",
        minimum=1,
        maximum=100000,
    ),
    ConfigItem(
        "ops.alert_channel",
        "str",
        "none",
        "告警接收方式：none / webhook / email",
        choices=("none", "webhook", "email"),
    ),
    ConfigItem(
        "ops.alert_target",
        "str",
        "",
        "告警接收地址：webhook URL 或邮箱",
    ),
    # —— 经验层事件管道（SPEC-010.1） ——
    ConfigItem(
        "events.upload_max_items",
        "int",
        500,
        "经验层事件单次上传最多多少条，超过整批拒绝，客户端据此分批重传",
        minimum=1,
        maximum=5000,
    ),
    ConfigItem(
        "events.upload_max_bytes",
        "int",
        2_000_000,
        "经验层事件单次上传请求体最大字节数（按 Content-Length 头判断），超过整批拒绝",
        minimum=1000,
        maximum=50_000_000,
    ),
    ConfigItem(
        "events.device_time_suspicious_threshold_seconds",
        "int",
        300,
        "设备时间和服务端接收时间相差超过这个秒数，事件就标记为“设备时间可疑”，"
        "分析用的时间改用服务端接收时间",
        minimum=1,
        maximum=86_400,
    ),
    ConfigItem(
        "events.alert_window_minutes",
        "int",
        5,
        "计算事件上传重复率、拒收率的时间窗口（分钟）",
        minimum=1,
        maximum=60,
    ),
    ConfigItem(
        "events.alert_min_events",
        "int",
        20,
        "窗口内事件总数少于此值时不告警，避免小样本误报",
        minimum=1,
        maximum=100_000,
    ),
    ConfigItem(
        "events.alert_duplicate_rate",
        "float",
        0.3,
        "窗口内事件重复率超过此值就告警",
        minimum=0.0,
        maximum=1.0,
    ),
    ConfigItem(
        "events.alert_reject_rate",
        "float",
        0.1,
        "窗口内事件拒收率超过此值就告警",
        minimum=0.0,
        maximum=1.0,
    ),
    # —— 产品埋点（SPEC-010.1，和经验层事件完全分开的独立通道） ——
    ConfigItem(
        "analytics.retention_days",
        "int",
        90,
        "产品埋点保存天数，超期由后台任务清理",
        minimum=1,
        maximum=3650,
    ),
    # —— 部署与备份 ——
    ConfigItem(
        "ops.backup_retention_days",
        "int",
        14,
        "数据库备份保留天数",
        minimum=1,
        maximum=365,
    ),
)

BY_KEY: dict[str, ConfigItem] = {item.key: item for item in ITEMS}
