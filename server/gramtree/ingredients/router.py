"""食材库 HTTP 接口（SPEC-002.1 #19）。"""

from fastapi import APIRouter
from pydantic import BaseModel
from sqlalchemy import select

from gramtree.core.errors import ERROR_RESPONSES, NotFound
from gramtree.core.ids import IdV4
from gramtree.deps import SessionDep
from gramtree.ingredients.models import Ingredient, IngredientAlias

router = APIRouter(prefix="/ingredients", tags=["ingredients"])


class IngredientOut(BaseModel):
    id: IdV4
    standard_name: str
    aliases: list[str]
    pinyin: str
    pinyin_initials: str
    category: str
    version: str


@router.get("/{ingredient_id}", response_model=IngredientOut, responses=ERROR_RESPONSES)
def get_ingredient(ingredient_id: IdV4, db: SessionDep) -> IngredientOut:
    """读取一种食材的信息。如果这个 ID 已经合并到另一个,自动返回合并后的食材。"""
    current = ingredient_id
    for _ in range(10):  # 防止数据错误导致的死循环
        row = db.get(Ingredient, current)
        if row is None:
            raise NotFound()
        if row.merged_into is None:
            break
        current = row.merged_into
    else:
        raise NotFound(f"合并链太长或有循环：{ingredient_id}")

    aliases = list(
        db.scalars(select(IngredientAlias.alias).where(IngredientAlias.ingredient_id == row.id))
    )
    return IngredientOut(
        id=row.id,
        standard_name=row.standard_name,
        aliases=aliases,
        pinyin=row.pinyin,
        pinyin_initials=row.pinyin_initials,
        category=row.category,
        version=row.version,
    )
