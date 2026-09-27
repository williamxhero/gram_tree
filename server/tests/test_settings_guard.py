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

    app = create_app(make_settings(env="prod", auth_secret="s" * 40, mail_backend="smtp"))
    with TestClient(app) as c:
        assert c.get("/v1/dev/latest-email-code", params={"email": "a@b.cd"}).status_code == 404
