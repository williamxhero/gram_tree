# 一句话菜谱模型边界（SPEC-003.1）

默认 `GRAMTREE_AI_MODE=disabled`，不依赖模型的查看、结构化编辑、保存、换算正常工作。
禁用/超时/无额度时只做本地菜名关键词检索，不凭规则编造菜谱。

## 接入与运维

- `GRAMTREE_AI_MODE`：`disabled` / `live` / `replay` / `record`。
- `GRAMTREE_AI_API_KEY`：部署密钥，只从环境/密钥管理注入，不写入配置表、仓库或录制文件。
- `GRAMTREE_AI_REPLAY_DIR`：重放或录制目录；录制只用于合成输入，严禁生产用户数据。
- `ai.routes`：`intent`、`generate`、`normalize`、`embedding` 能力到 `small` / `large` / `vector` 档位。
- `ai.models`：每档 `provider`、`base_url`（OpenAI 兼容 API 根地址）、`model`，可选 `input_price` / `output_price`（每百万 token 同一计价单位）。供应商名称无硬编码。
- `ai.policies`：每能力 `timeout` 秒、`retries`（0–2）、`daily_limit`、`users`（用户 UUID → 每日额度覆盖）。按 UTC 日统计；一次生成的纠正和网络重试共享操作 ID，不重复计用户次数。
- `ai.monthly_budget`、`ai.budget_alert_ratio`、`ai.call_reservation`：全平台 UTC 月上限、告警比例、未知用量保守预留。配置价格需采用供应商实际上界；失败调用保留预留，避免未知成本漏算。
- `ai.log_retention_days`：请求/回答和生成会话默认 90 天。用量汇总长期保留以核算月预算，不通过 HTTP 暴露内部日志。

通过现有审计入口修改，例如：

```bash
gramtree config set ai.models '{"small":{"provider":"your-provider","base_url":"https://your-approved-host/v1","model":"your-small-model"},"large":{"provider":"your-provider","base_url":"https://your-approved-host/v1","model":"your-large-model"},"vector":{"provider":"your-provider","base_url":"https://your-approved-host/v1","model":"your-embedding-model"}}' --by operator --reason 'approved provider switch'
gramtree ai audit --user <uuid>
gramtree ai index --limit 100
gramtree ai purge-logs
```

Celery 每分钟处理保存事务中产生的 pending embedding；供应商失败会保留工作，五分钟过期租约可重试。每个版本一条向量；检索只使用可访问菜谱的当前版本，按菜谱去重。供应商/地址/模型和维度隔离；换模型后旧向量不会混用，关键词检索继续可用。删除菜谱/到期账号依靠外键级联删除向量与私有生成日志。

## 有限文字修改（SPEC-003.2 / #167）

- 部署需运行迁移至 `0018`。默认路由增加 `modify_intent`（小模型分类）和 `modify`（有限操作）；部署若完整覆盖 `ai.routes` / `ai.policies`，须显式加入这两项，缺配置仍拒绝调用，不旁路网关。
- 两项能力共享 `modify` 的每日产品请求额度；分类、操作生成和一次修正使用同一个请求 ID，不重复扣用户次数，实际调用成本仍逐次记录。
- `POST /v1/ai/recipes/modifications` 只接受本人菜谱/基准版本或本人生成请求，不接受客户端快照。当前只执行改文字，其他类别明确返回暂不支持或不确定。
- 预览不写菜谱版本。操作最初为 `pending`；`decisions` 接口只应用明确接受/修改的操作，重新检查实际结果，拒绝上游时默认拒绝依赖项。未处理项不能确认，全部拒绝已有菜谱时不创建空改动版本。
- `confirm` 使用最近的预览 `revision`，沿用不可变版本/生成首版流程、结构和安全门槛。可复刻问题只定位提示，不阻断未完成菜谱的私有保存。重试确认不会重复保存，过期基准拒绝写入。
- 提出和最终决定事件经既有登记表记录，确认事件与 `recipe.version_saved` 的版本 ID 关联；仅运维审计可查看，不新增公开经验明细接口。本票不包含本机恢复、调味等其他意图或自动说明。
- `tests/fixtures/ai/modification_corpus.json` 是合成文字修改回放，浏览器物化工具分别登记生成预览和未修改首版的精确来源快照，不放宽哈希匹配，也不调用付费模型。

## 合成录制与回放

仓库 `server/tests/fixtures/ai/recipe_corpus.json` 是去标识的合成样板，不是真实用户或真实供应商输出。测试将样板物化为按语义请求 + 提示词版本 SHA-256 命名的文件；不含 trace/user ID 和密钥。

```bash
uv run --directory server python ../tool/ai_replay_corpus.py --out .data/ai-replay
# 在 server 目录运行 API；目录相对于服务进程 cwd
GRAMTREE_AI_MODE=replay GRAMTREE_AI_REPLAY_DIR=.data/ai-replay uv run uvicorn gramtree.asgi:app
```

刷新：在隔离测试库、经批准供应商和**同一组合成请求**上设置 `GRAMTREE_AI_MODE=record` 与目标目录，走 HTTP 请求→generate（跳过问题）流程；返回内容/usage 会覆盖相同语义 key。人工检查去标识和结构后再更新样板；从不把生产录制直接提交。`tests/test_ai_gateway.py` 用本地 OpenAI 兼容 HTTP 服务验证供应商替换、录制刷新与脱敏，`tests/test_ai_recipes.py` 使用文件回放验证成功、一次纠正及失败。

浏览器端到端启动器自动物化合成样板并启用 replay，不调用外部模型。上线前必须补齐实际供应商及隐私条款公告；App 清单对此明确标注为上线前事项。

数值护栏在 `data/numeric_guardrails.json` 独立版本化，盐/膨松剂/酵母比例只是待验证的一般经验提醒，不是食品安全结论或营养建议；食品安全和疗效措辞依然复用已交付的规则系统。
