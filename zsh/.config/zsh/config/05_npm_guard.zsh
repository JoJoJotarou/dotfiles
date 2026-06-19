npm() {
    local has_global=0
    local has_global_command=0
    local previous_arg=""

    for arg in "$@"; do
        if [[ "$previous_arg" == "--location" && "$arg" == "global" ]]; then
            has_global=1
        fi

        case "$arg" in
            -g|--global|--global=true|--location=global)
                has_global=1
                ;;
            i|install|add)
                has_global_command=1
                ;;
        esac

        previous_arg="$arg"
    done

    if (( has_global && has_global_command )); then
        echo "Blocked: use pnpm global instead of npm -g"
        echo "Try: pnpm add -g <package>"
        return 64
    fi

    command npm "$@"
}
