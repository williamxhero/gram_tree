from fastapi import APIRouter, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from redis import Redis

from gramtree.api import client_config, health
from gramtree.core.errors import install_error_handlers
from gramtree.core.logging import configure_logging
from gramtree.core.middleware import RequestContextMiddleware
from gramtree.db import make_engine, make_session_factory
from gramtree.settings import Settings, get_settings

API_PREFIX = "/v1"


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or get_settings()
    configure_logging(settings.log_level)

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
    if settings.examples_enabled:
        from gramtree.examples.router import router as examples_router

        v1.include_router(examples_router)
    app.include_router(v1)
    return app
