"""Read projections over existing immutable versions and owner cooking records."""

from dataclasses import dataclass
from datetime import date, datetime


@dataclass(frozen=True)
class DietaryRange:
    timezone: str
    local_start: date
    local_end: date
    start_at: datetime
    end_at: datetime
