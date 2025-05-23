#!/bin/bash

# 服务停止脚本
echo "正在停止服务..."
pm2 stop http-meta && pm2 stop sub-store

if [ $? -ne 0 ]; then
  echo "停止 sub-store 服务失败！"
  exit 1 # 退出脚本，表示失败
fi
echo "sub-store 服务停止成功。"

if [ $? -ne 0 ]; then
  echo "停止 http-meta 服务失败！"
  exit 1 # 退出脚本，表示失败
fi

echo "http-meta 服务停止成功。"
echo "服务停止完成。"