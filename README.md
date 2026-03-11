# OpenClow 飞书安装说明（中国区）

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
在「权限管理」里按 OpenClow 官方文档配置权限并申请审核通过。  
参考（官方）：`https://docs.openclaw.ai/zh-cn/channels/feishu`

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

字段对应关系：
- 飞书 `App ID` -> `FEISHU_APP_ID`
- 飞书 `App Secret` -> `FEISHU_APP_SECRET`
