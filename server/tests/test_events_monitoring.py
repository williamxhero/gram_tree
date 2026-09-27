"""SPEC-010.1 票 3：上传监控指标（gramtree.events.metrics）和告警（gramtree.events.alerts）。"""

import json
import threading
from collections.abc import Iterator
from http.server import BaseHTTPRequestHandler, HTTPServer

import pytest
from redis import Redis

from gramtree.cli import main as cli
from gramtree.core.time import utcnow
from gramtree.events import metrics as events_metrics
from gramtree.tasks.jobs import check_events_alerts
from tests.accounts_support import Api, bearer, new_uuid
from tests.conftest import TEST_REDIS_URL


def _event(**overrides: object) -> dict:
    body = {
        "id": new_uuid(),
        "event_type": "pipeline.self_check",
        "type_version": 1,
        "device_id": "device-1",
        "device_time": utcnow().isoformat(),
        "app_version": "1.0.0",
        "content": {"ping": "pong"},
    }
    body.update(overrides)
    return body


def _redis() -> Redis:
    return Redis.from_url(TEST_REDIS_URL)


def set_config(key: str, value: str) -> None:
    assert cli(["config", "set", key, value, "--by", "test", "--reason", "测试"]) == 0


def run_check() -> dict:
    return check_events_alerts.apply().get()


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


# —— 上传后能读到上传量、重复数、拒收数、延迟 ——


def test_upload_records_accepted_duplicate_rejected_counts_and_delay(api: Api) -> None:
    tokens = api.login("cook@example.com")
    e1, e2 = _event(), _event()

    api.client.post("/v1/events/upload", json={"events": [e1, e2]}, headers=bearer(tokens))
    api.client.post("/v1/events/upload", json={"events": [e1]}, headers=bearer(tokens))  # 重复
    bad = _event(event_type="nonexistent.type", content={})
    api.client.post("/v1/events/upload", json={"events": [bad]}, headers=bearer(tokens))  # 拒收

    stats = events_metrics.window(_redis(), minutes=5)
    assert stats.accepted == 2
    assert stats.duplicate == 1
    assert stats.rejected == 1
    assert stats.total == 4
    assert stats.duplicate_rate == pytest.approx(0.25)
    assert stats.reject_rate == pytest.approx(0.25)
    # device_time 就是"现在"，延迟应该是个很小的数（正负都可能，取决于请求耗时）
    assert abs(stats.avg_delay_ms) < 30_000


def test_upload_with_no_accepted_events_has_no_delay_samples(api: Api) -> None:
    tokens = api.login("cook@example.com")
    bad = _event(event_type="nonexistent.type", content={})
    api.client.post("/v1/events/upload", json={"events": [bad]}, headers=bearer(tokens))

    stats = events_metrics.window(_redis(), minutes=5)
    assert stats.rejected == 1
    assert stats.avg_delay_ms == 0.0


# —— 重复率/拒收率超阈值告警 ——


def test_duplicate_rate_over_threshold_alerts(api: Api, webhook: str) -> None:
    set_config("ops.alert_channel", "webhook")
    set_config("ops.alert_target", webhook)
    set_config("events.alert_min_events", "2")
    set_config("events.alert_duplicate_rate", "0.0")

    tokens = api.login("cook@example.com")
    event = _event()
    api.client.post("/v1/events/upload", json={"events": [event]}, headers=bearer(tokens))
    api.client.post("/v1/events/upload", json={"events": [event]}, headers=bearer(tokens))

    result = run_check()
    assert result["sent"] is True
    assert any("重复率" in p for p in result["problems"])
    assert len(_Receiver.received) == 1

    # 同一窗口内不重复发
    assert run_check()["sent"] is False
    assert len(_Receiver.received) == 1


def test_reject_rate_over_threshold_alerts(api: Api, webhook: str) -> None:
    set_config("ops.alert_channel", "webhook")
    set_config("ops.alert_target", webhook)
    set_config("events.alert_min_events", "1")
    set_config("events.alert_reject_rate", "0.0")

    tokens = api.login("cook@example.com")
    bad = _event(event_type="nonexistent.type", content={})
    api.client.post("/v1/events/upload", json={"events": [bad]}, headers=bearer(tokens))

    result = run_check()
    assert result["sent"] is True
    assert any("拒收率" in p for p in result["problems"])


def test_below_min_events_does_not_alert(api: Api, webhook: str) -> None:
    set_config("ops.alert_channel", "webhook")
    set_config("ops.alert_target", webhook)
    set_config("events.alert_min_events", "1000")
    set_config("events.alert_duplicate_rate", "0.0")

    tokens = api.login("cook@example.com")
    event = _event()
    api.client.post("/v1/events/upload", json={"events": [event]}, headers=bearer(tokens))
    api.client.post("/v1/events/upload", json={"events": [event]}, headers=bearer(tokens))

    result = run_check()
    assert result["problems"] == []
    assert _Receiver.received == []


def test_rates_within_thresholds_do_not_alert(api: Api, webhook: str) -> None:
    set_config("ops.alert_channel", "webhook")
    set_config("ops.alert_target", webhook)
    set_config("events.alert_min_events", "1")

    tokens = api.login("cook@example.com")
    event = _event()
    api.client.post("/v1/events/upload", json={"events": [event]}, headers=bearer(tokens))

    result = run_check()
    assert result["problems"] == []
    assert _Receiver.received == []
