#!/bin/bash
set -e # 脚本遇到错误立即退出

pm2 stop Sub-Store && pm2 stop http-meta

# --- 定义下载链接 ---
SUB_STORE_BUNDLE_URL="https://github.com/sub-store-org/Sub-Store/releases/latest/download/sub-store.bundle.js"
SUB_STORE_FRONTEND_ZIP_URL="https://github.com/sub-store-org/Sub-Store-Front-End/releases/latest/download/dist.zip"
HTTP_META_BUNDLE_URL="https://github.com/xream/http-meta/releases/latest/download/http-meta.bundle.js"
HTTP_META_TPL_URL="https://github.com/xream/http-meta/releases/latest/download/tpl.yaml"
GEOLITE_COUNTRY_URL="https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb"
GEOLITE_ASN_URL="https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb"
MIHOMO_VERSION_URL="https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/version.txt"
MIHOMO_BASE_URL="https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha"


# --- 更新函数 ---
update_file() {
  local url="$1"
  local destination="$2"
  echo "正在更新: $destination ..."
  wget -q -L --connect-timeout=10 --timeout=20 --tries=3 --waitretry=5 "$url" -O "$destination"
  if [ $? -ne 0 ]; then
    echo "更新 $destination 失败！"
    return 1 # 返回非零状态码表示失败
  fi
  echo "更新 $destination 完成。"
  return 0 # 返回零状态码表示成功
}

update_mihomo() {
  echo "正在更新 mihomo..."
  local version=$(wget -q -L --connect-timeout=5 --timeout=10 --tries=2 --waitretry=0 -O - "$MIHOMO_VERSION_URL")
  if [ $? -ne 0 ]; then
    echo "获取 mihomo 版本信息失败！"
    return 1
  fi
  local arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64-compatible/)
  local mihomo_url="$MIHOMO_BASE_URL/mihomo-linux-$arch-$version.gz"
  local destination="$DATA_DIR/http-meta.gz"
  wget -q -L --connect-timeout=10 --timeout=20 --tries=3 --waitretry=5 "$mihomo_url" -O "$destination"
  if [ $? -ne 0 ]; then
    echo "下载 mihomo 失败！"
    return 1
  fi
  gunzip -f "$destination"
  rm -f "$destination" # 删除压缩包
  echo "更新 mihomo 完成。"
  return 0
}


update_frontend() {
  echo "正在更新前端..."
  local zip_file="$INSTALL_DIR/dist.zip"
  local temp_dist_dir="$INSTALL_DIR/dist" # 临时 dist 目录

  update_file "$SUB_STORE_FRONTEND_ZIP_URL" "$zip_file"
  if [ $? -ne 0 ]; then
    echo "更新前端 ZIP 文件失败！"
    return 1
  fi

  rm -rf "$FRONTEND_DIR" # 删除旧前端目录
  mkdir -p "$INSTALL_DIR" # 确保 $INSTALL_DIR 存在，如果之前frontend是唯一子目录，可能需要重建
  unzip -o "$zip_file" -d "$INSTALL_DIR" # 解压到 $INSTALL_DIR，会在 $INSTALL_DIR 下创建 dist 文件夹

  # 检查 dist 文件夹是否存在，避免出错
  if [ -d "$temp_dist_dir" ]; then
    mv "$temp_dist_dir" "$FRONTEND_DIR" # 将 dist 文件夹重命名为 frontend
  else
    echo "警告：dist.zip 解压后未找到 dist 文件夹，可能 zip 文件结构不符合预期。"
    # 可以选择是否返回错误，这里选择继续，但可能前端更新不完整
    # return 1
  fi

  rm -f "$zip_file" # 删除 ZIP 文件
  echo "更新前端完成。"
  return 0
}


# --- 执行更新 ---
echo "--- 开始更新 Sub-Store ---"

update_file "$SUB_STORE_BUNDLE_URL" "$INSTALL_DIR/sub-store.bundle.js"
update_frontend
update_file "$HTTP_META_BUNDLE_URL" "$DATA_DIR/http-meta.bundle.js"
update_file "$HTTP_META_TPL_URL" "$DATA_DIR/tpl.yaml"
update_file "$GEOLITE_COUNTRY_URL" "$DATA_DIR/GeoLite2-Country.mmdb"
update_file "$GEOLITE_ASN_URL" "$DATA_DIR/GeoLite2-ASN.mmdb"
update_mihomo


echo "Starting http-meta..."
pm2 start "$DATA_DIR/http-meta.bundle.js" --name "http-meta"
echo "http-meta started successfully!"

echo "Starting Sub-Store..."
pm2 start "$INSTALL_DIR/sub-store.bundle.js" --name "Sub-Store"
echo "Sub-Store started successfully!"

echo "Sub-Store and http-meta started successfully!"
