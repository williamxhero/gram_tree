# UI 规范与界面样稿

这个目录把原来只存在于 claude.ai 里的 UI 规范和界面样稿存进 git 仓库（用户 2026-09-29 的要求：所有 article 至少在 git 里有一份）。

| 文件 | 内容 | 对应 SPEC | 原 Artifact |
|---|---|---|---|
| [`UI规范.md`](UI规范.md) | UI 规范正文：配色、字体、来源标记、三层结构、“为什么”面板、意图、兜底规则 | #18 SPEC-009.1、#34 SPEC-009.2 | 由 CLAUDE.md 第 6 节、`app/lib/app/theme.dart` 和组件库样稿整理 |
| [`UI使用指南.md`](UI使用指南.md) | 怎么用：主题取色、新增组件和意图、来源标记、兜底、画新样稿并存进仓库、合并前自查清单 | #18 SPEC-009.1 | 无（仓库里的文档） |
| [`component-library.html`](component-library.html) | 组件库样稿（可直接用浏览器打开，自带全部样式和脚本） | #18 SPEC-009.1 | https://claude.ai/artifact/EN6F9QAL5Qy3JMmK9VjdvW |
| [`account-privacy.html`](account-privacy.html) | 账号与隐私样稿（可直接用浏览器打开） | SPEC-013.2 账号与隐私 | claude.ai Project 里的“账号与隐私”样稿 |
| [`recipe-detail/`](recipe-detail/) | 菜谱详情页样稿（熟手常做）的源文件：`index.html` 和 `project/` 下的组件（`Kit`、`Main`、`Pro`、`Why`、`canvas.json`） | 菜谱详情页 | claude.ai Project 里的“菜谱详情页”画布 |
| [`recipe-authoring/`](recipe-authoring/) | 结构化菜谱作者工作台样稿：编辑、详情预览、版本历史、我的菜谱；支持浅色/深色和交互展开 | #20 SPEC-002.2 | 本地 HTML 样稿（浏览器可直接打开） |

## 说明

- `recipe-detail/` 是画布的**源文件**：`index.html` 引用平台运行时 `artifact-type/app.js`，`Pro.dc.html` 引用 `support.js`，这两个运行时文件属于 claude.ai 平台，没有导出，所以这份不能在本地直接打开渲染；要看效果请去 claude.ai 的原 Artifact，这里保存的是设计内容的备份。
- claude.ai 里的两个“Design System”Artifact 只是空的类型壳（没有项目内容），没有导出。
- “V1.1 交付报告”没有导出。
- 界面配色和字体的代码实现在 `app/lib/app/theme.dart`，以代码为准；样稿里的深色值是 #80 提议的定稿值。
- 产品设计文档（文件名含“设计文档”）**不放在这里**，也不进仓库，见 `CLAUDE.md` 第 0 节。
