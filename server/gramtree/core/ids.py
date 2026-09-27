"""对外 ID 约定：一律随机 UUID v4，不用自增序号。

需要离线创建的数据由客户端生成同样格式的 ID，服务端只校验格式并据此去重。
"""

import uuid
from typing import Annotated

from pydantic import AfterValidator


def new_id() -> uuid.UUID:
    return uuid.uuid4()


def _require_v4(value: uuid.UUID) -> uuid.UUID:
    if value.version != 4:
        raise ValueError("ID 必须是 UUID v4")
    return value


# 在请求模型和路径参数里用它代替 uuid.UUID
IdV4 = Annotated[uuid.UUID, AfterValidator(_require_v4)]
