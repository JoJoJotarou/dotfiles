#!/usr/bin/env bash

set -e  # 遇到错误退出

# 配置变量
name=k3s
master=${name}-master
node1=${name}-n1
node2=${name}-n2
USER=kube
K3S_VERSION="v1.27.8+k3s1"  # 可以修改版本号

# 获取机器IP地址
get_machine_ip() {
    local machine=$1
    orbctl list | awk -v name="$machine" '$1 == name {print $NF}'
}

# 检查K3s是否已安装
check_k3s_installed() {
    local host=$1
    ssh "$host" "command -v k3s >/dev/null 2>&1"
}

# 获取 K3s master token
get_k3s_token() {
    local master=$1
    local token=$(ssh "${USER}@${master}@orb" "sudo cat /var/lib/rancher/k3s/server/node-token 2>/dev/null || echo ''")
    echo "$token"
}

# 安装K3s master
install_master() {
    local master_ip=$(get_machine_ip $master)
    echo "🚀 在 $master 上安装 K3s Server..."
    
    if check_k3s_installed "${USER}@${master}@orb"; then
        echo "✅ K3s Server 已在 $master 上安装，跳过安装"
        return 0
    fi
    # 安装K3s server
    ssh "${USER}@${master}@orb" bash -s <<EOF
set -e

# 1. 安装 k3s server
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn sh -

# 2. 配置 kubeconfig
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown \$(id -u):\$(id -g) ~/.kube/config

# 避免重复写入
grep -qxF 'export KUBECONFIG=/home/${USER}/.kube/config' ~/.bashrc || echo 'export KUBECONFIG=/home/${USER}/.kube/config' >> ~/.bashrc

# 3. 配置镜像加速器
sudo mkdir -p /var/lib/rancher/k3s/agent/etc/containerd/certs.d/docker.io

sudo tee /var/lib/rancher/k3s/agent/etc/containerd/certs.d/docker.io/hosts.toml <<EOT
server = "https://docker.io"

[host."https://docker.1ms.run"]
  capabilities = ["pull", "resolve"]

[host."https://docker.1panel.live"]
  capabilities = ["pull", "resolve"]
EOT
EOF
}

# 安装K3s agent
install_agent() {
    local node=$1
    local master_ip=$2
    local token=$3
    
    echo "🚀 在 $node 上安装 K3s Agent..."
    
    if check_k3s_installed "${USER}@${node}@orb"; then
        echo "✅ K3s Agent 已在 $node 上安装，跳过安装"
        return 0
    fi
    
    local node_ip=$(get_machine_ip $node)

    ssh "${USER}@${node}@orb" bash -s <<EOF
set -e

# 安装 k3s agent 并连接到 master
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn K3S_URL=https://${master_ip}:6443 K3S_TOKEN=${token} sh -

# 配置镜像加速器
sudo mkdir -p /var/lib/rancher/k3s/agent/etc/containerd/certs.d/docker.io

sudo tee /var/lib/rancher/k3s/agent/etc/containerd/certs.d/docker.io/hosts.toml <<EOT
server = "https://docker.io"

[host."https://docker.1ms.run"]
  capabilities = ["pull", "resolve"]

[host."https://docker.1panel.live"]
  capabilities = ["pull", "resolve"]
EOT
EOF
}

# 等待节点就绪
wait_nodes_ready() {
    local master_ip=$(get_machine_ip $master)
    echo "⏳ 等待所有节点就绪..."
    
    local attempts=3
    local interval=5
    
    for ((i=1; i<=attempts; i++)); do
        echo "尝试 $i/$attempts: 检查节点状态..."
        
        local status=$(ssh "${USER}@${master}@orb" "sudo k3s kubectl get nodes -o wide 2>/dev/null || echo 'not-ready'")
        
        if echo "$status" | grep -q "Ready" && echo "$status" | grep -q "$node1\|$node2"; then
            echo "✅ 所有节点已就绪！"
            # echo "$status"
            return 0
        fi
        
        if [ $i -lt $attempts ]; then
            echo "等待 ${interval}秒后重试..."
            sleep $interval
        fi
    done
    
    echo "❌ 超时：节点未在预期时间内就绪"
    ssh "${USER}@${master}@orb" "sudo k3s kubectl get nodes -o wide" || true
    return 1
}

# 检查master是否就绪
check_master_ready() {
    local master_ip=$(get_machine_ip $master)
    echo "⏳ 检查master节点是否就绪..."
    
    local attempts=3
    local interval=5
    
    for ((i=1; i<=attempts; i++)); do
        echo "尝试 $i/$attempts: 检查master状态..."
        
        if ssh "${USER}@${master}@orb" "sudo systemctl is-active k3s >/dev/null 2>&1" && \
           ssh "${USER}@${master}@orb" "sudo k3s kubectl get nodes $master 2>/dev/null | grep -q Ready"; then
            echo "✅ Master节点已就绪！"
            return 0
        fi
        
        if [ $i -lt $attempts ]; then
            echo "等待 ${interval}秒后重试..."
            sleep $interval
        fi
    done
    
    echo "❌ 超时：master节点未在预期时间内就绪"
    return 1
}

# 卸载K3s（可选功能）
uninstall_k3s() {
    local host=$1
    echo "🧹 在 $host 上卸载 K3s..."
    
    ssh "${USER}@${host}@orb" 'bash -s' << 'EOF'
        if command -v k3s-uninstall.sh >/dev/null 2>&1; then
            sudo k3s-uninstall.sh
            sudo rm -rf ~/.kube
        elif command -v k3s-agent-uninstall.sh >/dev/null 2>&1; then
            sudo k3s-agent-uninstall.sh
            sudo rm -rf ~/.kube
        else
            echo "⚠️  未找到卸载脚本，尝试手动清理"
            sudo systemctl stop k3s k3s-agent 2>/dev/null || true
            sudo rm -rf /etc/rancher /var/lib/rancher /var/lib/containerd ~/.kube
        fi
EOF
}

# 主安装流程
main() {
    echo "🎯 开始安装 K3s 集群..."
    
    # 检查机器是否运行
    for machine in $master $node1 $node2; do
        if ! orbctl list | grep -q "^$machine "; then
            echo "❌ 机器 $machine 不存在，请先运行 k3s-machines-setup.sh"
            exit 1
        fi
    done
    
    # 启动所有机器（如果未运行）
    for machine in $master $node1 $node2; do
        if ! orbctl list | grep "^$machine " | grep -q "running"; then
            echo "🔌 启动机器 $machine..."
            orbctl start $machine
            sleep 5
        fi
    done
    
    # 安装master并获取token
    echo "🚀 安装master节点..."
    install_master
    local token=$(get_k3s_token "$master")
    if [ -z "$token" ]; then
        echo "❌ 获取K3s token失败"
        exit 1
    fi
    
    local master_ip=$(get_machine_ip $master)
    echo "🔑 K3s Token: $token"
    echo "🌐 Master IP: $master_ip"
    
    # 等待master就绪
    check_master_ready
    
    # 安装agents
    for node in $node1 $node2; do
        install_agent "$node" "$master_ip" "$token"
    done
    
    # 等待集群就绪
    wait_nodes_ready
    
    # 显示集群信息
    echo "🎉 K3s 集群安装完成！"
    echo ""
    echo "📊 集群状态:"
    ssh "${USER}@${master}@orb" "sudo k3s kubectl get nodes -o wide"
    
    echo ""
    echo "🔧 使用以下命令访问集群:"
    echo "  ssh ${USER}@${master}@orb \"sudo k3s kubectl get pods -A\""
    echo ""
    echo "📋 或者将kubeconfig复制到本地访问:"
    echo "  宿主机机器上（确保已安装 kubectl）：mkdir -p ~/.kube && ssh ${USER}@${master}@orb "sudo cat /etc/rancher/k3s/k3s.yaml" | \\
            sed \"s/127.0.0.1/${master_ip}/\" > ~/.kube/config"
}

# 支持卸载选项
if [ "$1" = "--uninstall" ]; then
    echo "🗑️  开始卸载 K3s 集群..."
    for machine in $master $node1 $node2; do
        uninstall_k3s "$machine"
    done
    echo "✅ K3s 集群卸载完成"
    exit 0
fi

# 支持状态检查
if [ "$1" = "--status" ]; then
    echo "📊 K3s 集群状态:"
    master_ip=$(get_machine_ip $master)
    if check_k3s_installed "${USER}@${master}@orb"; then
        ssh "${USER}@${master}@orb" "sudo k3s kubectl get nodes -o wide 2>/dev/null || echo 'K3s未运行'"
    else
        echo "❌ K3s 未安装"
    fi
    exit 0
fi

# 支持版本检查
if [ "$1" = "--version" ]; then
    if check_k3s_installed "${USER}@${master}@orb"; then
        ssh "${USER}@${master}@orb" "k3s --version"
    else
        echo "K3s未安装"
    fi
    exit 0
fi

# 重启集群
if [ "$1" = "--restart" ]; then
    echo "🔄 重启 K3s 集群..."
    ssh "${USER}@${master}@orb" "sudo systemctl restart k3s"
    for node in $node1 $node2; do
        ssh "${USER}@${node}@orb" "sudo systemctl restart k3s-agent"
    done
    echo "✅ 重启命令已发送，等待节点就绪..."
    check_master_ready
    wait_nodes_ready
    exit 0
fi

# 执行主安装流程
main "$@"