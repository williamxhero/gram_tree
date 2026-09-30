"""正式环境不能带着开发用的默认值启动。"""

import pytest

from gramtree.main import create_app
from tests.conftest import make_settings


def test_prod_refuses_default_auth_secret() -> None:
    with pytest.raises(RuntimeError, match="GRAMTREE_AUTH_SECRET"):
        create_app(make_settings(env="prod", mail_backend="smtp"))


def test_prod_refuses_memory_mail() -> None:
    with pytest.raises(RuntimeError, match="MAIL_BACKEND"):
        create_app(make_settings(env="prod", auth_secret="s" * 40))


def test_prod_has_no_dev_code_endpoint(database_url: str) -> None:
    from fastapi.testclient import TestClient

    app = create_app(
        make_settings(
            env="prod",
            auth_secret="s" * 40,
            image_signing_secret="i" * 40,
            mail_backend="smtp",
            recipe_storage_backend="s3",
            recipe_s3_bucket="test",
            recipe_s3_access_key_id="test",
            recipe_s3_secret_access_key="test",
        )
    )
    with TestClient(app) as c:
        assert c.get("/v1/dev/latest-email-code", params={"email": "a@b.cd"}).status_code == 404


def test_prod_has_no_dev_events_count_endpoint(database_url: str) -> None:
    from fastapi.testclient import TestClient

    app = create_app(
        make_settings(
            env="prod",
            auth_secret="s" * 40,
            image_signing_secret="i" * 40,
            mail_backend="smtp",
            recipe_storage_backend="s3",
            recipe_s3_bucket="test",
            recipe_s3_access_key_id="test",
            recipe_s3_secret_access_key="test",
        )
    )
    with TestClient(app) as c:
        params = {"event_type": "pipeline.self_check"}
        assert c.get("/v1/dev/events/count", params=params).status_code == 404
