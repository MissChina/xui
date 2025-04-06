#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# 检查是否为 root 用户
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用 root 用户运行此脚本！\n" && exit 1

# 系统架构检测
arch=$(arch)
if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
else
    echo -e "${red}不支持的系统架构: ${arch}${plain}"
    exit 1
fi

echo "架构: ${arch}"

# 检查系统
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}未检测到系统版本，请联系作者！${plain}\n" && exit 1
fi

echo "系统: ${release}"

# 检查处理器数量
if [ $(grep -c "processor" /proc/cpuinfo) -le 2 ]; then
    echo -e "${yellow}警告：检测到系统处理器数量小于或等于2，建议使用2核以上服务器运行XUI${plain}"
    sleep 2
fi

# 检测最新版本
get_latest_version() {
    latest_version=$(curl -Ls "https://api.github.com/repos/MissChina/xui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ -z "$latest_version" ]]; then
        latest_version="2.0"
    fi
    echo "$latest_version"
}

version=$(get_latest_version)
echo "检测到最新版本：${version}"

# 安装基本依赖
install_base() {
    echo -e "${green}安装依赖包...${plain}"
    if [[ $release == "centos" ]]; then
        yum update -y
        yum install wget curl unzip tar -y
    else
        apt update -y
        apt install wget curl unzip tar -y
    fi
    echo -e "${green}依赖包安装完成${plain}"
}

# 下载XUI
download_xui() {
    local filename="xui-linux-${arch}.zip"
    local xui_dir="/usr/local/xui"
    local tmp_dir="/usr/local"
    local download_url="https://github.com/MissChina/xui/releases/download/${version}/${filename}"
    
    if [ -f "${tmp_dir}/${filename}" ]; then
        rm -rf "${tmp_dir}/${filename}"
    fi
    
    # 清理旧目录，确保干净安装
    if [ -d "${xui_dir}" ]; then
        rm -rf "${xui_dir}"
    fi
    
    mkdir -p "${xui_dir}"
    
    echo -e "${green}下载 xui v${version} (${arch})...${plain}"
    echo -e "下载链接: ${download_url}"
    
    wget -O "${tmp_dir}/${filename}" "${download_url}"
    if [ $? -ne 0 ]; then
        echo -e "${red}下载 xui 失败，请确保你的服务器能够下载 Github 的文件${plain}"
        exit 1
    fi
    
    cd "${tmp_dir}"
    
    # 改进解压过程，增加错误处理和详细输出
    echo -e "${green}正在解压文件...${plain}"
    unzip -o "${filename}" -d "${xui_dir}"
    
    # 检查解压结果
    if [ $? -ne 0 ]; then
        echo -e "${red}解压 xui 失败！尝试使用替代方法...${plain}"
        # 尝试使用替代解压方法
        mkdir -p "${xui_dir}/temp"
        unzip -o "${filename}" -d "${xui_dir}/temp"
        
        if [ $? -ne 0 ]; then
            echo -e "${red}解压仍然失败，请检查磁盘空间和权限${plain}"
            exit 1
        else
            # 手动移动文件
            mv "${xui_dir}/temp"/* "${xui_dir}/"
            rm -rf "${xui_dir}/temp"
        fi
    fi
    
    # 确认关键文件存在
    if [ ! -f "${xui_dir}/xui" ]; then
        echo -e "${red}安装失败，未找到关键文件！请检查下载的压缩包是否正确${plain}"
        exit 1
    fi
    
    # 设置权限
    echo -e "${green}设置文件权限...${plain}"
    chmod +x "${xui_dir}/xui" "${xui_dir}/xui.sh"
    
    # 处理xray可执行文件
    if [ -f "${xui_dir}/bin/xray-linux-${arch}" ]; then
        chmod +x "${xui_dir}/bin/xray-linux-${arch}"
    fi
    
    # 创建服务
    echo -e "${green}创建系统服务...${plain}"
    if [ -f "${xui_dir}/xui.service" ]; then
        cp "${xui_dir}/xui.service" /etc/systemd/system/
        chmod 644 /etc/systemd/system/xui.service
    else
        # 如果服务文件不存在，则创建一个
        cat > /etc/systemd/system/xui.service << EOF
[Unit]
Description=XUI Panel
After=network.target

[Service]
Type=simple
WorkingDirectory=/usr/local/xui
ExecStart=/usr/local/xui/xui
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF
        chmod 644 /etc/systemd/system/xui.service
    fi
    
    systemctl daemon-reload
    systemctl enable xui
    
    echo -e "${green}xui v${version} 安装完成，已设置开机自启${plain}"
    echo -e "${yellow}请使用 systemctl start xui 启动服务${plain}"
    echo -e "${yellow}面板默认访问地址为 http://服务器IP:9999${plain}"
}

# 卸载XUI
uninstall_xui() {
    systemctl stop xui
    systemctl disable xui
    rm -rf /etc/systemd/system/xui.service
    rm -rf /usr/local/xui
    systemctl daemon-reload
    echo -e "${green}卸载成功${plain}"
}

# 显示菜单
show_menu() {
    echo -e "xui 安装管理脚本\n"
    echo -e "1. ${green}安装 xui${plain}"
    echo -e "2. ${yellow}卸载 xui${plain}"
    echo -e "0. ${plain}退出\n"
}

# 主逻辑
show_menu
read -p "请输入选项 [0-2]: " option
case "${option}" in
    1)
        install_base
        download_xui
        ;;
    2)
        uninstall_xui
        ;;
    0)
        exit 0
        ;;
    *)
        echo -e "${red}请输入正确的选项 [0-2]${plain}"
        exit 1
        ;;
esac
