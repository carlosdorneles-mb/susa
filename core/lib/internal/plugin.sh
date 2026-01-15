#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# Plugin Helper Functions
# ============================================================

# --- Plugin Helper Functions ---

# Checks if git is installed
ensure_git_installed() {
    if ! command -v git &> /dev/null; then
        log_error "Git not found. Install git first."
        return 1
    fi
    return 0
}

# Checks if user has SSH access to GitHub configured
has_github_ssh_access() {
    # Check if SSH key exists
    if [ ! -f "$HOME/.ssh/id_rsa" ] && [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        return 1
    fi

    # Test SSH connection to GitHub (timeout after 3 seconds)
    if timeout 3 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        return 0
    fi

    return 1
}

# Checks if user has SSH access to GitLab configured
has_gitlab_ssh_access() {
    # Check if SSH key exists
    if [ ! -f "$HOME/.ssh/id_rsa" ] && [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        return 1
    fi

    # Test SSH connection to GitLab (timeout after 3 seconds)
    if timeout 3 ssh -T git@gitlab.com 2>&1 | grep -q "Welcome to GitLab"; then
        return 0
    fi

    return 1
}

# Checks if user has SSH access to Bitbucket configured
has_bitbucket_ssh_access() {
    # Check if SSH key exists
    if [ ! -f "$HOME/.ssh/id_rsa" ] && [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        return 1
    fi

    # Test SSH connection to Bitbucket (timeout after 3 seconds)
    if timeout 3 ssh -T git@bitbucket.org 2>&1 | grep -q "authenticated"; then
        return 0
    fi

    return 1
}

# Detects Git provider from URL
detect_git_provider() {
    local url="$1"

    if [[ "$url" =~ github\.com ]]; then
        echo "github"
    elif [[ "$url" =~ gitlab\.com ]]; then
        echo "gitlab"
    elif [[ "$url" =~ bitbucket\.org ]]; then
        echo "bitbucket"
    else
        echo "unknown"
    fi
}

# Detects the version of a plugin in the directory
detect_plugin_version() {
    local plugin_dir="$1"
    local version="0.0.0"

    if [ -f "$plugin_dir/version.txt" ]; then
        version=$(cat "$plugin_dir/version.txt" | tr -d '\n')
    fi

    echo "$version"
}

# Counts commands from a plugin
count_plugin_commands() {
    local plugin_dir="$1"
    find "$plugin_dir" -type f -name "main.sh" 2> /dev/null | wc -l | xargs
}

# Gets plugin categories (first-level directories excluding .git)
get_plugin_categories() {
    local plugin_dir="$1"
    find "$plugin_dir" -mindepth 1 -maxdepth 1 -type d ! -name ".git" -exec basename {} \; 2> /dev/null | sort | paste -sd "," -
}

# Updates the lock file (creates if doesn't exist)
update_lock_file() {
    log_info "Atualizando arquivo susa.lock..."
    log_debug "Executando: $CORE_DIR/susa self lock"

    if "$CORE_DIR/susa" self lock > /dev/null 2>&1; then
        log_debug "Lock file atualizado com sucesso"
    else
        log_warning "Não foi possível atualizar o susa.lock. Execute 'susa self lock' manualmente."
        log_debug "Você pode precisar executar: susa self lock"
    fi
}

# Validates if repository is accessible
validate_repo_access() {
    local url="$1"

    log_debug "Validando acesso ao repositório..."

    # Use git ls-remote to check if we can access the repo
    if git ls-remote "$url" HEAD &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Clones plugin from a Git repository
clone_plugin() {
    local url="$1"
    local dest_dir="$2"

    if git clone "$url" "$dest_dir" 2>&1; then
        # Remove .git to save space
        rm -rf "$dest_dir/.git"
        return 0
    else
        return 1
    fi
}

# Converts user/repo to full Git URL
# Supports GitHub, GitLab and Bitbucket
# Supports --ssh flag to force SSH URLs
normalize_git_url() {
    local url="$1"
    local force_ssh="${2:-false}"
    local provider="${3:-github}" # Default to GitHub for backwards compatibility

    # If it's user/repo format, convert to full URL
    if [[ "$url" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]; then
        local should_use_ssh="$force_ssh"

        # Auto-detect SSH if not forced
        if [ "$force_ssh" != "true" ]; then
            case "$provider" in
                github)
                    if has_github_ssh_access; then
                        should_use_ssh="true"
                    fi
                    ;;
                gitlab)
                    if has_gitlab_ssh_access; then
                        should_use_ssh="true"
                    fi
                    ;;
                bitbucket)
                    if has_bitbucket_ssh_access; then
                        should_use_ssh="true"
                    fi
                    ;;
            esac
        fi

        # Generate URL based on provider
        if [ "$should_use_ssh" = "true" ]; then
            case "$provider" in
                github)
                    echo "git@github.com:${url}.git"
                    ;;
                gitlab)
                    echo "git@gitlab.com:${url}.git"
                    ;;
                bitbucket)
                    echo "git@bitbucket.org:${url}.git"
                    ;;
            esac
        else
            case "$provider" in
                github)
                    echo "https://github.com/${url}.git"
                    ;;
                gitlab)
                    echo "https://gitlab.com/${url}.git"
                    ;;
                bitbucket)
                    echo "https://bitbucket.org/${url}.git"
                    ;;
            esac
        fi
    else
        # Full URL provided
        local detected_provider=$(detect_git_provider "$url")

        # If force_ssh and it's an HTTPS URL, convert to SSH
        if [ "$force_ssh" = "true" ]; then
            case "$detected_provider" in
                github)
                    if [[ "$url" =~ ^https://github.com/ ]]; then
                        echo "$url" | sed 's|https://github.com/|git@github.com:|'
                    else
                        echo "$url"
                    fi
                    ;;
                gitlab)
                    if [[ "$url" =~ ^https://gitlab.com/ ]]; then
                        echo "$url" | sed 's|https://gitlab.com/|git@gitlab.com:|'
                    else
                        echo "$url"
                    fi
                    ;;
                bitbucket)
                    if [[ "$url" =~ ^https://bitbucket.org/ ]]; then
                        echo "$url" | sed 's|https://bitbucket.org/|git@bitbucket.org:|'
                    else
                        echo "$url"
                    fi
                    ;;
                *)
                    echo "$url"
                    ;;
            esac
        else
            echo "$url"
        fi
    fi
}

# Extracts plugin name from URL
extract_plugin_name() {
    local url="$1"
    basename "$url" .git
}
