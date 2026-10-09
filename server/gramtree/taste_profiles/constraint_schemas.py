"""Cooking settings are data, not a recipe adaptation/compilation request."""

from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

DayType = Literal["weekday", "weekend"]
Meal = Literal["breakfast", "lunch", "dinner"]
DishType = Literal["meat", "vegetable", "soup", "staple", "other"]
DISH_TYPES: tuple[DishType, ...] = ("meat", "vegetable", "soup", "staple", "other")
EquipmentId = Annotated[str, Field(pattern=r"^[a-z][a-z0-9_]{0,39}$")]


class CookingMealTime(BaseModel):
    model_config = ConfigDict(extra="forbid")
    day_type: DayType
    meal: Meal
    minutes: int = Field(strict=True, ge=1, le=1440)


class CookingMealTemplate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    day_type: DayType
    meal: Meal
    dish_count: int = Field(strict=True, ge=1, le=20)
    composition: list[DishType] = Field(min_length=1, max_length=20)

    @model_validator(mode="after")
    def consistent_count(self) -> "CookingMealTemplate":
        if self.dish_count != len(self.composition):
            raise ValueError("道数须与菜型组合一致")
        return self


class CookingConstraints(BaseModel):
    model_config = ConfigDict(extra="forbid")
    household_servings: int | None = Field(default=None, strict=True, ge=1, le=1000)
    equipment: list[EquipmentId] = Field(default_factory=list, max_length=100)
    meal_times: list[CookingMealTime] = Field(default_factory=list, max_length=6)
    meal_templates: list[CookingMealTemplate] = Field(default_factory=list, max_length=6)

    @model_validator(mode="after")
    def unique_choices(self) -> "CookingConstraints":
        if len(set(self.equipment)) != len(self.equipment):
            raise ValueError("厨具不能重复")
        for values in (self.meal_times, self.meal_templates):
            slots = {(value.day_type, value.meal) for value in values}
            if len(slots) != len(values):
                raise ValueError("同一餐不能重复设置")
        return self


class CookingEquipment(BaseModel):
    model_config = ConfigDict(extra="forbid")
    id: EquipmentId
    label: str = Field(min_length=1, max_length=40)
    aliases: list[str] = Field(default_factory=list, max_length=20)


class CookingEquipmentVocabulary(BaseModel):
    model_config = ConfigDict(extra="forbid")
    items: list[CookingEquipment] = Field(min_length=1, max_length=100)

    @model_validator(mode="after")
    def unique_ids(self) -> "CookingEquipmentVocabulary":
        if len({item.id for item in self.items}) != len(self.items):
            raise ValueError("厨具词表 ID 不能重复")
        return self


class CookingConstraintsOut(BaseModel):
    profile_version: int
    constraints: CookingConstraints
    equipment_vocabulary: list[CookingEquipment]
    dish_types: list[DishType]
    servings_min: int
    servings_max: int
