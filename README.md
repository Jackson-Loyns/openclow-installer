# OpenClow 安装与飞书接入（macOS，中国区）

这个仓库只做一件事：
用一条命令在 macOS 安装 OpenClow，并把飞书配置好。

你发的截图已放到仓库：
- `assets/bailian-plan.png`

## 1. 先在飞书开放平台准备好应用

入口：[飞书开放平台](https://open.feishu.cn)

按顺序操作：

1. 创建企业自建应用
2. 开启 Bot（机器人能力）
3. 在「Permissions & Scopes」导入权限
4. 在「Events & Callbacks」选择 **persistent connection**（长连接）
5. 添加事件 `im.message.receive_v1`
6. 发布应用版本
7. 复制 `App ID` 和 `App Secret`

权限 JSON：

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

## 2. 安装（只需要这一条命令）

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s --
```

脚本地址（可点开）：[install.sh](https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh)

安装脚本会自动：
- 检查并安装 Node / Python（仅 macOS）
- 安装 OpenClow
- 让你输入飞书 `App ID / App Secret`
- 让你选择模型厂商（默认阿里百炼）
- 生成 `openclow-manager`

## 3. 安装完成后怎么用

启动管理器：

```bash
openclow-manager
```

如果提示 `command not found`：

```bash
source ~/.zshrc
openclow-manager
```

管理器里按这个顺序：

1. 选 `2) 设置飞书/模型配置`
2. 选 `3) 启动并开启自启动`

执行 `3` 后会自动打开控制台页面（带 token）。

## 4. 页面地址怎么打开才对

不要手动输 `http://127.0.0.1:18789/`。

请用：

```bash
openclow dashboard
```

这个命令会自动带 token 打开浏览器，不会出现 `gateway token missing`。

## 5. 常见问题

### 5.1 飞书提示 `No connection detected`

处理步骤：

1. 确认你已经添加事件 `im.message.receive_v1`
2. 确认飞书应用已经发布版本
3. 本机执行 `openclow-manager`，再选 `3) 启动并开启自启动`
4. 回飞书页面重新点 `Save`

如果还不行，手动执行一次：

```bash
OPENCLAW_CONFIG_PATH=~/.config/openclow/openclaw.json ~/.local/bin/openclow plugins enable feishu
openclow-manager
```

### 5.2 安装后怎么确认成功

```bash
~/.local/bin/openclow --help
~/.local/bin/openclow dashboard --no-open
```

- 第一条有帮助输出：说明程序已安装
- 第二条会打印 dashboard 地址

### 5.3 看实时日志

```bash
tail -f ~/.openclow/openclow.log ~/.openclow/openclow.err.log
```

## 6. 模型配置说明（阿里百炼）

百炼入口：[阿里百炼 Coding Plan](https://bailian.console.aliyun.com/cn-beijing/?spm=5176.29619931.J_SEsSjsNv72yRuRFS2VknO.2.1f5a10d7wzFGtq&tab=coding-plan#/efm/detail)

你发的这张图对应的是百炼套餐页面（用于选套餐和创建 Key）：

![阿里百炼套餐页面](https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/assets/bailian-plan.png)

规则：
- 选择 `aliyun-bailian` 时，必须填写 API Key，安装器会写入智能路由
- 选择 `default` 时，不写智能路由，保持 OpenClaw 默认行为

关键配置文件：
- `~/.config/openclow/config.env`
- `~/.config/openclow/openclaw.json`
