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
import uuid
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
    if args.action in {"safety-recheck", "safety-status", "safety-validate"}:
        from sqlalchemy import func, select

        from gramtree.recipes import food_safety
        from gramtree.recipes.models import RecipeSafetyRecheck

        try:
            policy = food_safety.rules()
            if args.action == "safety-validate":
                print(_fmt({"rules_version": policy.version, "digest": policy.digest()}))
                return 0
            with _session() as session:
                if args.action == "safety-recheck":
                    if args.enqueue:
                        queued = food_safety.queue_rechecks(session, policy)
                        session.commit()
                        from gramtree.tasks.jobs import recheck_food_safety

                        task = recheck_food_safety.delay(limit=args.limit)
                        print(
                            _fmt(
                                {
                                    "rules_version": policy.version,
                                    "queued": queued,
                                    "task_id": task.id,
                                }
                            )
                        )
                        return 0
                    result = food_safety.run_rechecks(session, policy, args.limit)
                    print(_fmt(result))
                    return 1 if result["failed"] else 0
                counts = dict(
                    session.execute(
                        select(RecipeSafetyRecheck.status, func.count())
                        .where(RecipeSafetyRecheck.rules_version == policy.version)
                        .group_by(RecipeSafetyRecheck.status)
                    ).all()
                )
                jobs = session.scalars(
                    select(RecipeSafetyRecheck)
                    .where(RecipeSafetyRecheck.rules_version == policy.version)
                    .order_by(RecipeSafetyRecheck.created_at.desc())
                    .limit(args.limit)
                )
                print(
                    _fmt(
                        {
                            "rules_version": policy.version,
                            "counts": counts,
                            "jobs": [
                                {
                                    "id": str(job.id),
                                    "version_id": str(job.version_id),
                                    "status": job.status,
                                    "attempts": job.attempts,
                                    "last_error": job.last_error,
                                    "attempted_at": job.attempted_at.isoformat()
                                    if job.attempted_at
                                    else None,
                                    "completed_at": job.completed_at.isoformat()
                                    if job.completed_at
                                    else None,
                                }
                                for job in jobs
                            ],
                        }
                    )
                )
                return 0
        except (ValueError, OSError) as exc:
            print(f"安全规则错误：{exc}", file=sys.stderr)
            return 1
    if args.action == "seed-safety-retry":
        # A CLI fixture permits crash/retry acceptance through external boundaries.
        if get_settings().env != "test":
            print("这个命令只允许在 test 环境使用", file=sys.stderr)
            return 1
        from datetime import timedelta

        from gramtree.core.time import utcnow
        from gramtree.recipes.models import RecipeSafetyRecheck, RecipeVersion

        with _session() as session:
            job = session.get(RecipeSafetyRecheck, uuid.UUID(args.job_id))
            if job is None:
                return 1
            if args.mode == "expired-lease":
                job.status = "running"
                job.attempted_at = utcnow() - timedelta(minutes=10)
            elif args.mode == "invalid-snapshot":
                version = session.get(RecipeVersion, job.version_id)
                if version is None:
                    return 1
                version.snapshot = {**version.snapshot, "servings": 0}
            elif args.mode == "repair-snapshot":
                version = session.get(RecipeVersion, job.version_id)
                if version is None:
                    return 1
                version.snapshot = {**version.snapshot, "servings": 1}
            session.commit()
        print(_fmt({"job_id": args.job_id, "mode": args.mode}))
        return 0
    if args.action == "drain-save-events":
        from gramtree.tasks.jobs import drain_recipe_save_outbox

        print(f"已投递 {drain_recipe_save_outbox()} 条菜谱版本事件")
        return 0
    if args.action == "seed-legacy-scaling-mode":
        if get_settings().env != "test":
            print("这个命令只允许在 test 环境使用", file=sys.stderr)
            return 1
        from gramtree.recipes.models import RecipeVersion

        try:
            version_id = uuid.UUID(args.version_id)
        except ValueError:
            print("版本 ID 无效", file=sys.stderr)
            return 1
        with _session() as session:
            version = session.get(RecipeVersion, version_id)
            if version is None:
                print("未找到菜谱版本", file=sys.stderr)
                return 1
            snapshot = dict(version.snapshot)
            ingredients = list(snapshot.get("ingredients", []))
            if not ingredients:
                print("菜谱版本没有食材", file=sys.stderr)
                return 1
            ingredients[0] = {**ingredients[0], "scaling_mode": None}
            snapshot["ingredients"] = ingredients
            version.snapshot = snapshot
            session.commit()
        print(f"已将版本 {args.version_id} 的首个食材标记为旧版缩放方式")
        return 0
    if args.action == "quantification-receipts":
        from gramtree.events.queries import query_events

        with _session() as session:
            rows = query_events(
                session,
                user_id=uuid.UUID(args.user),
                event_type="recipe.quantification_decision",
                version=1,
            )
            print(_fmt({"items": [{"content": e.content} for e in rows]}))
        return 0
    if args.action == "save-event-receipt":
        from sqlalchemy import select

        from gramtree.events.models import Event

        with _session() as session:
            event = session.scalar(
                select(Event).where(
                    Event.event_type == "recipe.version_saved",
                    Event.correlation["recipe_version_id"].astext == args.version_id,
                )
            )
            if event is None:
                print("未找到菜谱版本保存事件", file=sys.stderr)
                return 1
            receipt = {
                "event_id": str(event.id),
                "recipe_version_id": event.content.get("recipe_version_id"),
                "previous_version_id": event.content.get("previous_version_id"),
                "edit_operations": event.content.get("edit_operations", []),
                "ai_assisted": event.content.get("ai_assisted", False),
            }
            print(_fmt(receipt))
            return 0
    return 2


def cmd_openapi(args: argparse.Namespace) -> int:
    from gramtree.openapi_export import export

    text = export()
    if args.out:
        with open(args.out, "w", encoding="utf-8", newline="\n") as f:
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


def cmd_ai(args: argparse.Namespace) -> int:
    from sqlalchemy import func, select

    from gramtree import models as _models  # noqa: F401 — register foreign-key targets
    from gramtree.ai import indexing
    from gramtree.ai.models import AICall, GenerationLog, RecipeEmbedding
    from gramtree.events.models import Event

    with _session() as session:
        if args.action == "index":
            result = indexing.run(session, get_settings(), args.limit)
            print(_fmt(result))
            return 1 if result["failed"] else 0
        if args.action == "purge-logs":
            print(_fmt(indexing.purge(session)))
            return 0
        user_id = uuid.UUID(args.user)
        calls = list(
            session.scalars(
                select(AICall).where(AICall.user_id == user_id).order_by(AICall.created_at)
            )
        )
        events = session.scalars(
            select(Event)
            .where(Event.user_id == user_id, Event.event_type == "ai.recipe_generation")
            .order_by(Event.received_at)
        )
        print(
            _fmt(
                {
                    "calls": [
                        {
                            "capability": c.capability,
                            "model": c.model,
                            "provider": c.provider,
                            "request_id": str(c.request_id),
                            "content_id": str(c.content_id) if c.content_id else None,
                            "prompt_version": c.prompt_version,
                            "input_tokens": c.input_tokens,
                            "output_tokens": c.output_tokens,
                            "cost": c.cost,
                            "duration_ms": c.duration_ms,
                            "status": c.status,
                            "error_code": c.error_code,
                        }
                        for c in calls
                    ],
                    "totals": {
                        cap: {
                            "cost": sum(c.cost for c in calls if c.capability == cap),
                            "input_tokens": sum(
                                c.input_tokens for c in calls if c.capability == cap
                            ),
                            "output_tokens": sum(
                                c.output_tokens for c in calls if c.capability == cap
                            ),
                        }
                        for cap in {c.capability for c in calls}
                    },
                    "log_count": session.scalar(
                        select(func.count())
                        .select_from(GenerationLog)
                        .join(AICall)
                        .where(AICall.user_id == user_id)
                    ),
                    "embeddings": dict(
                        session.execute(
                            select(RecipeEmbedding.status, func.count()).group_by(
                                RecipeEmbedding.status
                            )
                        ).all()
                    ),
                    "events": [e.content for e in events],
                    "modification_events": [
                        {"id": str(e.id), "correlation": e.correlation, "content": e.content}
                        for e in session.scalars(
                            select(Event)
                            .where(
                                Event.user_id == user_id,
                                Event.event_type == "ai.recipe_modification",
                            )
                            .order_by(Event.received_at, Event.id)
                        )
                    ],
                    "version_events": [
                        {"id": str(e.id), "correlation": e.correlation, "content": e.content}
                        for e in session.scalars(
                            select(Event)
                            .where(
                                Event.user_id == user_id,
                                Event.event_type == "recipe.version_saved",
                            )
                            .order_by(Event.received_at, Event.id)
                        )
                    ],
                }
            )
        )
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="gramtree")
    sub = parser.add_subparsers(dest="command", required=True)

    ai = sub.add_parser("ai", help="内部 AI 用量与索引维护（不通过 HTTP 暴露日志）")
    ai_sub = ai.add_subparsers(dest="action", required=True)
    audit = ai_sub.add_parser("audit")
    audit.add_argument("--user", required=True)
    index = ai_sub.add_parser("index")
    index.add_argument("--limit", type=int, default=100)
    ai_sub.add_parser("purge-logs")
    ai.set_defaults(func=cmd_ai)

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
    safety_recheck = recipes_sub.add_parser(
        "safety-recheck", help="按当前规则复检已有菜谱版本（可重复执行）"
    )
    safety_recheck.add_argument("--limit", type=int, default=100)
    safety_recheck.add_argument(
        "--enqueue", action="store_true", help="投递 Celery 任务而非同步执行"
    )
    safety_status = recipes_sub.add_parser("safety-status", help="查看食品安全复检队列状态")
    safety_status.add_argument("--limit", type=int, default=20)
    recipes_sub.add_parser("safety-validate", help="校验并输出当前食品安全规则版本")
    retry = recipes_sub.add_parser("seed-safety-retry", help="仅测试环境：构造复检故障或过期租约")
    retry.add_argument("job_id")
    retry.add_argument("mode", choices=("expired-lease", "invalid-snapshot", "repair-snapshot"))
    legacy_scaling = recipes_sub.add_parser(
        "seed-legacy-scaling-mode",
        help="仅测试环境：把版本首个食材标记为旧版空缩放方式",
    )
    legacy_scaling.add_argument("version_id")
    receipt = recipes_sub.add_parser(
        "save-event-receipt",
        help="输出一条菜谱版本经验事件的验收收据",
    )
    receipt.add_argument("version_id")
    quantification_receipts = recipes_sub.add_parser(
        "quantification-receipts", help="输出量化建议处理的经验事件验收收据"
    )
    quantification_receipts.add_argument("--user", required=True)
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
