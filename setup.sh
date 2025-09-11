#!/bin/zsh

# Dotfiles 管理脚本：安装、卸载、备份、恢复（支持 GNU Stow）

# 🎨 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 📦 模块列表（根据你的 dotfiles 项目结构）
MODULES=(
    "git"
    "gradle"
    "maven"
    "ssh"
    "wezterm"
    "zsh"
)

# 📁 当前脚本所在目录
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BAK_DIR="$DOTFILES_DIR/.bak"
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
BAK_TIMESTAMP_DIR="$BAK_DIR/bak_$TIMESTAMP"

# 🧪 是否 dry-run 模式
DRY_RUN=false

# ✅ 检查 stow 是否安装
check_stow() {
    if ! command -v stow &> /dev/null; then
        echo -e "${RED}错误: GNU Stow 未安装${NC}"
        echo -e "请使用以下命令安装:"
        echo -e "  ${YELLOW}macOS: brew install stow${NC}"
        echo -e "  ${YELLOW}Ubuntu: sudo apt install stow${NC}"
        exit 1
    fi
}

# 🗂️ 备份单个文件（保留目录结构）
backup_file() {
    local target="$1"
    local rel_path="${target#$HOME/}"
    local bak_path="$BAK_TIMESTAMP_DIR/$rel_path"
    local bak_dir="$(dirname "$bak_path")"

    mkdir -p "$bak_dir"

    if $DRY_RUN; then
        rsync -a "$target" "$bak_path" 2>/dev/null
        echo -e "${YELLOW}  [Dry-run] 拷贝: $target → $bak_path${NC}"
    else
        mv "$target" "$bak_path" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${YELLOW}  移动: $target → $bak_path${NC}"
        else
            echo -e "${RED}  无法移动（权限或不存在）: $target${NC}"
        fi
    fi
}

# 🔍 检查并备份模块中将被覆盖的文件
backup_module_files() {
    local module="$1"
    local module_dir="$DOTFILES_DIR/$module"
    echo -e "${BLUE}检查模块: $module${NC}"

    if [ ! -d "$module_dir" ]; then
        echo -e "${RED}  模块目录不存在，跳过${NC}"
        return
    fi

    find "$module_dir" -type f | while read -r file; do
        local rel_path="${file#$module_dir/}"
        local target_path="$HOME/$rel_path"

        if [[ "$target_path" == "$HOME"* ]] && [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
            # 备份目录不存在则创建
            if [[ ! -d "$BAK_TIMESTAMP_DIR" ]]; then
                mkdir -p "$BAK_TIMESTAMP_DIR"
            fi

            backup_file "$target_path"
        fi
    done
}

prepare_module_dirs() {
    local module="$1"
    local module_dir="$DOTFILES_DIR/$module"

    find "$module_dir" -type f | while read -r file; do
        local rel_path="${file#$module_dir/}"
        local target_path="$HOME/$rel_path"
        local target_dir="$(dirname "$target_path")"

        if [ ! -d "$target_dir" ]; then
            mkdir -p "$target_dir"
            echo -e "${GREEN}  创建目录: $target_dir${NC}"
        fi
    done
}

update_antidote_path_in_zshrc() {
    local zshrc_path="$DOTFILES_DIR/zsh/.config/zsh/.zshrc"
    local antidote_path="$DOTFILES_DIR/zsh/.config/zsh/antidote/antidote.zsh"

    if [ ! -f "$zshrc_path" ]; then
        echo -e "${RED}未找到 .zshrc 文件，跳过 Antidote 路径替换${NC}"
        return
    fi

    if [ ! -f "$antidote_path" ]; then
        echo -e "${RED}未找到 Antidote 文件，跳过路径替换${NC}"
        return
    fi

    # 替换 .zshrc 中的 Antidote 路径（只替换 source 行）
    if [[ "$OSTYPE" == darwin* ]]; then
        sed -i '' "s|^source .*antidote.zsh|source \"$antidote_path|" "$zshrc_path"
    else
        sed -i "s|^source .*antidote.zsh|source \"$antidote_path|" "$zshrc_path"
    fi

    echo -e "${GREEN}✅ 已更新 .zshrc 中的 Antidote 路径为:${NC}"
    echo -e "${YELLOW}  $antidote_path${NC}"
}

# 🚀 安装 dotfiles
install_dotfiles() {
    echo -e "${BLUE}开始安装 dotfiles...${NC}"

    for module in "${MODULES[@]}"; do
        backup_module_files "$module"
        prepare_module_dirs "$module"
    done

    for module in "${MODULES[@]}"; do
        if [ -d "$DOTFILES_DIR/$module" ]; then
            echo -e "${GREEN}安装模块: $module${NC}"
            cd "$DOTFILES_DIR" || exit
            if $DRY_RUN; then
                echo -e "${YELLOW}  [Dry-run] stow -v -t \"$HOME\" \"$module\"${NC}"
            else
                stow -v -t "$HOME" "$module"
            fi
            if [ "$module" = "zsh" ]; then
                update_antidote_path_in_zshrc
            fi
        fi
    done

    echo -e "${GREEN}✅ 安装完成${NC}"
    echo -e "${YELLOW}备份文件保存在: $BAK_TIMESTAMP_DIR${NC}"
}

# 🧹 卸载 dotfiles
uninstall_dotfiles() {
    echo -e "${BLUE}开始卸载 dotfiles...${NC}"
    for module in "${MODULES[@]}"; do
        if [ -d "$DOTFILES_DIR/$module" ]; then
            echo -e "${RED}卸载模块: $module${NC}"
            cd "$DOTFILES_DIR" || exit
            if $DRY_RUN; then
                echo -e "${YELLOW}  [Dry-run] stow -v -D -t \"$HOME\" \"$module\"${NC}"
            else
                stow -v -D -t "$HOME" "$module"
            fi
        fi
    done
    echo -e "${GREEN}✅ 卸载完成${NC}"
}

# ♻️ 恢复备份
restore_backup() {
    local restore_dir="$1"

    if [ ! -d "$restore_dir" ]; then
        echo -e "${RED}备份目录不存在: $restore_dir${NC}"
        exit 1
    fi

    echo -e "${BLUE}开始恢复备份: $restore_dir${NC}"
    cd "$restore_dir" || exit

    find . -type f | while read -r file; do
        local rel_path="${file#./}"
        local target_path="$HOME/$rel_path"
        local target_dir="$(dirname "$target_path")"

        mkdir -p "$target_dir"
        cp -a "$file" "$target_path"
        echo -e "${GREEN}  恢复: $file → $target_path${NC}"
    done

    echo -e "${GREEN}✅ 恢复完成${NC}"
}

# 📋 列出模块
list_modules() {
    echo -e "${BLUE}可用模块:${NC}"
    for module in "${MODULES[@]}"; do
        if [ -d "$DOTFILES_DIR/$module" ]; then
            echo -e "  ${GREEN}[✓] $module${NC}"
        else
            echo -e "  ${RED}[✗] $module${NC}"
        fi
    done
}

# 📖 帮助信息
show_help() {
    echo -e "${BLUE}dotfiles 管理脚本${NC}"
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  -i, --install           安装 dotfiles（并备份）"
    echo "  -u, --uninstall         卸载 dotfiles"
    echo "  -l, --list              列出模块"
    echo "  -h, --help              显示帮助"
    echo "  --dry-run               预览操作，不实际执行 stow 或移动文件"
    echo "  --restore <目录路径>   恢复指定备份目录中的文件"
}

# 🧠 主函数
main() {
    check_stow

    case "$1" in
        -i|--install)
            install_dotfiles
            ;;
        -u|--uninstall)
            uninstall_dotfiles
            ;;
        -l|--list)
            list_modules
            ;;
        -h|--help)
            show_help
            ;;
        --dry-run)
            DRY_RUN=true
            install_dotfiles
            ;;
        --restore)
            restore_backup "$2"
            ;;
        *)
            echo -e "${RED}错误: 无效选项${NC}"
            show_help
            exit 1
            ;;
    esac
}

main "$@"