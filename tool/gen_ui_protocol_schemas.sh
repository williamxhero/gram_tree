#!/usr/bin/env bash
# 把 app/assets/contracts/ui_protocol/ 下的 Schema 和测试样例内嵌成 Dart 常量
# （app/lib/ui_protocol/embedded_assets.g.dart）。
#
# 原因：Schema 在 App 端渲染前用来校验服务端下发的页面描述（SPEC-009.1 #77），
# 样例是服务端和 App 测试共用的合法/不合法页面描述。实测通过 rootBundle.loadString()
# 读这个目录下的文件，在同一个测试文件里第二次触发时会永远卡住不返回——Schema 那份是
# 被 Riverpod FutureProvider 持有时在 `flutter test`（VM）里复现，样例那份是在测试体里
# 直接调用时在 `flutter test --platform chrome`（web）里复现，具体原因见
# docs/adr/0005-界面描述协议共享契约.md。内嵌成编译期常量彻底绕开这整类问题。
# 契约文件本身仍然是唯一来源，这个脚本只是把内容复制成 Dart 字符串；改了 Schema 或
# 新增样例就重跑这个脚本，把生成结果和源文件一起提交，不要手改生成的 .g.dart。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONTRACTS_DIR="$ROOT/app/assets/contracts/ui_protocol"
OUT="$ROOT/app/lib/ui_protocol/embedded_assets.g.dart"

python3 - "$CONTRACTS_DIR" "$OUT" <<'PY'
import sys
from pathlib import Path


def dart_string_literal(value: str) -> str:
    # Dart 双引号字符串：反斜杠、双引号、$（插值）都要转义；控制字符用 \uXXXX。
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


def collect(base_dir: Path, glob: str, app_dir: Path) -> list[tuple[str, str]]:
    entries = []
    for path in sorted(base_dir.rglob(glob)):
        asset_key = path.relative_to(app_dir).as_posix()
        entries.append((asset_key, path.read_text(encoding="utf-8")))
    return entries


def render_map(name: str, entries: list[tuple[str, str]]) -> list[str]:
    lines = [f"const Map<String, String> {name} = {{"]
    for asset_key, text in entries:
        lines.append(f"  {dart_string_literal(asset_key)}: {dart_string_literal(text)},")
    lines.append("};")
    return lines


contracts_dir = Path(sys.argv[1])
out_path = Path(sys.argv[2])
app_dir = contracts_dir.parents[2]  # .../app/assets/contracts/ui_protocol -> app/

schemas = collect(contracts_dir / "schema", "*.schema.json", app_dir)
samples = collect(contracts_dir / "samples", "*.json", app_dir)

if not schemas:
    raise SystemExit(f"no .schema.json files found under {contracts_dir / 'schema'}")
if not samples:
    raise SystemExit(f"no sample .json files found under {contracts_dir / 'samples'}")

lines = [
    "// GENERATED FILE — DO NOT EDIT.",
    "// 运行 tool/gen_ui_protocol_schemas.sh 从 app/assets/contracts/ui_protocol/ 重新生成。",
    "",
    "/// asset 路径（和 protocol_paths.dart 里算出的键一致）到 Schema 原始 JSON 文本。",
    "/// 为什么内嵌成常量而不是运行时用 rootBundle 读：见 tool/gen_ui_protocol_schemas.sh 顶部的注释。",
    *render_map("embeddedUiProtocolSchemas", schemas),
    "",
    "/// asset 路径到两端共用测试样例的原始 JSON 文本（SPEC-009.1 #77）。",
    *render_map("embeddedUiProtocolSamples", samples),
    "",
]

out_path.write_text("\n".join(lines), encoding="utf-8")
print(f"generated {out_path} ({len(schemas)} schema files, {len(samples)} sample files)")
PY

(cd "$ROOT/app" && dart format lib/ui_protocol/embedded_assets.g.dart)
