# x-ui 简化版

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

访问项目发布页面，下载对应系统架构的安装包：
- amd64：适用于大多数 x86_64 架构服务器
- arm64：适用于 ARM 架构服务器

### 2. 安装步骤

```bash
# 创建安装目录
mkdir -p /usr/local/x-ui

# 解压安装包
tar zxvf x-ui-linux-amd64.tar.gz -C /usr/local/x-ui

# 设置执行权限
chmod +x /usr/local/x-ui/x-ui
chmod +x /usr/local/x-ui/bin/xray-linux-*
chmod +x /usr/local/x-ui/x-ui.sh

# 创建软链接
ln -s /usr/local/x-ui/x-ui.sh /usr/bin/x-ui

# 安装系统服务
cp /usr/local/x-ui/x-ui.service /etc/systemd/system/

# 启动服务
systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui
```

### 3. Docker 安装

```bash
# 创建数据目录
mkdir -p ~/x-ui/{db,cert}

# 运行容器
docker run -d \
    --name x-ui \
    --network host \
    --restart unless-stopped \
    -v ~/x-ui/db:/etc/x-ui \
    -v ~/x-ui/cert:/root/cert \
    你的docker镜像地址
```

## 使用说明

### 访问面板

- 默认地址：http://服务器IP:54321
- 默认账号：admin
- 默认密码：admin

> 首次登录后请立即修改默认密码！

### 管理命令

```bash
# 显示管理菜单
x-ui

# 启动服务
x-ui start

# 停止服务
x-ui stop

# 重启服务
x-ui restart

# 查看状态
x-ui status

# 设置开机自启
x-ui enable

# 取消开机自启
x-ui disable

# 查看日志
x-ui log

# 更新面板
x-ui update
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
1. 查看日志：`x-ui log`
2. 检查端口占用：`netstat -tlnp | grep 端口号`
3. 检查权限：`ls -l /usr/local/x-ui/`

### 2. 节点无法连接

排查方法：
1. 检查 xray 服务状态：`x-ui status`
2. 确认防火墙设置
3. 验证节点配置
4. 检查网络连接

## 更新日志

### v1.0.0
- 初始版本发布
- 移除 Telegram 机器人功能
- 移除 v2-ui 迁移功能
- 移除 SSL 证书申请功能
- 保留核心代理和面板功能

## 技术支持

如有问题，请通过以下方式获取支持：
1. 提交 Issue
2. 查看项目文档
3. 加入讨论群组

## 免责声明

本项目仅供学习和研究使用，请遵守当地法律法规。
