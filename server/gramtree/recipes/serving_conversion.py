"""Deterministic recipe serving conversion kernel (SPEC-002.3).

This module deliberately has no database or HTTP dependencies. The Flutter client
implements the same small contract so a loaded immutable snapshot remains usable
while offline.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass
from decimal import ROUND_HALF_UP, Decimal
from typing import Literal

ScalingRule = Literal["proportional", "unchanged", "round"]

_BATCH_WARNING = "注意分批下锅，时间以成熟判断为准。"


class ServingConversionError(ValueError):
    """A user-correctable serving conversion request error."""

    def __init__(self, code: str, message: str, detail: str | None = None) -> None:
        super().__init__(detail or message)
        self.code = code
        self.message = message
        self.detail = detail


@dataclass(frozen=True)
class ServingIngredientInput:
    id: str
    display_name: str
    quantity: float
    unit: str
    scaling_mode: ScalingRule = "proportional"


@dataclass(frozen=True)
class ServingStepInput:
    id: str
    instruction: str
    ingredient_ids: tuple[str, ...] = ()
    duration_seconds: int = 0
    temperature_celsius: float | None = None
    heat: str | None = None


@dataclass(frozen=True)
class ConvertedIngredient:
    id: str
    display_name: str
    original_quantity: float
    display_quantity: float
    unit: str
    rule: ScalingRule
    deviation_ratio: float | None
    deviation_warning: bool


@dataclass(frozen=True)
class ConvertedStep:
    id: str
    instruction: str
    duration_seconds: int
    temperature_celsius: float | None
    heat: str | None
    batch_warning: bool
    batch_warning_text: str | None


@dataclass(frozen=True)
class ServingWarning:
    code: str
    ingredient_id: str | None
    message: str


@dataclass(frozen=True)
class ServingConversion:
    original_servings: int
    target_servings: int
    min_servings: int
    max_servings: int
    ingredients: tuple[ConvertedIngredient, ...]
    steps: tuple[ConvertedStep, ...]
    warnings: tuple[ServingWarning, ...]
    total_time_seconds: int
    active_time_seconds: int

    def as_dict(self) -> dict[str, object]:
        return asdict(self)


def _number(value: Decimal) -> float:
    """Use a stable two-decimal display precision without banker's rounding."""
    return float(value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))


def _whole(value: Decimal) -> float:
    return float(value.quantize(Decimal("1"), rounding=ROUND_HALF_UP))


def convert_servings(
    *,
    original_servings: int,
    target_servings: int,
    ingredients: list[ServingIngredientInput],
    steps: list[ServingStepInput],
    min_servings: int = 1,
    max_servings: int = 20,
    round_deviation_threshold: float = 0.20,
    batch_multiplier: float = 2.0,
    total_time_seconds: int | None = None,
    active_time_seconds: int | None = None,
) -> ServingConversion:
    """Convert an immutable snapshot to a target serving count.

    Proportional and round ingredients use the serving ratio; unchanged values do
    not. Round values use decimal half-up and never fall below one. Recipe step
    timing and heat are never scaled. Batch warnings only apply to steps that
    reference ingredients, because a standalone resting step does not become a
    larger batch operation.
    """
    if original_servings < 1:
        raise ServingConversionError("invalid_servings", "原菜谱份数必须至少为 1")
    if min_servings < 1 or max_servings < min_servings:
        raise ServingConversionError("invalid_servings_config", "份数范围配置有误")
    if target_servings < min_servings or target_servings > max_servings:
        raise ServingConversionError(
            "invalid_servings",
            f"份数必须在 {min_servings} 到 {max_servings} 之间",
            f"target_servings={target_servings} 超出允许范围 {min_servings}..{max_servings}",
        )
    if round_deviation_threshold < 0 or batch_multiplier < 1:
        raise ServingConversionError("invalid_servings_config", "换算阈值配置有误")

    ratio = Decimal(target_servings) / Decimal(original_servings)
    ingredients_out: list[ConvertedIngredient] = []
    warnings: list[ServingWarning] = []
    for item in ingredients:
        original = Decimal(str(item.quantity))
        theoretical = original * ratio
        deviation_ratio: float | None = None
        deviation_warning = False
        if item.scaling_mode == "unchanged":
            display = original
        elif item.scaling_mode == "round":
            display = max(Decimal("1"), Decimal(str(_whole(theoretical))))
            if theoretical != 0:
                deviation_ratio = float(abs(display - theoretical) / abs(theoretical))
                deviation_warning = deviation_ratio > round_deviation_threshold
                if deviation_warning:
                    warnings.append(
                        ServingWarning(
                            code="round_deviation",
                            ingredient_id=item.id,
                            message=(
                                f"{item.display_name}取整后与按比例结果相差较大，"
                                "请按口味微调其他用量。"
                            ),
                        )
                    )
        elif item.scaling_mode == "proportional":
            display = theoretical
        else:
            raise ServingConversionError(
                "invalid_scaling_mode",
                "菜谱包含无法识别的缩放方式",
                f"ingredients[{item.id}].scaling_mode={item.scaling_mode}",
            )
        ingredients_out.append(
            ConvertedIngredient(
                id=item.id,
                display_name=item.display_name,
                original_quantity=float(original),
                display_quantity=_number(display),
                unit=item.unit,
                rule=item.scaling_mode,
                deviation_ratio=deviation_ratio,
                deviation_warning=deviation_warning,
            )
        )

    is_large_batch = target_servings >= original_servings * batch_multiplier
    steps_out = tuple(
        ConvertedStep(
            id=step.id,
            instruction=step.instruction,
            duration_seconds=step.duration_seconds,
            temperature_celsius=step.temperature_celsius,
            heat=step.heat,
            batch_warning=is_large_batch and bool(step.ingredient_ids),
            batch_warning_text=_BATCH_WARNING
            if is_large_batch and bool(step.ingredient_ids)
            else None,
        )
        for step in steps
    )
    total = total_time_seconds
    if total is None:
        total = max((step.duration_seconds for step in steps), default=0)
    active = active_time_seconds
    if active is None:
        active = sum(step.duration_seconds for step in steps)
    return ServingConversion(
        original_servings=original_servings,
        target_servings=target_servings,
        min_servings=min_servings,
        max_servings=max_servings,
        ingredients=tuple(ingredients_out),
        steps=steps_out,
        warnings=tuple(warnings),
        total_time_seconds=total,
        active_time_seconds=active,
    )
