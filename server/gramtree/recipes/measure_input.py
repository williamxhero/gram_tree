"""Confirmed personal-measure input, independent of later tool/library changes."""

import math
import uuid
from typing import Literal

import jwt
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.core.errors import ApiError, NotFound
from gramtree.core.ids import IdV4
from gramtree.ingredients.models import Ingredient, IngredientAttribute
from gramtree.recipes.measure_models import PersonalMeasure
from gramtree.recipes.schemas import RecipeIngredient, ValueSource


def _exact_text(value: float) -> str:
    # Provenance must retain actual adopted values, not display-rounded values.
    return str(int(value)) if value == int(value) else str(value)


class MeasureInputRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    measure_id: IdV4
    ingredient_id: IdV4 | None = None
    quantity: float = Field(ge=0, le=10_000_000, allow_inf_nan=False)
    base_unit: Literal["g", "ml"]
    accept_estimate: bool = False


class MeasureInputOut(BaseModel):
    original: str
    base_quantity: float | None = None
    base_unit: Literal["g", "ml"]
    status: Literal["ready", "no_density", "estimate_confirmation_required"]
    basis: str
    quantity_source: ValueSource | None = None
    measure_input_token: str | None = None


def preview_input(
    session: Session, owner_id: uuid.UUID, body: MeasureInputRequest, signing_secret: str
) -> MeasureInputOut:
    measure = session.scalar(
        select(PersonalMeasure).where(
            PersonalMeasure.id == body.measure_id,
            PersonalMeasure.owner_id == owner_id,
            PersonalMeasure.deleted_at.is_(None),
        )
    )
    if measure is None:
        raise NotFound()
    original = f"{_exact_text(body.quantity)} {measure.name}"
    basis = (
        f"作者登记的{measure.name}，每次容量 {_exact_text(measure.capacity_ml)} 毫升；"
        f"输入 {original}。"
    )
    quantity = body.quantity * measure.capacity_ml
    estimated = False
    if body.ingredient_id is not None and session.get(Ingredient, body.ingredient_id) is None:
        raise NotFound("标准食材不存在")
    if body.base_unit == "g":
        density = (
            session.scalar(
                select(IngredientAttribute).where(
                    IngredientAttribute.ingredient_id == body.ingredient_id,
                    IngredientAttribute.field == "density",
                )
            )
            if body.ingredient_id is not None
            else None
        )
        if density is None:
            return MeasureInputOut(
                original=original,
                base_unit=body.base_unit,
                status="no_density",
                basis=basis + "缺少密度数据，无法可靠换算成克；请填写克数或改用毫升。",
            )
        ingredient = session.get(Ingredient, body.ingredient_id)
        assert ingredient is not None
        value = float(density.value)
        quantity *= value
        estimated = density.status != "verified"
        basis += (
            f"密度 {_exact_text(value)} 克/毫升，来源：{density.source}；"
            f"食材库版本 {ingredient.version}，{'估算、未经校对' if estimated else '已校对'}。"
        )
    if not math.isfinite(quantity) or quantity > 10_000_000:
        raise ApiError(422, "invalid_request", "换算后的基础量超出范围")
    if estimated and not body.accept_estimate:
        return MeasureInputOut(
            original=original,
            base_quantity=quantity,
            base_unit=body.base_unit,
            status="estimate_confirmation_required",
            basis=basis,
        )
    source = ValueSource(
        source="ai_estimated" if estimated else "author_filled", original=original, basis=basis
    )
    # Receipt binds the accepted input to the account and ingredient, not mutable
    # rows. A recovered draft remains usable after recalibration/deletion. It is
    # deliberately not an authentication token and cannot authorize API calls.
    token = jwt.encode(
        {
            "purpose": "personal_measure_input_v1",
            "owner": str(owner_id),
            "ingredient_id": str(body.ingredient_id) if body.ingredient_id else None,
            "quantity": quantity,
            "unit": body.base_unit,
            "source": source.model_dump(),
        },
        signing_secret + ":personal-measure-input-v1",
        algorithm="HS256",
    )
    return MeasureInputOut(
        original=original,
        base_quantity=quantity,
        base_unit=body.base_unit,
        status="ready",
        basis=basis,
        quantity_source=source,
        measure_input_token=token,
    )


def confirmed_source(
    ingredient: RecipeIngredient,
    owner_id: uuid.UUID | None,
    signing_secret: str,
    baseline: RecipeIngredient | None = None,
) -> ValueSource | None:
    if ingredient.measure_input_token is None:
        return None
    # Only the caller's account-owned editing baseline is trusted. Identical
    # adopted evidence survives signing-key rotation; client-swapped values do not.
    if baseline is not None and all(
        getattr(ingredient, field) == getattr(baseline, field)
        for field in (
            "id",
            "ingredient_id",
            "measure_input_token",
            "quantity",
            "unit",
            "base_quantity",
            "base_unit",
            "quantity_source",
        )
    ):
        return baseline.quantity_source
    try:
        receipt = jwt.decode(
            ingredient.measure_input_token,
            signing_secret + ":personal-measure-input-v1",
            algorithms=["HS256"],
        )
        if (
            receipt.get("purpose") != "personal_measure_input_v1"
            or receipt.get("owner") != str(owner_id)
            or receipt.get("ingredient_id")
            != (str(ingredient.ingredient_id) if ingredient.ingredient_id else None)
            or receipt.get("quantity") != ingredient.quantity
            or receipt.get("unit") != ingredient.unit
        ):
            raise ValueError("量具确认与当前食材或用量不一致")
        return ValueSource.model_validate(receipt["source"])
    except (jwt.InvalidTokenError, ValueError, KeyError, TypeError) as exc:
        raise ApiError(
            422, "invalid_measure_input", "量具输入确认已失效，请重新换算或改用基础单位"
        ) from exc
