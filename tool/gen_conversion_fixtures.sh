#!/usr/bin/env bash
# 把服务端和 App 共用的换算测试表（app/assets/*_cases.json）内嵌成 Dart 常量
# （app/test/fixtures/conversion_cases.g.dart），供页面测试读取。
#
# 原因和 tool/gen_ui_protocol_schemas.sh 相同：rootBundle.loadString() 在
# `flutter test --platform chrome` 下读资产会卡住不返回（见
# docs/adr/0005-界面描述协议共享契约.md），内嵌成编译期常量后两种平台都能跑同一份表。
# JSON 文件本身仍然是唯一来源（服务端测试直接读它）；改了测试表就重跑这个脚本，
# 把生成结果一起提交，不要手改生成的 .g.dart。`flutter test` 里有一条检查会比对两者。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/app/test/fixtures/conversion_cases.g.dart"
PYTHON="${PYTHON:-python3}"

"$PYTHON" - "$ROOT/app" "$OUT" <<'PY'
import sys
from pathlib import Path

ASSETS = [
    "assets/serving_conversion_cases.json",
    "assets/mold_conversion_cases.json",
    "assets/measure_display_cases.json",
    "assets/rounding_boundary_cases.json",
]


def dart_string_literal(value: str) -> str:
    out = ['"']
    for ch in value:
        if ch == "\\":
            out.append("\\\\")
        elif ch == '"':
            out.append('\\"')
        elif ch == "$":
            out.append("\\$")
        elif ch == "\n":
            out.append("\\n")
        elif ch == "\t":
            out.append("\\t")
        elif ch == "\r":
            out.append("\\r")
        elif ord(ch) < 0x20:
            out.append(f"\\u{ord(ch):04x}")
        else:
            out.append(ch)
    out.append('"')
    return "".join(out)


app_dir = Path(sys.argv[1])
out_path = Path(sys.argv[2])
lines = [
    "// GENERATED FILE — DO NOT EDIT.",
    "// 运行 tool/gen_conversion_fixtures.sh 从 app/assets/*_cases.json 重新生成。",
    "",
    "/// asset 路径到服务端和 App 共用换算测试表的原始 JSON 文本。",
    "const Map<String, String> embeddedConversionCases = {",
]
for asset in ASSETS:
    text = (app_dir / asset).read_text(encoding="utf-8")
    lines.append(f"  {dart_string_literal(asset)}: {dart_string_literal(text)},")
lines += ["};", ""]
out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text("\n".join(lines), encoding="utf-8", newline="\n")
print(f"generated {out_path} ({len(ASSETS)} fixture files)")
PY

(cd "$ROOT/app" && dart format test/fixtures/conversion_cases.g.dart)
