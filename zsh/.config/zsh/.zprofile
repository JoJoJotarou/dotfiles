# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
if [[ -f ~/.orbstack/shell/init.zsh ]]; then
    source ~/.orbstack/shell/init.zsh 2>/dev/null || :
fi

# Added by Toolbox App
if [[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]]; then
    export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
fi

if [[ -f /opt/homebrew/bin/brew ]]; then
    # 阿里云
    # export HOMEBREW_PIP_INDEX_URL=http://mirrors.aliyun.com/pypi/simple #ckbrew
    # export HOMEBREW_API_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles/api  #ckbrew
    # export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles #ckbrew
    # eval $(/opt/homebrew/bin/brew shellenv) #ckbrew

    # 清华大学
    export HOMEBREW_PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple #ckbrew
    export HOMEBREW_API_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api  #ckbrew
    export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles #ckbrew
    eval $(/opt/homebrew/bin/brew shellenv) #ckbrew
fi