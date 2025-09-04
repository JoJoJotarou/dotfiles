#!/bin/bash

# 安装 kubectl
# 使用 阿里云 APT 源（kubectl版本不是最新的）

set -e

CONFIG_PATH="$HOME/.kube"
APT_LIST="/etc/apt/sources.list.d/kubernetes.list"
KEYRING="/etc/apt/keyrings/kubernetes-apt-keyring.gpg"

function install_kubectl() {
  echo "🔐 添加 Kubernetes GPG 密钥..."
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | \
    sudo gpg --dearmor | sudo tee $KEYRING > /dev/null
  sudo chmod a+r $KEYRING

  echo "📦 添加阿里云 APT 源..."
  echo "deb [signed-by=$KEYRING] https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main" | \
    sudo tee $APT_LIST > /dev/null

  echo "🔄 更新软件包索引..."
  sudo apt-get update

  echo "🚀 安装 kubectl..."
  sudo apt-get install -y kubectl

  echo "✅ 安装完成，版本如下："
  kubectl version --client
}

function uninstall_kubectl_keep_config() {
  echo "🧹 卸载 kubectl（保留配置）..."
  sudo apt-get purge --auto-remove -y kubectl
  echo "✅ 已卸载 kubectl，保留配置文件：$CONFIG_PATH"
}

function uninstall_kubectl_full() {
  echo "🧹 卸载 kubectl（清除配置）..."
  sudo apt-get purge --auto-remove -y kubectl
  rm -rf $CONFIG_PATH
  echo "✅ 已卸载 kubectl，并清除配置文件"
}

echo ">>> 请选择操作：1(安装)；2(卸载[保留配置])；3(卸载[清除配置])"
read -p "Please Choose: " choice

case "$choice" in
  1) install_kubectl ;;
  2) uninstall_kubectl_keep_config ;;
  3) uninstall_kubectl_full ;;
  *) echo "❌ 无效选项，请输入 1、2 或 3。" ;;
esac