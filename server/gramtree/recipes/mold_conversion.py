"""Deterministic recipe mold conversion kernel (SPEC-002.3).

The kernel operates on immutable recipe snapshots and has no database or HTTP
coupling. Mold areas are normalized to square centimetres before computing the
ratio, so a saved recipe can be converted offline by the App as well.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass
from decimal import ROUND_HALF_UP, Decimal
from math import pi
from typing import Literal

MoldShape = Literal["round", "square", "rectangular", "custom"]

_MOLD_TIME_ADVISORY = "时间不按模具比例放大，建议从原时间开始检查，以成熟判断为准。"
_DONENESS_WARNING = "请以成熟判断为准，不要只看计时。"


class MoldConversionError(ValueError):
    """A user-correctable mold conversion request error."""

    def __init__(self, code: str, message: str, detail: str | None = None) -> None:
        super().__init__(detail or message)
        self.code = code
        self.message = message
        self.detail = detail


@dataclass(frozen=True)
class MoldInput:
    shape: MoldShape
    unit: str = "cm"
    diameter: float | None = None
    side: float | None = None
    width: float | None = None
    length: float | None = None


@dataclass(frozen=True)
class MoldIngredientInput:
    id: str
    display_name: str
    quantity: float
    unit: str
    scaling_mode: Literal["proportional", "unchanged", "round"] = "proportional"


@dataclass(frozen=True)
class MoldStepInput:
    id: str
    instruction: str
    duration_seconds: int = 0
    temperature_celsius: float | None = None
    heat: str | None = None
    action: str | None = None
    cookware: str | None = None
    doneness: str | None = None


@dataclass(frozen=True)
class ConvertedMoldIngredient:
    id: str
    display_name: str
    original_quantity: float
    display_quantity: float
    unit: str
    rule: str
    deviation_ratio: float | None
    deviation_warning: bool


@dataclass(frozen=True)
class ConvertedMoldStep:
    id: str
    instruction: str
    duration_seconds: int
    temperature_celsius: float | None
    heat: str | None
    time_advisory: str | None
    doneness_warning: bool
    doneness_warning_text: str | None


@dataclass(frozen=True)
class MoldConversionWarning:
    code: str
    ingredient_id: str | None
    message: str


@dataclass(frozen=True)
class MoldConversion:
    original_mold: dict[str, object]
    target_mold: dict[str, object]
    area_ratio: float
    ingredients: tuple[ConvertedMoldIngredient, ...]
    steps: tuple[ConvertedMoldStep, ...]
    warnings: tuple[MoldConversionWarning, ...]

    def as_dict(self) -> dict[str, object]:
        return asdict(self)


def _unit_factor(unit: str) -> Decimal:
    normalized = unit.strip().casefold()
    if normalized in {"cm", "厘米", "公分"}:
        return Decimal("1")
    if normalized in {"in", "inch", "inches", "寸"}:
        return Decimal("2.54")
    raise MoldConversionError("invalid_mold", "模具尺寸单位只支持厘米或英寸", f"unit={unit}")


def _positive(value: float | None, field: str) -> Decimal:
    if value is None or value <= 0:
        raise MoldConversionError("invalid_mold", "模具尺寸必须是正数", f"{field}={value}")
    return Decimal(str(value))


def _dimensions(mold: MoldInput) -> tuple[Decimal, Decimal]:
    """Return width and length in centimetres after validating the shape."""
    factor = _unit_factor(mold.unit)
    if mold.shape == "round":
        diameter = _positive(mold.diameter, "diameter") * factor
        return diameter, diameter
    if mold.shape == "square":
        side = mold.side if mold.side is not None else mold.width
        side_value = _positive(side, "side") * factor
        if mold.length is not None:
            length_value = _positive(mold.length, "length")
            raw_side = _positive(side, "side")
            if length_value != raw_side:
                raise MoldConversionError(
                    "invalid_mold", "方模的边长必须相等", "length 与 side 不一致"
                )
        return side_value, side_value
    if mold.shape in {"rectangular", "custom"}:
        width = _positive(mold.width, "width") * factor
        length = _positive(mold.length, "length") * factor
        return width, length
    raise MoldConversionError("invalid_mold", "不支持的模具形状", f"shape={mold.shape}")


def mold_area(mold: MoldInput) -> Decimal:
    width, length = _dimensions(mold)
    if mold.shape == "round":
        radius = width / Decimal("2")
        return Decimal(str(pi)) * radius * radius
    return width * length


def _number(value: Decimal) -> float:
    """Use stable two-decimal display precision without banker's rounding."""
    return float(value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))


def _whole(value: Decimal) -> Decimal:
    return value.quantize(Decimal("1"), rounding=ROUND_HALF_UP)


def _mold_dict(mold: MoldInput) -> dict[str, object]:
    return {
        "shape": mold.shape,
        "unit": mold.unit,
        "diameter": mold.diameter,
        "side": mold.side,
        "width": mold.width,
        "length": mold.length,
    }


def _is_baking_step(step: MoldStepInput) -> bool:
    context = " ".join(
        value.casefold()
        for value in (step.action, step.instruction, step.cookware, step.heat)
        if value
    )
    return any(
        marker in context
        for marker in ("烤", "焙", "烘", "烤箱", "oven", "bake", "roast")
    )


def convert_mold(
    *,
    original_mold: MoldInput,
    target_mold: MoldInput,
    ingredients: list[MoldIngredientInput],
    steps: list[MoldStepInput],
    round_deviation_threshold: float = 0.20,
) -> MoldConversion:
    """Convert proportional ingredients by bottom-area ratio.

    Unchanged ingredients and recipe step timing/temperature are deliberately
    preserved. Countable (``round``) ingredients are rounded half-up after the
    area ratio is applied and may produce a warning when the deviation is large.
    """
    if round_deviation_threshold < 0:
        raise MoldConversionError("invalid_mold_config", "模具换算阈值配置有误")
    source_area = mold_area(original_mold)
    target_area = mold_area(target_mold)
    if source_area <= 0 or target_area <= 0:  # defensive: _dimensions already checks this
        raise MoldConversionError("invalid_mold", "模具底面积必须是正数")
    ratio = target_area / source_area
    ingredients_out: list[ConvertedMoldIngredient] = []
    warnings: list[MoldConversionWarning] = []
    for item in ingredients:
        original = Decimal(str(item.quantity))
        theoretical = original * ratio
        rule = item.scaling_mode
        deviation_ratio: float | None = None
        deviation_warning = False
        if item.scaling_mode == "proportional":
            display = theoretical
            rule = "mold_ratio"
        elif item.scaling_mode == "unchanged":
            display = original
            rule = "unchanged"
        elif item.scaling_mode == "round":
            display = max(Decimal("1"), _whole(theoretical))
            rule = "round"
            if theoretical != 0:
                deviation_ratio = float(abs(display - theoretical) / abs(theoretical))
                deviation_warning = deviation_ratio > round_deviation_threshold
                if deviation_warning:
                    warnings.append(
                        MoldConversionWarning(
                            code="round_deviation",
                            ingredient_id=item.id,
                            message=(
                                f"{item.display_name}取整后与模具比例结果相差较大，"
                                "请按实际情况微调其他用量。"
                            ),
                        )
                    )
        else:
            raise MoldConversionError(
                "invalid_scaling_mode",
                "菜谱包含无法识别的缩放方式",
                f"ingredients[{item.id}].scaling_mode={item.scaling_mode}",
            )
        ingredients_out.append(
            ConvertedMoldIngredient(
                id=item.id,
                display_name=item.display_name,
                original_quantity=float(original),
                display_quantity=_number(display),
                unit=item.unit,
                rule=rule,
                deviation_ratio=deviation_ratio,
                deviation_warning=deviation_warning,
            )
        )

    steps_out: list[ConvertedMoldStep] = []
    for step in steps:
        has_baking_time = step.duration_seconds > 0 and _is_baking_step(step)
        steps_out.append(
            ConvertedMoldStep(
                id=step.id,
                instruction=step.instruction,
                duration_seconds=step.duration_seconds,
                temperature_celsius=step.temperature_celsius,
                heat=step.heat,
                time_advisory=_MOLD_TIME_ADVISORY if has_baking_time else None,
                doneness_warning=has_baking_time,
                doneness_warning_text=_DONENESS_WARNING if has_baking_time else None,
            )
        )
    if any(step.duration_seconds > 0 and _is_baking_step(step) for step in steps):
        warnings.append(
            MoldConversionWarning(
                code="doneness_check",
                ingredient_id=None,
                message="烘烤时间不按模具比例放大，请以成熟判断为准。",
            )
        )
    return MoldConversion(
        original_mold=_mold_dict(original_mold),
        target_mold=_mold_dict(target_mold),
        area_ratio=_number(ratio),
        ingredients=tuple(ingredients_out),
        steps=tuple(steps_out),
        warnings=tuple(warnings),
    )
