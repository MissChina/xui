#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}错误: 此脚本必须以 root 身份运行！${PLAIN}"
        exit 1
    fi
}

# 检查系统架构
check_arch() {
    ARCH=$(uname -m)
    if [[ $ARCH == "x86_64" || $ARCH == "x64" || $ARCH == "amd64" ]]; then
        ARCH="amd64"
    elif [[ $ARCH == "aarch64" || $ARCH == "arm64" ]]; then
        ARCH="arm64"
    else
        echo -e "${RED}不支持的架构: $ARCH${PLAIN}"
        exit 1
    fi
}

# 检查系统
check_system() {
    if [[ -f /etc/redhat-release ]]; then
        SYSTEM="centos"
    elif [[ -f /etc/debian_version ]]; then
        SYSTEM="debian"
    else
        echo -e "${RED}不支持的系统！${PLAIN}"
        exit 1
    fi
}

# 获取最新版本
get_latest_version() {
    echo -e "${GREEN}正在获取最新版本信息...${PLAIN}"
    
    # 尝试使用 GitHub API 获取最新版本
    LATEST_VERSION=$(curl -s https://api.github.com/repos/MissChina/xui/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ ! -n "$LATEST_VERSION" ]]; then
        echo -e "${YELLOW}GitHub API 获取失败，尝试从网页获取...${PLAIN}"
        # 如果 API 获取失败，尝试从网页获取
        LATEST_VERSION=$(curl -s https://github.com/MissChina/xui/releases/latest | grep -o 'tag/[^"]*' | cut -d'/' -f2)
    fi
    
    if [[ ! -n "$LATEST_VERSION" ]]; then
        echo -e "${RED}获取最新版本失败，请检查你的网络连接${PLAIN}"
        echo -e "${YELLOW}提示：如果使用代理，请确保代理设置正确${PLAIN}"
        exit 1
    fi
    
    echo -e "${GREEN}检测到最新版本：${LATEST_VERSION}${PLAIN}"
}

# 安装依赖
install_dependencies() {
    echo -e "${GREEN}安装依赖包...${PLAIN}"
    
    if [[ $SYSTEM == "centos" ]]; then
        yum update -y
        yum install -y wget curl unzip tar gzip
    else
        apt update -y
        apt install -y wget curl unzip tar gzip
    fi
    
    echo -e "${GREEN}依赖包安装完成${PLAIN}"
}

# 下载文件
download_file() {
    local url=$1
    local output=$2
    local max_retries=3
    local retry_count=1
    
    while [[ $retry_count -le $max_retries ]]; do
        echo -e "${GREEN}尝试下载 (第 $retry_count 次)...${PLAIN}"
        wget -N --no-check-certificate -O "$output" "$url"
        
        if [[ $? -eq 0 ]]; then
            return 0
        fi
        
        echo -e "${YELLOW}下载失败，等待 5 秒后重试...${PLAIN}"
        sleep 5
        retry_count=$((retry_count + 1))
    done
    
    return 1
}

# 安装 xui
install_x_ui() {
    # 停止已存在的服务
    systemctl stop xui 2>/dev/null
    
    # 下载最新版本
    local DOWNLOAD_URL="${GITHUB_URL}/releases/download/${LATEST_VERSION}/xui-linux-${ARCH}.tar.gz"
    echo -e "${GREEN}下载 xui ${LATEST_VERSION} (${ARCH})...${PLAIN}"
    echo -e "${GREEN}下载链接: ${DOWNLOAD_URL}${PLAIN}"
    
    # 尝试下载tar.gz文件
    if ! download_file "$DOWNLOAD_URL" "/usr/local/xui-linux-${ARCH}.tar.gz"; then
        echo -e "${YELLOW}tar.gz下载失败，尝试下载zip文件...${PLAIN}"
        DOWNLOAD_URL="${GITHUB_URL}/releases/download/${LATEST_VERSION}/xui-linux-${ARCH}.zip"
        
        if ! download_file "$DOWNLOAD_URL" "/usr/local/xui-linux-${ARCH}.zip"; then
            echo -e "${RED}下载 xui 失败，请检查你的网络连接${PLAIN}"
            echo -e "${YELLOW}提示：如果使用代理，请确保代理设置正确${PLAIN}"
            exit 1
        fi
    fi
    
    # 准备安装
    rm -rf /usr/local/xui
    mkdir -p /usr/local/xui
    
    # 解压
    echo -e "${GREEN}解压安装包...${PLAIN}"
    
    # 检查下载的是tar.gz还是zip文件
    if [[ -f "/usr/local/xui-linux-${ARCH}.tar.gz" ]]; then
        # 解压tar.gz文件
        tar -xzf "/usr/local/xui-linux-${ARCH}.tar.gz" -C /usr/local
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}解压 xui 失败，请检查磁盘空间和权限${PLAIN}"
            rm -f "/usr/local/xui-linux-${ARCH}.tar.gz"
            exit 1
        fi
        # 清理
        rm -f "/usr/local/xui-linux-${ARCH}.tar.gz"
    else
        # 创建临时目录
        local temp_dir="/tmp/xui-extract-$$"
        rm -rf "$temp_dir"
        mkdir -p "$temp_dir"
        
        # 解压zip文件到临时目录
        echo -e "${YELLOW}解压到临时目录...${PLAIN}"
        unzip -o "/usr/local/xui-linux-${ARCH}.zip" -d "$temp_dir"
        
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}解压 xui 失败，请检查磁盘空间和权限${PLAIN}"
            rm -rf "$temp_dir"
            rm -f "/usr/local/xui-linux-${ARCH}.zip"
            exit 1
        fi
        
        # 创建目标目录结构
        mkdir -p /usr/local/xui/bin
        
        # 复制文件，处理可能的路径分隔符问题
        echo -e "${YELLOW}复制文件...${PLAIN}"
        
        # 使用find命令查找并复制文件，避免路径分隔符问题
        find "$temp_dir" -type f -name "xui" -exec cp {} /usr/local/xui/ \;
        find "$temp_dir" -type f -name "*.sh" -exec cp {} /usr/local/xui/ \;
        find "$temp_dir" -type f -name "xui.service" -exec cp {} /usr/local/xui/ \;
        find "$temp_dir" -type f -name "geoip.dat" -exec cp {} /usr/local/xui/bin/ \;
        find "$temp_dir" -type f -name "geosite.dat" -exec cp {} /usr/local/xui/bin/ \;
        find "$temp_dir" -type f -name "xray-linux-${ARCH}" -exec cp {} /usr/local/xui/bin/ \;
        
        # 清理临时目录和zip文件
        rm -rf "$temp_dir"
        rm -f "/usr/local/xui-linux-${ARCH}.zip"
    fi
    
    # 设置权限
    chmod +x /usr/local/xui/xui
    chmod +x /usr/local/xui/bin/* 2>/dev/null
    chmod +x /usr/local/xui/*.sh 2>/dev/null
    
    # 创建软链接
    ln -sf /usr/local/xui/xui.sh /usr/bin/xui
    
    # 安装服务
    cp -f /usr/local/xui/xui.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable xui
    systemctl start xui
    
    echo -e "${GREEN}xui ${LATEST_VERSION} 安装成功！${PLAIN}"
    echo -e ""
    echo -e "面板访问地址: ${GREEN}http://服务器IP:54321${PLAIN}"
    echo -e "用户名: ${GREEN}admin${PLAIN}"
    echo -e "密码: ${GREEN}admin${PLAIN}"
    echo -e ""
    echo -e "xui 管理命令: ${GREEN}xui${PLAIN}"
}

# 卸载 xui
uninstall_x_ui() {
    echo -e "${YELLOW}确定卸载 xui 吗？(y/n)${PLAIN}"
    read -p "(默认: n): " CONFIRM
    if [[ $CONFIRM != "y" ]]; then
        echo -e "${GREEN}已取消${PLAIN}"
        return
    fi
    
    systemctl stop xui
    systemctl disable xui
    rm -rf /usr/local/xui
    rm -f /usr/bin/xui
    rm -f /etc/systemd/system/xui.service
    systemctl daemon-reload
    
    echo -e "${GREEN}xui 卸载成功${PLAIN}"
}

# 显示使用说明
show_usage() {
    echo -e "${GREEN}xui 管理脚本${PLAIN}"
    echo -e "使用方法: ${GREEN}bash install.sh [选项]${PLAIN}"
    echo -e "选项:"
    echo -e "  install   - 安装 xui"
    echo -e "  uninstall - 卸载 xui"
    echo -e "  help      - 显示此帮助信息"
}

# 显示菜单
show_menu() {
    echo -e "${GREEN}xui 安装管理脚本${PLAIN}"
    echo -e ""
    echo -e "${GREEN}1.${PLAIN} 安装 xui"
    echo -e "${GREEN}2.${PLAIN} 卸载 xui"
    echo -e "${GREEN}0.${PLAIN} 退出"
    read -p "请输入选项 [0-2]: " OPTION
    
    case $OPTION in
        0) exit 0 ;;
        1) check_root && check_arch && check_system && get_latest_version && install_dependencies && install_x_ui ;;
        2) check_root && uninstall_x_ui ;;
        *) echo -e "${RED}无效的选项${PLAIN}" ;;
    esac
}

# 主函数
main() {
    if [[ $# -gt 0 ]]; then
        case $1 in
            install) check_root && check_arch && check_system && get_latest_version && install_dependencies && install_x_ui ;;
            uninstall) check_root && uninstall_x_ui ;;
            help) show_usage ;;
            *) show_usage ;;
        esac
    else
        show_menu
    fi
}

# 执行主函数
main "$@"
