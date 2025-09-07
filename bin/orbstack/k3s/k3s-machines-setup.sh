#!/usr/bin/env bash


name=k3s
master=${name}-master
node1=${name}-n1
node2=${name}-n2
USER=kube

# 检查机器是否存在，不存在则创建
for MACHINE in $master $node1 $node2; do
    if ! orbctl list | grep -q "^$MACHINE "; then
        echo "⚙️ 创建机器 $MACHINE..."
        if [ "$MACHINE" == "$master" ]; then
            orbctl create -a arm64 -u $USER -c cloud-init.yaml ubuntu:noble $MACHINE
        else
            orbctl clone $master $MACHINE
        fi
    else
        echo "💪 机器 $MACHINE 已存在，跳过创建。"
    fi
done

# 启动机器
orbctl start $node1
orbctl start $node2

sleep 3

# 设置机器列表（通过 orbctl list 匹配 IP）
MACHINES=(${USER}@${master}@orb ${USER}@${node1}@orb ${USER}@${node2}@orb)
MACHINE_IPS=()
for MACHINE in $master $node1 $node2; do
    IP=$(orbctl list | awk -v name="$MACHINE" '$1 == name {print $NF}')
    if [[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        MACHINE_IPS+=("$IP")
    else
        echo "❌ 无法找到 $MACHINE 的 IP 地址，检查 orbctl list 输出。"
        exit 1
    fi
done

echo "🔍 机器列表和 IP 地址："
for i in "${!MACHINES[@]}"; do
    echo "${MACHINES[$i]} -> ${MACHINE_IPS[$i]}"
done

# 公钥路径
PUBKEY="$HOME/.ssh/id_ed25519.pub"

# 在每台机器上生成密钥（避免重复生成）
for HOST in "${MACHINES[@]}"; do
    echo "🔐 在 $HOST 上生成密钥对（如不存在）..."
    ssh "$HOST" "if [ ! -f ~/.ssh/id_ed25519 ]; then ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''; fi"
done

# 分发公钥到其他机器
for SOURCE in "${MACHINES[@]}"; do
    for TARGET in "${MACHINES[@]}"; do
        if [ "$SOURCE" != "$TARGET" ]; then
            echo "🚀 从 $SOURCE 分发公钥到 $TARGET..."
            ssh "$SOURCE" "cat ~/.ssh/id_ed25519.pub" | ssh "$TARGET" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && { TEMP_KEY=\$(mktemp); cat > \$TEMP_KEY; grep -qxFf \$TEMP_KEY ~/.ssh/authorized_keys || cat \$TEMP_KEY >> ~/.ssh/authorized_keys; rm -f \$TEMP_KEY; } && chmod 600 ~/.ssh/authorized_keys"
        fi
    done
done

# 测试互信（使用机器 IP）
echo "✅ 测试 SSH 互信..."

for i in "${!MACHINES[@]}"; do
    echo "${MACHINES[$i]} -> ${MACHINE_IPS[$i]}"
    for j in "${!MACHINES[@]}"; do
        if [ "${MACHINES[$i]}" != "${MACHINES[$j]}" ]; then
            echo "🔗 从 ${MACHINE_IPS[$i]} 测试连接到 ${MACHINE_IPS[$j]}..."
            ssh "${MACHINES[$i]}" "ssh -o StrictHostKeyChecking=no $USER@${MACHINE_IPS[$j]} 'echo ✅ 连接成功'"
        fi
    done
done

echo "🎉 所有机器已设置完成，SSH 互信测试通过！"