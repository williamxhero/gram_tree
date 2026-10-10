"""Explanation timeout/freshness at the real compatible-provider HTTP boundary."""

import json
from concurrent.futures import ThreadPoolExecutor
from contextlib import suppress
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import Event, Thread

import pytest
from fastapi.testclient import TestClient

from gramtree.main import create_app
from tests.accounts_support import bearer
from tests.conftest import make_settings
from tests.test_ai_recipes import cli, configure
from tests.test_change_explanations import EXPLANATIONS, manual_change
from tests.test_change_explanations import explanation_recordings as explanation_recordings
from tests.test_change_explanations import replay_explanation_api as replay_explanation_api
from tests.test_recipe_modifications import choice, propose
from tests.test_recipes import recipe_input


@pytest.fixture
def delayed_explanation_provider():
    arrived, release = Event(), Event()
    receipts = []

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, format, *args):
            pass

        def do_POST(self):
            body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            receipts.append(body)
            arrived.set()
            if not release.wait(timeout=15):
                self.send_error(504)
                return
            data = {
                "choices": [{"message": {"content": json.dumps(EXPLANATIONS["manual"])}}],
                "usage": {"prompt_tokens": 120, "completion_tokens": 240},
            }
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            # The timeout test intentionally disconnects the provider.
            with suppress(BrokenPipeError, ConnectionResetError, ConnectionAbortedError):
                self.wfile.write(json.dumps(data).encode())

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    server.daemon_threads = True
    thread = Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        yield f"http://127.0.0.1:{server.server_port}", arrived, release, receipts
    finally:
        release.set()
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)


def configure_explanation_provider(base_url, timeout: float = 15):
    configure(
        "ai.models",
        {
            "small": {
                "provider": "synthetic",
                "base_url": base_url,
                "model": "small",
                "input_price": 1,
                "output_price": 2,
            },
            "large": {"provider": "synthetic", "base_url": base_url, "model": "large"},
            "vector": {"provider": "synthetic", "base_url": base_url, "model": "vector"},
        },
    )
    configure(
        "ai.policies", {"change_explanation": {"timeout": timeout, "retries": 0, "daily_limit": 50}}
    )


def test_gateway_timeout_returns_failure_with_reserved_cost_and_manual_save_available(
    api, delayed_explanation_provider
):
    base_url, arrived, release, _receipts = delayed_explanation_provider
    headers = bearer(api.login("explanation-timeout@example.com"))
    created, changed, body, _payload = manual_change(api, headers)
    configure_explanation_provider(base_url, timeout=0.1)
    try:
        with TestClient(
            create_app(make_settings(ai_mode="live", ai_api_key="synthetic-test-placeholder")),
            raise_server_exceptions=False,
        ) as client:
            response = client.post("/v1/ai/recipes/change-explanation", headers=headers, json=body)
        assert arrived.is_set()
        assert response.status_code == 200, response.text
        assert response.json()["error"] == "model_unavailable"
        assert response.json()["change_note"] is None
    finally:
        release.set()
    user_id = api.client.get("/v1/me", headers=headers).json()["id"]
    calls = cli("ai", "audit", "--user", user_id)["calls"]
    assert len(calls) == 1 and calls[0]["status"] == "failed"
    assert calls[0]["reserved_cost"] > 0 and calls[0]["capability"] == "change_explanation"
    saved = api.client.post(
        f"/v1/recipes/{created['id']}/versions",
        headers=headers,
        json={"snapshot": changed, "change_note": "超时后作者手写用量调整"},
    )
    assert saved.status_code == 201, saved.text


def test_late_explanation_response_cannot_be_returned_for_updated_confirmed_decisions(
    replay_explanation_api, delayed_explanation_provider
):
    api, directory = replay_explanation_api
    base_url, arrived, release, receipts = delayed_explanation_provider
    headers = bearer(api.login("explanation-late@example.com"))
    created = api.client.post("/v1/recipes", headers=headers, json=recipe_input()).json()
    preview = propose(api, directory, headers, created)
    selected = choice(api, headers, preview, [{"operation_id": "wording-1", "decision": "accept"}])
    configure_explanation_provider(base_url)
    settings = make_settings(ai_mode="live", ai_api_key="synthetic-test-placeholder")
    with (
        TestClient(create_app(settings), raise_server_exceptions=False) as client,
        ThreadPoolExecutor(max_workers=1) as pool,
    ):
        pending = pool.submit(
            client.post,
            "/v1/ai/recipes/change-explanation",
            headers=headers,
            json={"modification_id": selected["id"], "revision": selected["revision"]},
        )
        try:
            assert arrived.wait(timeout=5)
            updated = choice(
                api,
                headers,
                selected,
                [{"operation_id": "wording-1", "decision": "modify", "after": "作者改成 3 厘米块"}],
            )
            assert updated["revision"] > selected["revision"]
        finally:
            release.set()
        response = pending.result(timeout=10)
    assert (
        response.status_code == 409
        and response.json()["error"]["code"] == "stale_modification_decisions"
    ), response.text
    assert len(receipts) == 1
    assert "JSON schema" in receipts[0]["messages"][0]["content"]
    payload = json.loads(receipts[0]["messages"][1]["content"])
    assert list(payload) == ["operations"]
    assert payload["operations"][0]["after"] == "将鸡肉切成 2 厘米块，放入碗中"
    assert set(payload["operations"][0]) == {"type", "id", "field", "before", "after", "intent"}
    saved = api.client.post(
        f"/v1/ai/recipes/modifications/{updated['id']}/confirm",
        headers=headers,
        json={"revision": updated["revision"], "change_note": "作者手写 3 厘米块"},
    )
    assert saved.status_code == 201, saved.text
