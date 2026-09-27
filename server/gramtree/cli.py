"""服务端命令行。

gramtree config list
gramtree config get <key>
gramtree config set <key> <value> --by <修改人> --reason <原因>
gramtree config history [<key>]
gramtree openapi [--out 路径]
"""

import argparse
import json
import sys
from typing import Any

from gramtree.db import make_engine, make_session_factory
from gramtree.runtime_config import service
from gramtree.runtime_config.registry import ITEMS
from gramtree.settings import get_settings


def _fmt(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False)


def _session():
    return make_session_factory(make_engine(get_settings().database_url))()


def cmd_config(args: argparse.Namespace) -> int:
    with _session() as session:
        if args.action == "list":
            values = service.get_all(session)
            for cfg in ITEMS:
                bounds = ""
                if cfg.minimum is not None or cfg.maximum is not None:
                    bounds = f" [{cfg.minimum}, {cfg.maximum}]"
                if cfg.choices:
                    bounds = f" {{{' / '.join(cfg.choices)}}}"
                print(
                    f"{cfg.key} = {_fmt(values[cfg.key])}"
                    f"  (默认 {_fmt(cfg.default)}{bounds})  {cfg.description}"
                )
            return 0
        if args.action == "get":
            print(_fmt(service.get(session, args.key)))
            return 0
        if args.action == "set":
            change = service.set_value(session, args.key, args.value, args.by, args.reason)
            print(f"{change.key}: {_fmt(change.old_value)} -> {_fmt(change.new_value)}")
            return 0
        if args.action == "history":
            for c in service.history(session, args.key):
                print(
                    f"{c.changed_at.isoformat()}  {c.key}: {_fmt(c.old_value)} -> "
                    f"{_fmt(c.new_value)}  by {c.changed_by}  原因：{c.reason}"
                )
            return 0
    return 2


def cmd_openapi(args: argparse.Namespace) -> int:
    from gramtree.openapi_export import export

    text = export()
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(text)
    else:
        sys.stdout.write(text)
    return 0


def cmd_backup(args: argparse.Namespace) -> int:
    from pathlib import Path

    from gramtree.ops import backup

    if args.action == "run":
        from gramtree.tasks.jobs import backup_database

        print(backup_database())
        return 0
    if args.action == "restore":
        backup.restore(Path(args.file), args.to)
        print(f"已恢复到 {args.to.rsplit('/', 1)[-1]}")
        return 0
    return 2


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="gramtree")
    sub = parser.add_subparsers(dest="command", required=True)

    config = sub.add_parser("config", help="查看和修改服务端配置项")
    config_sub = config.add_subparsers(dest="action", required=True)
    config_sub.add_parser("list")
    get = config_sub.add_parser("get")
    get.add_argument("key")
    set_ = config_sub.add_parser("set")
    set_.add_argument("key")
    set_.add_argument("value")
    set_.add_argument("--by", required=True, help="修改人")
    set_.add_argument("--reason", required=True, help="修改原因")
    history = config_sub.add_parser("history")
    history.add_argument("key", nargs="?")
    config.set_defaults(func=cmd_config)

    bk = sub.add_parser("backup", help="备份和恢复数据库")
    bk_sub = bk.add_subparsers(dest="action", required=True)
    bk_sub.add_parser("run", help="立刻备份一次（和每日定时任务相同）")
    restore = bk_sub.add_parser("restore", help="把备份恢复到一个新库")
    restore.add_argument("file")
    restore.add_argument("--to", required=True, help="目标库地址，库会被重建")
    bk.set_defaults(func=cmd_backup)

    openapi = sub.add_parser("openapi", help="导出 OpenAPI 描述")
    openapi.add_argument("--out")
    openapi.set_defaults(func=cmd_openapi)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        return args.func(args)
    except service.ConfigError as exc:
        print(f"错误：{exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
