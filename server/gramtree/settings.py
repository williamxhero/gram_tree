"""进程级设置：只从环境变量读取，部署时决定，运行中不变。

运行中可以改的参数放在 runtime_config（服务端配置项），不要放这里。
"""

from functools import lru_cache
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="GRAMTREE_", env_file=".env", extra="ignore")

    env: Literal["dev", "test", "staging", "prod"] = "dev"
    database_url: str = "postgresql+psycopg://postgres:postgres@localhost:5432/gramtree"
    redis_url: str = "redis://localhost:6379/0"
    log_level: str = "INFO"
    # 健康检查里探测数据库和 Redis 的超时（秒）
    health_timeout_seconds: float = 2.0
    # 告警邮件用的 SMTP；告警接收方式和地址是运行时配置项 ops.alert_*
    smtp_host: str = ""
    # 备份：本机目录和异地位置（rclone 的 remote:path，留空表示只存本机）
    backup_dir: str = "/var/backups/gramtree"
    backup_remote: str = ""
    smtp_port: int = 25
    smtp_from: str = "alerts@gramtree.local"

    @property
    def examples_enabled(self) -> bool:
        """示例接口只在非正式环境挂载，用来演示和测试全局约定。"""
        return self.env != "prod"


@lru_cache
def get_settings() -> Settings:
    return Settings()
