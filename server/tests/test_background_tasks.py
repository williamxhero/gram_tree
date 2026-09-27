"""后台任务链路：接口触发 → 任务进程执行 → 结果可以通过接口查到。

这里启动一个真的 Celery 任务进程（线程内），连测试用的 Redis。
"""

import time
from collections.abc import Iterator

import pytest
from celery.contrib.testing.worker import start_worker
from fastapi.testclient import TestClient

from gramtree.tasks.celery_app import celery_app


@pytest.fixture
def worker(database_url: str) -> Iterator[None]:
    with start_worker(celery_app, perform_ping_check=False, loglevel="WARNING"):
        yield


def test_triggered_task_runs_and_result_is_visible(client: TestClient, worker: None) -> None:
    resp = client.post("/v1/examples/heartbeats")
    assert resp.status_code == 202
    assert resp.json()["task_id"]

    deadline = time.monotonic() + 15
    items: list[dict] = []
    while time.monotonic() < deadline:
        items = client.get("/v1/examples/heartbeats").json()
        if items:
            break
        time.sleep(0.2)
    assert [item["source"] for item in items] == ["api"]


def test_beat_schedule_has_sample_periodic_task() -> None:
    schedule = celery_app.conf.beat_schedule
    assert schedule["heartbeat"]["task"] == "gramtree.tasks.jobs.record_heartbeat"
    assert schedule["check-api-alerts"]["task"] == "gramtree.tasks.jobs.check_api_alerts"
