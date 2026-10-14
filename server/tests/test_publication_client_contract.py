"""Client projection CLI keeps canonical defaults while producing valid Dart inputs."""

import json
import shutil
import subprocess
import sys
from pathlib import Path

import pytest


@pytest.mark.parametrize("name", ["PublicationPanel", "ImprovementPreviewInput"])
def test_publication_enum_default_is_explicit_only_in_generator_input(
    tmp_path: Path, name: str
) -> None:
    schema = {
        "type": "object",
        "properties": {
            "state": {"type": "string", "enum": ["draft", "published"], "default": "draft"},
            "note": {"anyOf": [{"type": "string"}, {"type": "null"}], "default": None},
        },
    }
    source = tmp_path / "canonical.json"
    target = tmp_path / "client.json"
    document = {"components": {"schemas": {name: schema}}}
    source.write_text(json.dumps(document), encoding="utf-8")
    script = Path(__file__).resolve().parents[2] / "tool" / "prepare_api_client.py"
    result = subprocess.run(
        [sys.executable, str(script), str(source), str(target)], capture_output=True, text=True
    )
    assert result.returncode == 0, result.stderr
    assert json.loads(source.read_text("utf-8")) == document
    projected = json.loads(target.read_text("utf-8"))["components"]["schemas"][name]
    assert projected["required"] == ["state"]
    assert projected["properties"]["state"] == {"type": "string", "enum": ["draft", "published"]}
    assert projected["properties"]["note"]["type"] == ["string", "null"]


@pytest.mark.parametrize("change", ["same", "tracked", "staged", "untracked", "deleted"])
def test_contract_checker_rejects_every_real_generated_change(tmp_path: Path, change: str) -> None:
    """Exercise the checker CLI without downloading or running a code generator."""
    root = tmp_path / "contract"
    tool = root / "tool"
    library = root / "app" / "packages" / "gramtree_api" / "lib"
    manifest = library.parent / ".openapi-generator" / "FILES"
    tool.mkdir(parents=True)
    library.mkdir(parents=True)
    manifest.parent.mkdir()
    (root / "api").mkdir()
    (root / "api" / "openapi.json").write_text("{}\n", encoding="utf-8", newline="\n")
    (library / "sample.dart").write_text("const sample = 1;\n", encoding="utf-8", newline="\n")
    manifest.write_text("lib/sample.dart\n", encoding="utf-8", newline="\n")
    checker = Path(__file__).resolve().parents[2] / "tool" / "check_api_client.sh"
    shutil.copyfile(checker, tool / checker.name)
    mutations = {
        "same": 'touch "$ROOT/app/packages/gramtree_api/.openapi-generator/FILES"',
        "tracked": 'printf "changed\\n" > "$ROOT/api/openapi.json"',
        "staged": 'cd "$ROOT"; printf "changed\\n" > api/openapi.json; git add api/openapi.json',
        "untracked": 'printf "new\\n" > "$ROOT/app/packages/gramtree_api/lib/new.dart"',
        "deleted": 'rm "$ROOT/app/packages/gramtree_api/lib/sample.dart"',
    }
    generator = tool / "gen_api_client.sh"
    generator.write_text(
        '#!/usr/bin/env bash\nset -euo pipefail\nROOT="$(cd "$(dirname "$0")/.." && pwd)"\n'
        + mutations[change]
        + "\n",
        encoding="utf-8",
        newline="\n",
    )
    generator.chmod(0o755)
    for arguments in [
        ["init", "--quiet"],
        ["config", "user.name", "Contract Test"],
        ["config", "user.email", "contract@example.invalid"],
        ["add", "."],
        ["commit", "--quiet", "-m", "baseline"],
    ]:
        subprocess.run(["git", *arguments], cwd=root, check=True, capture_output=True, text=True)
    # Windows can resolve bare bash to the WSL launcher before searching PATH.
    bash = shutil.which("bash")
    assert bash is not None, "The contract checker requires Bash on PATH"
    result = subprocess.run(
        [bash, (tool / checker.name).as_posix()],
        cwd=root,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    assert result.returncode == (0 if change == "same" else 1), result.stdout + result.stderr
    if change == "same":
        assert "OpenAPI 描述、Dart 客户端和服务端一致。" in result.stdout
    else:
        assert "服务端接口和仓库里的 OpenAPI 描述或 Dart 客户端不一致" in result.stdout
