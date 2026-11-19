# 登录 shell 专用。软件安装器加的内容（OrbStack、JetBrains Toolbox、grok 等）放在 ~/.zprofile，不进仓库。
# ZDOTDIR 生效后 zsh 不读 ~/.zprofile，这里显式接一下。
[[ -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile"
