#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 版本设置
VERSION="1.0.0"
echo -e "${BLUE}构建 xui v${VERSION}${NC}"

# 创建发布目录
RELEASE_DIR="release"
mkdir -p "$RELEASE_DIR"
echo -e "${GREEN}创建发布目录: $RELEASE_DIR${NC}"

# 支持的架构
ARCHS=("amd64" "arm64")

# 构建函数
build_xui() {
    local arch=$1
    
    echo -e "${BLUE}构建 ${arch} 版本...${NC}"
    
    # 创建临时构建目录
    local temp_dir="temp-$arch"
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir/bin"
    
    # 设置 Go 环境变量
    export GOOS=linux
    export GOARCH=$arch
    
    # 编译主程序
    echo -e "${YELLOW}编译主程序...${NC}"
    go build -o "$temp_dir/xui" main.go
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}构建失败!${NC}"
        exit 1
    fi
    
    # 复制文件 - 使用前斜杠作为路径分隔符
    echo -e "${YELLOW}复制文件...${NC}"
    
    # 复制 Xray 二进制文件
    if [ -f "bin/xray-linux-${arch}" ]; then
        cp "bin/xray-linux-${arch}" "$temp_dir/bin/"
    else
        echo -e "${RED}警告: bin/xray-linux-${arch} 未找到${NC}"
    fi
    
    # 复制 GeoIP 数据
    cp -f "bin/geoip.dat" "$temp_dir/bin/" 2>/dev/null || echo -e "${RED}警告: bin/geoip.dat 未找到${NC}"
    cp -f "bin/geosite.dat" "$temp_dir/bin/" 2>/dev/null || echo -e "${RED}警告: bin/geosite.dat 未找到${NC}"
    
    # 复制脚本和配置文件
    cp -f "install.sh" "$temp_dir/" 2>/dev/null || echo -e "${RED}警告: install.sh 未找到${NC}"
    cp -f "xui.service" "$temp_dir/" 2>/dev/null || echo -e "${RED}警告: xui.service 未找到${NC}"
    cp -f "xui.sh" "$temp_dir/" 2>/dev/null || echo -e "${RED}警告: xui.sh 未找到${NC}"
    
    # 设置权限
    chmod +x "$temp_dir/xui"
    chmod +x "$temp_dir/"*.sh 2>/dev/null
    chmod +x "$temp_dir/bin/"* 2>/dev/null
    
    # 确保所有文本文件使用 Unix 风格的行结束符
    find "$temp_dir" -type f -name "*.sh" -o -name "*.service" | xargs -r dos2unix -q 2>/dev/null
    
    # 创建 tar.gz 包
    echo -e "${YELLOW}创建 tar.gz 包...${NC}"
    tar -czf "$RELEASE_DIR/xui-linux-${arch}.tar.gz" -C "$temp_dir" .
    
    # 创建 zip 包
    echo -e "${YELLOW}创建 zip 包...${NC}"
    if command -v zip &> /dev/null; then
        # 进入临时目录创建 zip
        (cd "$temp_dir" && zip -r "../$RELEASE_DIR/xui-linux-${arch}.zip" .)
    else
        echo -e "${RED}警告: zip 命令未找到，跳过创建 zip 包${NC}"
    fi
    
    # 验证 tar.gz 包
    tar -tf "$RELEASE_DIR/xui-linux-${arch}.tar.gz" > /dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}tar.gz 包验证成功${NC}"
    else
        echo -e "${RED}tar.gz 包验证失败${NC}"
    fi
    
    # 如果存在 zip 包，验证它
    if [ -f "$RELEASE_DIR/xui-linux-${arch}.zip" ]; then
        if command -v unzip &> /dev/null; then
            echo -e "${YELLOW}验证 zip 包中的路径分隔符...${NC}"
            unzip -l "$RELEASE_DIR/xui-linux-${arch}.zip" | grep -q "\\"
            if [ $? -eq 0 ]; then
                echo -e "${RED}警告: zip 包中检测到反斜杠!${NC}"
            else
                echo -e "${GREEN}zip 包验证成功 - 未检测到反斜杠${NC}"
            fi
        else
            echo -e "${RED}警告: unzip 命令未找到，无法验证 zip 包${NC}"
        fi
    fi
    
    # 清理
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}${arch} 版本打包完成${NC}"
}

# 检查 Go 环境
if ! command -v go &> /dev/null; then
    echo -e "${RED}错误: 未找到 Go 环境. 请先安装 Go.${NC}"
    exit 1
fi

# 检查 dos2unix
if ! command -v dos2unix &> /dev/null; then
    echo -e "${YELLOW}警告: 未找到 dos2unix, 将尝试不进行行结束符转换${NC}"
fi

# 构建每种架构
for arch in "${ARCHS[@]}"; do
    build_xui "$arch"
done

# 显示发布信息
echo -e "${GREEN}所有版本编译完成!${NC}"
echo -e "${BLUE}发布文件位于 $RELEASE_DIR 目录${NC}"
echo -e "${YELLOW}生成的文件:${NC}"
ls -lh "$RELEASE_DIR" 