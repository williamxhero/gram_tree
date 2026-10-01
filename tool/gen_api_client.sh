#!/usr/bin/env bash
# 从服务端导出 OpenAPI 描述，再生成 App 用的 Dart 客户端（dart-dio + json_serializable）。
# 生成的代码不要手改；服务端接口改了就重跑这个脚本，把结果一起提交。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GENERATOR_VERSION="7.16.0"
JAR="${OPENAPI_GENERATOR_JAR:-$HOME/.cache/gramtree/openapi-generator-cli-$GENERATOR_VERSION.jar}"
SPEC="$ROOT/api/openapi.json"
OUT="$ROOT/app/packages/gramtree_api"

if [[ ! -f "$JAR" ]]; then
  mkdir -p "$(dirname "$JAR")"
  curl -fsSL -o "$JAR.tmp" \
    "https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/$GENERATOR_VERSION/openapi-generator-cli-$GENERATOR_VERSION.jar"
  mv "$JAR.tmp" "$JAR"
fi

(cd "$ROOT/server" && uv run --quiet gramtree openapi --out "$SPEC")

CLIENT_SPEC="$(mktemp)"
trap 'rm -f "$CLIENT_SPEC"' EXIT
(cd "$ROOT/server" && uv run --quiet python "$ROOT/tool/prepare_api_client.py" "$SPEC" "$CLIENT_SPEC")

rm -rf "$OUT"
java -jar "$JAR" generate --skip-validate-spec \
  -i "$CLIENT_SPEC" -g dart-dio -o "$OUT" \
  --global-property=apiTests=false,modelTests=false,apiDocs=false,modelDocs=false \
  --additional-properties=pubName=gramtree_api,pubVersion=1.0.0,pubDescription="GramTree API client (generated)",serializationLibrary=json_serializable \
  >/dev/null

# 生成的 json_serializable 代码用到 null-aware elements，需要 Dart 3.8
sed -i.bak "s/sdk: '>=3.5.0 <4.0.0'/sdk: '>=3.8.0 <4.0.0'/" "$OUT/pubspec.yaml" && rm "$OUT/pubspec.yaml.bak"
rm -rf "$OUT/doc" "$OUT/test" "$OUT/README.md" "$OUT/.travis.yml" "$OUT/git_push.sh"

cd "$OUT"
if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_ROOT="${GRAMTREE_FLUTTER_ROOT:-$HOME/.cache/gramtree/flutter}"
  if [[ -x "$FLUTTER_ROOT/bin/flutter" ]]; then
    PATH="$FLUTTER_ROOT/bin:$PATH"
    export PATH
  fi
fi
flutter pub get >/dev/null
dart run build_runner build --delete-conflicting-outputs >/dev/null
dart format lib >/dev/null
echo "generated $OUT"
