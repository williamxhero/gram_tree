#!/usr/bin/env bash
# CI 用：重新生成 OpenAPI 描述和 Dart 客户端，和仓库里的比较，不一致就失败。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPEC="$ROOT/api/openapi.json"
OUT="$ROOT/app/packages/gramtree_api"
"$ROOT/tool/gen_api_client.sh"
# Windows Git Bash can leave CRLF in the two top-level generated text files. Normalize those
# before comparing so the contract check tests content rather than the host line-ending policy.
sed -i 's/\r$//' "$SPEC" "$OUT/.openapi-generator/FILES"

cd "$ROOT"
changes="$(git status --porcelain -- api/openapi.json app/packages/gramtree_api)"
if [[ -n "$changes" ]]; then
  echo "服务端接口和仓库里的 OpenAPI 描述或 Dart 客户端不一致："
  echo "$changes"
  git --no-pager diff --stat -- api/openapi.json app/packages/gramtree_api
  echo "请运行 tool/gen_api_client.sh 并提交结果。"
  exit 1
fi
echo "OpenAPI 描述、Dart 客户端和服务端一致。"
