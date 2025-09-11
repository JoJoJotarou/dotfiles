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

# 具体用户函数
ghc.jo() {
    local repo_name=$(_extract_repo_name "$1")
    _clone_and_config "$repo_name" "jojojotarou.github.com" "JoJoJotarou" "58281079+JoJoJotarou@users.noreply.github.com"
}

ghc.et0() {
    local repo_name=$(_extract_repo_name "$1")
    _clone_and_config "$repo_name" "enjoytech0.github.com" "EnjoyTech0" "104669762+EnjoyTech0@users.noreply.github.com"
}