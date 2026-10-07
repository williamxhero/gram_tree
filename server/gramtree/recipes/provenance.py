"""Attribute manual edits without trusting a client to manufacture verification."""

from pydantic import BaseModel

from gramtree.recipes.schemas import RecipeSnapshot, ValueSource


def normalize_sources(
    snapshot: RecipeSnapshot,
    baseline: RecipeSnapshot | None = None,
    *,
    trusted_sources: bool = False,
) -> RecipeSnapshot:
    result = snapshot.model_copy(deep=True)

    def fill(node: BaseModel, old: BaseModel | None, fields: dict[str, tuple[str, ...]]) -> None:
        for source_field, values in fields.items():
            incoming = getattr(node, source_field)
            previous = getattr(old, source_field) if old is not None else None
            changed = old is not None and any(
                getattr(node, field) != getattr(old, field) for field in values
            )
            if changed and not trusted_sources:
                source = (
                    incoming
                    if incoming is not None and incoming.source == "author_filled"
                    else ValueSource(source="author_filled")
                )
            elif previous is not None and previous.source == "verified" and not changed:
                # Future cooking evidence stays backend-owned. The client omits
                # the verified source, while the unchanged baseline supplies it.
                source = previous
            else:
                source = (
                    incoming
                    or (previous if not changed else None)
                    or ValueSource(source="author_filled")
                )
            setattr(node, source_field, source)

    fill(
        result,
        baseline,
        {
            "servings_source": ("servings",),
            "text_source": ("description", "cuisine", "design_rationale"),
        },
    )
    old_items = {item.id: item for item in baseline.ingredients} if baseline else {}
    for item in result.ingredients:
        fill(
            item,
            old_items.get(item.id),
            {
                "quantity_source": ("quantity", "unit", "display_name", "ingredient_id"),
                "preparation_source": ("preparation",),
            },
        )
    old_steps = {step.id: step for step in baseline.steps} if baseline else {}
    for step in result.steps:
        fill(
            step,
            old_steps.get(step.id),
            {
                "instruction_source": ("instruction",),
                "duration_source": ("duration_seconds",),
                "heat_source": ("heat",),
                "temperature_source": ("temperature_celsius",),
                "doneness_source": ("doneness",),
            },
        )
    return result
