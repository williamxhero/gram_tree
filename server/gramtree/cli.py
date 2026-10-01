"""服务端命令行。

gramtree config list
gramtree config get <key>
gramtree config set <key> <value> --by <修改人> --reason <原因>
gramtree config history [<key>]
gramtree openapi [--out 路径]
gramtree accounts purge [--as-of 时间]
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


def cmd_recipes(args: argparse.Namespace) -> int:
    if args.action == "drain-save-events":
        from gramtree.tasks.jobs import drain_recipe_save_outbox

        print(f"已投递 {drain_recipe_save_outbox()} 条菜谱版本事件")
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
        try:
            backup.restore(Path(args.file), args.to, get_settings().database_url)
        except backup.RestoreRefused as exc:
            print(f"错误：{exc}", file=sys.stderr)
            return 1
        print(f"已恢复到 {args.to.rsplit('/', 1)[-1]}")
        return 0
    return 2


def cmd_accounts(args: argparse.Namespace) -> int:
    from datetime import datetime

    from gramtree.tasks.jobs import purge_deleted_accounts

    if args.as_of:
        as_of = datetime.fromisoformat(args.as_of)
        if as_of.tzinfo is None:
            print("错误：--as-of 必须带时区，例如 2026-10-20T00:00:00+08:00", file=sys.stderr)
            return 1
        count = purge_deleted_accounts(as_of.isoformat())
    else:
        count = purge_deleted_accounts()
    print(f"已删除 {count} 个注销到期账号的个人数据")
    return 0


def cmd_ingredients(args: argparse.Namespace) -> int:
    from pathlib import Path

    from gramtree.ingredients.importer import (
        IngredientImportError,
        import_directory,
        validate_directory,
    )

    if args.action == "import":
        try:
            with _session() as session:
                stats = import_directory(session, Path(args.dir))
        except IngredientImportError as exc:
            print(f"错误：{exc}", file=sys.stderr)
            return 1
        print(
            f"食材库 {stats['version']}：新增 {stats['added']} 种，内容有变化 {stats['changed']} 种"
        )
        return 0
    if args.action == "validate":
        baseline = Path(args.baseline_dir) if args.baseline_dir else None
        try:
            manifest, records = validate_directory(Path(args.dir), baseline)
        except IngredientImportError as exc:
            print(f"错误：{exc}", file=sys.stderr)
            return 1
        print(f"食材库 {manifest.version} 校验通过：{len(records)} 种")
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

    acc = sub.add_parser("accounts", help="账号维护")
    acc_sub = acc.add_subparsers(dest="action", required=True)
    purge = acc_sub.add_parser("purge", help="立刻删除注销到期账号的个人数据（和每日定时任务相同）")
    purge.add_argument("--as-of", help="按这个时间判断是否到期（默认现在），带时区的 ISO 8601")
    acc.set_defaults(func=cmd_accounts)

    recipes = sub.add_parser("recipes", help="菜谱维护")
    recipes_sub = recipes.add_subparsers(dest="action", required=True)
    recipes_sub.add_parser(
        "drain-save-events",
        help="重试未投递的菜谱版本经验事件",
    )
    recipes.set_defaults(func=cmd_recipes)

    ing = sub.add_parser("ingredients", help="食材库管理")
    ing_sub = ing.add_subparsers(dest="action", required=True)
    import_cmd = ing_sub.add_parser("import", help="把数据目录里的食材库导入数据库（幂等）")
    import_cmd.add_argument("dir", help="含 manifest.json 的数据目录，例如 data/ingredients")
    validate_cmd = ing_sub.add_parser("validate", help="离线校验食材库数据，不连接数据库")
    validate_cmd.add_argument("dir", help="含 manifest.json 的数据目录，例如 data/ingredients")
    validate_cmd.add_argument(
        "--baseline-dir",
        help="历史食材库目录；其中已有的标准 ID 不得从当前数据删除",
    )
    ing.set_defaults(func=cmd_ingredients)

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
