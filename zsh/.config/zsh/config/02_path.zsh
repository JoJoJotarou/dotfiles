# 添加自定义二进制路径到 PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"

# 添加 Homebrew (macOS)
if [[ "$OSTYPE" == darwin* ]]; then
    export PATH="/usr/local/bin:$PATH"
    export PATH="/opt/homebrew/bin:$PATH"
fi

# Java Home (默认 JDK17)
if [[ "$OSTYPE" == darwin* ]]; then
    export JAVA_HOME=$(/usr/libexec/java_home -v 17)
    export PATH=$PATH:$JAVA_HOME/bin
fi

if [[ -d "$HOME/Applications/apache-maven" ]]; then
    M2_HOME="$HOME/Applications/apache-maven"
    export PATH=$PATH:$M2_HOME/bin
fi

if [[ -d "$HOME/Applications/apache-tomcat" ]]; then
    TOMCAT_HOME="$HOME/Applications/apache-tomcat"
    export PATH=$PATH:$TOMCAT_HOME/bin
fi

if [[ -d "$HOME/Applications/gradle" ]]; then
    GRADEL_HOME="$HOME/Applications/gradle"
    export PATH=$PATH:$GRADEL_HOME/bin
fi
