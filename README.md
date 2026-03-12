# OpenClow 一键安装与飞书接入（macOS / 中国区）

```text
🦞 OpenClow Installer
```

## 1) 先在飞书开放平台完成应用配置

平台地址：`https://open.feishu.cn`

按顺序操作：

1. 创建「企业自建应用」
2. 在「应用能力」里开启机器人
3. 在「权限管理」里批量导入权限 JSON（见下方）
4. 在「开发配置」里把消息接收模式设为「长连接」
5. 添加事件：`im.message.receive_v1`
6. 发布应用（版本管理与发布）
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

打卡清单：
- [ ] 权限已保存并提交
- [ ] 管理员已审批
- [ ] 长连接已开启
- [ ] 事件 `im.message.receive_v1` 已添加
- [ ] 应用已发布

## 2) 一条命令安装（就是这一条）

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s --
```

安装器会自动完成：
- 环境检查（Node/Python/git）并显示检查过程
- 自动安装缺失环境（仅 macOS）
- 安装 OpenClow
- 询问飞书 `App ID / App Secret`
- 询问模型厂商（默认阿里百炼）
- 生成并启动 `openclow-manager`

## 3) 模型厂商配置（默认阿里百炼）

阿里百炼入口（Coding Plan）：
`https://bailian.console.aliyun.com/cn-beijing/?spm=5176.29619931.J_SEsSjsNv72yRuRFS2VknO.2.1f5a10d7wzFGtq&tab=coding-plan#/efm/detail`

为什么推荐：
- 一个 API Key 接多模型
- 代码、长文本、Agent 都能覆盖
- 安装器自动写好智能路由，减少手动调参

你的套餐参考：

| 模型 | PinchBench 排名 | 上下文 | 最佳场景 |
| --- | --- | --- | --- |
| MiniMax-M2.5 | 🥈 #2 级别 | 196K | Agent 任务、多步骤工作流 |
| Kimi-K2.5 | 🥉 #3 级别 | 262K | 通用对话、图片分析 |
| Qwen3.5-Plus | 高性能 | 1000K | 长文本总结 |
| Qwen3-Coder-Plus | 代码专家 | 1000K | 编程开发 |
| Qwen3-Max | 高性能 | 262K | 复杂推理 |
| Qwen-Plus | 平衡型 | 128K | 日常问答 |
| Qwen-Long | 超长文档 | 1000万 | 整本书/PDF |

预置智能路由：

| 任务类型 | 自动选择 | 成功率参考 |
| --- | --- | --- |
| 代码开发 | Qwen3-Coder-Plus | ~85%+ |
| Agent 工作流 | MiniMax-M2.5 | ~93% |
| 通用对话 | Kimi-K2.5 | ~93% |
| 长文本 | Qwen3.5-Plus | ~88%+ |
| 超长文档 | Qwen-Long | ~90%+ |
| 图片分析 | Kimi-K2.5 | ~93% |

规则说明：
- 选择「阿里百炼」才会要求填写 API Key，并启用智能路由。
- 选择「默认」则不写入智能路由，保持 OpenClaw 默认行为。

## 4) 启动与管理

安装后直接输入：

```bash
openclow-manager
```

如果当前终端提示 `command not found`，先执行：

```bash
source ~/.zshrc
openclow-manager
```

在管理器里：
- 先用 `2) 设置飞书/模型配置`
- 再用 `3) 启动并开启自启动`

## 5) 关键配置文件

- 安装输入配置：`~/.config/openclow/config.env`
- OpenClaw 运行配置：`~/.config/openclow/openclaw.json`

字段对应：
- `FEISHU_APP_ID`
- `FEISHU_APP_SECRET`
- `MODEL_PROVIDER`（`aliyun-bailian` / `default`）
- `MODELSTUDIO_API_KEY`
