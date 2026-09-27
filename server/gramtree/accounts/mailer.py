"""发邮件的接入层。业务代码只依赖 MailSender，换服务商时只换实现。"""

import smtplib
from dataclasses import dataclass, field
from email.message import EmailMessage
from typing import Protocol

from gramtree.settings import Settings


@dataclass(frozen=True)
class Mail:
    to: str
    subject: str
    body: str


class MailSender(Protocol):
    def send(self, mail: Mail) -> None: ...


@dataclass
class MemoryMailSender:
    """开发和测试用：邮件不发出去，留在 outbox 里。"""

    outbox: list[Mail] = field(default_factory=list)

    def send(self, mail: Mail) -> None:
        self.outbox.append(mail)

    def latest_to(self, address: str) -> Mail | None:
        for mail in reversed(self.outbox):
            if mail.to == address:
                return mail
        return None


class SmtpMailSender:
    def __init__(self, settings: Settings):
        self._settings = settings

    def send(self, mail: Mail) -> None:
        s = self._settings
        msg = EmailMessage()
        msg["From"] = s.mail_from
        msg["To"] = mail.to
        msg["Subject"] = mail.subject
        msg.set_content(mail.body)
        with smtplib.SMTP(s.smtp_host, s.smtp_port, timeout=10) as smtp:
            if s.smtp_starttls:
                smtp.starttls()
            if s.smtp_username:
                smtp.login(s.smtp_username, s.smtp_password)
            smtp.send_message(msg)


def make_mail_sender(settings: Settings) -> MailSender:
    if settings.mail_backend == "smtp":
        return SmtpMailSender(settings)
    return MemoryMailSender()
