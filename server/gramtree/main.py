from fastapi import APIRouter, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from redis import Redis

from gramtree.accounts import dev as accounts_dev
from gramtree.accounts import router as accounts
from gramtree.accounts.apple import AppleClient, HttpAppleTransport
from gramtree.accounts.mailer import make_mail_sender
from gramtree.analytics import router as analytics
from gramtree.api import client_config, health
from gramtree.core.errors import install_error_handlers
from gramtree.core.logging import configure_logging
from gramtree.core.middleware import RequestContextMiddleware
from gramtree.db import make_engine, make_session_factory
from gramtree.events import dev as events_dev
from gramtree.events import router as events
from gramtree.ingredients import router as ingredients
from gramtree.legal import router as legal
from gramtree.recipes import router as recipes
from gramtree.settings import Settings, get_settings
from gramtree.ui_protocol import router as ui_protocol

API_PREFIX = "/v1"


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or get_settings()
    configure_logging(settings.log_level)
    check_settings(settings)

    app = FastAPI(
        title="味谱 GramTree API",
        version="1.0.0",
        description="味谱服务端接口。Dart 客户端由这份描述生成，不要手改生成代码。",
        # operationId 用函数名，生成的 Dart 方法名才简洁（例如 clientConfig()）
        generate_unique_id_function=lambda route: route.name,
    )
    app.state.settings = settings
    engine = make_engine(settings.database_url, settings.health_timeout_seconds)
    app.state.engine = engine
    app.state.session_factory = make_session_factory(engine)
    app.state.redis = Redis.from_url(
        settings.redis_url,
        socket_timeout=settings.health_timeout_seconds,
        socket_connect_timeout=settings.health_timeout_seconds,
    )
    app.state.mailer = make_mail_sender(settings)
    app.state.apple = AppleClient(settings, HttpAppleTransport())

    install_error_handlers(app)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[o.strip() for o in settings.cors_origins.split(",") if o.strip()],
        allow_origin_regex=settings.cors_origin_regex,
        allow_methods=["*"],
        allow_headers=["*"],
        expose_headers=["X-Request-ID"],
    )
    app.add_middleware(RequestContextMiddleware)

    v1 = APIRouter(prefix=API_PREFIX)
    v1.include_router(health.router)
    v1.include_router(client_config.router)
    v1.include_router(accounts.router)
    v1.include_router(accounts.me_router)
    v1.include_router(events.router)
    v1.include_router(analytics.router)
    v1.include_router(ingredients.router)
    v1.include_router(recipes.router)
    v1.include_router(ui_protocol.router)
    if settings.dev_tools_enabled:
        v1.include_router(accounts_dev.router)
        v1.include_router(events_dev.router)
    if settings.examples_enabled:
        from gramtree.examples.router import router as examples_router

        v1.include_router(examples_router)
    app.include_router(v1)
    app.include_router(legal.router)
    return app


DEV_AUTH_SECRET = Settings.model_fields["auth_secret"].default


def check_settings(settings: Settings) -> None:
    """正式和预发环境不能带着开发用的默认值启动。"""
    if settings.env in ("staging", "prod"):
        if settings.auth_secret == DEV_AUTH_SECRET or len(settings.auth_secret) < 32:
            raise RuntimeError("GRAMTREE_AUTH_SECRET 必须设置成至少 32 位的随机串")
        if settings.mail_backend != "smtp":
            raise RuntimeError("正式环境的 GRAMTREE_MAIL_BACKEND 必须是 smtp")
        if len(settings.image_signing_secret) < 32:
            raise RuntimeError("GRAMTREE_IMAGE_SIGNING_SECRET 必须设置成至少 32 位的随机串")
        if settings.recipe_storage_backend != "s3":
            raise RuntimeError("正式环境的 GRAMTREE_RECIPE_STORAGE_BACKEND 必须是 s3")
        if not settings.recipe_s3_bucket or not settings.recipe_s3_access_key_id:
            raise RuntimeError("正式环境必须配置 GRAMTREE_RECIPE_S3_BUCKET 和访问密钥")
        if not settings.recipe_s3_secret_access_key:
            raise RuntimeError("正式环境必须配置 GRAMTREE_RECIPE_S3_SECRET_ACCESS_KEY")
