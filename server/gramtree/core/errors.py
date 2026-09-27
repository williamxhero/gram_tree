"""统一错误格式。

所有接口出错时都返回：
    {"error": {"code", "message", "detail", "request_id"}}
code 给客户端判断用；message 给用户看；detail 给开发者看；request_id 用来查日志。
"""

import logging
from typing import Any

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from starlette.exceptions import HTTPException as StarletteHTTPException

from gramtree.core.request_context import REQUEST_ID_HEADER, get_request_id

logger = logging.getLogger("gramtree.errors")


class ErrorBody(BaseModel):
    code: str
    message: str
    detail: str | None = None
    request_id: str | None = None


class ErrorResponse(BaseModel):
    error: ErrorBody


class ApiError(Exception):
    """业务代码里抛这个，由统一处理器转成错误格式。"""

    def __init__(self, status: int, code: str, message: str, detail: str | None = None):
        super().__init__(detail or message)
        self.status = status
        self.code = code
        self.message = message
        self.detail = detail


class NotFound(ApiError):
    def __init__(self, detail: str | None = None):
        super().__init__(404, "not_found", "没有找到相关内容", detail)


_HTTP_CODES = {
    400: ("bad_request", "请求有误"),
    401: ("unauthorized", "请先登录"),
    403: ("forbidden", "没有权限"),
    404: ("not_found", "没有找到相关内容"),
    405: ("method_not_allowed", "请求有误"),
    409: ("conflict", "内容有冲突，请刷新后再试"),
    429: ("rate_limited", "操作太频繁，请稍后再试"),
}

# 在 OpenAPI 里给每个接口声明的错误响应
ERROR_RESPONSES: dict[int | str, dict[str, Any]] = {
    422: {"model": ErrorResponse, "description": "参数错误"},
    500: {"model": ErrorResponse, "description": "服务端错误"},
}


def error_response(
    status: int,
    code: str,
    message: str,
    detail: str | None,
    *,
    headers: dict[str, str] | None = None,
) -> JSONResponse:
    request_id = get_request_id()
    body = ErrorResponse(
        error=ErrorBody(code=code, message=message, detail=detail, request_id=request_id)
    )
    all_headers = dict(headers or {})
    if request_id:
        all_headers[REQUEST_ID_HEADER] = request_id
    return JSONResponse(body.model_dump(), status_code=status, headers=all_headers or None)


def install_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(ApiError)
    async def _api_error(_: Request, exc: ApiError) -> JSONResponse:
        retry_after = getattr(exc, "retry_after", None)
        headers = {"Retry-After": str(retry_after)} if retry_after is not None else None
        return error_response(exc.status, exc.code, exc.message, exc.detail, headers=headers)

    @app.exception_handler(RequestValidationError)
    async def _validation(_: Request, exc: RequestValidationError) -> JSONResponse:
        parts = []
        for err in exc.errors():
            loc = ".".join(str(p) for p in err.get("loc", ()))
            parts.append(f"{loc}: {err.get('msg')}")
        detail = "; ".join(parts)
        logger.info("request validation failed", extra={"detail": detail})
        return error_response(422, "invalid_request", "请求参数有误", detail)

    @app.exception_handler(StarletteHTTPException)
    async def _http(_: Request, exc: StarletteHTTPException) -> JSONResponse:
        code, message = _HTTP_CODES.get(exc.status_code, ("http_error", "请求失败"))
        detail = exc.detail if isinstance(exc.detail, str) else None
        return error_response(exc.status_code, code, message, detail)

    # 未处理的异常由 RequestContextMiddleware 转成统一错误格式
