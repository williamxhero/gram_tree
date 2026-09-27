"""服务端配置项登记表。

SPEC-012 参数表里的数值、后面子 SPEC 新增的阈值和额度、以及能力开关，都在这里登记：
key、类型、默认值、取值范围、说明、是否下发给客户端。
数据库只存被改过的值；没改过的用默认值。改值走命令行（gramtree config set），会留历史。
"""

from dataclasses import dataclass
from typing import Literal

ValueType = Literal["int", "float", "bool", "str"]


@dataclass(frozen=True)
class ConfigItem:
    key: str
    type: ValueType
    default: int | float | bool | str
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
    # —— 接口约定 ——
    ConfigItem(
        "api.page_size_max",
        "int",
        100,
        "列表接口每页条数上限",
        minimum=1,
        maximum=500,
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
