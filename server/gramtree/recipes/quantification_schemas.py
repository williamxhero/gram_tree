"""Server-owned proposals and author decisions, never client-owned provenance."""

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

from gramtree.core.ids import IdV4
from gramtree.recipes.schemas import ReproducibilityProblem
from gramtree.ui_protocol.protocol import DetailLevel

Confidence = Literal["high", "medium", "low"]


class QuantificationInput(BaseModel):
    model_config = ConfigDict(extra="forbid")
    base_version_id: IdV4


class QuantificationSuggestion(BaseModel):
    model_config = ConfigDict(extra="forbid")
    problem_id: str = Field(min_length=1, max_length=300)
    value: str = Field(min_length=1, max_length=2000)
    unit: str | None = Field(default=None, min_length=1, max_length=20)
    basis: str = Field(min_length=1, max_length=500)
    confidence: Confidence
    baseline: str | None = Field(default=None, min_length=1, max_length=500)
    adjustment: str | None = Field(default=None, min_length=1, max_length=500)

    @model_validator(mode="after")
    def paired_variable(self):
        if bool(self.baseline) != bool(self.adjustment):
            raise ValueError("变量必须同时提供基准和调整方法")
        if any(
            value is not None and not value.strip()
            for value in (self.value, self.basis, self.unit, self.baseline, self.adjustment)
        ):
            raise ValueError("具体值、依据及变量说明不能为空")
        return self


class QuantificationOutput(BaseModel):
    model_config = ConfigDict(extra="forbid")
    suggestions: list[QuantificationSuggestion] = Field(min_length=1, max_length=2000)


class RecipeQuantificationOut(BaseModel):
    id: IdV4
    base_version_id: IdV4
    detail: DetailLevel = Field(default="standard", description="服务端选择的组件详略档位")
    problems: list[ReproducibilityProblem]
    suggestions: list[QuantificationSuggestion]


class QuantificationDecision(BaseModel):
    model_config = ConfigDict(extra="forbid")
    problem_id: str
    decision: Literal["accept", "modify", "ignore"]
    value: str | None = Field(default=None, min_length=1, max_length=2000)
    unit: str | None = Field(default=None, min_length=1, max_length=20)

    @model_validator(mode="after")
    def manual_value_only(self):
        if self.decision == "modify":
            if self.value is None or not self.value.strip():
                raise ValueError("修改需要具体值")
        elif self.value is not None or self.unit is not None:
            raise ValueError("接受或忽略不能传入建议值")
        return self


class QuantificationDecisionsInput(BaseModel):
    model_config = ConfigDict(extra="forbid")
    decisions: list[QuantificationDecision] = Field(default_factory=list, max_length=2000)
    accept_all: bool = False

    @model_validator(mode="after")
    def one_mode(self):
        if self.accept_all == bool(self.decisions):
            raise ValueError("请逐条处理或全部接受")
        ids = [d.problem_id for d in self.decisions]
        if len(ids) != len(set(ids)):
            raise ValueError("不能重复处理同一问题")
        return self
