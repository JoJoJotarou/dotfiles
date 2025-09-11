if [[ "$OSTYPE" == darwin* ]]; then
    # 切换 JDK 8
    jdk8() {
        export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
        echo "Switched to JDK 8"
    }

    # 切换 JDK 17
    jdk17() {
        export JAVA_HOME=$(/usr/libexec/java_home -v 17)
        echo "Switched to JDK 17"
    }
fi

# 创建目录并立即进入
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# 查找文件
ff() {
    find . -name "*$1*" -type f
}

# 查找目录
fd() {
    find . -name "*$1*" -type d
}