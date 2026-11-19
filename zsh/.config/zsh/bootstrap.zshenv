# 由 setup.sh 安装为 ~/.zshenv（真实文件，不是软链）。
#
# 为什么要这个文件：ZDOTDIR 必须在 zsh 读取其他启动文件之前设置好，而第三方
# 安装器（Antigravity/Kaku/nub/Qoder…）习惯往 ~/.zshenv、~/.zshrc 直接追加。
# 把 ~/.zshenv 留成这么短的真实文件，安装器写脏的也只是一眼能看完的 3 行。
#
# 修改这里后重跑 ./setup.sh --install 生效，或手工 cp 到 ~/.zshenv。

export ZDOTDIR="$HOME/.config/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
