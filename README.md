# OpenClow 一键安装

```text
🦞 OpenClow Installer
```

只需要一条命令：

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s --
```

执行后会在终端弹出飞书输入框，依次要求填写：
- `FEISHU_APP_ID`（必填）
- `FEISHU_APP_SECRET`（必填）
- `FEISHU_ENCRYPT_KEY`（可选）
- `FEISHU_VERIFICATION_TOKEN`（可选）

运行后会自动做这些事：

1. 检查系统（macOS / Linux）和架构（amd64 / arm64）
2. 检查并安装基础依赖（curl、tar、grep、sed、awk）
3. 检查并安装 Node.js（默认 >= 22）和 Python3（默认 >= 3.9）
4. 下载并安装 OpenClow
5. 弹出飞书输入并写入配置文件
6. 配置开机自启动

## 如何获取飞书信息

1. 打开飞书开放平台并登录（企业管理员账号）：`https://open.feishu.cn`
2. 创建企业自建应用（如果已有可跳过）。
3. 在应用的“凭证与基础信息”页面获取：
   - `App ID` -> 对应 `FEISHU_APP_ID`
   - `App Secret` -> 对应 `FEISHU_APP_SECRET`
4. 如果你开启了事件订阅，在“事件与回调”页面可找到或设置：
   - `Encrypt Key` -> 对应 `FEISHU_ENCRYPT_KEY`
   - `Verification Token` -> 对应 `FEISHU_VERIFICATION_TOKEN`

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
- `--non-interactive` 关闭输入框（此模式下需提前用参数或环境变量提供飞书必填项）

## 安装后位置

- 程序：`~/.openclow/bin/openclow`
- 命令软链：`~/.local/bin/openclow`
- 配置：`~/.config/openclow/config.env`
