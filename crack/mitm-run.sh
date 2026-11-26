#!/usr/bin/env bash
# 电脑端一键起代理抓包。用法: bash crack/mitm-run.sh [端口]
set -euo pipefail

PORT="${1:-8080}"
mkdir -p capture
export MDV_LOG="capture/hosts.log"

IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1")

cat <<INFO
== 谜底黑胶抓包 ==
代理端口 : $PORT
本机地址 : $IP
日志文件 : $MDV_LOG

手机设置 :
  1. 同一 Wi-Fi → HTTP 代理 → 手动 → 服务器 $IP，端口 $PORT
  2. Safari 打开 http://mitm.it → 下载 iOS 证书 → 设置里安装描述文件
  3. 设置 → 通用 → 关于本机 → 证书信任设置 → 打开完全信任
  4. 打开谜底黑胶：停在 Pro 页 5 秒，再点“恢复购买”

按 Ctrl-C 结束。
INFO

mitmdump -p "$PORT" --set block_global=false -s crack/log_hosts.py
