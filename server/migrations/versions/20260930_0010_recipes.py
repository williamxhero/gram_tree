"""最小私有菜谱闭环（SPEC-002.2 #105）。

Revision ID: 0010
Revises: 0009
Create Date: 2026-09-30
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0010"
down_revision: str | None = "0009"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "dishes",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("name"),
    )
    op.create_table(
        "dish_aliases",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("dish_id", sa.Uuid(), nullable=False),
        sa.Column("alias", sa.String(length=200), nullable=False),
        sa.ForeignKeyConstraint(["dish_id"], ["dishes.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("alias", name="uq_dish_aliases_alias"),
    )
    op.create_index("ix_dish_aliases_dish_id", "dish_aliases", ["dish_id"], unique=False)

    # The three recipe tables refer to one another. Create the columns first and
    # add the two forward foreign keys after recipe_versions exists.
    op.create_table(
        "recipes",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("dish_id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("visibility", sa.String(length=16), nullable=False),
        sa.Column("current_version_id", sa.Uuid(), nullable=True),
        sa.Column("source_version_id", sa.Uuid(), nullable=True),
        sa.Column("root_recipe_id", sa.Uuid(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["dish_id"], ["dishes.id"]),
        sa.ForeignKeyConstraint(["owner_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["root_recipe_id"], ["recipes.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_recipes_dish_id", "recipes", ["dish_id"], unique=False)
    op.create_index("ix_recipes_owner_id", "recipes", ["owner_id"], unique=False)
    op.create_index(
        "ix_recipes_owner_updated_at", "recipes", ["owner_id", "updated_at"], unique=False
    )

    op.create_table(
        "recipe_versions",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("recipe_id", sa.Uuid(), nullable=False),
        sa.Column("version_number", sa.Integer(), nullable=False),
        sa.Column("previous_version_id", sa.Uuid(), nullable=True),
        sa.Column("snapshot", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("derived", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("edit_operations", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("change_note", sa.Text(), nullable=False),
        sa.Column("ai_assisted", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["previous_version_id"], ["recipe_versions.id"]),
        sa.ForeignKeyConstraint(["recipe_id"], ["recipes.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("recipe_id", "version_number", name="uq_recipe_versions_recipe_number"),
    )
    op.create_index("ix_recipe_versions_recipe_id", "recipe_versions", ["recipe_id"], unique=False)
    op.create_index(
        "ix_recipe_versions_recipe_created_at",
        "recipe_versions",
        ["recipe_id", "created_at"],
        unique=False,
    )
    op.create_foreign_key(
        "fk_recipes_current_version_id",
        "recipes",
        "recipe_versions",
        ["current_version_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_recipes_source_version_id",
        "recipes",
        "recipe_versions",
        ["source_version_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_table(
        "recipe_save_outbox",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("recipe_id", sa.Uuid(), nullable=False),
        sa.Column("version_id", sa.Uuid(), nullable=False),
        sa.Column("owner_id", sa.Uuid(), nullable=False),
        sa.Column("previous_version_id", sa.Uuid(), nullable=True),
        sa.Column("edit_operations", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("ai_assisted", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("delivered_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["recipe_id"], ["recipes.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["version_id"], ["recipe_versions.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["owner_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("version_id", name="uq_recipe_save_outbox_version"),
    )
    op.create_index("ix_recipe_save_outbox_recipe_id", "recipe_save_outbox", ["recipe_id"])
    op.create_index("ix_recipe_save_outbox_version_id", "recipe_save_outbox", ["version_id"])
    op.create_index("ix_recipe_save_outbox_owner_id", "recipe_save_outbox", ["owner_id"])
    op.create_table(
        "recipe_images",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("recipe_id", sa.Uuid(), nullable=False),
        sa.Column("version_id", sa.Uuid(), nullable=False),
        sa.Column("storage_key", sa.String(500), nullable=False),
        sa.Column("content_type", sa.String(64), nullable=False),
        sa.Column("byte_size", sa.Integer(), nullable=False),
        sa.Column("width", sa.Integer(), nullable=True),
        sa.Column("height", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["recipe_id"], ["recipes.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["version_id"], ["recipe_versions.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_recipe_images_recipe_id", "recipe_images", ["recipe_id"])
    op.create_index("ix_recipe_images_version_id", "recipe_images", ["version_id"])
    op.create_index(
        "ix_recipe_images_version_created", "recipe_images", ["version_id", "created_at"]
    )


def downgrade() -> None:
    op.drop_index("ix_recipe_images_version_created", table_name="recipe_images")
    op.drop_index("ix_recipe_images_version_id", table_name="recipe_images")
    op.drop_index("ix_recipe_images_recipe_id", table_name="recipe_images")
    op.drop_table("recipe_images")
    op.drop_index("ix_recipe_save_outbox_owner_id", table_name="recipe_save_outbox")
    op.drop_index("ix_recipe_save_outbox_version_id", table_name="recipe_save_outbox")
    op.drop_index("ix_recipe_save_outbox_recipe_id", table_name="recipe_save_outbox")
    op.drop_table("recipe_save_outbox")
    op.drop_constraint("fk_recipes_source_version_id", "recipes", type_="foreignkey")
    op.drop_constraint("fk_recipes_current_version_id", "recipes", type_="foreignkey")
    op.drop_index("ix_recipe_versions_recipe_created_at", table_name="recipe_versions")
    op.drop_index("ix_recipe_versions_recipe_id", table_name="recipe_versions")
    op.drop_table("recipe_versions")
    op.drop_index("ix_recipes_owner_updated_at", table_name="recipes")
    op.drop_index("ix_recipes_owner_id", table_name="recipes")
    op.drop_index("ix_recipes_dish_id", table_name="recipes")
    op.drop_table("recipes")
    op.drop_index("ix_dish_aliases_dish_id", table_name="dish_aliases")
    op.drop_table("dish_aliases")
    op.drop_table("dishes")
