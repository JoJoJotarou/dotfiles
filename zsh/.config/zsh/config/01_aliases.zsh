# 常用别名和小函数
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias ls='ls -CF --color=auto'
alias grep='grep --color=auto'

# 覆盖、删除前先确认（脚本里用 command rm 绕过）
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# 创建目录并进入
mkcd() { mkdir -p "$1" && cd "$1"; }
