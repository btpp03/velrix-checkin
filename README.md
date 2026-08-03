# Velrix 每日签到

GitHub Actions 自动签到，支持多账号，签到结果通过 Telegram 通知。

## 工作原理

- 每天 UTC 0:00 自动触发（也可手动 `workflow_dispatch`）
- 调用 Velrix API `POST /v1/economy/daily` 完成签到
- 查询积分余额 `GET /v1/economy/balance`
- 汇总所有账号结果，通过 Telegram Bot 推送通知

## 配置

### 1. Secrets 设置

在仓库 **Settings → Secrets and variables → Actions** 中添加：

| Secret | 必填 | 说明 |
|--------|------|------|
| `VELRIX_COOKIES` | ✅ | 多账号 JSON 数组（见下方格式） |
| `VELRIX_COOKIE` | ➖ | 旧版单 cookie（兼容，优先级低于 COOKIES） |
| `TG_BOT_TOKEN` | ➖ | Telegram Bot Token（不填则跳过通知） |
| `TG_CHAT_ID` | ➖ | Telegram Chat ID |

### 2. VELRIX_COOKIES 格式

```json
[
  {
    "name": "账号备注名",
    "cookie": "velrix_session=xxx; SPSE=xxx; SPSI=xxx; __Host-csrf=xxx"
  },
  {
    "name": "另一个账号",
    "cookie": "velrix_session=yyy; SPSE=yyy; SPSI=yyy; __Host-csrf=yyy"
  }
]
```

### 3. 如何获取 Cookie

1. 登录 [velrix.net](https://www.velrix.net)
2. 打开浏览器开发者工具 → Application → Cookies
3. 复制 `velrix_session`、`SPSE`、`SPSI`、`__Host-csrf` 四个 cookie 的值
4. 拼成 `key=value; key=value` 格式

## 本地测试

```bash
export VELRIX_COOKIES='[{"name":"test","cookie":"velrix_session=xxx"}]'
export TG_BOT_TOKEN="your_bot_token"
export TG_CHAT_ID="your_chat_id"
chmod +x checkin.sh
./checkin.sh
```

## 通知效果

```
✅ Velrix 签到完成
✅ 账号1: claimed (💰520)
ℹ️ 账号2: already_claimed (💰1280)
❌ 账号3: error (💰?)
```

## 文件结构

```
velrix-checkin/
├── .github/workflows/
│   └── daily-checkin.yml   # GitHub Actions 定时任务
├── checkin.sh               # 签到脚本（多账号）
└── README.md
```
