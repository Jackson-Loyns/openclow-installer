# OpenClow 飞书接入教程（中国区图文版）

```text
🦞 OpenClow Installer
```

本教程是中国区专用流程。

官方入口：
- 飞书开放平台：https://open.feishu.cn
- OpenClaw 飞书文档（中文）：https://docs.openclaw.ai/zh-cn/channels/feishu

## 准备材料

- 企业管理员飞书账号
- 机器人名称
- 机器人头像

## 第 1 步：登录飞书开放平台

操作：访问 `https://open.feishu.cn` 并登录。

截图位：`docs/images/step-01-login.png`
![第1步登录飞书](docs/images/step-01-login.png)

## 第 2 步：创建企业自建应用

操作：点击「创建企业自建应用」，填写应用名称、描述、头像。

截图位：`docs/images/step-02-create-app.png`
![第2步创建应用](docs/images/step-02-create-app.png)

## 第 3 步：开启机器人能力

操作：进入「应用能力 > 机器人」，开启机器人并设置机器人名称。

截图位：`docs/images/step-03-enable-bot.png`
![第3步开启机器人](docs/images/step-03-enable-bot.png)

## 第 4 步：复制凭据

操作：在「凭证与基础信息」复制：
- `App ID`
- `App Secret`

截图位：`docs/images/step-04-credentials.png`
![第4步复制凭据](docs/images/step-04-credentials.png)

## 第 5 步：导入权限

操作：在「权限管理」使用 Batch Import 导入下面配置。

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

然后保存并提交审核。

截图位：`docs/images/step-05-permissions.png`
![第5步导入权限](docs/images/step-05-permissions.png)

## 第 6 步：配置消息接入（长连接）

操作：在消息接入里选择长连接，并添加事件 `im.message.receive_v1`。

截图位：`docs/images/step-06-message-connection.png`
![第6步消息接入](docs/images/step-06-message-connection.png)

## 第 7 步：发布应用

操作：创建版本，提交审核并发布。

截图位：`docs/images/step-07-release.png`
![第7步发布应用](docs/images/step-07-release.png)

## 第 8 步：本地安装（只需这一条命令）

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s --
```

截图位：`docs/images/step-08-local-install.png`
![第8步本地安装](docs/images/step-08-local-install.png)

## 第 9 步：填写本地配置

打开 `~/.config/openclow/config.env`，填写：
- `FEISHU_APP_ID`
- `FEISHU_APP_SECRET`
- `FEISHU_BOT_NAME`
- `FEISHU_BOT_AVATAR`

截图位：`docs/images/step-09-local-config.png`
![第9步填写配置](docs/images/step-09-local-config.png)

## 第 10 步：验收

- 飞书应用已发布
- 权限已审批通过
- 本地配置已填写
- 机器人可正常收发消息

截图位：`docs/images/step-10-check.png`
![第10步验收](docs/images/step-10-check.png)
