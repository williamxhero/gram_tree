"""Client projection CLI keeps canonical defaults while producing valid Dart inputs."""

import json
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
