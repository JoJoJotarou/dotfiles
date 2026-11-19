# 每个 zsh 进程都会读这里（交互 shell、脚本、ssh 远程命令、GUI 拉起的 shell）。
# 本文件只负责“按序加载”和密钥注入，具体配置放 env/*.zsh，不要直接写在这里。

for _env_file in "$ZDOTDIR"/env/*.zsh(N); do
    source "$_env_file"
done
unset _env_file

# 本机密钥，不入库（chmod 600）
[[ -f "$ZDOTDIR/secrets.zsh" ]] && source "$ZDOTDIR/secrets.zsh"
