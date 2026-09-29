"""测试食材库基础数据模型和迁移。

验证 #86 的 acceptance criteria:
- 数据库表创建成功
- SQLAlchemy 模型工作正常
- 基础 CRUD 操作
"""

import pytest
from sqlalchemy import select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from gramtree.ingredients.models import (
    Ingredient,
    IngredientAlias,
    IngredientMerge,
    IngredientVersion,
)


def test_ingredient_crud(engine: Engine) -> None:
    """测试食材的基础 CRUD 操作。"""
    with Session(engine) as session:
        # 插入一种食材
        ingredient = Ingredient(
            id="ing_soy_sauce_001",
            standard_name="生抽",
            pinyin="shengchou",
            pinyin_initial="sc",
            category="调料",
            version="1.0.0",
        )
        session.add(ingredient)
        session.commit()

        # 按 ID 查询
        result = session.execute(
            select(Ingredient).where(Ingredient.id == "ing_soy_sauce_001")
        ).scalar_one()
        assert result.standard_name == "生抽"
        assert result.pinyin == "shengchou"
        assert result.pinyin_initial == "sc"
        assert result.category == "调料"
        assert result.version == "1.0.0"


def test_ingredient_alias(engine: Engine) -> None:
    """测试食材别名。"""
    with Session(engine) as session:
        # 插入食材和别名
        ingredient = Ingredient(
            id="ing_soy_sauce_001",
            standard_name="生抽",
            pinyin="shengchou",
            pinyin_initial="sc",
            category="调料",
            version="1.0.0",
        )
        session.add(ingredient)
        session.flush()

        alias1 = IngredientAlias(ingredient_id="ing_soy_sauce_001", alias="酱油")
        alias2 = IngredientAlias(ingredient_id="ing_soy_sauce_001", alias="味极鲜")
        session.add_all([alias1, alias2])
        session.commit()

        # 查询别名
        aliases = session.execute(
            select(IngredientAlias).where(
                IngredientAlias.ingredient_id == "ing_soy_sauce_001"
            )
        ).scalars().all()
        assert len(aliases) == 2
        alias_names = {a.alias for a in aliases}
        assert alias_names == {"酱油", "味极鲜"}


def test_ingredient_version(engine: Engine) -> None:
    """测试版本记录。"""
    with Session(engine) as session:
        version = IngredientVersion(
            version="1.0.0",
            changelog="初始版本，约 300 种常见食材",
        )
        session.add(version)
        session.commit()

        # 查询版本
        result = session.execute(
            select(IngredientVersion).where(IngredientVersion.version == "1.0.0")
        ).scalar_one()
        assert result.changelog == "初始版本，约 300 种常见食材"
        assert result.released_at is not None


def test_ingredient_merge(engine: Engine) -> None:
    """测试食材合并记录。"""
    with Session(engine) as session:
        # 创建新旧两种食材
        old_ingredient = Ingredient(
            id="ing_soy_sauce_old",
            standard_name="老抽",
            pinyin="laochou",
            pinyin_initial="lc",
            category="调料",
            version="1.0.0",
        )
        new_ingredient = Ingredient(
            id="ing_soy_sauce_new",
            standard_name="生抽",
            pinyin="shengchou",
            pinyin_initial="sc",
            category="调料",
            version="1.1.0",
        )
        session.add_all([old_ingredient, new_ingredient])
        session.flush()

        # 记录合并
        merge = IngredientMerge(
            old_id="ing_soy_sauce_old",
            new_id="ing_soy_sauce_new",
            reason="合并老抽到生抽统一条目",
        )
        session.add(merge)
        session.commit()

        # 查询合并记录
        result = session.execute(
            select(IngredientMerge).where(IngredientMerge.old_id == "ing_soy_sauce_old")
        ).scalar_one()
        assert result.new_id == "ing_soy_sauce_new"
        assert result.reason == "合并老抽到生抽统一条目"


def test_query_by_version(engine: Engine) -> None:
    """测试按版本过滤查询。"""
    with Session(engine) as session:
        # 插入不同版本的食材
        ing1 = Ingredient(
            id="ing_001",
            standard_name="食材1",
            pinyin="shicai1",
            pinyin_initial="sc1",
            category="测试",
            version="1.0.0",
        )
        ing2 = Ingredient(
            id="ing_002",
            standard_name="食材2",
            pinyin="shicai2",
            pinyin_initial="sc2",
            category="测试",
            version="1.1.0",
        )
        session.add_all([ing1, ing2])
        session.commit()

        # 按版本查询
        v1_ingredients = session.execute(
            select(Ingredient).where(Ingredient.version == "1.0.0")
        ).scalars().all()
        assert len(v1_ingredients) == 1
        assert v1_ingredients[0].id == "ing_001"

        v11_ingredients = session.execute(
            select(Ingredient).where(Ingredient.version == "1.1.0")
        ).scalars().all()
        assert len(v11_ingredients) == 1
        assert v11_ingredients[0].id == "ing_002"


def test_cascade_delete_aliases(engine: Engine) -> None:
    """测试删除食材时级联删除别名。"""
    with Session(engine) as session:
        # 插入食材和别名
        ingredient = Ingredient(
            id="ing_to_delete",
            standard_name="待删除",
            pinyin="daishanchu",
            pinyin_initial="dsc",
            category="测试",
            version="1.0.0",
        )
        session.add(ingredient)
        session.flush()

        alias = IngredientAlias(ingredient_id="ing_to_delete", alias="别名")
        session.add(alias)
        session.commit()

        # 删除食材
        session.delete(ingredient)
        session.commit()

        # 别名应该被级联删除
        aliases = session.execute(
            select(IngredientAlias).where(IngredientAlias.ingredient_id == "ing_to_delete")
        ).scalars().all()
        assert len(aliases) == 0
