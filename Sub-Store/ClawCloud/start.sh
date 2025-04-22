#!/bin/bash
# 服务启动脚本
echo "正在启动服务..."
pm2 start "$DATA_DIR/http-meta.bundle.js" --name "http-meta"
if [ $? -ne 0 ]; then
  echo "启动 http-meta 服务失败！"
  exit 1 # 退出脚本，表示失败
fi
echo "http-meta 服务启动成功。"

pm2 start "$INSTALL_DIR/sub-store.bundle.js" --name "Sub-Store"
if [ $? -ne 0 ]; then
  echo "启动 Sub-Store 服务失败！"
  exit 1 # 退出脚本，表示失败
fi

echo "Sub-Store 服务启动成功。"
echo "服务启动完成。"
exit 0 # 脚本执行成功退出