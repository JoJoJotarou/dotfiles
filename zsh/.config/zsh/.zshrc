# 定义 Zsh 配置目录
export ZSH_CONFIG_DIR="${ZDOTDIR}/config"

# 加载所有自定义.zsh
if [ -d "$ZSH_CONFIG_DIR" ]; then
    for config_file in "$ZSH_CONFIG_DIR/"*.zsh; do
        if [ -f "$config_file" ] && [ -r "$config_file" ]; then
            # 可以取消注释下一行来调试加载过程
            # echo "Loading: $(basename "$config_file")"
            source "$config_file"
        fi
    done
else
    echo "⚠️  Zsh config directory not found: $ZSH_CONFIG_DIR"
fi

# 加载 Antidote 插件管理器
source "$ZDOTDIR/antidote/antidote.zsh"
antidote load "$ZDOTDIR/.zsh_plugins.txt"

# 加载 Starship 提示符
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# macOS Caps Lock 立即生效
hidutil property --set '{"CapsLockDelayOverride":0}'

clear

# zsh 插件配置（放其他位置不生效，须放在 .zshrc 最后）

# zsh-you-should-use 提示位置
export YSU_MESSAGE_POSITION="after"

# zsh-history-substring-search 使用上下方向键 ↑ 和 ↓ 通过输入的关键字搜索历史
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
# zsh-history-substring-search 搜索历史时，匹配到的关键字会被高亮显示
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=(bg=none,fg=magenta,bold)

# zsh-autosuggestions 自动建议的颜色
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=20'

# 初始化补全
autoload -U compinit && compinit