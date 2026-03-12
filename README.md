# OpenClow 飞书安装说明（中国区 / macOS）

```text
🦞 OpenClow Installer
```

## 1. 飞书配置（手把手）

平台地址：`https://open.feishu.cn`

按这个顺序做：

1. 创建应用  
进入飞书开放平台，创建「企业自建应用」，填应用名称和头像。

2. 开启机器人  
在「应用能力」里开启「机器人」。

3. 配权限  
在「权限管理」点击「批量导入」，粘贴下面这段权限 JSON，然后保存并提交审核：

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

审核打卡：
- [ ] 权限已保存
- [ ] 已提交审核
- [ ] 管理员审批通过

4. 消息接收设置  
在「开发配置」里把消息接收改成「长连接」，并添加消息事件 `im.message.receive_v1`。

5. 发布应用  
在「版本管理与发布」里创建版本并发布。

完成后，在「凭证与基础信息」复制：
- `App ID`
- `App Secret`

## 2. 本地执行安装命令

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s --
```

如果你想强制拉取最新脚本（防缓存），用：

```bash
curl -fsSL "https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh?ts=$(date +%s)" | bash -s --
```

这个命令会自动完成（仅适配 macOS）：
- 检查环境（会显示检查过程）
- 自动安装 OpenClow
- 在 macOS 无管理员权限时自动走用户目录安装（不依赖 sudo）
- 自动检查 `git` / Command Line Tools（首次可能弹出安装提示）
- 默认使用 `https://registry.npmmirror.com` 加速 npm 下载
- 提示输入飞书配置
- 生成并自动打开 `openclow-manager`

## 3. 配置文件位置

- `~/.config/openclow/config.env`（安装器输入配置）
- `~/.config/openclow/openclaw.json`（OpenClaw 实际运行配置，会自动同步）

如果要修改飞书配置，推荐直接用 `openclow-manager` 里的「2) 设置飞书配置」。

字段对应关系：
- 飞书 `App ID` -> `FEISHU_APP_ID`
- 飞书 `App Secret` -> `FEISHU_APP_SECRET`

## 4. 菜单化管理（新版终端界面）

安装后可直接运行：

```bash
openclow-manager
```

如果提示 `command not found`：

```bash
source ~/.zshrc
openclow-manager
```

或者前台直接启动：

```bash
~/.openclow/run-openclow.sh
```

说明：执行「3) 启动并开启自启动」后，才会建立 OpenClaw 网关长连接；飞书后台长连接保存失败时，先确保这里已启动成功。

支持：
- 查看当前配置（自动隐藏密钥）
- 修改飞书配置
- 启动并开启自启动
- 暂停/恢复服务
- 关闭自启动
- 重启服务
- 删除 OpenClow（带确认）
- 查看服务状态
- 查看最近日志

操作方式：
- `↑ / ↓` 选择菜单
- `Enter` 执行操作
- `q` 退出

如果终端里方向键菜单不响应，可用兼容模式：

```bash
OPENCLOW_MANAGER_SIMPLE=1 ~/.local/bin/openclow-manager
```

官方参考：
- OpenClaw 飞书文档（中文）：https://docs.openclaw.ai/zh-CN/channels/feishu
