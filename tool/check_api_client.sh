#!/usr/bin/env bash
# CI 用：重新生成 OpenAPI 描述和 Dart 客户端，和仓库里的比较，不一致就失败。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPEC="$ROOT/api/openapi.json"
OUT="$ROOT/app/packages/gramtree_api"
"$ROOT/tool/gen_api_client.sh"
# Windows Git Bash can leave CRLF in generated text files. Normalize them before comparing so
# the contract check tests content rather than the host line-ending policy.
sed -i 's/\r$//' "$SPEC" "$OUT/.openapi-generator/FILES"
find "$OUT/lib" -type f -name '*.dart' -exec sed -i 's/\r$//' {} +

cd "$ROOT"
# A rewritten manifest can have stale index stat data on Windows even when its
# bytes are unchanged. Compare content in both diffs, and still reject new files.
paths=(api/openapi.json app/packages/gramtree_api)
untracked="$(git ls-files --others --exclude-standard -- "${paths[@]}")"
if ! git diff --quiet -- "${paths[@]}" ||
   ! git diff --cached --quiet -- "${paths[@]}" || [[ -n "$untracked" ]]; then
  echo "服务端接口和仓库里的 OpenAPI 描述或 Dart 客户端不一致："
  git status --short -- "${paths[@]}"
  git --no-pager diff --stat -- "${paths[@]}"
  echo "请运行 tool/gen_api_client.sh 并提交结果。"
  exit 1
fi
echo "OpenAPI 描述、Dart 客户端和服务端一致。"
