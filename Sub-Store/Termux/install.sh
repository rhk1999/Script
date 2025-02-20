#!/usr/bin/env zsh
set -e  # 遇到错误立即退出

# 安装必要软件包 (根据需要调整)
# sudo apt update
# sudo apt install -y unzip wget nodejs npm
# npm i -g pm2

# 创建安装目录
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 下载前端和后端
wget https://github.com/sub-store-org/Sub-Store/releases/latest/download/sub-store.bundle.js
wget https://github.com/sub-store-org/Sub-Store-Front-End/releases/latest/download/dist.zip
unzip dist.zip
mv dist "$FRONTEND_DIR"
rm dist.zip

# 下载 http-meta 和 Geo 数据文件
mkdir -p "$DATA_DIR"
wget https://github.com/xream/http-meta/releases/latest/download/http-meta.bundle.js -O "$DATA_DIR/http-meta.bundle.js" # 移动到 data 目录
wget https://github.com/xream/http-meta/releases/latest/download/tpl.yaml -O "$DATA_DIR/tpl.yaml"
wget https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb -O "$DATA_DIR/GeoLite2-Country.mmdb"
wget https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb -O "$DATA_DIR/GeoLite2-ASN.mmdb"

# 下载和解压 mihomo(http-meta)
version=$(wget -q -L --connect-timeout=5 --timeout=10 --tries=2 --waitretry=0 -O - 'https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/version.txt')
mihomo_url="https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/mihomo-android-arm64-v8-$version.gz"
wget -q -L --connect-timeout=5 --timeout=10 --tries=2 --waitretry=0 "$mihomo_url" -O "$DATA_DIR/http-meta.gz" # 下载 mihomo 到 data 目录，命名为 http-meta.gz
gunzip "$DATA_DIR/http-meta.gz" # 解压 http-meta.gz

# 启动 http-meta 和 Sub-Store (多行，更清晰)
echo "Starting http-meta..."
pm2 start "$DATA_DIR/http-meta.bundle.js" --name "http-meta"
echo "http-meta started in background"

echo "Starting Sub-Store..."
pm2 start sub-store.bundle.js --name "Sub-Store"
echo "Sub-Store started in background"

echo "Sub-Store and http-meta setup and started successfully!"

