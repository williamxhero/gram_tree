"""服务端配置项和能力开关：命令行修改，接口立刻生效，留历史。"""

import pytest
from fastapi.testclient import TestClient

from gramtree.cli import main as cli


def test_client_config_defaults(client: TestClient) -> None:
    body = client.get("/v1/client-config").json()
    assert body["features"] == {
        "evolution_tree": False,
        "cooking_qa": False,
        "receipt_scan": False,
    }
    # 运维类配置不下发给 App
    assert not any(key.startswith("ops.") for key in body["params"])
    # SPEC-009.1 #79：等待组合接口的时限，初始 800 毫秒，经这个接口下发给 App
    assert body["params"]["ui.composition_timeout_ms"] == 800


def test_composition_timeout_change_takes_effect_immediately(client: TestClient) -> None:
    rc = cli(
        [
            "config",
            "set",
            "ui.composition_timeout_ms",
            "1500",
            "--by",
            "yosef",
            "--reason",
            "临时调大超时时限",
        ]
    )
    assert rc == 0
    body = client.get("/v1/client-config").json()
    assert body["params"]["ui.composition_timeout_ms"] == 1500


def test_feature_flag_change_takes_effect_immediately(client: TestClient) -> None:
    rc = cli(["config", "set", "feature.evolution_tree", "on", "--by", "yosef", "--reason", "内测"])
    assert rc == 0
    assert client.get("/v1/client-config").json()["features"]["evolution_tree"] is True


def test_change_history_is_recorded(capsys: pytest.CaptureFixture[str]) -> None:
    cli(["config", "set", "ops.alert_p95_ms", "800", "--by", "yosef", "--reason", "收紧"])
    cli(["config", "set", "ops.alert_p95_ms", "900", "--by", "ops", "--reason", "放宽一点"])
    capsys.readouterr()
    assert cli(["config", "history", "ops.alert_p95_ms"]) == 0
    lines = capsys.readouterr().out.strip().splitlines()
    assert len(lines) == 2
    assert "800 -> 900" in lines[0] and "by ops" in lines[0] and "放宽一点" in lines[0]
    assert "1500 -> 800" in lines[1] and "by yosef" in lines[1] and "收紧" in lines[1]


@pytest.mark.parametrize(
    ("key", "value"),
    [
        ("ops.alert_p95_ms", "10"),
        ("ops.alert_error_rate", "1.5"),
        ("ops.alert_channel", "pigeon"),
        ("feature.cooking_qa", "maybe"),
        ("api.page_size_max", "abc"),
    ],
)
def test_out_of_range_value_rejected(
    key: str, value: str, capsys: pytest.CaptureFixture[str]
) -> None:
    capsys.readouterr()
    cli(["config", "get", key])
    before = capsys.readouterr().out
    assert cli(["config", "set", key, value, "--by", "t", "--reason", "r"]) == 1
    assert "错误" in capsys.readouterr().err
    cli(["config", "get", key])
    assert capsys.readouterr().out == before
    cli(["config", "history", key])
    assert capsys.readouterr().out == ""


def test_unknown_key_rejected() -> None:
    assert cli(["config", "set", "nope.key", "1", "--by", "t", "--reason", "r"]) == 1


def test_reason_is_required() -> None:
    with pytest.raises(SystemExit):
        cli(["config", "set", "api.page_size_max", "50", "--by", "t"])
    assert cli(["config", "set", "api.page_size_max", "50", "--by", "t", "--reason", " "]) == 1
