#!/bin/bash

# 安装 docker 和 docker compose（插件）
# 阿里云源 + 国内docker镜像加速

set -e

function uninstall_docker_pkg() {
    echo "🧹 卸载 Docker 相关软件包（保留数据）..."
    sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo apt-get autoremove -y
}

function uninstall_docker_all() {
    echo "🔥 强制清除 Docker 所有文件与配置..."
    uninstall_docker_pkg
    echo "🗑️ 删除 Docker 数据与配置目录..."
    sudo rm -rf /var/lib/docker /var/lib/containerd /etc/docker
    echo "🧽 移除 Docker APT 源及 GPG 密钥..."
    sudo rm -f /etc/apt/sources.list.d/docker.list
    sudo rm -f /etc/apt/keyrings/docker.gpg
}

function install_docker() {
    echo "🔍 检查是否存在旧版本 Docker..."
    if dpkg -l | grep -E 'docker-ce|docker-ce-cli|containerd.io|docker-buildx-plugin|docker-compose-plugin' > /dev/null; then
        echo "⚠️ 检测到旧版本 Docker，执行卸载（保留数据）..."
        uninstall_docker_pkg
    fi

    echo "📂 添加 Docker 官方源..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    echo "🔐 添加 Docker GPG 密钥..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null

    echo "🌐 配置 Docker 源列表..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo "📦 安装 Docker 社区版本及插件..."
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "🚀 配置国内镜像加速器..."
    sudo mkdir -p /etc/docker
    cat <<EOF | sudo tee /etc/docker/daemon.json > /dev/null
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.1panel.live",
    "https://docker.m.daocloud.io",
    "https://hub1.nat.tf"
  ]
}
EOF

    echo "🧩 启动并设置 Docker 开机启动..."
    sudo systemctl daemon-reexec
    sudo systemctl restart docker
    sudo systemctl enable docker

    echo "✅ Docker 安装完成！"
    echo "🔍 版本信息："
    docker version
    docker compose version
}

echo -e '\033[35m>>>\033[0m 当前脚本适用于 \033[32mUbuntu 24.04\033[0m，使用 \033[33m阿里云源 + 国内镜像加速器\033[0m 安装 Docker & Compose 插件'
echo -e "\033[35m>>>\033[0m 请选择操作：\033[34m1: 安装；2: 卸载[保留数据]；3: 卸载[清除数据]\033[0m"
read -p "Please Choose: " do_what

if [ "$do_what" -eq 1 ]; then
    install_docker
elif [ "$do_what" -eq 2 ]; then
    uninstall_docker_pkg
elif [ "$do_what" -eq 3 ]; then
    uninstall_docker_all
else
    echo -e '\033[31m未知操作，退出\033[0m'
fi