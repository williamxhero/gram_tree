"""账号相关的错误。code 给 App 判断用，message 直接给用户看。"""

from gramtree.core.errors import ApiError


class Unauthorized(ApiError):
    def __init__(self, detail: str | None = None):
        super().__init__(401, "unauthorized", "请先登录", detail)


class TokenExpired(ApiError):
    """访问令牌过期：App 收到后用刷新令牌续期。"""

    def __init__(self) -> None:
        super().__init__(401, "token_expired", "登录已过期", None)


class RefreshInvalid(ApiError):
    def __init__(self) -> None:
        super().__init__(401, "refresh_invalid", "登录已失效，请重新登录", None)


class InvalidEmail(ApiError):
    def __init__(self) -> None:
        super().__init__(422, "invalid_email", "邮箱格式不对，请检查一下", None)


class ResendTooSoon(ApiError):
    def __init__(self, retry_after: int):
        super().__init__(
            429, "resend_too_soon", f"验证码刚发过，{retry_after} 秒后可以重新发送", None
        )
        self.retry_after = retry_after


class DailyLimitReached(ApiError):
    def __init__(self) -> None:
        super().__init__(
            429, "daily_limit_reached", "今天发送次数已达上限，请明天再试，或用其他方式登录", None
        )


class CodeInvalid(ApiError):
    def __init__(self, attempts_left: int | None):
        message = (
            "验证码不对，请重新获取"
            if attempts_left is None
            else f"验证码不对，还可以再试 {attempts_left} 次"
        )
        super().__init__(400, "code_invalid", message, None)


class CodeExpired(ApiError):
    def __init__(self) -> None:
        super().__init__(400, "code_expired", "验证码已过期，请重新获取", None)


class CodeAttemptsExceeded(ApiError):
    def __init__(self) -> None:
        super().__init__(400, "code_attempts_exceeded", "验证码错误次数太多，请重新获取", None)


class AccountUnavailable(ApiError):
    def __init__(self) -> None:
        super().__init__(403, "account_unavailable", "这个账号已申请注销，不能再登录", None)


class IdentityTaken(ApiError):
    def __init__(self) -> None:
        super().__init__(
            409, "identity_taken", "这个登录方式已经属于另一个味谱账号，不能绑定", None
        )


class NotYourIdentity(ApiError):
    def __init__(self) -> None:
        super().__init__(403, "identity_mismatch", "请用这个账号绑定的登录方式验证", None)


class ReauthRequired(ApiError):
    def __init__(self) -> None:
        super().__init__(403, "reauth_required", "为了安全，请先重新验证身份", None)


class InvalidNickname(ApiError):
    def __init__(self, message: str):
        super().__init__(422, "invalid_nickname", message, None)


class InvalidTimezone(ApiError):
    def __init__(self) -> None:
        super().__init__(422, "invalid_timezone", "不认识这个时区", None)
