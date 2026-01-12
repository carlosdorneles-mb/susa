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

# Detects the version of a plugin in the directory
detect_plugin_version() {
    local plugin_dir="$1"
    local version="1.0.0"
    
    if [ -f "$plugin_dir/version.txt" ]; then
        version=$(cat "$plugin_dir/version.txt" | tr -d '\n')
    elif [ -f "$plugin_dir/VERSION" ]; then
        version=$(cat "$plugin_dir/VERSION" | tr -d '\n')
    fi
    
    echo "$version"
}

# Counts commands from a plugin
count_plugin_commands() {
    local plugin_dir="$1"
    find "$plugin_dir" -name "config.yaml" -type f | wc -l
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
normalize_git_url() {
    local url="$1"
    
    # If it's user/repo format, convert to full URL
    if [[ "$url" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]; then
        echo "https://github.com/${url}.git"
    else
        echo "$url"
    fi
}

# Extracts plugin name from URL
extract_plugin_name() {
    local url="$1"
    basename "$url" .git
}
