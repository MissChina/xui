#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}错误：请使用root用户运行此脚本${NC}"
    exit 1
fi

# 检查系统架构
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64)
        ARCH="arm64"
        ;;
    *)
        echo -e "${RED}错误：不支持的系统架构${NC}"
        exit 1
        ;;
esac

# 安装目录
INSTALL_DIR="/usr/local/x-ui"
BIN_DIR="/usr/bin"

# 下载地址
DOWNLOAD_URL="https://github.com/MissChina/xui/releases/latest/download/x-ui-linux-${ARCH}.tar.gz"

# 安装函数
install_xui() {
    echo -e "${BLUE}开始安装 x-ui...${NC}"
    
    # 创建安装目录
    mkdir -p $INSTALL_DIR
    
    # 下载安装包
    echo -e "${YELLOW}正在下载安装包...${NC}"
    if ! wget -O /tmp/x-ui.tar.gz $DOWNLOAD_URL; then
        echo -e "${RED}下载失败，请检查网络连接或访问 GitHub Releases 页面手动下载${NC}"
        echo -e "${YELLOW}下载地址：${DOWNLOAD_URL}${NC}"
        exit 1
    fi
    
    # 解压安装包
    echo -e "${YELLOW}正在解压安装包...${NC}"
    if ! tar zxvf /tmp/x-ui.tar.gz -C $INSTALL_DIR; then
        echo -e "${RED}解压失败，请检查下载的安装包是否完整${NC}"
        exit 1
    fi
    
    # 设置执行权限
    chmod +x $INSTALL_DIR/x-ui
    chmod +x $INSTALL_DIR/bin/xray-linux-*
    chmod +x $INSTALL_DIR/x-ui.sh
    
    # 创建软链接
    ln -sf $INSTALL_DIR/x-ui.sh $BIN_DIR/x-ui
    
    # 安装系统服务
    cp $INSTALL_DIR/x-ui.service /etc/systemd/system/
    
    # 启动服务
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    
    # 清理临时文件
    rm -f /tmp/x-ui.tar.gz
    
    echo -e "${GREEN}x-ui 安装完成！${NC}"
    echo -e "${BLUE}面板地址：http://服务器IP:54321${NC}"
    echo -e "${BLUE}默认用户名：admin${NC}"
    echo -e "${BLUE}默认密码：admin${NC}"
    echo -e "${YELLOW}请及时修改默认密码！${NC}"
}

# 卸载函数
uninstall_xui() {
    echo -e "${YELLOW}开始卸载 x-ui...${NC}"
    
    systemctl stop x-ui
    systemctl disable x-ui
    rm -f /etc/systemd/system/x-ui.service
    rm -f $BIN_DIR/x-ui
    rm -rf $INSTALL_DIR
    
    echo -e "${GREEN}x-ui 卸载完成！${NC}"
}

# 主菜单
show_menu() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}            x-ui 安装脚本               ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "1. 安装 x-ui"
    echo -e "2. 卸载 x-ui"
    echo -e "0. 退出"
    echo -e "${BLUE}========================================${NC}"
    read -p "请选择操作 [0-2]: " choice
    case $choice in
        1)
            install_xui
            ;;
        2)
            uninstall_xui
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${RED}无效的选择，请重新输入${NC}"
            show_menu
            ;;
    esac
}

# 显示菜单
show_menu
