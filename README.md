# xui

轻量级、安全的 xray 代理面板，支持多用户多协议管理

## 特性

- 🚀 轻量高效 - 专注核心功能，资源占用低
- 🔒 安全可靠 - 内置多种安全策略和访问控制
- 📊 流量监控 - 实时统计流量和系统状态
- 🛠️ 简易管理 - 直观的Web界面，便捷的命令行工具
- 🔄 多协议支持 - vmess、vless、trojan、shadowsocks 等

## 快速开始

### 一键安装

```bash
bash <(curl -Ls https://raw.githubusercontent.com/MissChina/xui/master/install.sh)
```

### 系统要求

- 系统: CentOS 7+、Ubuntu 16+、Debian 8+
- 内存: 最低 512MB
- 存储: 最低 1GB 可用空间
- 架构: x86_64 (amd64) 或 aarch64 (arm64)

## 安装指南

### 自动安装（推荐）

执行以下命令启动安装脚本：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/MissChina/xui/master/install.sh)
```

选择菜单中的"安装 xui"选项，脚本将自动检测系统环境并完成安装。

### 手动安装

1. 下载适合系统架构的安装包：
   - [xui-linux-amd64.tar.gz](https://github.com/MissChina/xui/releases/latest/download/xui-linux-amd64.tar.gz) - 适用于 x86_64 架构
   - [xui-linux-arm64.tar.gz](https://github.com/MissChina/xui/releases/latest/download/xui-linux-arm64.tar.gz) - 适用于 aarch64 架构

2. 解压安装包并设置权限：

```bash
# 创建安装目录
mkdir -p /usr/local/xui

# 解压文件
tar -xzf xui-linux-amd64.tar.gz -C /usr/local/xui

# 设置执行权限
chmod +x /usr/local/xui/xui
chmod +x /usr/local/xui/bin/*
chmod +x /usr/local/xui/*.sh

# 创建软链接
ln -sf /usr/local/xui/xui.sh /usr/bin/xui

# 安装服务
cp -f /usr/local/xui/xui.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable xui
systemctl start xui
```

### Docker 安装

```bash
# 创建数据目录
mkdir -p ~/xui-data/{db,cert}

# 运行容器
docker run -d \
  --name xui \
  --restart unless-stopped \
  --network host \
  -v ~/xui-data/db:/etc/xui \
  -v ~/xui-data/cert:/root/cert \
  misschina/xui:latest
```

## 使用说明

### 访问面板

安装完成后，可以通过以下方式访问面板：

- 地址: `http://服务器IP:54321/?token=访问令牌`
- 默认用户名: `admin`
- 默认密码: `admin`

访问令牌在安装完成后会显示，也可以通过运行 `xui` 命令查看。

> ⚠️ 安全提示：首次登录后务必修改默认密码和面板访问端口！

### 管理命令

安装完成后，可使用 `xui` 命令管理面板：

```bash
# 显示管理菜单
xui

# 启动服务
xui start

# 停止服务
xui stop

# 重启服务
xui restart

# 查看状态
xui status

# 查看日志
xui log

# 更新面板
xui update

# 备份配置
xui backup

# 恢复配置
xui restore

# 查看帮助
xui help
```

## 安全建议

1. 立即修改默认密码和访问端口
2. 启用 HTTPS (可通过 Nginx/Caddy 反向代理实现)
3. 使用防火墙限制面板访问IP
4. 定期更新系统和面板
5. 定期备份配置文件

## 常见问题

### 面板无法访问

1. 检查服务状态: `xui status`
2. 查看错误日志: `xui log`
3. 检查防火墙是否开放端口: `iptables -L`
4. 确认面板端口和访问令牌是否正确

### 节点连接失败

1. 检查节点配置是否正确
2. 查看xray日志: `journalctl -u xui`
3. 确认服务器防火墙是否开放节点端口
4. 检查服务器是否可以正常访问外网

## 开发与构建

### 环境要求

- Go 1.19+
- Node.js 16+ (用于前端构建)

### 构建步骤

1. 克隆代码仓库：
   ```bash
   git clone https://github.com/MissChina/xui.git
   cd xui
   ```

2. 在 Linux/macOS 上构建：
   ```bash
   bash build.sh
   ```

3. 在 Windows 上构建：
   ```powershell
   .\build.ps1
   ```

构建完成后的文件将位于 `release` 目录。

## 更新日志

### v1.0.0
- 首个正式版本发布
- 实现核心代理管理功能
- 支持多用户多协议管理
- 流量统计和限制功能
- 系统状态监控

## 许可证

[MIT License](LICENSE)
