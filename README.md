# OpenClow 一键安装

```text
🦞 OpenClow Installer
```

只需要一条命令：

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s --
```

运行后会自动做这些事：

1. 检查系统（macOS / Linux）和架构（amd64 / arm64）
2. 检查并安装基础依赖（curl、tar、grep、sed、awk）
3. 检查并安装 Node.js（默认 >= 22）和 Python3（默认 >= 3.9）
4. 下载并安装 OpenClow
5. 写入配置文件（飞书项默认可留空，后续再填）
6. 配置开机自启动

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

## 安装后位置

- 程序：`~/.openclow/bin/openclow`
- 命令软链：`~/.local/bin/openclow`
- 配置：`~/.config/openclow/config.env`
