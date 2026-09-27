# 味谱 GramTree — 服务端

FastAPI + SQLAlchemy + Alembic，PostgreSQL 16（pgvector）、Redis、Celery。选型和约定见 `../docs/adr/`。

## 本机启动

```bash
docker compose up          # API http://localhost:8000/v1/health、数据库、Redis、任务进程
```

不用 Docker 时（云端会话已由启动钩子装好 PostgreSQL 和 Redis）：

```bash
uv sync
uv run alembic upgrade head
uv run uvicorn gramtree.asgi:app --reload
uv run celery -A gramtree.tasks.celery_app worker --beat -l info
```

## 目录

| 路径 | 内容 |
|---|---|
| `gramtree/main.py` | 组装应用：中间件、错误处理、`/v1` 路由 |
| `gramtree/core/` | 全局约定：ID、时间、错误格式、请求编号、日志、分页 |
| `gramtree/runtime_config/` | 服务端配置项和能力开关（登记表在 `registry.py`） |
| `gramtree/api/` | 对外接口（健康检查、App 配置） |
| `gramtree/examples/` | 约定的参考写法，只在非正式环境挂载 |
| `gramtree/tasks/` | Celery 任务和定时任务 |
| `gramtree/observability/` | 接口指标和告警 |
| `gramtree/ops/` | 备份和恢复 |
| `migrations/` | Alembic 迁移（数据库结构只能在这里改） |
| `tests/` | 接口测试，连真实 PostgreSQL 和 Redis |
| `deploy/` | 单机部署、HTTPS、备份说明 |

## 常用命令

```bash
uv run ruff format . && uv run ruff check . && uv run pyright
uv run pytest -q
uv run alembic revision --autogenerate -m "说明"   # 改了模型后生成迁移，检查后提交
uv run gramtree config list                       # 服务端配置项
uv run gramtree config set <key> <value> --by <人> --reason <原因>
uv run gramtree openapi                           # 导出 OpenAPI；生成客户端用 ../tool/gen_api_client.sh
```

新数据表的模型要在 `gramtree/models.py` 里 import，Alembic 才能比对到。
