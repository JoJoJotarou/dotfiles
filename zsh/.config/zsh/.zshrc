# 定义 Zsh 配置目录
export ZSH_CONFIG_DIR="${ZDOTDIR}/config"

# 加载所有配置模块
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
source "/Users/changjunjie/Developer/Personal/dotfiles/zsh/.config/zsh/antidote/antidote.zsh"
antidote load "$ZDOTDIR/.zsh_plugins.txt"

# 加载 Starship 提示符
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# macOS Caps Lock 立即生效
hidutil property --set '{"CapsLockDelayOverride":0}'

clear