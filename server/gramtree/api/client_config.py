from typing import Any

from fastapi import APIRouter
from pydantic import BaseModel

from gramtree.core.errors import ERROR_RESPONSES
from gramtree.deps import SessionDep
from gramtree.runtime_config import service
from gramtree.runtime_config.registry import ITEMS

router = APIRouter(tags=["config"])


class ClientConfig(BaseModel):
    """App 启动时拉取的服务端配置。"""

    features: dict[str, bool]
    """能力开关，key 去掉了 feature. 前缀。关闭的入口在 App 里不出现。"""
    params: dict[str, Any]
    """下发给 App 的参数。"""


@router.get(
    "/client-config",
    response_model=ClientConfig,
    responses=ERROR_RESPONSES,
    summary="App 用的能力开关和参数",
)
def client_config(session: SessionDep) -> ClientConfig:
    values = service.get_all(session)
    features: dict[str, bool] = {}
    params: dict[str, Any] = {}
    for cfg in ITEMS:
        if not cfg.public:
            continue
        if cfg.is_feature_flag:
            features[cfg.key.removeprefix("feature.")] = bool(values[cfg.key])
        else:
            params[cfg.key] = values[cfg.key]
    return ClientConfig(features=features, params=params)
