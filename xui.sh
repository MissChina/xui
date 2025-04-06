#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

# 配置项
CONFIG_FILE="/etc/xui/config.json"
BACKUP_DIR="/etc/xui/backup"
SSL_DIR="/root/cert"
VERSION="1.0.0"

# 安装路径
INSTALL_DIR="/usr/local/xui"

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}错误: 请使用root用户运行此脚本！${PLAIN}"
        exit 1
    fi
}

# 检查xui状态
check_status() {
    if systemctl is-active --quiet xui; then
        echo -e "xui状态: ${GREEN}运行中${PLAIN}"
    else
        echo -e "xui状态: ${RED}未运行${PLAIN}"
    fi
    
    echo -e "xui版本: ${GREEN}v${VERSION}${PLAIN}"
    
    # 获取服务器IP
    IP=$(curl -s4 ip.sb) || IP=$(curl -s6 ip.sb) || IP=$(hostname -I | awk '{print $1}')
    
    # 获取面板端口
    PANEL_PORT=$(grep -o '"port":[0-9]*' ${CONFIG_FILE} 2>/dev/null | awk -F':' '{print $2}')
    if [[ -z "${PANEL_PORT}" ]]; then
        PANEL_PORT=54321
    fi
    
    # 生成安全访问令牌 (如果不存在)
    ACCESS_TOKEN=$(grep -o '"accessToken":"[^"]*' ${CONFIG_FILE} 2>/dev/null | awk -F'"' '{print $4}')
    if [[ -z "${ACCESS_TOKEN}" ]]; then
        ACCESS_TOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 16)
        # 保存访问令牌
        if [[ -f ${CONFIG_FILE} ]]; then
            sed -i "s/\"accessToken\":\"[^\"]*\"/\"accessToken\":\"${ACCESS_TOKEN}\"/" ${CONFIG_FILE}
        fi
    fi
    
    echo -e "面板访问地址: ${GREEN}http://${IP}:${PANEL_PORT}/?token=${ACCESS_TOKEN}${PLAIN}"
}

# 启动xui
start_xui() {
    systemctl start xui
    sleep 2
    
    if systemctl is-active --quiet xui; then
        echo -e "${GREEN}xui 启动成功！${PLAIN}"
    else
        echo -e "${RED}xui 启动失败，请检查日志信息！${PLAIN}"
    fi
}

# 停止xui
stop_xui() {
    systemctl stop xui
    sleep 2
    
    if ! systemctl is-active --quiet xui; then
        echo -e "${GREEN}xui 已停止！${PLAIN}"
    else
        echo -e "${RED}xui 停止失败，请检查日志信息！${PLAIN}"
    fi
}

# 重启xui
restart_xui() {
    systemctl restart xui
    sleep 2
    
    if systemctl is-active --quiet xui; then
        echo -e "${GREEN}xui 重启成功！${PLAIN}"
    else
        echo -e "${RED}xui 重启失败，请检查日志信息！${PLAIN}"
    fi
}

# 查看xui状态
view_status() {
    systemctl status xui -l
}

# 设置xui开机自启
enable_xui() {
    systemctl enable xui
    if [[ $? == 0 ]]; then
        echo -e "${GREEN}设置xui开机自启成功！${PLAIN}"
    else
        echo -e "${RED}设置xui开机自启失败！${PLAIN}"
    fi
}

# 取消xui开机自启
disable_xui() {
    systemctl disable xui
    if [[ $? == 0 ]]; then
        echo -e "${GREEN}取消xui开机自启成功！${PLAIN}"
    else
        echo -e "${RED}取消xui开机自启失败！${PLAIN}"
    fi
}

# 查看xui日志
view_log() {
    journalctl -u xui -n 50 --no-pager
    
    echo -e "\n${YELLOW}如需查看更多日志，请运行: journalctl -u xui -f${PLAIN}"
}

# 检查更新
check_update() {
    echo -e "${GREEN}正在检查更新...${PLAIN}"
    
    LATEST_VERSION=$(curl -s https://api.github.com/repos/MissChina/xui/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ ! -n "$LATEST_VERSION" ]]; then
        echo -e "${RED}检查更新失败，请检查网络连接！${PLAIN}"
        return
    fi
    
    # 去除版本号中的v前缀
    LATEST_VERSION=${LATEST_VERSION#v}
    
    if [[ $LATEST_VERSION == $VERSION ]]; then
        echo -e "${GREEN}当前已是最新版本：${VERSION}${PLAIN}"
    else
        echo -e "${YELLOW}发现新版本：${LATEST_VERSION}，当前版本：${VERSION}${PLAIN}"
        read -p "是否进行升级？(y/N): " -e ANSWER
        if [[ $ANSWER =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}开始升级...${PLAIN}"
            wget -O /usr/local/update-xui.sh https://raw.githubusercontent.com/MissChina/xui/master/install.sh
            if [[ $? -ne 0 ]]; then
                echo -e "${RED}下载升级脚本失败，请手动升级！${PLAIN}"
                exit 1
            fi
            bash /usr/local/update-xui.sh
            rm -f /usr/local/update-xui.sh
        else
            echo -e "${YELLOW}已取消升级${PLAIN}"
        fi
    fi
}

# 备份面板数据
backup_xui() {
    mkdir -p ${BACKUP_DIR}
    local BACKUP_FILE="${BACKUP_DIR}/xui-backup-$(date +%Y%m%d%H%M%S).tar.gz"
    
    if [[ -d /etc/xui ]]; then
        echo -e "${GREEN}开始备份面板数据...${PLAIN}"
        tar -czf ${BACKUP_FILE} -C /etc xui
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}备份成功！${PLAIN}"
            echo -e "备份文件：${BACKUP_FILE}"
        else
            echo -e "${RED}备份失败！${PLAIN}"
        fi
    else
        echo -e "${RED}未找到面板数据目录，无法备份！${PLAIN}"
    fi
}

# 恢复面板数据
restore_xui() {
    if [[ ! -d ${BACKUP_DIR} || -z "$(ls -A ${BACKUP_DIR} 2>/dev/null)" ]]; then
        echo -e "${RED}未找到备份文件！${PLAIN}"
        return
    fi
    
    # 列出所有备份文件
    echo -e "${GREEN}找到以下备份文件:${PLAIN}"
    local index=1
    local backup_files=()
    
    for file in $(ls -t ${BACKUP_DIR}/*.tar.gz 2>/dev/null); do
        echo -e "${GREEN}$index.${PLAIN} $(basename $file) ($(date -r $file '+%Y-%m-%d %H:%M:%S'))"
        backup_files[$index]=$file
        index=$((index + 1))
    done
    
    read -p "请选择要恢复的备份文件 [1-$((index-1))]: " -e CHOICE
    
    if [[ $CHOICE -ge 1 && $CHOICE -lt $index ]]; then
        local selected_file=${backup_files[$CHOICE]}
        
        echo -e "${YELLOW}警告: 恢复操作将覆盖当前数据！${PLAIN}"
        read -p "是否继续？(y/N): " -e CONFIRM
        
        if [[ $CONFIRM =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}开始恢复数据...${PLAIN}"
            systemctl stop xui
            
            tar -xzf ${selected_file} -C /
            if [[ $? -eq 0 ]]; then
                systemctl start xui
                echo -e "${GREEN}数据恢复成功！${PLAIN}"
            else
                echo -e "${RED}数据恢复失败！${PLAIN}"
            fi
        else
            echo -e "${YELLOW}已取消恢复操作${PLAIN}"
        fi
    else
        echo -e "${RED}选择无效！${PLAIN}"
    fi
}

# 显示帮助信息
show_help() {
    echo -e "${GREEN}xui 管理脚本 ${VERSION}${PLAIN}"
    echo -e "用法: $0 [选项]"
    echo -e ""
    echo -e "选项:"
    echo -e "  start         启动 xui"
    echo -e "  stop          停止 xui"
    echo -e "  restart       重启 xui"
    echo -e "  status        查看 xui 状态"
    echo -e "  enable        设置 xui 开机自启"
    echo -e "  disable       取消 xui 开机自启"
    echo -e "  log           查看 xui 日志"
    echo -e "  update        检查并更新 xui"
    echo -e "  backup        备份 xui 配置"
    echo -e "  restore       恢复 xui 配置"
    echo -e "  help          显示此帮助信息"
}

# 显示菜单
show_menu() {
    clear
    echo -e "${GREEN}xui 管理脚本 ${VERSION}${PLAIN}"
    echo -e "  ${GREEN}1.${PLAIN} 启动 xui"
    echo -e "  ${GREEN}2.${PLAIN} 停止 xui"
    echo -e "  ${GREEN}3.${PLAIN} 重启 xui"
    echo -e "  ${GREEN}4.${PLAIN} 查看 xui 状态"
    echo -e "  ${GREEN}5.${PLAIN} 设置 xui 开机自启"
    echo -e "  ${GREEN}6.${PLAIN} 取消 xui 开机自启"
    echo -e "  ${GREEN}7.${PLAIN} 查看 xui 日志"
    echo -e "  ${GREEN}8.${PLAIN} 检查并更新 xui"
    echo -e "  ${GREEN}9.${PLAIN} 备份 xui 配置"
    echo -e "  ${GREEN}10.${PLAIN} 恢复 xui 配置"
    echo -e "  ${GREEN}0.${PLAIN} 退出脚本"
    echo -e "————————————————"
    check_status
    echo -e "————————————————"
    
    read -p "请输入选项 [0-10]: " -e CHOICE
    
    case $CHOICE in
        1) start_xui ;;
        2) stop_xui ;;
        3) restart_xui ;;
        4) view_status ;;
        5) enable_xui ;;
        6) disable_xui ;;
        7) view_log ;;
        8) check_update ;;
        9) backup_xui ;;
        10) restore_xui ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效的选项！${PLAIN}" ;;
    esac
}

# 主函数
main() {
    check_root
    
    case "$1" in
        start) start_xui ;;
        stop) stop_xui ;;
        restart) restart_xui ;;
        status) check_status ;;
        enable) enable_xui ;;
        disable) disable_xui ;;
        log) view_log ;;
        update) check_update ;;
        backup) backup_xui ;;
        restore) restore_xui ;;
        help) show_help ;;
        *) show_menu ;;
    esac
}

# 执行主函数
main "$@"
