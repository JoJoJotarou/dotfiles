#!/usr/bin/env zsh
# doctor.sh — 对照 packages/ 清单体检本机开发工具。只报告，不删除、不安装。
emulate -L zsh

# 在精简环境里也能找到 brew / nub / pnpm / cargo / go / uv
path_prepend() {
    [[ -d "$1" ]] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}
path_prepend "$HOME/bin"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.nub/node-shim"
path_prepend "$HOME/.nub/shims"
path_prepend "$HOME/Library/pnpm"
path_prepend "$HOME/.cargo/bin"
path_prepend "/opt/homebrew/bin"
path_prepend "/usr/local/bin"
path_prepend "${GOPATH:-$HOME/go}/bin"
export PATH

DOTFILES_DIR="${0:A:h:h}"
PACKAGES="$DOTFILES_DIR/packages"

warns=0
checks=0
ok_n=0

if [[ -t 1 ]]; then
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'
    BOLD=$'\033[1m'
    NC=$'\033[0m'
else
    GREEN= YELLOW= BLUE= BOLD= NC=
fi

pretty() {
    local p="$1"
    print -r -- "${p/#$HOME/~}"
}

section() {
    print
    print "${BLUE}${BOLD}── $1 ──${NC}"
}

ok() {
    (( ok_n++ ))
    (( checks++ ))
    print "${GREEN}✅${NC} $1"
}

warn() {
    (( warns++ ))
    (( checks++ ))
    print "${YELLOW}⚠️${NC}  $1"
}

info() {
    print "   $1"
}

# 读清单：去掉空行、# 注释、Windows 回车
load_list() {
    local file="$1"
    local line
    items=()
    if [[ ! -f "$file" ]]; then
        warn "找不到清单：$(pretty "$file")"
        return 1
    fi
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=${line%$'\r'}
        [[ -z "$line" || "$line" == \#* ]] && continue
        items+=("$line")
    done < "$file"
    return 0
}

# Brewfile 里的 brew/cask 名（引号内第一段）
parse_brewfile() {
    local file="$1"
    brew_listed=()
    cask_listed=()
    local line name
    [[ -f "$file" ]] || { warn "找不到 Brewfile：$(pretty "$file")"; return 1 }
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=${line%$'\r'}
        if [[ "$line" == brew[[:space:]]\"* ]]; then
            name="${line#brew \"}"
            name="${name%%\"*}"
            [[ -n "$name" ]] && brew_listed+=("$name")
        elif [[ "$line" == cask[[:space:]]\"* ]]; then
            name="${line#cask \"}"
            name="${name%%\"*}"
            [[ -n "$name" ]] && cask_listed+=("$name")
        fi
    done < "$file"
    return 0
}

# 精确匹配，或一边是 tap 全名（foo/tap/name）一边是短名（name）
formula_eq() {
    local a="$1" b="$2"
    [[ "$a" == "$b" ]] && return 0
    [[ "${a:t}" == "${b:t}" && ( "$a" == */* || "$b" == */* ) ]] && return 0
    return 1
}

in_formulae() {
    local needle="$1" x
    for x in "$@[2,-1]"; do
        formula_eq "$needle" "$x" && return 0
    done
    return 1
}

in_exact() {
    local needle="$1" x
    for x in "$@[2,-1]"; do
        [[ "$needle" == "$x" ]] && return 0
    done
    return 1
}

# ---------- Homebrew ----------
section "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
    warn "未找到 brew，跳过 Homebrew 检查"
else
    parse_brewfile "$PACKAGES/Brewfile"
    leaves=("${(@f)$(brew leaves 2>/dev/null)}")
    casks=("${(@f)$(brew list --cask 2>/dev/null)}")
    installed_full=("${(@f)$(brew list --formula --full-name 2>/dev/null)}")

    extra=0
    missing=0
    for item in "${leaves[@]}"; do
        [[ -z "$item" ]] && continue
        if ! in_formulae "$item" "${brew_listed[@]}"; then
            warn "brew leaf 未在 Brewfile 中：$item"
            extra=1
        fi
    done
    for item in "${brew_listed[@]}"; do
        if ! in_formulae "$item" "${installed_full[@]}"; then
            warn "Brewfile 中的 formula 未安装：$item"
            missing=1
        fi
    done
    for item in "${casks[@]}"; do
        [[ -z "$item" ]] && continue
        if ! in_exact "$item" "${cask_listed[@]}"; then
            warn "cask 未在 Brewfile 中：$item"
            extra=1
        fi
    done
    for item in "${cask_listed[@]}"; do
        if ! in_exact "$item" "${casks[@]}"; then
            warn "Brewfile 中的 cask 未安装：$item"
            missing=1
        fi
    done
    if (( !extra && !missing )); then
        ok "formulae / casks 与 Brewfile 一致（${#brew_listed[@]} 个 formula，${#cask_listed[@]} 个 cask）"
    fi
fi

# ---------- pnpm ----------
section "pnpm 全局 CLI"
if ! command -v pnpm >/dev/null 2>&1; then
    warn "未找到 pnpm，跳过 pnpm 检查"
else
    load_list "$PACKAGES/pnpm-global.txt"
    listed=("${items[@]}")
    current=()
    raw=$(pnpm ls -g --depth 0 --json 2>/dev/null) || raw=""
    if command -v python3 >/dev/null 2>&1 && [[ -n "$raw" ]]; then
        current=("${(@f)$(print -r -- "$raw" | python3 -c '
import json,sys
data=json.load(sys.stdin)
names=set()
for item in data:
    names.update((item.get("dependencies") or {}).keys())
print("\n".join(sorted(names, key=str.lower)))
')}")
    fi
    extra=0
    missing=0
    for item in "${current[@]}"; do
        [[ -z "$item" ]] && continue
        if ! in_exact "$item" "${listed[@]}"; then
            warn "pnpm 全局包未在清单中：$item"
            extra=1
        fi
    done
    for item in "${listed[@]}"; do
        if ! in_exact "$item" "${current[@]}"; then
            warn "清单中的 pnpm 全局包未安装：$item"
            missing=1
        fi
    done
    if (( !extra && !missing )); then
        ok "pnpm 全局包与清单一致（${#listed[@]} 个）"
    fi
fi

# ---------- uv ----------
section "uv tool"
if ! command -v uv >/dev/null 2>&1; then
    warn "未找到 uv，跳过 uv 检查"
else
    load_list "$PACKAGES/uv-tools.txt"
    listed=("${items[@]}")
    current=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=${line%%$'\r'}
        [[ -z "$line" || "$line" == [[:space:]]* || "$line" == -* ]] && continue
        current+=("${${line# }%% *}")
    done < <(uv tool list 2>/dev/null)
    extra=0
    missing=0
    for item in "${current[@]}"; do
        [[ -z "$item" ]] && continue
        if ! in_exact "$item" "${listed[@]}"; then
            warn "uv tool 未在清单中：$item"
            extra=1
        fi
    done
    for item in "${listed[@]}"; do
        if ! in_exact "$item" "${current[@]}"; then
            warn "清单中的 uv tool 未安装：$item"
            missing=1
        fi
    done
    if (( !extra && !missing )); then
        ok "uv tools 与清单一致（${#listed[@]} 个）"
    fi
fi

# ---------- cargo ----------
section "cargo install"
if ! command -v cargo >/dev/null 2>&1; then
    warn "未找到 cargo，跳过 cargo 检查"
else
    load_list "$PACKAGES/cargo-install.txt"
    listed=("${items[@]}")
    current=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=${line%%$'\r'}
        [[ -z "$line" || "$line" == [[:space:]]* ]] && continue
        current+=("${${line%% *}%%:}")
    done < <(cargo install --list 2>/dev/null)
    extra=0
    missing=0
    for item in "${current[@]}"; do
        [[ -z "$item" ]] && continue
        if ! in_exact "$item" "${listed[@]}"; then
            warn "cargo install 的 crate 未在清单中：$item"
            extra=1
        fi
    done
    for item in "${listed[@]}"; do
        if ! in_exact "$item" "${current[@]}"; then
            warn "清单中的 crate 未安装：$item"
            missing=1
        fi
    done
    if (( !extra && !missing )); then
        ok "cargo crates 与清单一致（${#listed[@]} 个）"
    fi
fi

# ---------- go ----------
section "go install"
load_list "$PACKAGES/go-install.txt"
listed=("${items[@]}")
# 清单写成 path@latest，比较时去掉版本后缀
listed_paths=()
for item in "${listed[@]}"; do
    listed_paths+=("${item%%@*}")
done
current_paths=()
go_bin="${GOPATH:-$HOME/go}/bin"
if [[ ! -d "$go_bin" ]]; then
    if (( ${#listed_paths[@]} )); then
        warn "找不到 $(pretty "$go_bin")，但清单里有 ${#listed_paths[@]} 个包"
    else
        ok "没有 go 安装的二进制，清单也为空"
    fi
else
    if ! command -v go >/dev/null 2>&1; then
        warn "未找到 go，无法读取 $(pretty "$go_bin") 里二进制的模块路径"
    else
        for b in "$go_bin"/*(N); do
            [[ -f "$b" ]] || continue
            pkgpath=$(go version -m "$b" 2>/dev/null | awk '$1=="path"{print $2; exit}')
            if [[ -n "$pkgpath" ]]; then
                current_paths+=("$pkgpath")
            else
                warn "无法读取 $(pretty "$b") 的模块路径"
            fi
        done
        extra=0
        missing=0
        for item in "${current_paths[@]}"; do
            if ! in_exact "$item" "${listed_paths[@]}"; then
                warn "go 二进制未在清单中：$item"
                extra=1
            fi
        done
        for item in "${listed_paths[@]}"; do
            if ! in_exact "$item" "${current_paths[@]}"; then
                warn "清单中的 go 包未安装：$item"
                missing=1
            fi
        done
        if (( !extra && !missing )); then
            ok "go 二进制与清单一致（${#listed_paths[@]} 个）"
        fi
    fi
fi

# ---------- npm -g（除 npm 自身外应为空）----------
section "npm 全局（应为空）"
if ! command -v npm >/dev/null 2>&1; then
    ok "未找到 npm，跳过（视为没有 npm 全局包）"
else
    current=()
    raw=$(npm ls -g --depth 0 --json 2>/dev/null) || raw=""
    if command -v python3 >/dev/null 2>&1 && [[ -n "$raw" ]]; then
        current=("${(@f)$(print -r -- "$raw" | python3 -c '
import json,sys
data=json.load(sys.stdin)
deps=(data.get("dependencies") or {})
names=[n for n in deps if n != "npm"]
print("\n".join(sorted(names, key=str.lower)))
')}")
    fi
    extra=0
    for item in "${current[@]}"; do
        [[ -z "$item" ]] && continue
        warn "npm 全局包应改走 pnpm：$item"
        extra=1
    done
    if (( !extra )); then
        ok "npm 全局除 npm 自身外为空"
    fi
fi

# ---------- 失效软链 ----------
section "失效软链（~/.local/bin、~/bin）"
dangling=()
for dir in "$HOME/.local/bin" "$HOME/bin"; do
    [[ -d "$dir" ]] || continue
    for link in "$dir"/*(N); do
        [[ -L "$link" ]] || continue
        if [[ ! -e "$link" ]]; then
            dangling+=("$(pretty "$link") -> $(pretty "$(readlink "$link")")")
        fi
    done
done
if (( ${#dangling[@]} )); then
    for item in "${dangling[@]}"; do
        warn "失效软链：$item"
    done
else
    ok "~/.local/bin 与 ~/bin 没有失效软链"
fi

# ---------- $HOME 隐藏项 ----------
section "\$HOME 隐藏项"
load_list "$PACKAGES/home-allowlist.txt"
listed=("${items[@]}")
current=()
for p in "$HOME"/.* "$HOME"/.[!.]* "$HOME"/..?*(N); do
    name="${p:t}"
    [[ "$name" == "." || "$name" == ".." ]] && continue
    [[ -e "$p" || -L "$p" ]] || continue
    current+=("$name")
done
# 去重（$HOME/.* 和 $HOME/.[!.]* 会重叠）
typeset -A seen
uniq=()
for item in "${current[@]}"; do
    [[ -n "${seen[$item]:-}" ]] && continue
    seen[$item]=1
    uniq+=("$item")
done
current=("${uniq[@]}")
extra=0
for item in "${current[@]}"; do
    if ! in_exact "$item" "${listed[@]}"; then
        warn "未登记的隐藏项：$(pretty "$HOME/$item")"
        extra=1
    fi
done
# 白名单里已消失的项只提示，不算越界（可能是主动清理）
stale=0
for item in "${listed[@]}"; do
    if ! in_exact "$item" "${current[@]}"; then
        info "白名单中已不存在：$(pretty "$HOME/$item")"
        stale=1
    fi
done
if (( !extra )); then
    if (( stale )); then
        ok "没有新的隐藏项（白名单里有已消失的条目，见上方，可考虑从 home-allowlist.txt 删掉）"
    else
        ok "\$HOME 隐藏项与白名单一致（${#listed[@]} 项）"
    fi
fi

# ---------- 总结 ----------
print
print "${BOLD}── 总结 ──${NC}"
if (( warns == 0 )); then
    print "${GREEN}✅ 全部通过${NC}（${checks} 项检查）"
else
    print "${YELLOW}⚠️  ${warns} 条预警${NC} / ${checks} 项检查。以上只报告，没有删除或改动任何东西。"
fi
exit 0
