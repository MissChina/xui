#!/bin/bash

# 瀹氫箟棰滆壊
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

# 鐗堟湰鍙?
VERSION="1.0.0"

# 妫€鏌ユ槸鍚︿负 root 鐢ㄦ埛
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}閿欒: 姝よ剼鏈繀椤讳互 root 韬唤杩愯锛?{PLAIN}"
        exit 1
    fi
}

# 妫€鏌ョ郴缁熸灦鏋?
check_arch() {
    ARCH=$(uname -m)
    if [[ $ARCH == "x86_64" || $ARCH == "x64" || $ARCH == "amd64" ]]; then
        ARCH="amd64"
    elif [[ $ARCH == "aarch64" || $ARCH == "arm64" ]]; then
        ARCH="arm64"
    else
        echo -e "${RED}涓嶆敮鎸佺殑鏋舵瀯: $ARCH${PLAIN}"
        exit 1
    fi
}

# 妫€鏌ョ郴缁?
check_system() {
    if [[ -f /etc/redhat-release ]]; then
        SYSTEM="centos"
    elif [[ -f /etc/debian_version ]]; then
        SYSTEM="debian"
    else
        echo -e "${RED}涓嶆敮鎸佺殑绯荤粺锛?{PLAIN}"
        exit 1
    fi
}

# 瀹夎渚濊禆
install_dependencies() {
    echo -e "${GREEN}瀹夎渚濊禆鍖?..${PLAIN}"
    
    if [[ $SYSTEM == "centos" ]]; then
        yum update -y
        yum install -y wget curl unzip tar gzip
    else
        apt update -y
        apt install -y wget curl unzip tar gzip
    fi
    
    echo -e "${GREEN}渚濊禆鍖呭畨瑁呭畬鎴?{PLAIN}"
}

# 涓嬭浇鏂囦欢
download_file() {
    local url=$1
    local output=$2
    local max_retries=3
    local retry_count=1
    
    while [[ $retry_count -le $max_retries ]]; do
        echo -e "${GREEN}灏濊瘯涓嬭浇 (绗?$retry_count 娆?...${PLAIN}"
        wget --no-check-certificate --timeout=15 --tries=3 -O "$output" "$url"
        
        if [[ $? -eq 0 ]]; then
            return 0
        fi
        
        echo -e "${YELLOW}涓嬭浇澶辫触锛岀瓑寰?5 绉掑悗閲嶈瘯...${PLAIN}"
        sleep 5
        retry_count=$((retry_count + 1))
    done
    
    return 1
}

# 瀹夎 xui
install_x_ui() {
    # 鍋滄宸插瓨鍦ㄧ殑鏈嶅姟
    systemctl stop xui 2>/dev/null
    
    # 閰嶇疆涓嬭浇URL - 鐩存帴浠庝唬鐮佷粨搴撶殑release鐩綍鑾峰彇
    GITHUB_URL="https://raw.githubusercontent.com/MissChina/xui/main/release"
    local DOWNLOAD_URL="${GITHUB_URL}/xui-linux-${ARCH}.tar.gz"
    
    echo -e "${GREEN}涓嬭浇 xui v${VERSION} (${ARCH})...${PLAIN}"
    echo -e "${GREEN}涓嬭浇閾炬帴: ${DOWNLOAD_URL}${PLAIN}"
    
    # 灏濊瘯涓嬭浇tar.gz鏂囦欢
    if ! download_file "$DOWNLOAD_URL" "/usr/local/xui-linux-${ARCH}.tar.gz"; then
        echo -e "${YELLOW}tar.gz涓嬭浇澶辫触锛屽皾璇曚笅杞絲ip鏂囦欢...${PLAIN}"
        DOWNLOAD_URL="${GITHUB_URL}/xui-linux-${ARCH}.zip"
        
        if ! download_file "$DOWNLOAD_URL" "/usr/local/xui-linux-${ARCH}.zip"; then
            echo -e "${RED}涓嬭浇 xui 澶辫触锛岃妫€鏌ヤ綘鐨勭綉缁滆繛鎺?{PLAIN}"
            echo -e "${YELLOW}鎻愮ず锛氬鏋滀娇鐢ㄤ唬鐞嗭紝璇风‘淇濅唬鐞嗚缃纭?{PLAIN}"
            exit 1
        fi
    fi
    
    # 鍑嗗瀹夎
    rm -rf /usr/local/xui
    mkdir -p /usr/local/xui
    
    # 瑙ｅ帇
    echo -e "${GREEN}瑙ｅ帇瀹夎鍖?..${PLAIN}"
    
    # 妫€鏌ヤ笅杞界殑鏄痶ar.gz杩樻槸zip鏂囦欢
    if [[ -f "/usr/local/xui-linux-${ARCH}.tar.gz" ]]; then
        # 瑙ｅ帇tar.gz鏂囦欢
        tar -xzf "/usr/local/xui-linux-${ARCH}.tar.gz" -C /usr/local
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}瑙ｅ帇 xui 澶辫触锛岃妫€鏌ョ鐩樼┖闂村拰鏉冮檺${PLAIN}"
            rm -f "/usr/local/xui-linux-${ARCH}.tar.gz"
            exit 1
        fi
        # 娓呯悊
        rm -f "/usr/local/xui-linux-${ARCH}.tar.gz"
    else
        # 鍒涘缓涓存椂鐩綍
        local temp_dir="/tmp/xui-extract-$$"
        rm -rf "$temp_dir"
        mkdir -p "$temp_dir"
        
        # 瑙ｅ帇zip鏂囦欢鍒颁复鏃剁洰褰?
        echo -e "${YELLOW}瑙ｅ帇鍒颁复鏃剁洰褰?..${PLAIN}"
        unzip -o "/usr/local/xui-linux-${ARCH}.zip" -d "$temp_dir"
        
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}瑙ｅ帇 xui 澶辫触锛岃妫€鏌ョ鐩樼┖闂村拰鏉冮檺${PLAIN}"
            rm -rf "$temp_dir"
            rm -f "/usr/local/xui-linux-${ARCH}.zip"
            exit 1
        fi
        
        # 鍒涘缓鐩爣鐩綍缁撴瀯
        mkdir -p /usr/local/xui/bin
        
        # 澶嶅埗鏂囦欢锛屽鐞嗗彲鑳界殑璺緞鍒嗛殧绗﹂棶棰?
        echo -e "${YELLOW}澶嶅埗鏂囦欢...${PLAIN}"
        
        # 浣跨敤find鍛戒护鏌ユ壘骞跺鍒舵枃浠讹紝閬垮厤璺緞鍒嗛殧绗﹂棶棰?
        find "$temp_dir" -type f -name "xui" -exec cp {} /usr/local/xui/ \;
        find "$temp_dir" -type f -name "*.sh" -exec cp {} /usr/local/xui/ \;
        find "$temp_dir" -type f -name "xui.service" -exec cp {} /usr/local/xui/ \;
        find "$temp_dir" -type f -name "geoip.dat" -exec cp {} /usr/local/xui/bin/ \;
        find "$temp_dir" -type f -name "geosite.dat" -exec cp {} /usr/local/xui/bin/ \;
        find "$temp_dir" -type f -name "xray-linux-${ARCH}" -exec cp {} /usr/local/xui/bin/ \;
        
        # 娓呯悊涓存椂鐩綍鍜寊ip鏂囦欢
        rm -rf "$temp_dir"
        rm -f "/usr/local/xui-linux-${ARCH}.zip"
    fi
    
    # 璁剧疆鏉冮檺
    chmod +x /usr/local/xui/xui
    chmod +x /usr/local/xui/bin/* 2>/dev/null
    chmod +x /usr/local/xui/*.sh 2>/dev/null
    
    # 鍒涘缓杞摼鎺?
    ln -sf /usr/local/xui/xui.sh /usr/bin/xui
    
    # 瀹夎鏈嶅姟
    cp -f /usr/local/xui/xui.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable xui
    systemctl start xui
    
    echo -e "${GREEN}xui v${VERSION} 瀹夎鎴愬姛锛?{PLAIN}"
    echo -e ""
    
    # 鑾峰彇鐪熷疄IP鐢ㄤ簬闈㈡澘璁块棶
    IP=$(curl -s4 ifconfig.me || curl -s6 ifconfig.me)
    if [[ -z "$IP" ]]; then
        IP=$(ip -4 addr | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | head -n 1)
    fi
    if [[ -z "$IP" ]]; then
        IP=$(hostname -I | awk '{print $1}')
    fi
    
    # 妫€鏌ユ槸鍚︽垚鍔熻幏鍙栧埌IP
    if [[ -z "$IP" ]]; then
        IP="鎮ㄧ殑鏈嶅姟鍣↖P"
    fi
    
    echo -e "闈㈡澘璁块棶鍦板潃: ${GREEN}http://${IP}:54321${PLAIN}"
    echo -e "鐢ㄦ埛鍚? ${GREEN}admin${PLAIN}"
    echo -e "瀵嗙爜: ${GREEN}admin${PLAIN}"
    echo -e ""
    echo -e "xui 绠＄悊鍛戒护: ${GREEN}xui${PLAIN}"
}

# 鍗歌浇 xui
uninstall_x_ui() {
    echo -e "${YELLOW}纭畾鍗歌浇 xui 鍚楋紵(y/n)${PLAIN}"
    read -p "(榛樿: n): " CONFIRM
    if [[ $CONFIRM != "y" ]]; then
        echo -e "${GREEN}宸插彇娑?{PLAIN}"
        return
    fi
    
    systemctl stop xui
    systemctl disable xui
    rm -rf /usr/local/xui
    rm -f /usr/bin/xui
    rm -f /etc/systemd/system/xui.service
    systemctl daemon-reload
    
    echo -e "${GREEN}xui 鍗歌浇鎴愬姛${PLAIN}"
}

# 鏄剧ず浣跨敤璇存槑
show_usage() {
    echo -e "${GREEN}xui 绠＄悊鑴氭湰${PLAIN}"
    echo -e "浣跨敤鏂规硶: ${GREEN}bash install.sh [閫夐」]${PLAIN}"
    echo -e "閫夐」:"
    echo -e "  install   - 瀹夎 xui"
    echo -e "  uninstall - 鍗歌浇 xui"
    echo -e "  help      - 鏄剧ず姝ゅ府鍔╀俊鎭?
}

# 鏄剧ず鑿滃崟
show_menu() {
    echo -e "${GREEN}xui 瀹夎绠＄悊鑴氭湰${PLAIN}"
    echo -e ""
    echo -e "${GREEN}1.${PLAIN} 瀹夎 xui"
    echo -e "${GREEN}2.${PLAIN} 鍗歌浇 xui"
    echo -e "${GREEN}0.${PLAIN} 閫€鍑?
    read -p "璇疯緭鍏ラ€夐」 [0-2]: " OPTION
    
    case $OPTION in
        0) exit 0 ;;
        1) check_root && check_arch && check_system && install_dependencies && install_x_ui ;;
        2) check_root && uninstall_x_ui ;;
        *) echo -e "${RED}鏃犳晥鐨勯€夐」${PLAIN}" ;;
    esac
}

# 涓诲嚱鏁?
main() {
    if [[ $# -gt 0 ]]; then
        case $1 in
            install) check_root && check_arch && check_system && install_dependencies && install_x_ui ;;
            uninstall) check_root && uninstall_x_ui ;;
            help) show_usage ;;
            *) show_usage ;;
        esac
    else
        show_menu
    fi
}

# 鎵ц涓诲嚱鏁?
main "$@"
