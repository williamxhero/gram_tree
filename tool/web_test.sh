#!/usr/bin/env bash
# 网页版端到端测试：把 integration_test 编译成网页，在无界面的 Chromium 里跑。
# 用法：tool/web_test.sh [integration_test/某个文件.dart ...]（默认跑 integration_test 下全部）
#
# 需要：
#   CHROME_EXECUTABLE  Chromium/Chrome 可执行文件，传给 --chrome-binary（不传时 chromedriver 会用系统默认的 Chrome，
#                      版本可能和 chromedriver 不一致；云端会话由 session-start 钩子设好）
#   chromedriver       主版本和浏览器一致；在 PATH 里，或用 CHROMEDRIVER 指定
# 注意：必须用 --profile（debug 模式下结果回不来会卡住）；--no-web-resources-cdn 避免从 CDN 拉渲染引擎。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/app"

CHROMEDRIVER="${CHROMEDRIVER:-chromedriver}"
PORT="${CHROMEDRIVER_PORT:-4444}"
if [[ $# -gt 0 ]]; then
  targets=("$@")
else
  mapfile -t targets < <(find integration_test -name '*_test.dart' | sort)
fi

"$CHROMEDRIVER" --port="$PORT" >/tmp/chromedriver.log 2>&1 &
driver_pid=$!
trap 'kill $driver_pid 2>/dev/null || true' EXIT
for _ in $(seq 1 50); do
  curl -fs "http://localhost:$PORT/status" >/dev/null 2>&1 && break
  sleep 0.2
done

status=0
for target in "${targets[@]}"; do
  echo "== $target"
  flutter drive --profile --no-web-resources-cdn \
    --driver=test_driver/integration_test.dart \
    --target="$target" \
    -d web-server --browser-name=chrome --headless \
    ${CHROME_EXECUTABLE:+--chrome-binary="$CHROME_EXECUTABLE"} \
    --dart-define=APP_ENV=dev || status=1
done
exit $status
