# 服务端部署（阶段一：单台服务器）

阶段一用一台服务器跑全部组件：Caddy（HTTPS）→ API，另有 PostgreSQL + pgvector、Redis、任务进程。
服务器先放在无需 ICP 备案的近邻地区（如中国香港）；面向国内公众正式上线前迁回境内（SPEC-011）。

## 需要你准备

- 一台装好 Docker 的 Linux 服务器（2 核 4 GB 起步）
- 一个域名，A 记录指向服务器；80 和 443 端口对外开放
- 一个服务器之外的备份位置（对象存储或另一台机器），配置成 rclone 的 remote

## 第一次部署

```bash
git clone https://github.com/williamxhero/gram_tree.git && cd gram_tree/server/deploy
cp .env.example .env          # 填域名、邮箱、数据库密码、备份位置
rclone config --config ./rclone.conf   # 配置异地备份的 remote，名字和 .env 里一致
docker compose -f docker-compose.prod.yml up -d --build
curl https://<你的域名>/v1/health     # 应返回 {"status":"ok",...}
```

API 容器启动时会先执行数据库迁移。

## 更新

```bash
git pull && docker compose -f docker-compose.prod.yml up -d --build
```

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
