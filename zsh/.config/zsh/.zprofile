# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
if [[ -f ~/.orbstack/shell/init.zsh ]]; then
    source ~/.orbstack/shell/init.zsh 2>/dev/null || :
fi

if [[ -f /opt/homebrew/bin/brew ]]; then
    export HOMEBREW_PIP_INDEX_URL=http://mirrors.aliyun.com/pypi/simple #ckbrew
    export HOMEBREW_API_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles/api  #ckbrew
    export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles #ckbrew
    eval $(/opt/homebrew/bin/brew shellenv) #ckbrew
fi