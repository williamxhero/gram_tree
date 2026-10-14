import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel


class ExportJobView(BaseModel):
    id: uuid.UUID
    status: Literal["pending", "processing", "completed", "failed", "expired"]
    created_at: datetime
    completed_at: datetime | None = None
    expires_at: datetime | None = None
    download_url: str | None = None
    error_code: str | None = None


class ExportJobList(BaseModel):
    items: list[ExportJobView]
