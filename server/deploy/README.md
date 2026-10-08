# 服务端部署（阶段一：单台服务器）

阶段一用一台服务器跑全部组件：Caddy（HTTPS）→ API，另有 PostgreSQL + pgvector、Redis、任务进程。
服务器先放在无需 ICP 备案的近邻地区（如中国香港）；面向国内公众正式上线前迁回境内（SPEC-011）。

## 需要你准备

- 一台装好 Docker 的 Linux 服务器（2 核 4 GB 起步）
- 一个域名，A 记录指向服务器；80 和 443 端口对外开放
- 一个服务器之外的备份位置（对象存储或另一台机器），配置成 rclone 的 remote
- 一个能发邮件的 SMTP 账号（登录验证码要用），填进 `.env` 的 `GRAMTREE_SMTP_*`
- 访问令牌密钥：`openssl rand -hex 32` 生成，填进 `GRAMTREE_AUTH_SECRET`（不设置 API 不会启动）
- 如果 iOS 版要开放“通过 Apple 登录”：在 Apple 开发者后台给 App 打开 Sign in with Apple，建一个 Key，把 Bundle ID、Team ID、Key ID 和 .p8 内容填进 `GRAMTREE_APPLE_*`

## 第一次部署

```bash
git clone https://github.com/williamxhero/gram_tree.git && cd gram_tree/server/deploy
cp .env.example .env          # 填域名、邮箱、数据库密码、备份位置、SMTP、令牌密钥
rclone config --config ./rclone.conf   # 配置异地备份的 remote，名字和 .env 里一致
docker compose -f docker-compose.prod.yml up -d --build
curl https://<你的域名>/v1/health     # 应返回 {"status":"ok",...}
```

API 容器启动时会先执行数据库迁移。

## 更新

```bash
git pull && docker compose -f docker-compose.prod.yml up -d --build
```

## 食品安全规则更新与复检

规则在 `gramtree/recipes/data/food_safety_rules.json`，修改触发条件、阈值、用语或依据时必须增加 `version`（禁止用语表也有独立版本）。同一个版本号的内容会被数据库指纹锁定，不能替换。规则需要走代码评审；发布前确认依据和阈值。

API 与 worker 部署同一份规则，更新时一起重建、重启。Celery beat 每分钟发现过期的菜谱版本并复检，每批最多 100 条，后续批次自动继续。需要立刻执行或检查状态时：

```bash
docker compose -f docker-compose.prod.yml exec worker gramtree recipes safety-validate
docker compose -f docker-compose.prod.yml exec worker gramtree recipes safety-recheck --enqueue
docker compose -f docker-compose.prod.yml exec worker gramtree recipes safety-status --limit 20
# 同步处理一批，输出 checked/failed/remaining；出现失败退出码为 1
docker compose -f docker-compose.prod.yml exec worker gramtree recipes safety-recheck --limit 100
```

队列以“菜谱版本 + 规则版本”去重，状态、尝试次数和错误类型持久化在 PostgreSQL。成功后当前安全索引和任务完成状态一起提交，`safety_at_save` 永远保留创建时结论；旧数据没有原始检查时保持空值。失败保留之前的安全索引并标记为 `retry`，下一批自动重试。任务进程退出留下的 `running` 租约 5 分钟后可重试；`safety-status` 输出每个状态的数量、最近任务和时间，日志按任务 ID 查找。投递失败时已创建的队列记录仍由 beat 处理。

新版本同时保存检查时的菜名和别名等文字，复检与页面即时检查使用这份原始输入；历史数据缺少这份输入时使用当前菜名和别名，保持原始结论为空。规则更新后的旧索引在 HTTP 响应中标记 `safety.stale=true`，复检成功后恢复为 `false`。

步骤计时表示整个步骤时长。豆浆的五分钟条件只接受规则表列出的独立沸腾后持续加热步骤（例如 `真正煮沸后继续煮`，`duration_seconds=300`）；把升温、沸腾或冷却混在一个步骤的总计时会保留提醒，应拆成单独步骤。其他未被规则识别的说法也保留提醒，规则表的证据条件需在评审中明确扩展。

测试或外部规则卷可通过 `GRAMTREE_FOOD_SAFETY_RULES_PATH` 指定规则文件，API、worker 和维护命令必须一致。不要在运行中的两个进程上部署不同版本的文件。

## 修改服务端配置项

```bash
docker compose -f docker-compose.prod.yml exec api gramtree config list
docker compose -f docker-compose.prod.yml exec api \
  gramtree config set ops.alert_channel webhook --by 你的名字 --reason "接入告警"
docker compose -f docker-compose.prod.yml exec api gramtree config history
```

## 备份与恢复

- 任务进程每天北京时间凌晨 3 点备份一次，写到 `backups` 卷，并复制到 `GRAMTREE_BACKUP_REMOTE`。
- 保留天数：`gramtree config set ops.backup_retention_days <天数> ...`，本机和异地都按它清理。
- 立刻备份一次：`docker compose -f docker-compose.prod.yml exec worker gramtree backup run`

恢复演练（上线前做一次，之后每季度一次）：

```bash
# 1. 把一份备份恢复到新库 gramtree_restore（不影响正在用的库）
docker compose -f docker-compose.prod.yml exec worker gramtree backup restore \
  /var/backups/gramtree/<文件名>.dump \
  --to postgresql+psycopg://gramtree:<密码>@db:5432/gramtree_restore
# 2. 用新库起一个临时 API，检查健康状态和数据
docker compose -f docker-compose.prod.yml run --rm \
  -e GRAMTREE_DATABASE_URL=postgresql+psycopg://gramtree:<密码>@db:5432/gramtree_restore \
  api python -c "from fastapi.testclient import TestClient; from gramtree.asgi import app; print(TestClient(app).get('/v1/health').json())"
```

同样的演练在自动测试里每次提交都会跑一遍（`server/tests/test_backup_restore.py`）。
真正出事时，把恢复出的库改名成 `gramtree`，或者把 API 的数据库地址指向它，然后重启 api 和 worker。

## 私密过敏数据密钥与恢复边界

- `GRAMTREE_SENSITIVE_DATA_KEY` 是独立的随机 32 字节 AES-GCM 密钥（URL-safe base64 编码），API/worker/维护进程使用同一密钥；由环境变量或密钥管理注入，不复用访问令牌密钥，不进仓库、镜像或日志。例如在可信终端运行 `python -c "import base64,secrets; print(base64.urlsafe_b64encode(secrets.token_bytes(32)).decode())"` 后直接存入密钥管理。
- 当前过敏及历史旧新值均认证加密，并绑定账号及当前值/具体变更的角色。缺密钥、错误密钥或密文被交换时读写失败，不退回明文、不覆盖原数据；撤回和注销不需解密密钥，仍然清除当前值、敏感历史和关联元数据事件。
- 加密不等于备份无隐私风险：数据库备份与密钥备份必须分开保管、限制访问并按保留期销毁；旧备份可能包含撤回前密文。不要把密钥附带到数据库 dump。密钥丢失后敏感数据不可恢复；不能直接替换环境变量当作轮换，现阶段需先撤回/清除所有敏感数据或另行实施经审核的逐条认证重加密流程。
- **不能把旧备份中的授权当作今天仍有效**。项目的 `gramtree backup restore` 只恢复到独立库，并在报告成功前保守清除所有恢复出的过敏当前值、敏感历史与关联事件，追加服务端撤回记录、推进授权/档案版本。普通口味、偏好和约束保留；用户必须重新明确同意并重新填写，从空状态开始。
- 手工 `pg_restore`、磁盘快照或第三方恢复工具绕过上述安全步骤。这样的库不得挂到 API/worker；先在隔离环境迁移到当前 schema，运行恢复清理流程或可靠补齐快照之后所有撤回/注销记录及其删除动作，并验收敏感表/历史/事件已清除。无法证明撤回记录完整时必须全部清除敏感数据、撤销恢复的授权，不能静默复活。
- 本票没有敏感本机持久缓存、成员或 AI 共享。服务端未来读取/删除必须统一接入 `taste_profiles.allergies.read_sensitive` / `erase_sensitive`，与 owner-row 锁及授权版本一起使用；普通导出、摘要、模型上下文和日志不得直接读取敏感表。

## 告警

接口错误率和耗时由任务进程每分钟检查一次。阈值和接收方式都是配置项：

| 配置项 | 说明 |
|---|---|
| `ops.alert_window_minutes` | 统计窗口 |
| `ops.alert_error_rate` | 5xx 比例阈值 |
| `ops.alert_p95_ms` | 耗时 p95 阈值 |
| `ops.alert_min_requests` | 请求太少时不告警 |
| `ops.alert_channel` | `none` / `webhook` / `email` |
| `ops.alert_target` | webhook 地址或邮箱（邮件需要在 .env 配 SMTP） |

## 客户端测试版

- iOS：用 Xcode 归档后上传 TestFlight（需要 Apple 开发者账号和签名证书）。
- Android：`flutter build apk --dart-define=APP_ENV=staging`，把安装包发给测试用户或上传内测平台。
