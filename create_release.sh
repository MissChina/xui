#!/bin/bash

# 创建临时目录
mkdir -p temp_release/bin

# 复制关键文件
# xui主程序
cp xui temp_release/

# xray二进制文件
cp bin/xray-linux-amd64 temp_release/bin/
cp bin/xray-linux-arm64 temp_release/bin/

# GeoIP数据
cp bin/geoip.dat temp_release/bin/
cp bin/geosite.dat temp_release/bin/

# 脚本和配置文件
cp install.sh temp_release/
cp xui.service temp_release/
cp xui.sh temp_release/

# 确保使用LF换行符而不是CRLF
find temp_release -type f -name "*.sh" -exec dos2unix {} \;
dos2unix temp_release/xui.service

# 进入临时目录创建压缩包
cd temp_release
zip -r ../xui-linux-amd64.zip * -x "*.DS_Store" -x "*.git*"
cd ..

# 创建arm64版本
cp -r temp_release temp_release_arm64
rm temp_release_arm64/bin/xray-linux-amd64
mv temp_release_arm64/bin/xray-linux-arm64 temp_release_arm64/bin/xray-linux-arm64
cd temp_release_arm64
zip -r ../xui-linux-arm64.zip * -x "*.DS_Store" -x "*.git*"
cd ..

# 清理临时目录
rm -rf temp_release temp_release_arm64

echo "创建完成: xui-linux-amd64.zip 和 xui-linux-arm64.zip"
