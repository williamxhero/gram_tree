# Issue tracker: GitHub

本仓库的需求和票都是 GitHub issue（williamxhero/gram_tree）。

- 父 SPEC：#1–#12、#14；索引：#13。
- 子 SPEC：#15–#48，按 #13 “子 SPEC”表里的开发顺序做，每个子 SPEC 是对应父 SPEC 的子 issue。
- 票（ticket）：开发到某个子 SPEC 时才用 `to-tickets` 拆，挂成这个子 SPEC 的子 issue，标签 `ready-for-agent`，按依赖顺序发布，正文 “Blocked by” 写真实编号。
- 不改父 issue（子 SPEC 本身）的正文和标签。

## 工具

云端开发线程没有 `gh` 命令。技能里写 `gh ...` 的地方，改用 GitHub MCP 工具做同样的事：

| 技能里的操作 | 用什么 |
|---|---|
| 创建 issue（含挂到父 issue 下） | `issue_write`（method=create，`parent_issue_number`） |
| 读 issue 和评论 | `issue_read`（get / get_comments / get_sub_issues） |
| 列 issue | `list_issues` / `search_issues` |
| 评论 | `add_issue_comment` |
| 改标签、关闭 | `issue_write`（method=update） |

本地有 `gh` 时照技能原文用 `gh` 即可。

## Pull requests as a triage surface

**PRs as a request surface: no.**

## When a skill says "publish to the issue tracker"

创建一个 GitHub issue，按上面的约定挂到对应的子 SPEC 下。

## When a skill says "fetch the relevant ticket"

读这个 issue 的正文和全部评论。
