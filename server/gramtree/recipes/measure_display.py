"""Deterministic conversion from recipe base quantities to kitchen displays."""

from __future__ import annotations

from typing import Any

_FRACTIONS = (0.25, 1 / 3, 0.5, 2 / 3, 0.75, 1.0)


def _rounded_fraction(value: float) -> tuple[float, str]:
    if value <= 0:
        return 0.0, "0"
    whole = int(value)
    remainder = value - whole
    if remainder < 0.125 and whole == 0:
        # "0 勺" is not measurable; tiny positive amounts use the smallest
        # common fraction, and the grams shown alongside stay exact.
        return 0.25, "1/4"
    if remainder < 0.125:
        rounded = float(whole)
    else:
        fraction = min(_FRACTIONS, key=lambda candidate: abs(candidate - remainder))
        rounded = whole + fraction
        if rounded == whole + 1:
            whole += 1
            rounded = float(whole)
    if rounded == int(rounded):
        return rounded, str(int(rounded))
    fraction = round(rounded - int(rounded), 6)
    labels = {
        round(0.25, 6): "1/4",
        round(1 / 3, 6): "1/3",
        round(0.5, 6): "1/2",
        round(2 / 3, 6): "2/3",
        round(0.75, 6): "3/4",
    }
    label = labels[fraction]
    return rounded, f"{int(rounded)} {label}" if int(rounded) else label


def quantity_text(value: float) -> str:
    return str(int(value)) if value == int(value) else f"{value:.2f}".rstrip("0").rstrip(".")


def _grams(base_quantity: float, base_unit: str, density: float | None) -> float | None:
    if base_unit == "g":
        return base_quantity
    if base_unit == "ml" and density is not None:
        return base_quantity * density
    return None


def _base_result(base_quantity: float, base_unit: str, density: float | None) -> dict[str, Any]:
    unit = "g" if base_unit == "g" else "ml"
    unit_text = "克" if unit == "g" else "毫升"
    grams = _grams(base_quantity, unit, density) if unit == "ml" else base_quantity
    return {
        "text": f"{quantity_text(base_quantity)} {unit_text}",
        "display_quantity": float(base_quantity),
        "display_unit": unit,
        "grams": None if unit == "ml" and density is None else grams,
        "rule": "base",
    }


def _standard_result(base_quantity: float, base_unit: str, density: float | None) -> dict[str, Any]:
    millilitres = base_quantity if base_unit == "ml" else None
    if millilitres is None and density is not None:
        millilitres = base_quantity / density
    if millilitres is None:
        result = _base_result(base_quantity, base_unit, density)
        result["rule"] = "no_density"
        return result

    candidates = ((15.0, "汤匙"), (5.0, "茶匙"))
    quantity, unit, size = min(
        ((_rounded_fraction(millilitres / size)[0], label, size) for size, label in candidates),
        key=lambda item: (abs(item[0] * item[2] - millilitres), -item[2]),
    )
    _, fraction_text = _rounded_fraction(millilitres / size)
    grams = _grams(base_quantity, base_unit, density)
    grams_text = f"（{quantity_text(grams)} 克）" if grams is not None else ""
    return {
        "text": f"{fraction_text} {unit}{grams_text}",
        "display_quantity": quantity,
        "display_unit": unit,
        "grams": grams,
        "rule": "standard_measure",
    }


def display_amount(
    *,
    base_quantity: float,
    base_unit: str,
    density: float | None,
    mode: str,
    measure: dict[str, Any] | None,
) -> dict[str, Any]:
    """Return the stable display contract without mutating recipe source data."""
    if base_quantity < 0 or base_unit not in {"g", "ml"}:
        raise ValueError("基础量必须是非负克或毫升")
    if density is not None and density <= 0:
        raise ValueError("密度必须为正数")
    if mode == "base":
        return _base_result(float(base_quantity), base_unit, density)
    if mode == "standard":
        return _standard_result(float(base_quantity), base_unit, density)
    if mode != "home" or measure is None:
        raise ValueError("自家量具模式必须提供量具")
    capacity = float(measure["capacity_ml"])
    if capacity <= 0:
        raise ValueError("量具容量必须为正数")
    millilitres = base_quantity if base_unit == "ml" else None
    if millilitres is None and density is not None:
        millilitres = base_quantity / density
    if millilitres is None:
        result = _base_result(base_quantity, base_unit, density)
        result["rule"] = "no_density"
        return result
    quantity, fraction_text = _rounded_fraction(millilitres / capacity)
    grams = _grams(base_quantity, base_unit, density)
    grams_text = (
        f"（{quantity_text(grams)} 克）"
        if grams is not None
        else f"（{quantity_text(base_quantity)} 毫升）"
    )
    return {
        "text": f"约 {fraction_text} {measure['name']}{grams_text}",
        "display_quantity": quantity,
        "display_unit": str(measure["name"]),
        "grams": grams,
        "rule": "personal_measure",
    }
