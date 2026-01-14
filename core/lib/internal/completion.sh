#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# Susa CLI - Completion Helper Functions
# ============================================================

# Get completion file path for a shell
# Arguments:
#   $1 - shell type (bash, zsh)
# Returns: file path
get_completion_file_path() {
    local shell_type="${1:-}"

    case "$shell_type" in
        bash)
            echo "$HOME/.local/share/bash-completion/completions/susa"
            ;;
        zsh)
            echo "$HOME/.local/share/zsh/site-functions/_susa"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Get completion directory path for a shell
# Arguments:
#   $1 - shell type (bash, zsh)
# Returns: directory path
get_completion_dir_path() {
    local shell_type="${1:-}"

    case "$shell_type" in
        bash)
            echo "$HOME/.local/share/bash-completion/completions"
            ;;
        zsh)
            echo "$HOME/.local/share/zsh/site-functions"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Check if shell completion is installed
# Returns:
#   0 - Completion is installed
#   1 - Completion is not installed
is_completion_installed() {
    local shell_type="${1:-}"

    # If no shell specified, detect current shell
    if [[ -z "$shell_type" ]]; then
        shell_type=$(detect_shell_type)
    fi

    local completion_file=$(get_completion_file_path "$shell_type")
    [[ -n "$completion_file" && -f "$completion_file" ]] && return 0

    return 1
}

# Get completion installation status with details
# Returns status string with details
get_completion_status() {
    local shell_type="${1:-}"

    # If no shell specified, detect current shell
    if [[ -z "$shell_type" ]]; then
        shell_type=$(detect_shell_type)
    fi

    local comp_status="Not installed"
    local details=""
    local completion_file=$(get_completion_file_path "$shell_type")

    if [[ -z "$completion_file" ]]; then
        comp_status="Unknown"
        details="Shell não suportado"
    elif [[ -f "$completion_file" ]]; then
        comp_status="Installed"

        # Check if completion is loaded in current shell
        if is_completion_loaded "$shell_type"; then
            details="carregado no shell atual"
        else
            # Check if configured in shell config
            local shell_config="$HOME/.${shell_type}rc"
            local search_pattern="site-functions"
            [[ "$shell_type" == "bash" ]] && search_pattern="bash-completion"

            if [[ -f "$shell_config" ]] && grep -q "$search_pattern" "$shell_config" 2>/dev/null; then
                details="configurado em ~/.${shell_type}rc (reinicie o shell para carregar)"
            else
                details="arquivo existe (pode ser necessário reiniciar o shell)"
            fi
        fi
    else
        details="Execute: susa self completion --install"
    fi

    # Return status:details format
    echo "$comp_status:$details:$completion_file"
}

# Check if completion is loaded in current shell
# Returns:
#   0 - Completion is loaded
#   1 - Completion is not loaded
is_completion_loaded() {
    local shell_type="${1:-}"

    # If no shell specified, detect current shell
    if [[ -z "$shell_type" ]]; then
        shell_type=$(detect_shell_type)
    fi

    case "$shell_type" in
        bash)
            type _susa_completion &> /dev/null 2>&1 && return 0
            ;;
        zsh)
            type _susa &> /dev/null 2>&1 && return 0
            ;;
        *)
            return 1
            ;;
    esac

    return 1
}
