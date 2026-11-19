# 连按两下 Esc：在当前命令前加上 / 去掉 sudo（空行时用上一条命令）
sudo-command-line() {
    [[ -z $BUFFER ]] && BUFFER="$(fc -ln -1)"
    if [[ $BUFFER == sudo\ * ]]; then
        BUFFER="${BUFFER#sudo }"
    else
        BUFFER="sudo $BUFFER"
    fi
    CURSOR=${#BUFFER}
}
zle -N sudo-command-line
bindkey '\e\e' sudo-command-line
