# xui 简化版

一个轻量级的 xray 代理管理面板，专注于核心功能。

## 主要特点

- 🚀 简洁高效：去除了不必要的功能，专注于核心代理管理
- 🔒 安全可靠：支持多用户多协议管理
- 📊 实时监控：系统状态和流量统计
- 🛠️ 易于使用：网页可视化操作界面
- 🔄 多协议支持：vmess、vless、trojan、shadowsocks 等

## 快速开始

### 一键安装

```bash
bash <(curl -Ls https://raw.githubusercontent.com/MissChina/xui/master/install.sh)
```

### 系统要求

- 操作系统：CentOS 7+ / Ubuntu 16+ / Debian 8+
- 内存：512MB 以上
- 存储：1GB 以上可用空间

## 安装指南

### 1. 下载安装包

访问项目[发布页面](https://github.com/MissChina/xui/releases)，下载对应系统架构的安装包：
- amd64：适用于大多数 x86_64 架构服务器
- arm64：适用于 ARM 架构服务器

### 2. 手动安装步骤

```bash
# 创建安装目录
mkdir -p /usr/local/xui

# 解压安装包
unzip xui-linux-amd64.zip -d /usr/local/xui

# 设置执行权限
chmod +x /usr/local/xui/xui
chmod +x /usr/local/xui/bin/xray-linux-*
chmod +x /usr/local/xui/xui.sh

# 创建软链接
ln -s /usr/local/xui/xui.sh /usr/bin/xui

# 安装系统服务
cp /usr/local/xui/xui.service /etc/systemd/system/

# 启动服务
systemctl daemon-reload
systemctl enable xui
systemctl start xui
```

### 3. Docker 安装

```bash
# 创建数据目录
mkdir -p ~/xui/{db,cert}

# 运行容器
docker run -d \
    --name xui \
    --network host \
    --restart unless-stopped \
    -v ~/xui/db:/etc/xui \
    -v ~/xui/cert:/root/cert \
    misschina/xui:latest
```

## 使用说明

### 访问面板

- 默认地址：http://服务器IP:54321
- 默认账号：admin
- 默认密码：admin

> ⚠️ 首次登录后请立即修改默认密码！

### 管理命令

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

# 设置开机自启
xui enable

# 取消开机自启
xui disable

# 查看日志
xui log

# 更新面板
xui update

# 卸载面板
xui uninstall
```

## 安全建议

1. 修改默认端口
2. 使用强密码
3. 配置 HTTPS 访问
4. 定期更新系统
5. 配置防火墙规则

## 常见问题

### 1. 服务无法启动

检查步骤：
1. 查看日志：`xui log`
2. 检查端口占用：`netstat -tlnp | grep 端口号`
3. 检查权限：`ls -l /usr/local/xui/`

### 2. 节点无法连接

排查方法：
1. 检查 xray 服务状态：`xui status`
2. 确认防火墙设置
3. 验证节点配置
4. 检查网络连接

## 开发指南

### 构建发布版本

在 Windows 环境中，可以使用以下步骤构建发布版本：

```powershell
# 克隆代码库
git clone https://github.com/MissChina/xui.git
cd xui

# 设置执行权限
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# 生成发布包
.\release.ps1
```

生成的发布包将位于 `release` 目录中。

## 更新日志

### v1.0.0
- 初始版本发布
- 专注于核心代理和面板功能
- 支持多用户多协议管理

## 贡献指南

欢迎提交 Pull Request 或 Issue 来帮助改进这个项目。

## 免责声明

本项目仅供学习和研究使用，请遵守当地法律法规。

## 许可证

[MIT License](LICENSE)
