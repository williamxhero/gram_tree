"""接口出错率和耗时超过配置的阈值时告警。"""

import json
import threading
from collections.abc import Iterator
from http.server import BaseHTTPRequestHandler, HTTPServer

import pytest
from fastapi.testclient import TestClient

from gramtree.cli import main as cli
from gramtree.tasks.jobs import check_api_alerts


class _Receiver(BaseHTTPRequestHandler):
    received: list[dict] = []  # noqa: RUF012

    def do_POST(self) -> None:
        length = int(self.headers["Content-Length"])
        _Receiver.received.append(json.loads(self.rfile.read(length)))
        self.send_response(200)
        self.end_headers()

    def log_message(self, format: str, *args: object) -> None:
        pass


@pytest.fixture
def webhook() -> Iterator[str]:
    _Receiver.received = []
    server = HTTPServer(("127.0.0.1", 0), _Receiver)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    yield f"http://127.0.0.1:{server.server_port}/hook"
    server.shutdown()


def set_config(key: str, value: str) -> None:
    assert cli(["config", "set", key, value, "--by", "test", "--reason", "测试"]) == 0


def run_check() -> dict:
    return check_api_alerts.apply().get()


def test_error_rate_over_threshold_sends_webhook_alert(client: TestClient, webhook: str) -> None:
    set_config("ops.alert_channel", "webhook")
    set_config("ops.alert_target", webhook)
    set_config("ops.alert_min_requests", "5")
    for _ in range(5):
        client.get("/v1/health")
    for _ in range(5):
        client.get("/v1/examples/boom")

    result = run_check()
    assert result["total"] >= 10 and result["errors"] == 5
    assert result["sent"] is True
    assert len(_Receiver.received) == 1
    assert "错误率" in _Receiver.received[0]["text"]

    # 同一个窗口内不重复告警
    assert run_check()["sent"] is False
    assert len(_Receiver.received) == 1


def test_no_alert_below_threshold(client: TestClient, webhook: str) -> None:
    set_config("ops.alert_channel", "webhook")
    set_config("ops.alert_target", webhook)
    set_config("ops.alert_min_requests", "5")
    for _ in range(10):
        client.get("/v1/health")
    result = run_check()
    assert result["problems"] == []
    assert _Receiver.received == []


def test_slow_requests_trigger_latency_alert(client: TestClient, webhook: str) -> None:
    set_config("ops.alert_channel", "webhook")
    set_config("ops.alert_target", webhook)
    set_config("ops.alert_min_requests", "1")
    set_config("ops.alert_p95_ms", "50")
    # 数据库连不上时健康检查要等超时，天然就是一个慢接口
    from gramtree.main import create_app
    from tests.conftest import make_settings

    slow = make_settings(database_url="postgresql+psycopg://postgres:x@10.255.255.1:5432/none")
    with TestClient(create_app(slow), raise_server_exceptions=False) as c:
        c.get("/v1/health")
    result = run_check()
    assert any("耗时" in p for p in result["problems"])
    assert result["sent"] is True


def test_no_channel_configured_means_logged_but_not_sent(client: TestClient) -> None:
    set_config("ops.alert_min_requests", "1")
    client.get("/v1/examples/boom")
    result = run_check()
    assert result["problems"]
    assert result["sent"] is False
