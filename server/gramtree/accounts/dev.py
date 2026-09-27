"""开发和测试环境才挂载的辅助接口：读出最近发给某个邮箱的验证码。

端到端测试（网页版、安卓模拟器）用它代替收邮件。正式环境不挂载，也不进 OpenAPI 描述。
"""

import re

from fastapi import APIRouter, Query

from gramtree.accounts.deps import MailerDep
from gramtree.accounts.mailer import MemoryMailSender
from gramtree.core.errors import NotFound

router = APIRouter(prefix="/dev", include_in_schema=False)


@router.get("/latest-email-code")
def latest_email_code(mailer: MailerDep, email: str = Query()) -> dict[str, str]:
    if not isinstance(mailer, MemoryMailSender):
        raise NotFound("mail backend is not memory")
    mail = mailer.latest_to(email.strip().lower())
    match = re.search(r"\b(\d{6})\b", mail.body) if mail else None
    if match is None:
        raise NotFound("no code sent to this address")
    return {"code": match.group(1)}
