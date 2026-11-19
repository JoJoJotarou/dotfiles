# dotfiles
my dotfiles

## Usage

> 先装依赖：`brew install stow starship zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search zsh-completions`，再 clone 本仓库并 cd 进去。
> 若新 shell 提示 `compinit: insecure directories`，执行 `chmod go-w "$(brew --prefix)/share"`（brew 安装 zsh-completions 时的官方提示）。

```bash
# 安装所有 dotfiles 模块
./setup.sh --install

# 卸载所有 dotfiles 模块
./setup.sh --uninstall

# 查看可用模块
./setup.sh --list

# 查看帮助信息
./setup.sh --help
```

## 结构约定

- `git/ zsh/ ssh/ ghostty/ gradle/ maven/` 是 GNU Stow 模块，目录结构镜像 `$HOME`。
- `~/.zshenv` 是**真实文件**（不是软链），由 `setup.sh` 从 `zsh/.config/zsh/bootstrap.zshenv` 生成，只负责设置 `ZDOTDIR`。
- 环境变量分层：`zsh/.config/zsh/env/*.zsh` 对每个 zsh 进程生效（PATH、locale 等），`config/*.zsh` 只在交互式 shell 生效（alias、函数、需要 spawn 子进程的 `JAVA_HOME` 之类）。
- 密钥不放仓库：写到 `~/.config/zsh/secrets.zsh`（`chmod 600`，已在 `.gitignore` 中），由 `~/.config/zsh/.zshenv` 加载。
- 第三方安装器硬编码往 `~/.zshrc` / `~/.zprofile` 追加，这两个文件会被 `$ZDOTDIR/.zshrc` 和 `$ZDOTDIR/.zprofile` 末尾显式 source；这些安装器加的块留在 `~` 下，不搬进仓库；仓库里只放自己写的配置。