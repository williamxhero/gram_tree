#!/usr/bin/env bash
# 给端到端测试起一个真的服务端：新建空库 gramtree_e2e、跑完全部迁移、在后台启动，等健康检查通过。
# 用法：tool/e2e_server.sh start | stop
#
# 服务端用 test 环境：验证码只存在内存里，可以从 /v1/dev/latest-email-code 读出来（测试环境才有这个接口）。
# 需要本机的 PostgreSQL（含 pgvector）和 Redis；地址可以用 GRAMTREE_E2E_PG（不带库名）和 GRAMTREE_E2E_REDIS 改。数据库名可用 GRAMTREE_E2E_DATABASE_NAME 改。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${GRAMTREE_E2E_PORT:-8000}"
PID_FILE="${GRAMTREE_E2E_PID_FILE:-${TMPDIR:-/tmp}/gramtree_e2e_server_${PORT}.pid}"
LOG_FILE="${GRAMTREE_E2E_LOG_FILE:-${TMPDIR:-/tmp}/gramtree_e2e_server_${PORT}.log}"
PG="${GRAMTREE_E2E_PG:-postgresql+psycopg://postgres:postgres@localhost:5432}"
DATABASE_NAME="${GRAMTREE_E2E_DATABASE_NAME:-gramtree_e2e}"

stop() {
  if [[ -f "$PID_FILE" ]]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null || true
    rm -f "$PID_FILE"
  fi
}

start() {
  stop
  cd "$ROOT/server"
  export GRAMTREE_ENV=test
  export GRAMTREE_DATABASE_URL="$PG/$DATABASE_NAME"
  export GRAMTREE_REDIS_URL="${GRAMTREE_E2E_REDIS:-redis://localhost:6379/14}"
  export GRAMTREE_MAIL_BACKEND=memory

  uv run python - "$PG" "$DATABASE_NAME" <<'EOF'
import sys

import psycopg
import redis
from psycopg import sql

from gramtree.settings import Settings

url = sys.argv[1].replace("postgresql+psycopg://", "postgresql://") + "/postgres"
database = sys.argv[2]
with psycopg.connect(url, autocommit=True) as conn:
    conn.execute(sql.SQL("DROP DATABASE IF EXISTS {} WITH (FORCE)").format(sql.Identifier(database)))
    conn.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(database)))
redis.Redis.from_url(Settings().redis_url).flushdb()
EOF
  uv run alembic upgrade head >/dev/null
  uv run gramtree ingredients import tests/data/ingredients >/dev/null
  if [[ -n "${GRAMTREE_E2E_COMPOSITION_TIMEOUT_MS:-}" ]]; then
    uv run gramtree config set ui.composition_timeout_ms \
      "$GRAMTREE_E2E_COMPOSITION_TIMEOUT_MS" \
      --by e2e \
      --reason "给模拟器网络往返留出组合页面加载时间"
  fi

  # 单进程运行：验证码存在进程内存里，多进程时读不到
  nohup uv run uvicorn gramtree.asgi:app --host 0.0.0.0 --port "$PORT" >"$LOG_FILE" 2>&1 &
  echo $! >"$PID_FILE"
  for _ in $(seq 1 100); do
    if curl -fs "http://localhost:$PORT/v1/health" >/dev/null 2>&1; then
      echo "e2e server ready on :$PORT (log: $LOG_FILE)"
      return 0
    fi
    sleep 0.2
  done
  echo "e2e server did not start; log follows" >&2
  cat "$LOG_FILE" >&2
  stop
  return 1
}

case "${1:-}" in
  start) start ;;
  stop) stop ;;
  *) echo "usage: $0 start|stop" >&2; exit 2 ;;
esac
