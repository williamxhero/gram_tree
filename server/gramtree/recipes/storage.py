"""Private object-storage adapters used by recipe photos.

The application never stores a public URL.  Development can use the small
filesystem adapter, while staging/production use the S3-compatible adapter
(with MinIO as the local service).  Both adapters expose the same narrow
interface so image validation and ownership logic stay storage agnostic.
"""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Any, Protocol

from gramtree.core.errors import ApiError
from gramtree.settings import Settings

logger = logging.getLogger("gramtree.recipes.storage")


class ObjectStorage(Protocol):
    """The operations needed by the private recipe-image lifecycle."""

    def put(self, key: str, content: bytes, content_type: str) -> None: ...

    def get(self, key: str) -> bytes: ...

    def delete(self, key: str) -> None: ...

    def signed_get_url(self, key: str, expires_in: int) -> str | None: ...


class FilesystemObjectStorage:
    """Local-only adapter retained for tests and developer machines."""

    def __init__(self, root: str) -> None:
        self.root = Path(root).resolve()

    def _path(self, key: str) -> Path:
        path = (self.root / key).resolve()
        if self.root not in path.parents:
            raise ApiError(500, "storage_error", "图片存储配置有误")
        return path

    def put(self, key: str, content: bytes, content_type: str) -> None:
        del content_type  # The metadata is stored in the database.
        path = self._path(key)
        try:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)
        except OSError as exc:
            raise ApiError(503, "storage_unavailable", "图片暂时无法保存，请稍后再试") from exc

    def get(self, key: str) -> bytes:
        path = self._path(key)
        try:
            return path.read_bytes()
        except OSError as exc:
            raise ApiError(404, "not_found", "没有找到相关内容") from exc

    def delete(self, key: str) -> None:
        try:
            self._path(key).unlink(missing_ok=True)
        except OSError:
            logger.warning(
                "could not delete recipe image", extra={"storage_key": key}, exc_info=True
            )

    def signed_get_url(self, key: str, expires_in: int) -> str | None:
        del key, expires_in
        return None


class S3ObjectStorage:
    """Private S3-compatible adapter (AWS S3, MinIO, or another compatible service)."""

    def __init__(self, settings: Settings) -> None:
        try:
            import boto3
            from botocore.client import Config
        except ImportError as exc:  # pragma: no cover - dependency is declared in pyproject
            raise RuntimeError("boto3 is required for S3 recipe storage") from exc

        self.bucket = settings.recipe_s3_bucket
        if not self.bucket:
            raise RuntimeError("GRAMTREE_RECIPE_S3_BUCKET must be configured")
        client_config = Config(
            signature_version="s3v4",
            s3={"addressing_style": "path" if settings.recipe_s3_path_style else "auto"},
        )
        self._client: Any = boto3.client(
            "s3",
            endpoint_url=settings.recipe_s3_endpoint_url or None,
            region_name=settings.recipe_s3_region,
            aws_access_key_id=settings.recipe_s3_access_key_id or None,
            aws_secret_access_key=settings.recipe_s3_secret_access_key or None,
            config=client_config,
        )
        self._presign_client: Any = self._client
        if settings.recipe_s3_public_endpoint_url:
            self._presign_client = boto3.client(
                "s3",
                endpoint_url=settings.recipe_s3_public_endpoint_url,
                region_name=settings.recipe_s3_region,
                aws_access_key_id=settings.recipe_s3_access_key_id or None,
                aws_secret_access_key=settings.recipe_s3_secret_access_key or None,
                config=client_config,
            )

    def put(self, key: str, content: bytes, content_type: str) -> None:
        try:
            self._client.put_object(
                Bucket=self.bucket,
                Key=key,
                Body=content,
                ContentType=content_type,
            )
        except Exception as exc:
            logger.warning("could not write recipe image to object storage", exc_info=True)
            raise ApiError(503, "storage_unavailable", "图片暂时无法保存，请稍后再试") from exc

    def get(self, key: str) -> bytes:
        try:
            response = self._client.get_object(Bucket=self.bucket, Key=key)
            body = response["Body"]
            return body.read()
        except Exception as exc:
            logger.warning("could not read recipe image from object storage", exc_info=True)
            raise ApiError(404, "not_found", "没有找到相关内容") from exc

    def delete(self, key: str) -> None:
        try:
            self._client.delete_object(Bucket=self.bucket, Key=key)
        except Exception:
            logger.warning("could not delete recipe image from object storage", exc_info=True)

    def signed_get_url(self, key: str, expires_in: int) -> str:
        try:
            return str(
                self._presign_client.generate_presigned_url(
                    "get_object",
                    Params={"Bucket": self.bucket, "Key": key},
                    ExpiresIn=expires_in,
                )
            )
        except Exception as exc:
            logger.warning("could not create signed recipe-image URL", exc_info=True)
            raise ApiError(503, "storage_unavailable", "图片暂时无法读取，请稍后再试") from exc


def make_recipe_storage(settings: Settings) -> ObjectStorage:
    if settings.recipe_storage_backend == "s3":
        return S3ObjectStorage(settings)
    return FilesystemObjectStorage(settings.recipe_media_dir)
