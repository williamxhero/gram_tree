# 本人数据导出格式 v1

公开网页：`GET /data-export-format`。本文件描述当前实现，不表示 SPEC-010.2 的全部领域已经落地。

## 文件结构

ZIP 中按实体拆分 UTF-8 JSON，另有 `photos/` 原始上传文件和 `manifest.json`。
实体文件的统一结构：

```json
{"format_version": 1, "entity": "recipes", "items": []}
```

- ID 为 UUID 字符串；时间为带时区的 RFC3339 字符串；可选空值为 `null`。
- 已支持但没有数据的实体保留文件，`items` 为 `[]`。
- **缺少文件不表示账号没有该类数据**。以清单中的 `supported_entities` / `unavailable_entities` 为准。
- 清单还包含 `exported_at`、`owner_id`、`format_documentation`、`scope`、`excluded`。
- 当前 `scope` 为 `supported_server_entities_only`，`complete_spec47_export` 为 `false`。调用方不得隐藏此限制或将此导出称为全量 SPEC47 导出。

## 已支持实体

| 文件 | 内容与边界 |
| --- | --- |
| `account.json` | 本人昵称、时区、手机号、实名状态、创建时间；不含凭据。 |
| `identities.json` | 登录方式、本人邮箱、创建时间；不含 token、密码或凭据散列。 |
| `consents.json` | 本人同意/撤回回执。 |
| `recipes.json` | 本人菜谱、可见状态、当前版本、来源标识。外部来源最多包含可公开的昵称、标题、版本与相对链接，不复制他人完整菜谱。 |
| `recipe_versions.json` | 本人全部已存储版本、快照、编辑操作/意图、修改说明、派生值与来源、可复现性、结论/规则版本、安全信息、AI 标记。 |
| `quantification_suggestions.json` | 本人量化建议、选择与保存结果；保留 AI 标记。 |
| `cooking_records.json` | 本人冻结做菜历史、换算上下文、调整、口味摘要、同餐者标识、验证状态。 |
| `cooking_record_revisions.json` | 本人记录修订，包括个人评分、反馈、标签、原话；不含他人记录。 |
| `taste_profiles.json` / `taste_profile_changes.json` | 普通口味值、版本、理由、锁定、应用/撤销时间及来源记录。敏感字段的变化值明确标记 withheld。 |
| `personal_measures.json` | 本人的量具，含软删除条目。 |
| `ai_generation_drafts.json` / `ai_modification_suggestions.json` | 已在服务器保存的本人 AI 草稿/建议/选择，显式 `ai_assisted: true`；不含可能复制他人内容的修改基线。 |
| `recipe_imports.json` | 本人导入来源、原文；不输出加密字节或他人内容基线。 |
| `events.json` | 仅本人、注册表对应类型/版本明确可导出的事件；按版本 schema 过滤。 |
| `photos.json` / `photos/` | 本人菜谱图片和暂存上传的元数据与原始存储字节。上传时已去除 EXIF/位置数据，导出不再次转码。 |

## 不包含的内容

任何导出均不包含他人完整菜谱/记录/反馈详情、访问或审计日志、内部人数/计数/评分、信任或风控数据、AI 调用计费日志、凭据。

当前基线没有服务器实体的领域在 `unavailable_entities` 中逐项披露：库存、采购清单、价格、菜单、计划、社交建议、收藏、点赞、屏蔽、公开反馈、做菜照片、推荐。不能以空数组冒充这些领域已实现。

家庭成员与过敏敏感数据受已有“不导出”边界保护；不解密、不复制密文，敏感变更历史值也不导出。客户端本地未同步菜谱草稿和待上传离线写入不在服务器 ZIP 中；同步成功的菜谱版本才进入本导出。

## 申请、重试与下载

- `POST /v1/me/exports`：最近重新验证身份后申请，返回 `202` 与持久任务。
- `GET /v1/me/exports` / `GET /v1/me/exports/{id}`：仅本人读取任务状态。
- `POST /v1/me/exports/{id}/retry`：重新验证后重试失败任务；保留原任务 ID，不再占当天申请额度。默认最多尝试 3 次。
- `GET /v1/me/exports/{id}/download?expires=...&signature=...`：登录本人、HMAC 签名与有效期同时校验。链接相对同站地址；转发链接不授予权限。
- 下载响应为 `application/zip`，禁止缓存。默认完成后 24 小时失效；到期边界立即拒绝，即使清理任务尚未执行。
- `export.daily_limit` 默认 3，按 UTC 日独立计数，与普通 API 限流无关。
- `export.download_ttl_seconds` 默认 86400；`export.max_attempts` 默认 3。
- 失败仅保存无内容错误码，丢弃失败 ZIP；队列故障不丢持久任务，周期 drain 可恢复。

App 在设置中显示后台进度与完成提醒。下载走同一认证链；手机端使用系统分享/保存。网页仅作为测试替身，不持久保存 ZIP。注销、退出、切换账号或撤回时取消尚未交付的原生准备任务并清理本机私有副本。已由用户交给其他应用的文件不受本应用控制。

## 部署与清理

API 与 worker 必须共享私有、持久的 `GRAMTREE_EXPORT_DIR`（默认 `.data/exports`），不得位于公开静态目录。

```bash
celery -A gramtree.tasks.celery_app worker --beat -l warning
python -m gramtree.exports run
python -m gramtree.exports cleanup
```

删除单条记录或私密菜谱时，同一 owner 锁串行处理导出生成与删除，作废本人所有已生成和待处理导出，并移除 ZIP；过期任务保留以维持当天配额，不影响他人任务。存储不可用时返回 503，不报告删除成功；若部分文件已移除但事务随后失败，旧导出可能不可用，应重新申请。删除之前已经打开的下载流及用户已保存的副本无法撤回。

周期任务清理过期文件（包括主动失效任务遗留的文件）；操作员命令可用于恢复。`--as-of` 接受带时区 ISO 时间以验证精确边界。清理还处理没有任务的孤立 ZIP 和超过 24 小时的遗留临时文件。账号清除同时删除本人导出 ZIP 与任务元数据，不影响其他用户。

原生本地副本、Android DocumentsUI 保存与 iOS 分享的实际平台验证须以运行证据为准；网页替身不能充当原生验收证据。
