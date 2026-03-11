# OpenClow 飞书接入教程（中国区）

```text
🦞 OpenClow Installer
```

目标：先在飞书完成机器人应用创建，再用一条命令把 OpenClow 安装到本地并接上飞书。

参考文档：
- OpenClaw 飞书文档（中文）：https://docs.openclaw.ai/zh-cn/channels/feishu
- 飞书开放平台：https://open.feishu.cn
- 飞书官方教程（流程参考）：https://www.feishu.cn/content/article/7613711414611463386

## 1. 创建飞书机器人应用（打卡）

- [ ] 打开并登录 `https://open.feishu.cn`
- [ ] 创建「企业自建应用」
- [ ] 填写应用名称、描述、头像
- [ ] 在「凭证与基础信息」复制：
  - `App ID`
  - `App Secret`
- [ ] 在「应用能力 > 机器人」启用机器人，并设置机器人名称

## 2. 配置权限（打卡）

在「权限管理」使用批量导入（Batch Import），导入下面配置：

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

- [ ] 保存权限配置
- [ ] 提交需要审核的权限申请
- [ ] 管理员审批通过

## 3. 配置消息接入（打卡）

按 OpenClaw 推荐，选择「长连接」接收消息（不需要公网地址）。

- [ ] 在飞书开发配置中启用长连接消息接入
- [ ] 添加消息事件 `im.message.receive_v1`
- [ ] 保存配置

## 4. 发布应用（打卡）

- [ ] 创建版本
- [ ] 提交审核并发布
- [ ] 确认企业内可用

## 5. 本地安装（只要这一条命令）

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s --
```

脚本会自动完成：环境检查、依赖安装、OpenClow 安装、配置文件生成、自启动配置。

## 6. 填写本地配置（打卡）

打开 `~/.config/openclow/config.env`，填写：

- `FEISHU_APP_ID=...`
- `FEISHU_APP_SECRET=...`
- `FEISHU_BOT_NAME=...`
- `FEISHU_BOT_AVATAR=...`
- `FEISHU_ENCRYPT_KEY=...`（可选）
- `FEISHU_VERIFICATION_TOKEN=...`（可选）

## 7. 验收（打卡）

- [ ] 飞书应用已发布
- [ ] 权限全部通过
- [ ] 本地配置已填写
- [ ] 机器人可正常收发消息
