"""食材库版本号的格式和比较（SPEC-002.1 #101）。

版本号是 `主.次.修` 三段数字，格式由数据文件里的 `manifest.json` 定（见 `importer.py`）。
增量接口要判断“哪些版本晚于客户端手上的版本”，而按字符串比是错的：`"2.10.0" < "2.9.0"`。
所以版本号一律先按这个格式解析成整数元组再比，取最新版本也按这个大小，不看导入时间。
"""

import re
from collections.abc import Iterable

# 数据文件的 manifest.json 和接口的 since_version 都用这个格式
VERSION_PATTERN = r"^(\d+)\.(\d+)\.(\d+)$"

_VERSION_RE = re.compile(VERSION_PATTERN)

# 可比较的版本号：主、次、修三段数字
VersionKey = tuple[int, int, int]


def parse_version(version: str) -> VersionKey:
    """把版本号解析成可比较的整数元组；格式不对直接报错，不静默当成某个值。"""
    match = _VERSION_RE.match(version)
    if match is None:
        raise ValueError(f"版本号格式不对：{version}")
    return (int(match[1]), int(match[2]), int(match[3]))


def latest_version(versions: Iterable[str]) -> str | None:
    """按版本号大小取最新的一个；一个版本都没有时返回 None。"""
    return max(versions, key=parse_version, default=None)
