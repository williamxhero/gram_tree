"""Operator-only improvement curation; never exposed as an authenticated user route.

python -m gramtree.recipes.improvement_cli show RECIPE_ID
python -m gramtree.recipes.improvement_cli set RECIPE_ID --by OPERATOR --reason REASON
python -m gramtree.recipes.improvement_cli unset RECIPE_ID --by OPERATOR --reason REASON
"""

import argparse
import json
import sys
import uuid

from gramtree.core.errors import ApiError
from gramtree.db import make_engine, make_session_factory
from gramtree.recipes.improvement_models import ImprovementCuration, RecipeImprovementFact
from gramtree.recipes.improvements import branch_inputs, creation_event
from gramtree.recipes.models import Recipe
from gramtree.settings import get_settings


def main() -> int:
    parser = argparse.ArgumentParser(description="运营设置或撤销改良精选")
    parser.add_argument("action", choices=["show", "set", "unset"])
    parser.add_argument("recipe_id", type=uuid.UUID)
    parser.add_argument("--by")
    parser.add_argument("--reason")
    args = parser.parse_args()
    if args.action != "show" and (
        not args.by or not args.by.strip() or not args.reason or not args.reason.strip()
    ):
        parser.error("写入必须填写 --by 和 --reason")
    factory = make_session_factory(make_engine(get_settings().database_url))
    with factory() as session:
        fact = session.get(RecipeImprovementFact, args.recipe_id)
        recipe = session.get(Recipe, args.recipe_id)
        if fact is None or recipe is None:
            print("改良菜谱不存在", file=sys.stderr)
            return 1
        if args.action != "show":
            # Lock the recipe so concurrent operator requests have a linear audit trail.
            from sqlalchemy import select

            session.scalar(select(Recipe).where(Recipe.id == recipe.id).with_for_update())
            row = session.get(ImprovementCuration, recipe.id)
            if row is None:
                row = ImprovementCuration(
                    recipe_id=recipe.id, curated=False, changed_by=args.by, reason=args.reason
                )
                session.add(row)
            before = row.curated
            row.curated = args.action == "set"
            row.changed_by = args.by
            row.reason = args.reason
            from gramtree.core.time import utcnow

            row.updated_at = utcnow()
            if before != row.curated:
                creation_event(
                    session,
                    recipe.owner_id,
                    "recipe.improvement_curated",
                    {
                        "recipe_id": str(recipe.id),
                        "curated": row.curated,
                        "changed_by": args.by,
                        "reason": args.reason,
                    },
                    {"recipe_version_id": str(fact.version_id)},
                )
            session.commit()
        try:
            print(json.dumps(branch_inputs(session, recipe.id), ensure_ascii=False))
        except ApiError as exc:
            print(str(exc), file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
