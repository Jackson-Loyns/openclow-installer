# OpenClow 极简安装说明（macOS / 中国区）

## 1) 先准备飞书应用（3分钟）

入口：[飞书开放平台](https://open.feishu.cn)

只做这几件事：
1. 创建企业自建应用
2. 开启机器人（Bot）
3. 在 `Permissions & Scopes` 里导入权限（见下面 JSON）
4. 在 `Events & Callbacks` 里选择 `persistent connection`
5. 添加事件：`im.message.receive_v1`
6. 发布应用版本
7. 记下 `App ID` 和 `App Secret`

权限管理（直接复制到飞书「批量导入权限」）：

```json
{
  "scopes": {
    "tenant": [
      "aily:file:read",
      "aily:file:write",
      "application:application.app_message_stats.overview:readonly",
      "application:application:self_manage",
      "application:bot.menu:write",
      "cardkit:card:write",
      "contact:user.employee_id:readonly",
      "corehr:file:download",
      "docs:document.content:read",
      "event:ip_list",
      "im:chat",
      "im:chat.access_event.bot_p2p_chat:read",
      "im:chat.members:bot_access",
      "im:message",
      "im:message.group_at_msg:readonly",
      "im:message.group_msg",
      "im:message.p2p_msg:readonly",
      "im:message:readonly",
      "im:message:send_as_bot",
      "im:resource",
      "sheets:spreadsheet",
      "wiki:wiki:readonly"
    ],
    "user": [
      "aily:file:read",
      "aily:file:write",
      "im:chat.access_event.bot_p2p_chat:read"
    ]
  }
}
```

## 2) 安装（只用这一条命令）

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s --
```

安装过程中会自动：
- 检查并安装 Node / Python（仅 macOS）
- 询问飞书 `App ID / App Secret`
- 生成管理命令 `openclow-manager`

## 3) 启动

```bash
openclow-manager
```

进管理器后：
1. 选 `2) 设置飞书/模型配置`
2. 选 `3) 启动并开启自启动`

> 执行 `3` 后会自动打开控制台页面。

如果提示 `command not found`：

```bash
source ~/.zshrc
openclow-manager
```

## 4) 打开网页（正确方式）

不要手动输 `127.0.0.1`。

请用：

```bash
openclow dashboard
```

这条命令会带上 token 打开浏览器，避免 `gateway token missing`。

## 5) 你给的图片（阿里百炼套餐页）

这是百炼套餐页面，用来选套餐和创建 API Key：

![阿里百炼套餐页面](https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/bailian-plan.png)

百炼入口：[阿里百炼 Coding Plan](https://bailian.console.aliyun.com/cn-beijing/?spm=5176.29619931.J_SEsSjsNv72yRuRFS2VknO.2.1f5a10d7wzFGtq&tab=coding-plan#/efm/detail)

## 6) 出问题时只看这三条

1. 飞书显示 `No connection detected`
```bash
openclow-manager
```
先选 `2` 再选 `3`，然后回飞书页面点 `Save`。

2. 手动确认配置可用
```bash
OPENCLAW_CONFIG_PATH=~/.config/openclow/openclaw.json ~/.local/bin/openclow config validate
```

3. 看错误日志
```bash
tail -n 120 ~/.openclow/openclow.err.log
```
