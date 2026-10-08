#!/usr/bin/env bash
# 网页版端到端测试：把 integration_test 编译成网页，在无界面的 Chromium 里跑。
# 用法：tool/web_test.sh [integration_test/某个文件.dart ...]（默认跑 integration_test 下全部）
#
# 需要：
#   CHROME_EXECUTABLE  Chromium/Chrome 可执行文件，传给 --chrome-binary（不传时 chromedriver 会用系统默认的 Chrome，
#                      版本可能和 chromedriver 不一致；云端会话由 session-start 钩子设好）
#   chromedriver       主版本和浏览器一致；在 PATH 里，或用 CHROMEDRIVER 指定
# 端到端测试连真的服务端：脚本先用 tool/e2e_server.sh 起一个（test 环境、空库），跑完关掉。
#   已经有服务端在跑时设 GRAMTREE_E2E_SERVER=external 跳过。
# 注意：必须用 --profile（debug 模式下结果回不来会卡住）；--no-web-resources-cdn 避免从 CDN 拉渲染引擎。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_BASE_URL="${API_BASE_URL:-http://localhost:${GRAMTREE_E2E_PORT:-8000}}"
cd "$ROOT/app"

CHROMEDRIVER="${CHROMEDRIVER:-chromedriver}"
FLUTTER="${FLUTTER:-flutter}"
PORT="${CHROMEDRIVER_PORT:-4444}"
if [[ $# -gt 0 ]]; then
  targets=("$@")
else
  mapfile -t targets < <(find integration_test -name '*_test.dart' | sort)
fi

"$CHROMEDRIVER" --port="$PORT" >/tmp/chromedriver.log 2>&1 &
driver_pid=$!
reachability_pid=""
REACHABILITY_TEST_URL="${REACHABILITY_TEST_URL:-http://127.0.0.1:${REACHABILITY_TEST_PORT:-8766}}"
if [[ " ${targets[*]} " == *api_reachability_test.dart* ]]; then
  reachability_fixture="$ROOT/tool/reachability_test_server.py"
  # Native Windows Python needs a drive-letter path, as in gen_api_client.sh.
  if command -v cygpath >/dev/null 2>&1; then
    reachability_fixture="$(cygpath -m "$reachability_fixture")"
  fi
  python3 "$reachability_fixture" --port="${REACHABILITY_TEST_PORT:-8766}" >/tmp/reachability-test.log 2>&1 &
  reachability_pid=$!
fi
cleanup() {
  [[ -z "$reachability_pid" ]] || kill "$reachability_pid" 2>/dev/null || true
  kill $driver_pid 2>/dev/null || true
  [[ "${GRAMTREE_E2E_SERVER:-}" == external ]] || "$ROOT/tool/e2e_server.sh" stop
}
trap cleanup EXIT
[[ "${GRAMTREE_E2E_SERVER:-}" == external ]] || "$ROOT/tool/e2e_server.sh" start
for _ in $(seq 1 50); do
  curl -fs "http://localhost:$PORT/status" >/dev/null 2>&1 && break
  sleep 0.2
done

status=0
for target in "${targets[@]}"; do
  echo "== $target"
  "$FLUTTER" drive --timeout=300 --profile --no-web-resources-cdn \
    --driver=test_driver/integration_test.dart \
    --target="$target" \
    -d web-server --browser-name=chrome --headless --driver-port="$PORT" \
    ${CHROME_EXECUTABLE:+--chrome-binary="$CHROME_EXECUTABLE"} \
    --dart-define=APP_ENV=dev \
    --dart-define=API_BASE_URL="$API_BASE_URL" \
    --dart-define=REACHABILITY_TEST_URL="$REACHABILITY_TEST_URL" || status=1
done
if [[ "$status" != 0 ]]; then
  cat "${GRAMTREE_E2E_LOG_FILE:-${TMPDIR:-/tmp}/gramtree_e2e_server_${GRAMTREE_E2E_PORT:-8000}.log}" || true
fi
exit $status
