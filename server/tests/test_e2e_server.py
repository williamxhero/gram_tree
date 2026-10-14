"""Acceptance bootstrap must support multiple logins from one runner IP."""

import os
import socket
import subprocess
import uuid
from pathlib import Path

import httpx
from sqlalchemy import create_engine, make_url, text

from tests.conftest import TEST_DATABASE_URL, TEST_REDIS_URL


def test_e2e_bootstrap_supports_more_than_one_hundred_logins(tmp_path: Path) -> None:
    root = Path(__file__).resolve().parents[2]
    database = f"gramtree_e2e_auth_{uuid.uuid4().hex}"
    target = make_url(TEST_DATABASE_URL).set(database=database)
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        port = sock.getsockname()[1]
    env = {
        **os.environ,
        "GRAMTREE_E2E_PG": target.render_as_string(hide_password=False).rsplit("/", 1)[0],
        "GRAMTREE_E2E_DATABASE_NAME": database,
        "GRAMTREE_E2E_REDIS": TEST_REDIS_URL,
        "GRAMTREE_E2E_PORT": str(port),
        "GRAMTREE_E2E_PID_FILE": (tmp_path / "server.pid").as_posix(),
        "GRAMTREE_E2E_LOG_FILE": (tmp_path / "server.log").as_posix(),
        "GRAMTREE_AI_REPLAY_DIR": (tmp_path / "replay").as_posix(),
    }
    command = [
        os.environ.get("GRAMTREE_TEST_BASH", "bash"),
        (root / "tool" / "e2e_server.sh").as_posix(),
    ]
    try:
        subprocess.run([*command, "start"], cwd=root, env=env, check=True, timeout=300)
        # Independent acceptance accounts share one runner IP/device. Only
        # burst budgets are enlarged; production daily budgets remain in force.
        for category, day_limit in (("search_list", 4800), ("auth", 1200), ("ai", 1200)):
            for dimension in ("account", "device", "ip"):
                for window, expected in (("minute", 1000), ("day", day_limit)):
                    configured = subprocess.run(
                        [
                            "uv",
                            "run",
                            "gramtree",
                            "config",
                            "get",
                            f"rate.{category}.{dimension}_per_{window}",
                        ],
                        cwd=root / "server",
                        env={
                            **env,
                            "GRAMTREE_DATABASE_URL": target.render_as_string(hide_password=False),
                        },
                        check=True,
                        capture_output=True,
                        text=True,
                        timeout=30,
                    )
                    assert int(configured.stdout.strip()) == expected
        with httpx.Client(base_url=f"http://127.0.0.1:{port}") as client:
            for index in range(101):
                response = client.post(
                    "/v1/auth/email/code",
                    json={"email": f"acceptance-{index}@example.com", "purpose": "login"},
                )
                assert response.status_code == 200, response.text
            # Only the daily budget is overridden, not the same-email cooldown.
            # Retry the latest address: 101 requests can outlast the first cooldown.
            response = client.post(
                "/v1/auth/email/code",
                json={"email": "acceptance-100@example.com", "purpose": "login"},
            )
            assert response.status_code == 429
            assert response.json()["error"]["code"] == "resend_too_soon"
            # Independent browser accounts also share the runner subnet. Exercise
            # actual logins beyond its production budget, not only code delivery.
            for index in range(11):
                email = f"acceptance-{index}@example.com"
                code = client.get("/v1/dev/latest-email-code", params={"email": email})
                assert code.status_code == 200
                response = client.post(
                    "/v1/auth/email/login", json={"email": email, "code": code.json()["code"]}
                )
                assert response.status_code == 200, response.text
    finally:
        try:
            subprocess.run([*command, "stop"], cwd=root, env=env, check=True, timeout=30)
        finally:
            admin = create_engine(target.set(database="postgres"), isolation_level="AUTOCOMMIT")
            try:
                with admin.connect() as connection:
                    connection.execute(text(f'DROP DATABASE IF EXISTS "{database}" WITH (FORCE)'))
            finally:
                admin.dispose()
