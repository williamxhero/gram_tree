FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

# pg_dump/pg_restore 用于每日备份，rclone 用于把备份复制到服务器之外
RUN apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client rclone ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir "uv>=0.8,<0.9"

WORKDIR /srv
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project
COPY . .
RUN uv sync --frozen --no-dev

ENV PATH="/srv/.venv/bin:$PATH"
EXPOSE 8000
# 启动时先跑迁移、导入食材库,再起服务；数据库结构只能通过迁移修改
CMD ["sh", "-c", "alembic upgrade head && gramtree ingredients import data/ingredients && uvicorn gramtree.asgi:app --host 0.0.0.0 --port 8000 --proxy-headers --forwarded-allow-ips='*'"]
