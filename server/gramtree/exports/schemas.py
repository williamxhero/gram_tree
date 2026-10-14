import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel

ExportStatus = Literal["pending", "processing", "completed", "failed", "expired"]


class ExportJobView(BaseModel):
    id: uuid.UUID
    status: ExportStatus
    created_at: datetime
    completed_at: datetime | None = None
    expires_at: datetime | None = None
    download_url: str | None = None
    error_code: str | None = None


class ExportJobList(BaseModel):
    items: list[ExportJobView]
