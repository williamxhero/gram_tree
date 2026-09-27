"""数据库每日备份和恢复。

- 备份：pg_dump 自定义格式写到本机备份目录，再用 rclone 复制到服务器之外的位置
  （GRAMTREE_BACKUP_REMOTE，例如 s3:bucket/gramtree 或 另一台机器的 sftp 目录）。
- 保留天数是运行时配置项 ops.backup_retention_days，本机和异地都按它清理。
- 恢复：pg_restore 到一个新库，演练时用健康检查和业务数据确认恢复成功。
"""

import logging
import shutil
import subprocess
from datetime import UTC, datetime, timedelta
from pathlib import Path

from sqlalchemy import create_engine, make_url, text

from gramtree.core.time import utcnow

logger = logging.getLogger("gramtree.backup")

FILE_PREFIX = "gramtree-"
FILE_SUFFIX = ".dump"


def libpq_url(sqlalchemy_url: str) -> str:
    """把 SQLAlchemy 的地址转成 pg_dump 认识的地址。"""
    return (
        make_url(sqlalchemy_url).set(drivername="postgresql").render_as_string(hide_password=False)
    )


def run_backup(database_url: str, backup_dir: Path) -> Path:
    backup_dir.mkdir(parents=True, exist_ok=True)
    stamp = utcnow().strftime("%Y%m%dT%H%M%SZ")
    target = backup_dir / f"{FILE_PREFIX}{stamp}{FILE_SUFFIX}"
    partial = target.with_suffix(".partial")
    subprocess.run(
        ["pg_dump", "--format=custom", "--no-owner", f"--file={partial}", libpq_url(database_url)],
        check=True,
        capture_output=True,
    )
    partial.rename(target)
    logger.info("backup written", extra={"file": str(target), "bytes": target.stat().st_size})
    return target


def upload(path: Path, remote: str) -> None:
    subprocess.run(["rclone", "copy", str(path), remote], check=True, capture_output=True)
    logger.info("backup uploaded", extra={"file": path.name, "remote": remote})


def prune_local(backup_dir: Path, retention_days: int) -> list[Path]:
    cutoff = utcnow() - timedelta(days=retention_days)
    removed = []
    for path in sorted(backup_dir.glob(f"{FILE_PREFIX}*{FILE_SUFFIX}")):
        stamp = path.name.removeprefix(FILE_PREFIX).removesuffix(FILE_SUFFIX)
        try:
            taken = datetime.strptime(stamp, "%Y%m%dT%H%M%SZ").replace(tzinfo=UTC)
        except ValueError:
            continue
        if taken < cutoff:
            path.unlink()
            removed.append(path)
    return removed


def prune_remote(remote: str, retention_days: int) -> None:
    subprocess.run(
        ["rclone", "delete", remote, "--min-age", f"{retention_days}d", "--include", "*.dump"],
        check=True,
        capture_output=True,
    )


class RestoreRefused(ValueError):
    pass


def restore(backup_file: Path, target_url: str, live_url: str) -> None:
    """恢复到一个新库（库已存在会先删掉重建）。目标是正在用的库时拒绝执行。"""
    target = make_url(target_url)
    live = make_url(live_url)
    if (target.host, target.port or 5432, target.database) == (
        live.host,
        live.port or 5432,
        live.database,
    ):
        raise RestoreRefused(f"目标库 {target.database} 就是正在使用的库，不能直接覆盖")
    admin = create_engine(target.set(database="postgres"), isolation_level="AUTOCOMMIT")
    with admin.connect() as conn:
        conn.execute(text(f'DROP DATABASE IF EXISTS "{target.database}" WITH (FORCE)'))
        conn.execute(text(f'CREATE DATABASE "{target.database}"'))
    admin.dispose()
    subprocess.run(
        [
            "pg_restore",
            "--no-owner",
            "--exit-on-error",
            f"--dbname={libpq_url(target_url)}",
            str(backup_file),
        ],
        check=True,
        capture_output=True,
    )
    logger.info("backup restored", extra={"file": str(backup_file), "database": target.database})


def tools_available() -> bool:
    return shutil.which("pg_dump") is not None and shutil.which("pg_restore") is not None
