# OpenClow 一键安装脚本（macOS / Linux）

这个仓库提供 `install.sh`，用于自动完成：

- 系统与架构检测（仅 `macOS` / `Linux`，仅 `amd64` / `arm64`）
- 依赖检查与自动安装（`curl`、`tar`、`grep`、`sed`、`awk`）
- 从 GitHub Release 下载 OpenClow 并安装到本地
- 写入飞书基础配置
- 配置开机自启动
  - Linux: `systemd --user`
  - macOS: `LaunchAgent`

## 1. 推荐的发布方式（让用户可以 `curl` 安装）

1. 把本仓库推送到 GitHub（例如：`your-org/openclow-installer`）。
2. 使用 Raw 地址供用户安装：

```bash
curl -fsSL https://raw.githubusercontent.com/your-org/openclow-installer/main/install.sh | bash
```

## 2. 用户安装命令示例

### 2.1 交互式安装（会提示输入飞书配置）

```bash
curl -fsSL https://raw.githubusercontent.com/your-org/openclow-installer/main/install.sh | bash -s --
```

### 2.2 无交互安装（CI/批量部署）

```bash
curl -fsSL https://raw.githubusercontent.com/your-org/openclow-installer/main/install.sh | bash -s -- \
  --repo your-org/openclow \
  --version latest \
  --feishu-app-id "cli_xxx" \
  --feishu-app-secret "xxx" \
  --feishu-encrypt-key "xxx" \
  --feishu-verification-token "xxx"
```

### 2.3 指定自定义下载地址（当 Release 命名不一致时）

```bash
curl -fsSL https://raw.githubusercontent.com/your-org/openclow-installer/main/install.sh | bash -s -- \
  --download-url "https://github.com/your-org/openclow/releases/download/v1.2.3/openclow_linux_amd64.tar.gz"
```

## 3. 参数说明

```text
--repo <owner/repo>                  GitHub 仓库（默认 openclow/openclow）
--version <tag|latest>               版本（默认 latest）
--download-url <url>                 直接下载地址（最高优先级）
--install-root <path>                安装目录（默认 ~/.openclow）
--bin-dir <path>                     软链目录（默认 ~/.local/bin）
--config-file <path>                 配置文件（默认 ~/.config/openclow/config.env）
--exec-name <name>                   包内可执行文件名（默认 openclow）
--no-autostart                       不开启自启动
--non-interactive                    非交互模式
--skip-deps                          跳过依赖自动安装
--feishu-app-id <value>              飞书 App ID
--feishu-app-secret <value>          飞书 App Secret
--feishu-encrypt-key <value>         飞书 Encrypt Key
--feishu-verification-token <value>  飞书 Verification Token
```

## 4. 安装后文件位置

- 程序主目录：`~/.openclow`
- 可执行文件：`~/.openclow/bin/openclow`
- 全局命令软链：`~/.local/bin/openclow`
- 配置文件：`~/.config/openclow/config.env`

## 5. 自启动说明

### Linux

- 服务名：`openclow.service`
- 管理命令：

```bash
systemctl --user status openclow
systemctl --user restart openclow
```

### macOS

- LaunchAgent: `~/Library/LaunchAgents/com.openclow.agent.plist`
- 日志：
  - `~/.openclow/openclow.log`
  - `~/.openclow/openclow.err.log`

## 6. 维护者发布建议

建议你的 OpenClow Release 资产文件命名包含 OS/ARCH 信息，例如：

- `openclow_linux_amd64.tar.gz`
- `openclow_linux_arm64.tar.gz`
- `openclow_darwin_amd64.tar.gz`
- `openclow_darwin_arm64.tar.gz`

这样安装脚本可以自动匹配下载地址，不需要用户额外传 `--download-url`。
