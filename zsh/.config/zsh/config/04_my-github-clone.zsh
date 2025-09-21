# 从各种格式中提取仓库名
_extract_repo_name() {
    local input="$1"
    if [[ $input =~ ^git@github\.com: ]]; then
        echo "$input" | sed 's/git@github\.com:[^\/]*\///; s/\.git$//'
    elif [[ $input =~ ^https://github\.com/ ]]; then
        echo "$input" | sed 's|https://github\.com/[^/]*/||; s/\.git$//'
    else
        echo "$input"
    fi
}

# 克隆和配置仓库
_clone_and_config() {
    local repo_name="$1"
    local git_domain="$2"
    local user_name="$3"
    local user_email="$4"
    
    echo "=>start clone $repo_name..." &&
    git clone "git@${git_domain}:${user_name}/$repo_name" &&
    cd "$repo_name" &&
    git config --local user.name "$user_name" &&
    git config --local user.email "$user_email" &&
    cd - &&
    echo "=>succ" || echo "=>fail!!"
}

# 定义 Jo 用户相关变量
JO_DOMAIN="jojojotarou.github.com"
JO_USER_NAME="JoJoJotarou"
JO_USER_EMAIL="58281079+JoJoJotarou@users.noreply.github.com"

# 定义 et0 用户相关变量
ET0_DOMAIN="enjoytech0.github.com"
ET0_USER_NAME="EnjoyTech0"
ET0_USER_EMAIL="104669762+EnjoyTech0@users.noreply.github.com"

# 具体用户函数
ghc_jo() {
    local repo_name=$(_extract_repo_name "$1")
    _clone_and_config "$repo_name" "$JO_DOMAIN" "$JO_USER_NAME" "$JO_USER_EMAIL"
}

ghc_et0() {
    local repo_name=$(_extract_repo_name "$1")
    _clone_and_config "$repo_name" "$ET0_DOMAIN" "$ET0_USER_NAME" "$ET0_USER_EMAIL"
}

# 通用检查函数，减少代码重复
_check_git_settings() {
    local domain="$1"
    local user_name="$2"
    local user_email="$3"

    # 检查是否是git项目
    if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) != "true" ]]; then
        echo "⚠️ not a git project"
        # 询问是否初始化git项目
        # 修复 read 命令在某些环境下不支持 -p 参数的问题，将提示信息单独输出
        echo -n "❓ Do you want to initialize a new git repository? (y/n) "
        read REPLY
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            # 配置git 项目，添加 remote url、user.name、user.email
            git init
            git remote add origin "git@${domain}:${user_name}/$(basename $(pwd))"
            git config --local user.name "$user_name"
            git config --local user.email "$user_email"
            echo "✅ git project initialized and configured"
        else
            echo "❌ git project initialization cancelled"
            return 1
        fi
    fi

    # 检查当前仓库的remote url
    local remote_url=$(git remote get-url origin)
    if [[ $remote_url =~ $domain ]]; then
        echo "✅ current remote url is $remote_url"
    else
        git remote set-url origin "git@${domain}:${user_name}/$(basename $(pwd))"
        echo "✅ remote url updated to git@${domain}:${user_name}/$(basename $(pwd))"
    fi

    # 检查当前仓库的user.name
    local name=$(git config --local user.name)
    if [[ $name == "$user_name" ]]; then
        echo "✅ current user.name is $user_name"
    else
        git config --local user.name "$user_name"
        echo "✅ user.name updated to $user_name"
    fi

    # 检查当前仓库的user.email
    local email=$(git config --local user.email)
    if [[ $email == "$user_email" ]]; then
        echo "✅ current user.email is $user_email"
    else
        git config --local user.email "$user_email"
        echo "✅ user.email updated to $user_email"
    fi
}

gh_check_for_jo() {
    _check_git_settings "$JO_DOMAIN" "$JO_USER_NAME" "$JO_USER_EMAIL"
}

gh_check_for_et0() {
    _check_git_settings "$ET0_DOMAIN" "$ET0_USER_NAME" "$ET0_USER_EMAIL"
}
