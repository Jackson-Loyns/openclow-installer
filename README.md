# OpenClow 一键安装

```text
🦞 OpenClow Installer
```

只需要一条命令：

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s --
```

默认不弹输入框，自动完成安装与配置文件写入。

运行后会自动做这些事：

1. 检查系统（macOS / Linux）和架构（amd64 / arm64）
2. 检查并安装基础依赖（curl、tar、grep、sed、awk）
3. 检查并安装 Node.js（默认 >= 22）和 Python3（默认 >= 3.9）
4. 下载并安装 OpenClow
5. 自动写入配置文件（优先使用你传入或已有的飞书配置）
6. 配置开机自启动

## 飞书配置（可选补充）

如果你要在安装时一起填飞书参数，执行：

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s -- --prompt-feishu
```

也可以安装后直接编辑：

`~/.config/openclow/config.env`

字段：
- `FEISHU_APP_ID`
- `FEISHU_APP_SECRET`
- `FEISHU_ENCRYPT_KEY`
- `FEISHU_VERIFICATION_TOKEN`

## 可选参数（一般不用）

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s -- \
  --repo your-org/openclow \
  --version latest
```

常用开关：

- `--no-autostart` 不启用自启动
- `--skip-node-check` 跳过 Node 检查
- `--skip-python-check` 跳过 Python 检查
- `--min-node-version 22` 自定义 Node 最低版本
- `--min-python-version 3.9` 自定义 Python 最低版本
- `--prompt-feishu` 安装时弹出飞书输入框
- `--non-interactive` 强制无交互安装

## 安装后位置

- 程序：`~/.openclow/bin/openclow`
- 命令软链：`~/.local/bin/openclow`
- 配置：`~/.config/openclow/config.env`
