"""Add ingredient tables

Revision ID: 0006
Revises: 0005
Create Date: 2026-09-30

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "0006"
down_revision: str | None = "0005"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create ingredients table
    op.create_table(
        'ingredients',
        sa.Column('id', sa.String(length=64), nullable=False),
        sa.Column('standard_name', sa.String(length=100), nullable=False),
        sa.Column('pinyin', sa.String(length=200), nullable=False),
        sa.Column('pinyin_initial', sa.String(length=50), nullable=False),
        sa.Column('category', sa.String(length=50), nullable=False),
        sa.Column('version', sa.String(length=20), nullable=False),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.PrimaryKeyConstraint('id', name=op.f('pk_ingredients'))
    )
    op.create_index('ix_ingredients_category', 'ingredients', ['category'])
    op.create_index('ix_ingredients_pinyin_initial', 'ingredients', ['pinyin_initial'])
    op.create_index('ix_ingredients_pinyin_initial_prefix', 'ingredients', ['pinyin_initial'], postgresql_ops={'pinyin_initial': 'text_pattern_ops'})
    op.create_index('ix_ingredients_pinyin', 'ingredients', ['pinyin'])
    op.create_index('ix_ingredients_pinyin_prefix', 'ingredients', ['pinyin'], postgresql_ops={'pinyin': 'text_pattern_ops'})
    op.create_index('ix_ingredients_standard_name', 'ingredients', ['standard_name'])

    # Create ingredient_aliases table
    op.create_table(
        'ingredient_aliases',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('ingredient_id', sa.String(length=64), nullable=False),
        sa.Column('alias', sa.String(length=100), nullable=False),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['ingredient_id'], ['ingredients.id'], name=op.f('fk_ingredient_aliases_ingredient_id_ingredients'), ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id', name=op.f('pk_ingredient_aliases')),
        sa.UniqueConstraint('ingredient_id', 'alias', name='uq_ingredient_aliases_ingredient_alias')
    )
    op.create_index('ix_ingredient_aliases_alias', 'ingredient_aliases', ['alias'])
    op.create_index('ix_ingredient_aliases_alias_prefix', 'ingredient_aliases', ['alias'], postgresql_ops={'alias': 'text_pattern_ops'})
    op.create_index('ix_ingredient_aliases_ingredient_id', 'ingredient_aliases', ['ingredient_id'])

    # Create ingredient_versions table
    op.create_table(
        'ingredient_versions',
        sa.Column('version', sa.String(length=20), nullable=False),
        sa.Column('released_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('changelog', sa.String(length=1000), nullable=False),
        sa.PrimaryKeyConstraint('version', name=op.f('pk_ingredient_versions'))
    )

    # Create ingredient_merges table
    op.create_table(
        'ingredient_merges',
        sa.Column('old_id', sa.String(length=64), nullable=False),
        sa.Column('new_id', sa.String(length=64), nullable=False),
        sa.Column('merged_at', sa.TIMESTAMP(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('reason', sa.String(length=500), nullable=True),
        sa.ForeignKeyConstraint(['new_id'], ['ingredients.id'], name=op.f('fk_ingredient_merges_new_id_ingredients'), ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('old_id', name=op.f('pk_ingredient_merges'))
    )
    op.create_index('ix_ingredient_merges_new_id', 'ingredient_merges', ['new_id'])


def downgrade() -> None:
    op.drop_index('ix_ingredient_merges_new_id', table_name='ingredient_merges')
    op.drop_table('ingredient_merges')
    op.drop_table('ingredient_versions')
    op.drop_index('ix_ingredient_aliases_ingredient_id', table_name='ingredient_aliases')
    op.drop_index('ix_ingredient_aliases_alias_prefix', table_name='ingredient_aliases')
    op.drop_index('ix_ingredient_aliases_alias', table_name='ingredient_aliases')
    op.drop_table('ingredient_aliases')
    op.drop_index('ix_ingredients_standard_name', table_name='ingredients')
    op.drop_index('ix_ingredients_pinyin_prefix', table_name='ingredients')
    op.drop_index('ix_ingredients_pinyin', table_name='ingredients')
    op.drop_index('ix_ingredients_pinyin_initial_prefix', table_name='ingredients')
    op.drop_index('ix_ingredients_pinyin_initial', table_name='ingredients')
    op.drop_index('ix_ingredients_category', table_name='ingredients')
    op.drop_table('ingredients')
