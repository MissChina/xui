#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

# 检查是否以root运行
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}错误: 此脚本必须以 root 身份运行！${PLAIN}"
    exit 1
fi

# 检查服务状态
check_status() {
    status=$(systemctl status xui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ "$status" == "running" ]]; then
        echo -e "xui 状态: ${GREEN}运行中${PLAIN}"
    else
        echo -e "xui 状态: ${RED}未运行${PLAIN}"
    fi
}

# 启动服务
start_service() {
    systemctl start xui
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}xui 启动成功${PLAIN}"
    else
        echo -e "${RED}xui 启动失败，请检查日志${PLAIN}"
    fi
}

# 停止服务
stop_service() {
    systemctl stop xui
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}xui 停止成功${PLAIN}"
    else
        echo -e "${RED}xui 停止失败${PLAIN}"
    fi
}

# 重启服务
restart_service() {
    systemctl restart xui
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}xui 重启成功${PLAIN}"
    else
        echo -e "${RED}xui 重启失败${PLAIN}"
    fi
}

# 启用开机自启
enable_service() {
    systemctl enable xui
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}xui 已设置为开机自启${PLAIN}"
    else
        echo -e "${RED}设置开机自启失败${PLAIN}"
    fi
}

# 禁用开机自启
disable_service() {
    systemctl disable xui
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}xui 已禁用开机自启${PLAIN}"
    else
        echo -e "${RED}禁用开机自启失败${PLAIN}"
    fi
}

# 显示菜单
show_menu() {
    echo -e "${GREEN}xui 管理脚本${PLAIN}"
    echo -e ""
    echo -e "${GREEN}1.${PLAIN} 查看状态"
    echo -e "${GREEN}2.${PLAIN} 启动服务"
    echo -e "${GREEN}3.${PLAIN} 停止服务"
    echo -e "${GREEN}4.${PLAIN} 重启服务"
    echo -e "${GREEN}5.${PLAIN} 设置开机自启"
    echo -e "${GREEN}6.${PLAIN} 禁用开机自启"
    echo -e "${GREEN}0.${PLAIN} 退出"
    
    read -p "请输入选项 [0-6]: " CHOICE
    
    case $CHOICE in
        0) exit 0 ;;
        1) check_status ;;
        2) start_service ;;
        3) stop_service ;;
        4) restart_service ;;
        5) enable_service ;;
        6) disable_service ;;
        *) echo -e "${RED}无效的选项${PLAIN}" ;;
    esac
}

# 主函数
main() {
    if [[ $# -gt 0 ]]; then
        case $1 in
            status) check_status ;;
            start) start_service ;;
            stop) stop_service ;;
            restart) restart_service ;;
            enable) enable_service ;;
            disable) disable_service ;;
            *) show_menu ;;
        esac
    else
        show_menu
    fi
}

# 执行主函数
main "$@" 