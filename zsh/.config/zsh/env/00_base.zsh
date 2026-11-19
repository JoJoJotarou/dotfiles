# 基础环境：PATH 和全局环境变量。每个 zsh 进程都生效（含非交互 shell、ssh 远程命令、脚本），
# 所以只放便宜的字符串拼接，不要在这里跑 java_home、go env 这类会起子进程的命令。

# 幂等前置：.zshenv 每个 zsh 都跑，嵌套 shell 不能把同一目录叠加成重复项。
path_prepend() {
    [[ -d "$1" ]] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

path_prepend "$HOME/bin"
path_prepend "$HOME/.local/bin"

# dotfiles 仓库内脚本（ghm 等）。
# 本文件: dotfiles/zsh/.config/zsh/env/ → 上五级为 dotfiles 仓库根
DOTFILES_ROOT="${0:A:h:h:h:h:h}"
path_prepend "$DOTFILES_ROOT/bin/git"

# nub: node + 包管理器 shim（nub upgrade 后重跑 `nub node shim` / `nub pm shim`）
path_prepend "$HOME/.nub/node-shim"
path_prepend "$HOME/.nub/shims"

# Rust
if [[ -f "$HOME/.cargo/env" ]]; then
    case ":$PATH:" in
        *":$HOME/.cargo/bin:"*) ;;
        *) source "$HOME/.cargo/env" ;;
    esac
fi

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
path_prepend "$PNPM_HOME"

# Homebrew (macOS)
if [[ "$OSTYPE" == darwin* ]]; then
    path_prepend "/usr/local/bin"
    path_prepend "/opt/homebrew/bin"
fi

# Go 装的命令行工具（go install）
path_prepend "${GOPATH:-$HOME/go}/bin"

# Maven（手动解压在 ~/Applications）
path_prepend "$HOME/Applications/apache-maven/bin"

export PATH

# SSH/Mosh 登录（如 iPhone Termius）时客户端常不带 LANG，这里补上 UTF-8，避免中文乱码。
[[ -n "$SSH_CONNECTION" ]] && export LANG=zh_CN.UTF-8

# uv 用阿里云 PyPI 镜像（放这里脚本里调 uv 也能读到）
export UV_DEFAULT_INDEX="https://mirrors.aliyun.com/pypi/simple/"
