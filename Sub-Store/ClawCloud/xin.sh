#!/bin/bash

# 添加日志功能
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 错误处理函数
handle_error() {
  log "错误发生在第 $1 行: $2"
  exit 1
}
trap 'handle_error $LINENO "$BASH_COMMAND"' ERR
set -e  # 遇到错误立即退出

# 检查必要工具
check_dependencies() {
  local deps=("wget" "unzip" "npm" "pm2")
  for dep in "${deps[@]}"; do
    if ! command -v $dep &> /dev/null; then
      log "缺少依赖: $dep"
      return 1
    fi
  done
  return 0
}

# 下载函数，带重试机制
download_with_retry() {
  local url="$1"
  local output="$2"
  local max_attempts=3
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    log "下载 $output (尝试 $attempt/$max_attempts)"
    if wget -q --show-progress "$url" -O "$output"; then
      log "下载成功: $output"
      return 0
    fi
    
    log "下载失败，等待重试..."
    sleep 2
    attempt=$((attempt + 1))
  done
  
  log "下载失败: $url"
  return 1
}

# 主程序开始
log "开始安装 sub-store..."

# 检查依赖
if ! check_dependencies; then
  log "请安装缺少的依赖后重试"
  log "可以使用以下命令安装：sudo apt update && sudo apt install -y unzip wget nodejs npm && npm i -g pm2"
  exit 1
fi

# 检查是否已安装
if [ -d "$HOME/sub-store" ] && [ -f "$HOME/sub-store/sub-store.bundle.js" ]; then
  read -p "检测到已存在安装，是否继续? (y/n): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    exit 0
  fi
fi

# 设置环境变量
log "配置环境变量..."
grep -q "INSTALL_DIR=\"\$HOME/sub-store\"" ~/.zsh_env || {
  echo '# 基本文件夹变量' >> ~/.zsh_env
  echo 'export INSTALL_DIR="$HOME/sub-store"' >> ~/.zsh_env
  echo 'export DATA_DIR="$INSTALL_DIR/data"' >> ~/.zsh_env
  echo 'export FRONTEND_DIR="$INSTALL_DIR/frontend"' >> ~/.zsh_env

  echo '# http-meta变量' >> ~/.zsh_env
  echo 'export META_FOLDER="$DATA_DIR"' >> ~/.zsh_env
  echo 'export HOST=::' >> ~/.zsh_env
  echo 'export PORT=9876' >> ~/.zsh_env

  echo '# sub-store变量' >> ~/.zsh_env
  echo 'export SUB_STORE_FRONTEND_PATH="$FRONTEND_DIR"' >> ~/.zsh_env
  echo 'export SUB_STORE_MMDB_COUNTRY_PATH="$DATA_DIR/GeoLite2-Country.mmdb"' >> ~/.zsh_env
  echo 'export SUB_STORE_MMDB_ASN_PATH="$DATA_DIR/GeoLite2-ASN.mmdb"' >> ~/.zsh_env
  echo 'export SUB_STORE_BACKEND_PREFIX=true' >> ~/.zsh_env
  echo 'export SUB_STORE_FRONTEND_BACKEND_PATH=/rainyhush' >> ~/.zsh_env
  echo 'export SUB_STORE_BACKEND_API_PORT=19993' >> ~/.zsh_env
  echo 'export SUB_STORE_FRONTEND_PORT=19992' >> ~/.zsh_env
}

# 加载环境变量
. ~/.zsh_env

# 创建安装目录
log "创建安装目录..."
mkdir -p "$INSTALL_DIR" "$DATA_DIR" "$FRONTEND_DIR"
cd "$INSTALL_DIR"

# 下载前端和后端
log "下载 sub-store 后端..."
download_with_retry "https://github.com/sub-store-org/Sub-Store/releases/latest/download/sub-store.bundle.js" "sub-store.bundle.js"

log "下载 sub-store 前端..."
download_with_retry "https://github.com/sub-store-org/Sub-Store-Front-End/releases/latest/download/dist.zip" "dist.zip"
unzip -o dist.zip
if [ -d "dist" ]; then
  rm -rf "$FRONTEND_DIR"
  mv dist "$FRONTEND_DIR"
  rm -f dist.zip
  log "前端解压完成"
else
  log "前端解压失败"
  exit 1
fi

# 下载 http-meta 和 Geo 数据文件
log "下载 http-meta..."
download_with_retry "https://github.com/xream/http-meta/releases/latest/download/http-meta.bundle.js" "$DATA_DIR/http-meta.bundle.js"
download_with_retry "https://github.com/xream/http-meta/releases/latest/download/tpl.yaml" "$DATA_DIR/tpl.yaml"

log "下载 GeoLite2 数据库..."
download_with_retry "https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb" "$DATA_DIR/GeoLite2-Country.mmdb"
download_with_retry "https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb" "$DATA_DIR/GeoLite2-ASN.mmdb"

# 下载和解压 mihomo(http-meta)
log "获取最新 mihomo 版本..."
version=$(wget -q -L --connect-timeout=5 --timeout=10 --tries=2 --waitretry=0 -O - 'https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/version.txt')
if [ -z "$version" ]; then
  log "获取版本信息失败，使用默认版本"
  version="v1.18.0"
fi

arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64-compatible/)
log "检测到架构: $arch, 版本: $version"

mihomo_url="https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/mihomo-linux-$arch-$version.gz"
log "下载 mihomo..."
download_with_retry "$mihomo_url" "$DATA_DIR/http-meta.gz"

log "解压 mihomo..."
gunzip -f "$DATA_DIR/http-meta.gz"
chmod +x "$DATA_DIR/http-meta"

# 启动服务
log "启动 http-meta 服务..."
pm2 delete http-meta 2>/dev/null || true
pm2 start "$DATA_DIR/http-meta.bundle.js" --name "http-meta"

log "启动 sub-store 服务..."
pm2 delete Sub-Store 2>/dev/null || true
pm2 start sub-store.bundle.js --name "sub-store"

# 检查服务
sleep 3
if pm2 list | grep -q "http-meta.*online" && pm2 list | grep -q "sub-store.*online"; then
  log "服务启动成功!"
  
  # 显示访问信息
  #ipv4_address=$(curl 4.icanhazip.com 2>/dev/null)
  log "sub-store 已成功安装"
  #log "- 本地访问: http://127.0.0.1:19992"
  #log "- 网络访问: http://${ipv4_address}:19992"
else
  log "服务启动异常，请检查日志:"
  log "- 查看日志: pm2 logs"
fi

log "安装完成!"