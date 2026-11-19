# AI agent 规则（dotfiles 仓库）

这个仓库管理本机 zsh 等配置，改坏会让每个新终端卡死。动手前读完。

## 绝对不要
- 不要在循环里往任何 shell 启动文件（`.zshrc`、`.zshenv`、`.zprofile`、`env/*`、`config/*`）追加内容。追加类操作只做一次，做完检查文件。
- 不要提交含绝对 home 路径（`/Users/...`）的内容，一律写 `~` 或 `$HOME`。
- 不要读取、输出或提交 `~/.config/zsh/secrets.zsh`。
- 不要提交 `docs/`。
- 不要 `git push --force`，不要改写已推送的历史。

## 改启动文件时
1. 先备份：`cp <file> <file>.bak-$(date +%Y%m%d-%H%M%S)`。
2. 改完立刻验证：`wc -c <file>`（应为几 KB）和 `TERM=xterm-256color zsh -i -c exit`（无报错、几秒内退出）。
3. 做启动耗时分析时，`zmodload zsh/zprof` 只在 `.zshrc` 第一行加一次、末尾加一次 `zprof`，分析完删除。

## 结构
- `~/.zshenv` 是真实文件，只设 `ZDOTDIR`；`env/*.zsh` 对所有 zsh 生效，只放便宜的字符串操作；`config/*.zsh` 只在交互 shell 生效。
- 第三方安装器写进 `~/.zshrc` / `~/.zprofile` 的内容留在原处，不搬进仓库。
- `zsh/.stow-local-ignore` 每行是 Perl 正则，不是通配符。
