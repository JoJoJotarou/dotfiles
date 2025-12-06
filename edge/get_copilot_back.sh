#!/bin/bash

# 找回 Edge 边栏中消失的 Copilot 图标（2025年11月）https://www.bilibili.com/opus/1130656411342077990

# 检查 Microsoft Edge 是否正在运行
if pgrep -x "Microsoft Edge" > /dev/null; then
  echo "请完全关闭 Microsoft Edge 后再运行此脚本。"
  exit 1
fi

# 定义 Local State 文件路径
LOCAL_STATE="$HOME/Library/Application Support/Microsoft Edge/Local State"

# 检查文件是否存在
if [ ! -f "$LOCAL_STATE" ]; then
  echo "未找到 Local State 文件：$LOCAL_STATE"
  exit 1
fi

# 使用 jq 修改 variations_country 为 US
if command -v jq >/dev/null 2>&1; then
  # 创建备份
  cp "$LOCAL_STATE" "$LOCAL_STATE.bak"

  # 修改 JSON 内容
  jq '.variations_country = "US"' "$LOCAL_STATE.bak" > "$LOCAL_STATE"

  echo "已将 variations_country 设置为 US。"
else
  echo "请先安装 jq 工具：brew install jq"
  exit 1
fi
