"""汇总所有数据表模型，给 Alembic 自动比对用。新模块的模型在这里 import。"""

from gramtree.accounts import models as _accounts  # noqa: F401
from gramtree.analytics import models as _analytics  # noqa: F401
from gramtree.db import Base
from gramtree.events import models as _events  # noqa: F401
from gramtree.examples import models as _examples  # noqa: F401
from gramtree.ingredients import models as _ingredients  # noqa: F401
from gramtree.recipes import measure_models as _measure_models  # noqa: F401
from gramtree.recipes import models as _recipes  # noqa: F401
from gramtree.runtime_config import models as _runtime_config  # noqa: F401

metadata = Base.metadata
