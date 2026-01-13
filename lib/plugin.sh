#!/bin/bash

# ============================================================
# Plugin Helper Functions
# ============================================================

# --- Plugin Helper Functions ---

# Checks if git is installed
ensure_git_installed() {
    if ! command -v git &>/dev/null; then
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

# Detects the version of a plugin in the directory
detect_plugin_version() {
    local plugin_dir="$1"
    local version="0.0.0"

    if [ -f "$plugin_dir/version.txt" ]; then
        version=$(cat "$plugin_dir/version.txt" | tr -d '\n')
    elif [ -f "$plugin_dir/VERSION" ]; then
        version=$(cat "$plugin_dir/VERSION" | tr -d '\n')
    elif [ -f "$plugin_dir/.version" ]; then
        version=$(cat "$plugin_dir/.version" | tr -d '\n')
    fi

    echo "$version"
}

# Counts commands from a plugin
count_plugin_commands() {
    local plugin_dir="$1"
    find "$plugin_dir" -name "config.yaml" -type f | wc -l
}

# Validates if repository is accessible
validate_repo_access() {
    local url="$1"

    log_debug "Validando acesso ao repositório..."

    # Use git ls-remote to check if we can access the repo
    if git ls-remote "$url" HEAD &>/dev/null; then
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

# Converts user/repo to full GitHub URL
# Supports --ssh flag to force SSH URLs
normalize_git_url() {
    local url="$1"
    local force_ssh="${2:-false}"

    # If it's user/repo format, convert to full URL
    if [[ "$url" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]; then
        # Use SSH if forced or if user has SSH access
        if [ "$force_ssh" = "true" ] || has_github_ssh_access; then
            echo "git@github.com:${url}.git"
        else
            echo "https://github.com/${url}.git"
        fi
    else
        # If force_ssh and it's an HTTPS GitHub URL, convert to SSH
        if [ "$force_ssh" = "true" ] && [[ "$url" =~ ^https://github.com/ ]]; then
            # Convert https://github.com/user/repo.git to git@github.com:user/repo.git
            echo "$url" | sed 's|https://github.com/|git@github.com:|'
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
