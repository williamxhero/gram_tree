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
    # 允许跨域访问的网页来源（逗号分隔）。网页版只用于测试，正式环境留空
    cors_origins: str = ""
    # 健康检查里探测数据库和 Redis 的超时（秒）
    health_timeout_seconds: float = 2.0
    # 告警邮件用的 SMTP；告警接收方式和地址是运行时配置项 ops.alert_*
    smtp_host: str = ""
    # 备份：本机目录和异地位置（rclone 的 remote:path，留空表示只存本机）
    backup_dir: str = "/var/backups/gramtree"
    backup_remote: str = ""
    smtp_port: int = 25
    smtp_from: str = "alerts@gramtree.local"
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_starttls: bool = False

    # —— 账号与登录（SPEC-013.2） ——
    # 签发访问令牌的密钥。正式环境必须设置成足够长的随机串
    auth_secret: str = "dev-only-secret-change-me-0123456789abcdef"
    # 验证码邮件怎么发：smtp（正式）或 memory（开发和测试，发出的邮件留在内存里）
    mail_backend: Literal["smtp", "memory"] = "memory"
    mail_from: str = "味谱 <no-reply@gramtree.local>"
    # 通过 Apple 登录：App 的 Bundle ID，以及用来换取和撤销授权的密钥（.p8 内容）
    # apple_client_id 留空表示不启用 Apple 登录
    apple_client_id: str = ""
    apple_team_id: str = ""
    apple_key_id: str = ""
    apple_private_key: str = ""

    # —— 菜谱图片（私有本地/S3 兼容适配器的最小配置） ——
    # 本地开发和测试写入此目录；部署时由对象存储适配器替换，不把公开 URL 存进数据库。
    recipe_media_dir: str = ".data/recipe-media"
    image_signing_secret: str = "dev-recipe-image-signing-secret"

    @property
    def cors_origin_regex(self) -> str | None:
        """开发和测试环境放行本机任意端口，方便网页版连本机服务端。"""
        if self.env in ("dev", "test"):
            return r"https?://(localhost|127\.0\.0\.1)(:\d+)?"
        return None

    @property
    def dev_tools_enabled(self) -> bool:
        """开发和测试环境才有的辅助接口（例如读出发给某个邮箱的验证码）。"""
        return self.env in ("dev", "test")

    @property
    def examples_enabled(self) -> bool:
        """示例接口只在非正式环境挂载，用来演示和测试全局约定。"""
        return self.env != "prod"


@lru_cache
def get_settings() -> Settings:
    return Settings()
