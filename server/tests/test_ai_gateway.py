"""Replaceable model protocol acceptance through HTTP and operator commands."""

import json
import threading
from collections.abc import Iterator
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import pytest

from tests.accounts_support import Api, bearer
from tests.test_ai_recipes import CORPUS, begin, cli, configure, generate


@pytest.fixture
def provider(monkeypatch, tmp_path: Path) -> Iterator[tuple[str, Path, list[dict]]]:
    receipts: list[dict] = []

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, format: str, *args):
            pass

        def do_POST(self):
            body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            receipts.append({"path": self.path, "body": body})
            if self.path.endswith("embeddings"):
                response = {"data": [{"embedding": CORPUS["embedding"]}]}
            else:
                payload = json.loads(body["messages"][1]["content"])
                if "names" in payload:
                    output = CORPUS["normalization"]
                elif "intent" in payload:
                    output = CORPUS["valid"]
                else:
                    output = CORPUS["intent"]
                response = {"choices": [{"message": {"content": json.dumps(output)}}]}
            response["usage"] = CORPUS["usage"]
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    monkeypatch.setenv("GRAMTREE_AI_MODE", "record")
    monkeypatch.setenv("GRAMTREE_AI_API_KEY", "synthetic-test-placeholder")
    monkeypatch.setenv("GRAMTREE_AI_REPLAY_DIR", str(tmp_path))
    try:
        yield f"http://127.0.0.1:{server.server_port}", tmp_path, receipts
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


@pytest.fixture
def record_api(provider, api: Api) -> Api:
    return api


def test_provider_routes_can_switch_and_refresh_sanitized_recordings(record_api, provider):
    base_url, recordings, receipts = provider
    headers = bearer(record_api.login("provider@example.com"))
    user = record_api.client.get("/v1/me", headers=headers).json()
    for name in ("first", "second"):
        configure(
            "ai.models",
            {
                tier: {
                    "provider": name,
                    "base_url": f"{base_url}/{name}",
                    "model": f"{name}-{tier}",
                    "input_price": 1,
                    "output_price": 2,
                }
                for tier in ("small", "large", "vector")
            },
        )
        found = begin(record_api, headers)
        assert found["local_fallback"] is False
        result = generate(record_api, headers, found["request_id"])
        assert result["draft"]["recipe"]["snapshot"]["servings"] == 2
        assert result["error"] is None
    calls = cli("ai", "audit", "--user", user["id"])["calls"]
    assert {c["provider"] for c in calls} == {"first", "second"}
    assert all(c["status"] == "succeeded" and c["cost"] > 0 for c in calls)
    assert {r["body"]["model"] for r in receipts} == {
        f"{name}-{tier}" for name in ("first", "second") for tier in ("small", "large", "vector")
    }
    assert any(
        "JSON schema" in r["body"]["messages"][0]["content"]
        for r in receipts
        if r["body"]["model"].endswith("large")
    )
    recorded = list(recordings.glob("*.json"))
    assert len(recorded) == 4  # Stable semantic replay keys, refreshed on provider switch.
    for path in recorded:
        content = path.read_text(encoding="utf-8")
        assert "synthetic-test-placeholder" not in content
        assert user["id"] not in content
        assert "provider@example.com" not in content
        assert json.loads(content)["usage"]["prompt_tokens"] == 120
