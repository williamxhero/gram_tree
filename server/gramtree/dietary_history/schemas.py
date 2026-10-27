"""Owner-only dietary statistics contract; no telemetry or AI inference."""

from datetime import date
from typing import Literal

from pydantic import BaseModel, Field

from gramtree.core.ids import IdV4
from gramtree.core.time import Timestamp

DietaryPeriod = Literal["week", "month", "year"]


class DietaryDistributionItem(BaseModel):
    key: str
    count: int = Field(ge=0, description="Records containing this category, once per record")


class DietaryDishCount(BaseModel):
    dish_id: IdV4
    name: str
    count: int = Field(ge=1)
    first_cooked_at: Timestamp


class DietaryUnclassifiedDish(BaseModel):
    record_id: IdV4
    name: str | None
    occurred_at: Timestamp


class DietaryStatisticsOut(BaseModel):
    period: DietaryPeriod
    timezone: str
    local_start: date
    local_end: date = Field(description="Exclusive local end date")
    start_at: Timestamp
    end_at: Timestamp
    generated_at: Timestamp
    cooking_count: int = Field(ge=0)
    ingredient_record_count: int = Field(ge=0)
    ingredient_distribution: list[DietaryDistributionItem]
    cuisine_distribution: list[DietaryDistributionItem]
    frequent_dishes: list[DietaryDishCount]
    new_dishes: list[DietaryDishCount]
    unclassified_dish_count: int = Field(ge=0)
    unclassified_dishes: list[DietaryUnclassifiedDish] = Field(
        description="Unresolved record facts, not merged dishes or claims of first attempts"
    )
