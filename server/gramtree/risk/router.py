from fastapi import APIRouter, Request
from pydantic import BaseModel, Field

from gramtree.accounts.deps import OptionalIdentityAuth
from gramtree.core.errors import ERROR_RESPONSES, ApiError, ErrorResponse
from gramtree.core.time import utcnow
from gramtree.deps import RedisDep, SessionDep, SettingsDep
from gramtree.risk import service

router = APIRouter(prefix="/risk", tags=["risk"])


class CaptchaVerification(BaseModel):
    challenge_id: str = Field(min_length=8, max_length=128)
    response: str = Field(min_length=1, max_length=512)


class CaptchaVerificationOut(BaseModel):
    accepted: bool
    access_restored: bool


@router.post(
    "/captcha",
    response_model=CaptchaVerificationOut,
    responses={400: {"model": ErrorResponse}, **ERROR_RESPONSES},
    summary="完成访问安全验证",
)
def verify_captcha(
    body: CaptchaVerification,
    request: Request,
    redis: RedisDep,
    session: SessionDep,
    settings: SettingsDep,
    auth: OptionalIdentityAuth,
) -> CaptchaVerificationOut:
    candidates = []
    device_id = auth.device_session.device_id if auth else request.headers.get("X-Device-ID")
    if device_id:
        candidates.append(("device", device_id))
    if request.client:
        candidates.append(("ip", request.client.host))
        subnet = service.request_subnet(request.client.host)
        if subnet:
            candidates.append(("ip", f"subnet:{subnet}"))
    if auth is not None:
        candidates.append(("account", str(auth.user.id)))
    accepted = service.verify_captcha(
        redis,
        session,
        settings,
        request.app.state.captcha,
        challenge_id=body.challenge_id,
        response=body.response,
        candidates=candidates,
        now=request.app.state.clock() if hasattr(request.app.state, "clock") else utcnow(),
    )
    if not accepted:
        raise ApiError(400, "captcha_invalid", "安全验证未通过，请重试", None)
    return CaptchaVerificationOut(accepted=True, access_restored=True)
