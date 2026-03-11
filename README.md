# OpenClow Installer (macOS / Linux)

```text
🦞  OpenClow Installer
```
## 快速开始（curl 方式）

交互式安装（会提示输入飞书参数）：

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s --
```

无交互安装：

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s -- \
  --repo your-org/openclow \
  --version latest \
  --feishu-app-id "cli_xxx" \
  --feishu-app-secret "xxx" \
  --feishu-encrypt-key "xxx" \
  --feishu-verification-token "xxx"
```

## 常用参数

```text
--repo <owner/repo>                  GitHub 仓库（默认 openclow/openclow）
--version <tag|latest>               版本（默认 latest）
--download-url <url>                 自定义下载地址（最高优先级）
--install-root <path>                安装目录（默认 ~/.openclow）
--bin-dir <path>                     软链目录（默认 ~/.local/bin）
--config-file <path>                 配置文件（默认 ~/.config/openclow/config.env）
--exec-name <name>                   包内可执行名（默认 openclow）
--no-autostart                       不开启自启动
--non-interactive                    非交互模式
--skip-deps                          跳过基础依赖安装
--skip-node-check                    跳过 Node.js 检查
--skip-python-check                  跳过 Python 检查
--min-node-version <major>           最小 Node 主版本（默认 22）
--min-python-version <major.minor>   最小 Python 版本（默认 3.9）
--feishu-app-id <value>              飞书 App ID
--feishu-app-secret <value>          飞书 App Secret
--feishu-encrypt-key <value>         飞书 Encrypt Key
--feishu-verification-token <value>  飞书 Verification Token
```

## 目录与文件

- 程序目录：`~/.openclow`
- 启动脚本：`~/.openclow/run-openclow.sh`
- 二进制：`~/.openclow/bin/openclow`
- 软链：`~/.local/bin/openclow`
- 配置：`~/.config/openclow/config.env`

## 自启动管理

Linux:

```bash
systemctl --user status openclow
systemctl --user restart openclow
systemctl --user stop openclow
```

macOS:

```bash
launchctl print gui/$(id -u)/com.openclow.agent
launchctl kickstart -k gui/$(id -u)/com.openclow.agent
```

## 龙虾元素

脚本执行时会输出：

```text
🦞 OpenClow Installer
```

如果你需要，我可以再给你做一版“龙虾 ASCII Banner + 进度条动画”终端主题版本。

## 依赖依据（联网检索）

- OpenClaw 官方文档（安装命令与 Node 要求线索）：
  - [OpenClaw Docs](https://docs.openclaw.ai/introduction/getting-started/installation)
  - [OpenClaw GitHub](https://github.com/bestK/openclaw)

说明：官方文档重点强调 Node 环境；本安装器在此基础上补充了 Python 检查，便于后续脚本化运维与插件扩展。
