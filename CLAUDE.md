# 味谱（GramTree）开发指南

> 这份文件是开发流程的唯一依据，每个开发线程开工前先读一遍。
> 流程和测试规则来自用户 2026-09-27 在项目里的决定；环境数据来自同日在云端的实测（见文末“环境实测记录”）。
> 规则要改，先问用户，改完同步这份文件。

## 1. 开发顺序与循环

子 SPEC 是 GitHub issue #15～#48，按 #13 索引“子 SPEC”表里的开发顺序（第 1 个是 #15 工程骨架，最后一个是 #48）。**一次只做一个子 SPEC**，每个子 SPEC 走完下面一整圈，才开始下一个：

1. **拆票**：用 `to-tickets` 把这个子 SPEC 拆成 tickets。
   - tickets 发到本仓库的 GitHub Issues，挂成这个子 SPEC 的子 issue，标签 `ready-for-agent`，按依赖顺序发（被依赖的先发），“Blocked by” 写真实 issue 编号。
   - 不改父 issue（子 SPEC 本身）的正文和标签。
   - 技能第 4 步要求“先给用户看拆分再发布”。默认做法：把拆分清单作为一条回复发在开发线程里，**不停下来等回复**，直接发布并继续；用户看到后提意见再调整。（这条是按用户“持续推进”的要求定的默认，用户若想每次先确认，改这里。）
2. **实现**：用 `implement-spec` 实现这个子 SPEC 和它的全部 tickets。
   - 一个子 SPEC 对应一个分支、一个 PR；PR 正文写明关闭这个子 SPEC 和它的全部 tickets（`Closes #n`）。
   - 按 tickets 的依赖关系并行实现；全部完成后跑一次代码评审（`/code-review`），修完再把 PR 标成可评审。
3. **合并**：CI 全绿、没有未处理的评审意见后，**由 Claude 自己合并到 main**，不等用户。PR 里列出“需要真机测试的点”（见第 3 节），合并不等真机测试结果。
4. **下一个**：合并后才对下一个子 SPEC 跑 `to-tickets`。

禁止事项：
- 不要提前把后面子 SPEC 的 tickets 拆出来。
- 不要跳过顺序，也不要同时开两个子 SPEC 的 PR。
- 发现子 SPEC 本身有问题（互相矛盾、缺前置），先在线程里问用户，不要自己改 SPEC。改了的话按项目约定同步 Change Log 和 #13 索引。

持续推进，直到 34 个子 SPEC 都合并到 main。阶段二、三的内容还留在父 SPEC 里，届时再拆子 SPEC。

### 技能

技能已按上游提交 `c55ee46` 固定在仓库的 `.claude/skills/`，以仓库里的版本为准，要升级单独提 PR（来源和许可见 `.claude/skills/README.md`）：

| 用途 | 技能 |
|---|---|
| 拆票 | `.claude/skills/to-tickets` |
| 实现整个子 SPEC | `.claude/skills/implement-spec`（上游还在 in-progress 目录） |
| 实现单个 ticket（implement-spec 的子代理用） | `.claude/skills/implement`，配合 `.claude/skills/tdd` |

- 用户说的 “Implement-spec” 就是 `implement-spec`。
- issue 跟踪和领域文档的配置在 `docs/agents/`（GitHub Issues、标签 `ready-for-agent`），技能不会再要求跑 `setup-matt-pocock-skills`。
- 云端线程没有 `gh` 命令，技能里用 `gh` 的地方改用 GitHub MCP 工具，对照表在 `docs/agents/issue-tracker.md`。

## 2. 技术栈

- 客户端：Flutter（一套代码出 iOS、Android，同时必须能编译成网页版用于测试）。默认 Riverpod、go_router、drift。
- 服务端：Python + FastAPI，SQLAlchemy + Alembic，默认 uv、ruff、pyright；Redis + Celery。
- 数据库：PostgreSQL + JSONB + pgvector。
- 接口契约：Dart 客户端代码由 FastAPI 的 OpenAPI 描述自动生成（默认 openapi-generator 的 dart-dio），不手工修改；CI 检查三者一致。
- 选型理由和版本在 `docs/adr/0001-技术栈与工具链.md`，全局约定（ID、时间、错误格式、分页、配置项、能力开关）在 `docs/adr/0002-全局约定.md`。换库或改约定先写新的决策记录。

## 3. 测试

原则：只测外部行为。服务端测试只通过对外接口；App 测试只看页面显示和操作结果。

| 层 | 内容 | 在哪跑 |
|---|---|---|
| 1. 服务端接口测试 | 连真的 PostgreSQL（含 pgvector），空库跑完全部迁移，测试之间数据隔离；AI 调用用事先录好的回答（样板在 SPEC-003.1 #23） | 云端线程 + CI |
| 2. Flutter 单元测试和界面测试 | 用按 OpenAPI 生成的假数据渲染页面 | 云端线程 + CI（`flutter test`，另跑一遍 `--platform chrome`） |
| 3. 网页版功能测试（主力） | `integration_test` 编译成网页，在 Chromium 里跑完整功能流程 | 云端线程 + CI |
| 4. 安卓模拟器测试（只测手机能力） | 只覆盖网页测不到的地方：锁屏计时和通知、分享进 App、相机、离线本地数据库、后台同步 | 只在 CI（GitHub Actions 的 Linux 机器），云端线程跑不了 |
| 5. 真机测试 | 用户自己安排 | 用户手机 |

用户的规则（2026-09-27）：能用安卓就尽量用安卓，但只在需要用到手机能力的地方测；网页版用来做全面的功能测试。实测结果是云端线程没有 KVM，跑不了安卓模拟器，所以：
- 第 1～3 层在开发线程里本地跑，每次推送前都要跑过。
- 第 4 层放在 GitHub Actions 里跑（GitHub 的 Linux 机器支持安卓模拟器硬件加速）。**这一层在 #15 里先搭一条样板验证能跑通**；如果跑不通，退回“只用网页版 + 真机”，并在线程里告诉用户。iOS 模拟器不自动跑。
- 每个 PR 的正文有一节“需要真机测试的点”，列出这次改动里网页版和模拟器都覆盖不到、需要用户在手机上确认的地方。合并不等真机测试。

### 客户端必须能编译成网页版

- 手机专有能力（本地通知、锁屏计时、分享接收、相机、本地数据库、后台任务等）一律放在一层接口后面，手机端用真实实现，网页端用替身实现，界面代码只依赖接口。
- 网页版只是测试目标，不是要发布的产品（#15 的 Out of Scope 里写的“Web 版 App”指的是不对外发布网页版）。
- CI 里有一步 `flutter build web`，编译不过就失败。

### 常用命令

```bash
# 服务端（server/）
uv run ruff format . && uv run ruff check . && uv run pyright
uv run pytest -q                       # 第 1 层，连本机 PostgreSQL 和 Redis

# App（app/）
dart format lib test integration_test test_driver
flutter analyze
flutter test                           # 第 2 层
flutter test --platform chrome         # 第 2 层在浏览器里再跑一遍
flutter build web
../tool/web_test.sh                    # 第 3 层：网页版端到端

# 接口契约（仓库根目录）
tool/gen_api_client.sh                 # 服务端接口改了就跑，把 api/openapi.json 和 app/packages/gramtree_api 一起提交
```

网页端到端的注意事项（`--profile`、`--no-web-resources-cdn`、`--no-sandbox`、chromedriver 版本）已经封装在 `tool/web_test.sh` 和会话启动钩子里，原因见 `docs/adr/0003-测试分层与网页版.md`。

第 4 层在 `.github/workflows/ci.yml` 的 `android-e2e` 任务（API 34 x86_64 模拟器），跑的是 `app/integration_test/` 里同一份测试；需要只在手机上测的用例，放进 `integration_test/` 并在网页端用 `kIsWeb` 跳过。iOS 模拟器任务 `ios-e2e` 只在手动触发 CI 时跑。

## 4. 云端环境

仓库的会话启动钩子 `.claude/hooks/session-start.sh`（在 `.claude/settings.json` 登记，只在云端会话里运行）会装好并启动：

- PostgreSQL 16 + pgvector（Ubuntu 源的 `postgresql-16-pgvector`），用户 `postgres` / 密码 `postgres`，库 `gramtree`；Redis
- Flutter 3.47.5（`/opt/flutter`，从 storage.googleapis.com 下载）
- 网页测试用的 `google-chrome` 包装脚本（加 `--no-sandbox`）和同版本 chromedriver（`/opt/gramtree-tools/bin`）
- `server/` 的 Python 依赖（`uv sync`）和 `app/` 的 Dart 依赖

并把 `PATH`、`CHROME_EXECUTABLE` 写进会话环境。新的容器第一次开工大约要等 2 分钟（主要是下载解压 Flutter）。

被网络策略拦住的：`dl.google.com`（安卓 SDK，所以云端连 APK 也编不了）、`pub.dartlang.org`（旧域名，用 pub.dev 即可）、`apt.postgresql.org`（用 Ubuntu 自带源代替）、`googlechromelabs.github.io`（chromedriver 版本清单，直接按版本号从 storage.googleapis.com 下载）、ghcr.io 的镜像下载。github.com 网页被拦，但 git clone 和 raw.githubusercontent.com 可以。Docker 能用，但构建镜像时容器里的 apt 访问不了外网，所以服务端镜像只在 CI 的 `server-image` 任务里构建验证。

## 仓库结构

| 目录 | 内容 |
|---|---|
| `server/` | FastAPI 服务端；`server/deploy/` 是单机部署和备份说明 |
| `app/` | Flutter 客户端；`app/packages/gramtree_api/` 是生成的接口客户端，不要手改 |
| `api/openapi.json` | 服务端接口描述，由 `tool/gen_api_client.sh` 导出 |
| `tool/` | 生成客户端、比对契约、网页端到端测试的脚本 |
| `docs/adr/` | 决策记录 |
| `docs/agents/` | 技能用的项目配置 |
| `.claude/` | 会话启动钩子和固定版本的技能 |

## 5. 每个 PR 的检查清单

- [ ] 这个子 SPEC 的全部 tickets 都在 PR 里完成，PR 写明关闭它们
- [ ] 第 1～3 层测试在本地跑过；CI 全绿（含 `flutter build web`、OpenAPI 一致性检查、安卓模拟器端到端）
- [ ] 代码评审的问题已修完，没有未处理的评审意见
- [ ] PR 正文列出“需要真机测试的点”（没有就写“无”）
- [ ] 合并到 main 后，再开始下一个子 SPEC 的拆票

## 环境实测记录（2026-09-27）

- 云端容器：4 核、15 GB 内存、约 30 GB 可写磁盘，Ubuntu 24.04。没有 `/dev/kvm`，CPU 没有虚拟化标志，所以安卓模拟器无法启动，没有继续装安卓 SDK（`dl.google.com` 也被拦）。
- Flutter 3.47.5：新建示例应用，`flutter test` 通过（约 14 秒），`flutter test --platform chrome` 通过（约 36 秒），`flutter drive` 网页集成测试在 profile 模式下通过（编译加运行约 33 秒）；debug 模式卡住 4 分钟超时。
- PostgreSQL 16 + pgvector 0.6.0：建扩展和向量距离查询正常。
- GitHub Actions 上跑安卓模拟器没有在这里实测，是按 GitHub 公开的能力推断的，在 #15 里验证。

## Agent skills

### Issue tracker

需求和票都在 GitHub Issues（williamxhero/gram_tree），标签 `ready-for-agent`。See `docs/agents/issue-tracker.md`.

### Domain docs

single-context：根目录 `CONTEXT.md`（还没有，用到时再建）和 `docs/adr/`。See `docs/agents/domain.md`.
