# 开发工具清单

每类工具只走一个渠道，装了什么记在这个目录里。换机时按下面命令恢复；日常用仓库根目录的 `bin/doctor.sh` 体检（只报告，不删除）。

一条原则：**一个工具只走一个渠道。**

| 类型 | 渠道 | 清单 | 恢复 |
| --- | --- | --- | --- |
| App、系统级 CLI | Homebrew | `Brewfile` | `brew bundle --file=packages/Brewfile` |
| Node 版本 | nub | （由 brew 安装 nub） | `brew bundle` 会装 nub |
| JS / Node CLI | `pnpm add -g` | `pnpm-global.txt` | `grep -v '^#' packages/pnpm-global.txt \| xargs pnpm add -g` |
| Python CLI | `uv tool` | `uv-tools.txt` | `grep -v '^#' packages/uv-tools.txt \| xargs -n1 uv tool install` |
| Rust CLI | `cargo install` | `cargo-install.txt` | `grep -v '^#' packages/cargo-install.txt \| xargs -n1 cargo install` |
| Go CLI | `go install` | `go-install.txt` | `grep -v '^#' packages/go-install.txt \| xargs -n1 go install` |
| 一次性试用 | `npx` / `uvx` / `pnpm dlx` | 不留清单 | 用完不留痕 |

不要用 npm 全局装 CLI（本仓库已拦截 `npm -g`）。不要 brew、nub、官网安装包各装一份 Node。

## 文件说明

- `Brewfile`：Homebrew 的 tap、formulae、casks。刷新时请带上 `--no-uv --no-go --no-cargo --no-npm`（这几类有各自的清单；本机 brew 自带的 uv 偏旧，默认 dump 会因不支持的参数失败）：

  ```bash
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle dump --file=packages/Brewfile --force \
    --no-uv --no-go --no-cargo --no-npm --no-flatpak --no-winget --no-krew
  ```

- `pnpm-global.txt`、`uv-tools.txt`、`cargo-install.txt`、`go-install.txt`：对应渠道的包名（go 清单写的是 `go install` 用的包路径，带 `@latest`）。`#` 开头为注释。
- `home-allowlist.txt`：`$HOME` 下已登记的隐藏文件/目录（只写 basename）。`doctor.sh` 对照它，只预警新冒出来的项。AI 工具在 `$HOME` 下建的目录路径往往改不了，用白名单盯增量，不要硬搬。

新装一个工具就补进对应清单；不用了先卸载，再从清单里划掉。
