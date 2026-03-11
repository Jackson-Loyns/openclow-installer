# OpenClow 本地一键部署

```text
🦞 OpenClow Installer
```

## 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s --
```

## 自动完成内容

- 检查系统和架构（macOS / Linux, amd64 / arm64）
- 检查并安装基础依赖
- 检查并安装 Node/Python 运行环境
- 下载并安装 OpenClow
- 生成本地配置并配置自启动
- 写入飞书配置字段（包含机器人名称与头像）

配置文件路径：`~/.config/openclow/config.env`

## 飞书一键化目标（调查结论）

- 你要的目标是：用户只填 `机器人名称 + 头像`，自动创建并接入飞书机器人。
- 当前脚本已支持这两个字段：
  - `FEISHU_BOT_NAME`
  - `FEISHU_BOT_AVATAR`
- 但“自动创建飞书应用/机器人”这一步，按公开文档流程仍依赖飞书开放平台控制台操作（创建企业自建应用、拿凭据），不是纯本地脚本可完全替代的流程。

参考：
- 飞书自建应用开发流程（官方文档）：https://open.feishu.cn/document/home/introduction-to-custom-app-development/self-built-application-development-process
- OpenClaw 安装文档：https://docs.openclaw.ai/install/index

## 你现在可以直接传入机器人信息

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s -- \
  --feishu-bot-name "你的机器人名称" \
  --feishu-bot-avatar "https://example.com/avatar.png"
```
