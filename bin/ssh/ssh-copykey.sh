#!/bin/bash

# 用法: ./addkey.sh username@ip[:port]

if [ -z "$1" ]; then
  echo "用法: $0 username@ip[:port]"
  exit 1
fi

target="$1"

# 解析 target
user_host=$(echo "$target" | cut -d: -f1)
port=$(echo "$target" | cut -s -d: -f2)

if [ -z "$port" ]; then
  port=22
fi

# 检查并生成 SSH key
if [ ! -f ~/.ssh/id_rsa ]; then
  echo "🔑 本地没有 id_rsa，正在生成..."
  ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname)" -N "" -f ~/.ssh/id_rsa
  echo "✅ 密钥生成完成: ~/.ssh/id_rsa ~/.ssh/id_rsa.pub"
fi

pubkey=$(cat ~/.ssh/id_rsa.pub)

echo "👉 正在将公钥上传到 $user_host (端口 $port)"

ssh -p "$port" "$user_host" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && \
  grep -qxF '$pubkey' ~/.ssh/authorized_keys || \
  echo '$pubkey' >> ~/.ssh/authorized_keys && \
  chmod 600 ~/.ssh/authorized_keys"

if [ $? -eq 0 ]; then
  echo "✅ 公钥已上传，可以尝试免密登录：ssh -p $port $user_host"
else
  echo "❌ 上传失败，请检查目标服务器是否允许 SSH 登录"
fi

