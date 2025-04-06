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

# 显示菜单
show_menu() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}            x-ui 管理脚本               ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "1. 启动 x-ui"
    echo -e "2. 停止 x-ui"
    echo -e "3. 重启 x-ui"
    echo -e "4. 查看状态"
    echo -e "5. 设置开机自启"
    echo -e "6. 取消开机自启"
    echo -e "7. 查看日志"
    echo -e "8. 更新面板"
    echo -e "0. 退出"
    echo -e "${BLUE}========================================${NC}"
    read -p "请选择操作 [0-8]: " choice
    case $choice in
        1)
            systemctl start x-ui
            echo -e "${GREEN}x-ui 已启动${NC}"
            ;;
        2)
            systemctl stop x-ui
            echo -e "${GREEN}x-ui 已停止${NC}"
            ;;
        3)
            systemctl restart x-ui
            echo -e "${GREEN}x-ui 已重启${NC}"
            ;;
        4)
            systemctl status x-ui
            ;;
        5)
            systemctl enable x-ui
            echo -e "${GREEN}x-ui 已设置开机自启${NC}"
            ;;
        6)
            systemctl disable x-ui
            echo -e "${GREEN}x-ui 已取消开机自启${NC}"
            ;;
        7)
            journalctl -u x-ui -f
            ;;
        8)
            echo -e "${YELLOW}正在更新 x-ui...${NC}"
            curl -sL https://raw.githubusercontent.com/MissChina/xui/master/install.sh | bash
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
