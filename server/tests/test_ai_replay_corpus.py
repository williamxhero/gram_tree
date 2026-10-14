"""Synthetic browser recordings must cover the actual HTTP generation payloads."""

import json
import subprocess
import sys
from pathlib import Path

import pytest

from tests.accounts_support import bearer
from tests.test_ai_recipes import cli, generate

ROOT = Path(__file__).resolve().parents[2]
CONSEQUENTIAL = json.loads(
    (ROOT / "server/tests/fixtures/ai/taste_substitution_modification_corpus.json").read_text(
        "utf-8"
    )
)


@pytest.fixture
def replay_recordings(monkeypatch, tmp_path):
    monkeypatch.setenv("GRAMTREE_AI_MODE", "replay")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    return tmp_path


@pytest.fixture
def replay_api(replay_recordings, api):
    return api


@pytest.mark.parametrize("scenario", ["taste", "substitution"])
def test_materialized_corpus_normalizes_consequential_generation(
    replay_api, replay_recordings, scenario
):
    api, directory = replay_api, replay_recordings
    cli("ingredients", "import", str(ROOT / "server/tests/data/ingredients"))
    subprocess.run(
        [
            sys.executable,
            str(ROOT / "tool/ai_replay_corpus.py"),
            "--out",
            str(directory),
            "--import-substitution-library",
        ],
        check=True,
    )
    headers = bearer(api.login(f"replay-{scenario}@example.com"))
    requested = api.client.post(
        "/v1/ai/recipes/requests",
        headers=headers,
        json={"text": CONSEQUENTIAL[scenario]["generation_text"]},
    )
    assert requested.status_code == 200, requested.text
    generated = generate(api, headers, requested.json()["request_id"])
    assert generated["error"] is None, generated
    user = api.client.get("/v1/me", headers=headers).json()
    calls = cli("ai", "audit", "--user", user["id"])["calls"]
    normalization = [call for call in calls if call["capability"] == "normalize"]
    # Generation tolerates normalization failure, so its successful response alone
    # cannot prove that the semantic replay key matched the runtime request.
    assert normalization, calls
    assert all(call["status"] == "succeeded" for call in normalization), normalization
