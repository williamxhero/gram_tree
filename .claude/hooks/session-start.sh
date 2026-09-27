#!/bin/bash
# 云端会话启动时装好开发和测试需要的全部东西（只在 Claude Code on the web 里运行）。
# 幂等：已装好的会跳过。详见 CLAUDE.md 的“云端环境”一节。
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
FLUTTER_VERSION="3.47.5"
FLUTTER_HOME="/opt/flutter"
TOOLS="/opt/gramtree-tools"
mkdir -p "$TOOLS/bin"

log() { echo "[session-start] $*" >&2; }

# ---------- PostgreSQL 16 + pgvector、Redis ----------
if ! ls /usr/share/postgresql/16/extension/vector.control >/dev/null 2>&1; then
  log "installing pgvector"
  apt-get install -y -q postgresql-16-pgvector >/dev/null 2>&1 \
    || { apt-get update -q >/dev/null 2>&1 && apt-get install -y -q postgresql-16-pgvector >/dev/null; }
fi
service postgresql start >/dev/null 2>&1 || true
service redis-server start >/dev/null 2>&1 || true
for _ in $(seq 1 30); do
  pg_isready -q && break
  sleep 1
done
su postgres -c "psql -q -c \"ALTER USER postgres PASSWORD 'postgres';\"" >/dev/null
su postgres -c "psql -tAc \"SELECT 1 FROM pg_database WHERE datname='gramtree'\"" | grep -q 1 \
  || su postgres -c "createdb gramtree"

# ---------- Flutter ----------
if [ ! -x "$FLUTTER_HOME/bin/flutter" ] || ! "$FLUTTER_HOME/bin/flutter" --version 2>/dev/null | grep -q "Flutter $FLUTTER_VERSION"; then
  log "installing Flutter $FLUTTER_VERSION"
  rm -rf "$FLUTTER_HOME"
  curl -fsSL -o /tmp/flutter.tar.xz \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  tar xf /tmp/flutter.tar.xz -C /opt
  rm /tmp/flutter.tar.xz
fi
git config --global --get-all safe.directory | grep -qx "$FLUTTER_HOME" \
  || git config --global --add safe.directory "$FLUTTER_HOME"
export PATH="$FLUTTER_HOME/bin:$PATH"
flutter --disable-analytics >/dev/null 2>&1 || true
flutter config --no-cli-animations >/dev/null 2>&1 || true

# ---------- 网页测试：Chromium（预装）+ 同版本 chromedriver ----------
CHROMIUM="$(ls -d /opt/pw-browsers/chromium-*/chrome-linux/chrome 2>/dev/null | head -1 || true)"
if [ -n "$CHROMIUM" ]; then
  # 以 root 运行需要 --no-sandbox；chromedriver 按 PATH 里的 google-chrome 找浏览器
  cat > "$TOOLS/bin/google-chrome" <<WRAP
#!/bin/sh
exec "$CHROMIUM" --no-sandbox "\$@"
WRAP
  chmod +x "$TOOLS/bin/google-chrome"
  CHROME_VERSION="$("$CHROMIUM" --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')"
  if [ ! -x "$TOOLS/bin/chromedriver" ] || ! "$TOOLS/bin/chromedriver" --version | grep -q "$CHROME_VERSION"; then
    log "installing chromedriver $CHROME_VERSION"
    curl -fsSL -o /tmp/chromedriver.zip \
      "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VERSION}/linux64/chromedriver-linux64.zip"
    python3 -c "import zipfile; zipfile.ZipFile('/tmp/chromedriver.zip').extractall('/tmp/cd')"
    mv /tmp/cd/chromedriver-linux64/chromedriver "$TOOLS/bin/chromedriver"
    chmod +x "$TOOLS/bin/chromedriver"
    rm -rf /tmp/cd /tmp/chromedriver.zip
  fi
fi

# ---------- 项目依赖 ----------
(cd "$ROOT/server" && uv sync --quiet)
if [ -f "$ROOT/app/pubspec.yaml" ]; then
  (cd "$ROOT/app" && flutter pub get >/dev/null)
fi

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export PATH=\"$FLUTTER_HOME/bin:$HOME/.pub-cache/bin:$TOOLS/bin:\$PATH\""
    echo "export CHROME_EXECUTABLE=\"$TOOLS/bin/google-chrome\""
  } >> "$CLAUDE_ENV_FILE"
fi
log "ready"
