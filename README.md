# OpenClow 飞书安装说明（中国区）

```text
🦞 OpenClow Installer
```

## 1. 先在飞书开放平台准备应用

平台地址：`https://open.feishu.cn`

按顺序完成：
- 创建企业自建应用
- 开启机器人能力
- 在「凭证与基础信息」拿到 `App ID` 和 `App Secret`
- 在权限管理完成 OpenClow 需要的权限申请并通过审批

## 2. 本地执行安装命令

```bash
curl -fsSL https://raw.githubusercontent.com/Jackson-Loyns/openclow-installer/main/install.sh | bash -s --
```

执行后会自动：
- 检查并安装环境（macOS / Linux）
- 安装 OpenClow
- **在终端提示你输入飞书配置**
  - `FEISHU_APP_ID`（必填）
  - `FEISHU_APP_SECRET`（必填）
  - `FEISHU_ENCRYPT_KEY`（可选）
  - `FEISHU_VERIFICATION_TOKEN`（可选）
- 写入配置并设置自启动

## 3. 配置文件位置

`~/.config/openclow/config.env`

如果要修改飞书配置，直接编辑这个文件即可。
