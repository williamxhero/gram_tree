"""当前时间的来源。接口里取“现在”都走这里，测试可以把时钟往后拨（例如验证令牌过期）。"""

from collections.abc import Callable
from datetime import datetime
from typing import Annotated

from fastapi import Depends, Request

from gramtree.core.time import utcnow

Clock = Callable[[], datetime]


def get_clock(request: Request) -> Clock:
    return getattr(request.app.state, "clock", utcnow)


ClockDep = Annotated[Clock, Depends(get_clock)]
