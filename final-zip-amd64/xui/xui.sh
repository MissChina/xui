#!/bin/bash

# 棰滆壊瀹氫箟
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 妫€鏌ユ槸鍚︿负root鐢ㄦ埛
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}閿欒锛氳浣跨敤root鐢ㄦ埛杩愯姝よ剼鏈?{NC}"
    exit 1
fi

# 鏄剧ず鑿滃崟
show_menu() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}            xui 绠＄悊鑴氭湰               ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "1. 鍚姩 xui"
    echo -e "2. 鍋滄 xui"
    echo -e "3. 閲嶅惎 xui"
    echo -e "4. 鏌ョ湅鐘舵€?
    echo -e "5. 璁剧疆寮€鏈鸿嚜鍚?
    echo -e "6. 鍙栨秷寮€鏈鸿嚜鍚?
    echo -e "7. 鏌ョ湅鏃ュ織"
    echo -e "8. 鏇存柊闈㈡澘"
    echo -e "9. 鍗歌浇闈㈡澘"
    echo -e "0. 閫€鍑?
    echo -e "${BLUE}========================================${NC}"
    read -p "璇烽€夋嫨鎿嶄綔 [0-9]: " choice
    case $choice in
        1)
            systemctl start xui
            echo -e "${GREEN}xui 宸插惎鍔?{NC}"
            ;;
        2)
            systemctl stop xui
            echo -e "${GREEN}xui 宸插仠姝?{NC}"
            ;;
        3)
            systemctl restart xui
            echo -e "${GREEN}xui 宸查噸鍚?{NC}"
            ;;
        4)
            systemctl status xui
            ;;
        5)
            systemctl enable xui
            echo -e "${GREEN}xui 宸茶缃紑鏈鸿嚜鍚?{NC}"
            ;;
        6)
            systemctl disable xui
            echo -e "${GREEN}xui 宸插彇娑堝紑鏈鸿嚜鍚?{NC}"
            ;;
        7)
            journalctl -u xui -f
            ;;
        8)
            echo -e "${YELLOW}姝ｅ湪鏇存柊 xui...${NC}"
            curl -sL https://raw.githubusercontent.com/MissChina/xui/master/install.sh | bash
            ;;
        9)
            echo -e "${YELLOW}纭畾瑕佸嵏杞?xui 鍚楋紵姝ゆ搷浣滀笉鍙€?[y/n]${NC}"
            read -p "榛樿涓?n: " confirm
            if [[ $confirm == "y" ]]; then
                echo -e "${YELLOW}姝ｅ湪鍗歌浇 xui...${NC}"
                curl -sL https://raw.githubusercontent.com/MissChina/xui/master/install.sh | bash -s -- uninstall
                echo -e "${GREEN}xui 宸插嵏杞?{NC}"
            else
                echo -e "${BLUE}宸插彇娑堝嵏杞芥搷浣?{NC}"
            fi
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${RED}鏃犳晥鐨勯€夋嫨锛岃閲嶆柊杈撳叆${NC}"
            show_menu
            ;;
    esac
}

# 鍛戒护琛屽弬鏁板鐞?
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
