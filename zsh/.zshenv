# 定义 Zsh 配置目录
export ZDOTDIR=$HOME/.config/zsh

if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi