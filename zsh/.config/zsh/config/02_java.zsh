# Java：默认 JDK 17，切换用 `jdk 8`、`jdk 21`、`jdk 25`（只影响当前窗口）
[[ "$OSTYPE" == darwin* ]] || return 0

export JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null)

jdk() {
    local v="$1"; [[ "$v" == 8 ]] && v=1.8
    local home; home=$(/usr/libexec/java_home -v "$v" 2>/dev/null) || {
        echo "没找到 JDK $1，已装的有："; /usr/libexec/java_home -V 2>&1 | grep -E '^\s+[0-9]'; return 1; }
    grep -q "JAVA_VERSION=\"$v" "$home/release" 2>/dev/null || {
        echo "没找到 JDK $1，已装的有："; /usr/libexec/java_home -V 2>&1 | grep -E '^\s+[0-9]'; return 1; }
    export JAVA_HOME="$home"
    echo "已切换到 JDK $1"
}
