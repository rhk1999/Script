#!/bin/bash
set -e  # 遇到错误立即退出

# 安装必要软件包 (根据需要调整)
# sudo apt update
# sudo apt install -y unzip wget nodejs npm
# npm i -g pm2

echo '# 基本文件夹变量' >> ~/.bashrc
echo 'export INSTALL_DIR="$HOME/Sub-Store"' >> ~/.bashrc
echo 'export DATA_DIR="$INSTALL_DIR/data"' >> ~/.bashrc
echo 'export FRONTEND_DIR="$INSTALL_DIR/frontend"' >> ~/.bashrc

echo '# http-meta变量' >> ~/.bashrc
echo 'export META_FOLDER="$DATA_DIR"' >> ~/.bashrc
echo 'export HOST=::' >> ~/.bashrc
echo 'export PORT=9876' >> ~/.bashrc

echo '# Sub-Store变量' >> ~/.bashrc
echo 'export SUB_STORE_FRONTEND_PATH="$FRONTEND_DIR"' >> ~/.bashrc
echo 'export SUB_STORE_MMDB_COUNTRY_PATH="$DATA_DIR/GeoLite2-Country.mmdb"' >> ~/.bashrc
echo 'export SUB_STORE_MMDB_ASN_PATH="$DATA_DIR/GeoLite2-ASN.mmdb"' >> ~/.bashrc

. ~/.bashrc

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
arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64-compatible/)
mihomo_url="https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/mihomo-linux-$arch-$version.gz"
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



