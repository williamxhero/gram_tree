"""汇总所有数据表模型，给 Alembic 自动比对用。新模块的模型在这里 import。"""

from gramtree.accounts import models as _accounts  # noqa: F401
from gramtree.db import Base
from gramtree.examples import models as _examples  # noqa: F401
from gramtree.runtime_config import models as _runtime_config  # noqa: F401

metadata = Base.metadata
