# OpenClow + 飞书本地部署教程

```text
🦞 OpenClow Installer
```

这份教程目标是：先创建好飞书/Lark 机器人应用，再用一条命令把本地 OpenClow 安装并接上。

官方参考：
- OpenClaw Feishu 文档：https://docs.openclaw.ai/channels/feishu
- 飞书开放平台：https://open.feishu.cn
- Lark（美国/国际）开放平台：https://open.larksuite.com/app

## 1. 先在飞书创建应用机器人（打卡清单）

- [ ] 打开平台并登录
  - 中国大陆租户：`https://open.feishu.cn`
  - 美国/国际租户：`https://open.larksuite.com/app`
- [ ] 点击「Create enterprise app（创建企业自建应用）」
- [ ] 填写应用名称、描述、头像
- [ ] 在「Credentials & Basic Info（凭证与基础信息）」复制：
  - `App ID`（格式一般是 `cli_xxx`）
  - `App Secret`
- [ ] 在「App Capability > Bot」启用机器人能力并设置机器人名称

## 2. 权限管理（按 OpenClaw 推荐）

在「Permissions」里使用 Batch Import（批量导入）：

```json
{
  "scopes": {
    "tenant": [
      "aily:file:read",
      "aily:file:write",
      "application:application.app_message_stats.overview:readonly",
      "application:application:self_manage",
      "application:bot.menu:write",
      "cardkit:card:read",
      "cardkit:card:write",
      "contact:user.employee_id:readonly",
      "corehr:file:download",
      "event:ip_list",
      "im:chat.access_event.bot_p2p_chat:read",
      "im:chat.members:bot_access",
      "im:message",
      "im:message.group_at_msg:readonly",
      "im:message.p2p_msg:readonly",
      "im:message:readonly",
      "im:message:send_as_bot",
      "im:resource"
    ],
    "user": [
      "aily:file:read",
      "aily:file:write",
      "im:chat.access_event.bot_p2p_chat:read"
    ]
  }
}
```

## 3. 事件回调（美国 Lark 重点）

推荐方式：**Long Connection（长连接 / WebSocket）**，不需要公网回调地址。

- [ ] 在「Event Subscription」选择「Use long connection to receive events」
- [ ] 添加事件：`im.message.receive_v1`
- [ ] 确保本地 OpenClow 网关在运行后再保存（否则可能保存失败）

美国场景建议：
- 使用 `open.larksuite.com` 创建应用
- OpenClow 里把 Feishu 域设置为 `lark`（国际域）

如果你公司必须走 webhook 回调模式，再额外配置：
- `Verification Token`
- 可从公网访问的 HTTPS 回调地址（美国网络可达）

## 4. 发布应用

- [ ] 在「Version Management & Release」创建版本
- [ ] 提交审核并发布
- [ ] 等待管理员审批（企业自建应用通常流程较快）

## 5. 本地一键安装（只要这一条命令）

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s --
```

脚本会自动：
- 检查系统环境（macOS / Linux）
- 检查并安装依赖与 Node/Python
- 下载并安装 OpenClow
- 写入配置文件并配置自启动

配置文件路径：`~/.config/openclow/config.env`

## 6. 把飞书信息写入本地配置

在 `~/.config/openclow/config.env` 填入：

- `FEISHU_APP_ID=...`
- `FEISHU_APP_SECRET=...`
- `FEISHU_ENCRYPT_KEY=...`（可选）
- `FEISHU_VERIFICATION_TOKEN=...`（仅 webhook 模式必填）
- `FEISHU_BOT_NAME=...`
- `FEISHU_BOT_AVATAR=...`

## 7. 完成验收（打卡）

- [ ] 飞书应用已发布并有权限
- [ ] 事件订阅已保存（推荐长连接）
- [ ] 本地配置文件已填 App ID / App Secret
- [ ] 机器人能收到并回复消息
