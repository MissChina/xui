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
    echo -e "${BLUE}            xui 管理脚本               ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "1. 启动 xui"
    echo -e "2. 停止 xui"
    echo -e "3. 重启 xui"
    echo -e "4. 查看状态"
    echo -e "5. 设置开机自启"
    echo -e "6. 取消开机自启"
    echo -e "7. 查看日志"
    echo -e "8. 更新面板"
    echo -e "9. 卸载面板"
    echo -e "0. 退出"
    echo -e "${BLUE}========================================${NC}"
    read -p "请选择操作 [0-9]: " choice
    case $choice in
        1)
            systemctl start xui
            echo -e "${GREEN}xui 已启动${NC}"
            ;;
        2)
            systemctl stop xui
            echo -e "${GREEN}xui 已停止${NC}"
            ;;
        3)
            systemctl restart xui
            echo -e "${GREEN}xui 已重启${NC}"
            ;;
        4)
            systemctl status xui
            ;;
        5)
            systemctl enable xui
            echo -e "${GREEN}xui 已设置开机自启${NC}"
            ;;
        6)
            systemctl disable xui
            echo -e "${GREEN}xui 已取消开机自启${NC}"
            ;;
        7)
            journalctl -u xui -f
            ;;
        8)
            echo -e "${YELLOW}正在更新 xui...${NC}"
            curl -sL https://raw.githubusercontent.com/MissChina/xui/master/install.sh | bash
            ;;
        9)
            echo -e "${YELLOW}确定要卸载 xui 吗？此操作不可逆 [y/n]${NC}"
            read -p "默认为 n: " confirm
            if [[ $confirm == "y" ]]; then
                echo -e "${YELLOW}正在卸载 xui...${NC}"
                curl -sL https://raw.githubusercontent.com/MissChina/xui/master/install.sh | bash -s -- uninstall
                echo -e "${GREEN}xui 已卸载${NC}"
            else
                echo -e "${BLUE}已取消卸载操作${NC}"
            fi
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

# 命令行参数处理
case $1 in
    start)
        systemctl start xui
        ;;
    stop)
        systemctl stop xui
        ;;
    restart)
        systemctl restart xui
        ;;
    status)
        systemctl status xui
        ;;
    enable)
        systemctl enable xui
        ;;
    disable)
        systemctl disable xui
        ;;
    log)
        journalctl -u xui -f
        ;;
    update)
        curl -sL https://raw.githubusercontent.com/MissChina/xui/master/install.sh | bash
        ;;
    uninstall)
        curl -sL https://raw.githubusercontent.com/MissChina/xui/master/install.sh | bash -s -- uninstall
        ;;
    *)
        show_menu
esac
