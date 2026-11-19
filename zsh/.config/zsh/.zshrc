# 交互式 zsh 配置。环境变量和 PATH 在 env/（.zshenv 加载），这里只放交互相关的。

# 1. 自定义配置：选项、别名、Java、Esc Esc 补 sudo、npm 防误装
for f in "$ZDOTDIR"/config/*.zsh(N); do source "$f"; done
unset f

# 2. 补全（zsh-completions 和 grok 的补全加进 fpath 后再初始化）
_brew_share="${HOMEBREW_PREFIX:-/opt/homebrew}/share"
fpath=("$_brew_share/zsh-completions" $fpath)
[[ -d "$HOME/.grok/completions/zsh" ]] && fpath=("$HOME/.grok/completions/zsh" $fpath)
autoload -Uz compinit && compinit

# 3. 插件（都用 brew 装，没装的自动跳过；history-substring-search 必须在 syntax-highlighting 之后）
for _p in zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search; do
    [[ -f "$_brew_share/$_p/$_p.zsh" ]] && source "$_brew_share/$_p/$_p.zsh"
done
unset _p _brew_share

# 4. 提示符
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# 5. 插件设置（须在插件加载之后）
bindkey '^[[A' history-substring-search-up               # ↑ 按已输入的关键字搜历史
bindkey '^[[B' history-substring-search-down             # ↓
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=(bg=none,fg=magenta,bold)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=3'                   # 自动建议的颜色

# 6. 第三方安装器写入 ~/.zshrc 的内容（ZDOTDIR 生效后 zsh 不读 ~/.zshrc，这里显式接一下）
[[ -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc"
