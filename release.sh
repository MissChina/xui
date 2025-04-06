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

# 创建临时目录
TEMP_DIR=$(mktemp -d)
RELEASE_DIR="release"

# 清理函数
cleanup() {
    echo -e "${YELLOW}清理临时文件...${NC}"
    rm -rf "$TEMP_DIR"
    rm -rf "$RELEASE_DIR"
}

# 确保清理在脚本退出时执行
trap cleanup EXIT

# 创建发布目录
mkdir -p "$RELEASE_DIR"

# 支持的架构列表
ARCHS=("amd64" "arm64")

# 编译函数
build() {
    local arch=$1
    echo -e "${BLUE}开始编译 ${arch} 版本...${NC}"
    
    # 设置环境变量
    export GOOS=linux
    export GOARCH=$arch
    
    # 编译
    go build -o "$TEMP_DIR/x-ui" main.go
    
    # 复制必要文件
    cp -r bin "$TEMP_DIR/"
    cp install.sh "$TEMP_DIR/"
    cp x-ui.service "$TEMP_DIR/"
    cp x-ui.sh "$TEMP_DIR/"
    
    # 创建压缩包
    cd "$TEMP_DIR"
    tar czf "../$RELEASE_DIR/x-ui-linux-${arch}.tar.gz" *
    cd - > /dev/null
    
    echo -e "${GREEN}${arch} 版本编译完成${NC}"
}

# 检查 Go 环境
if ! command -v go &> /dev/null; then
    echo -e "${RED}错误：未找到 Go 环境，请先安装 Go${NC}"
    exit 1
fi

# 主循环
for arch in "${ARCHS[@]}"; do
    build "$arch"
done

echo -e "${GREEN}所有版本编译完成！${NC}"
echo -e "${BLUE}发布文件位于 $RELEASE_DIR 目录${NC}"
echo -e "${YELLOW}请将以下文件上传到 GitHub Releases：${NC}"
ls -lh "$RELEASE_DIR"/ 