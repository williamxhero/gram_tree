"""导出给客户端用的 OpenAPI 描述。

按正式环境的设置导出，所以示例接口不会进入客户端。输出稳定（键排序），方便 CI 比较。
"""

import json

from gramtree.main import create_app
from gramtree.settings import Settings


def export() -> str:
    app = create_app(
        Settings(env="prod", auth_secret="export-only-" + "x" * 32, mail_backend="smtp")
    )
    return json.dumps(app.openapi(), ensure_ascii=False, indent=2, sort_keys=True) + "\n"
