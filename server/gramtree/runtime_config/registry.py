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
