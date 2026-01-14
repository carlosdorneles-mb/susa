#!/bin/bash

# ============================================================
# Installation Tracking Library
# ============================================================
# Functions to track software installations in lock file

# Ensure yq is available
source "$LIB_DIR/dependencies.sh"
ensure_yq_installed || {
    echo "Error: yq is required" >&2
    exit 1
}

# Get lock file path
get_lock_file_path() {
    echo "${CLI_DIR}/susa.lock"
}

# Mark software as installed in lock file
# Usage: mark_installed "docker" "24.0.5"
mark_installed() {
    local software_name="$1"
    local version="${2:-unknown}"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        log_warning "Lock file not found. Run 'susa self lock' first."
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Check if installations section exists
    if ! yq eval '.installations' "$lock_file" &>/dev/null || [ "$(yq eval '.installations' "$lock_file")" = "null" ]; then
        # Create installations section
        yq eval -i '.installations = []' "$lock_file"
    fi

    # Check if software already tracked
    local exists=$(yq eval ".installations[] | select(.name == \"$software_name\") | .name" "$lock_file" 2>/dev/null)

    if [ -n "$exists" ] && [ "$exists" != "null" ]; then
        # Update existing entry
        yq eval -i "(.installations[] | select(.name == \"$software_name\") | .installed) = true" "$lock_file"
        yq eval -i "(.installations[] | select(.name == \"$software_name\") | .version) = \"$version\"" "$lock_file"
        yq eval -i "(.installations[] | select(.name == \"$software_name\") | .installed_at) = \"$timestamp\"" "$lock_file"
    else
        # Add new entry
        yq eval -i ".installations += [{\"name\": \"$software_name\", \"installed\": true, \"version\": \"$version\", \"installed_at\": \"$timestamp\"}]" "$lock_file"
    fi

    return 0
}

# Mark software as uninstalled in lock file
# Usage: mark_uninstalled "docker"
mark_uninstalled() {
    local software_name="$1"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 0
    fi

    # Check if software is tracked
    local exists=$(yq eval ".installations[] | select(.name == \"$software_name\") | .name" "$lock_file" 2>/dev/null)

    if [ -n "$exists" ] && [ "$exists" != "null" ]; then
        # Mark as uninstalled and clear version
        yq eval -i "(.installations[] | select(.name == \"$software_name\") | .installed) = false" "$lock_file"
        yq eval -i "(.installations[] | select(.name == \"$software_name\") | .version) = null" "$lock_file"
        yq eval -i "del(.installations[] | select(.name == \"$software_name\") | .installed_at)" "$lock_file"
    fi

    return 0
}

# Update software version in lock file
# Usage: update_version "docker" "24.0.6"
update_version() {
    local software_name="$1"
    local version="$2"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Check if software is tracked
    local exists=$(yq eval ".installations[] | select(.name == \"$software_name\") | .name" "$lock_file" 2>/dev/null)

    if [ -n "$exists" ] && [ "$exists" != "null" ]; then
        yq eval -i "(.installations[] | select(.name == \"$software_name\") | .version) = \"$version\"" "$lock_file"
        yq eval -i "(.installations[] | select(.name == \"$software_name\") | .updated_at) = \"$timestamp\"" "$lock_file"
        return 0
    fi

    return 1
}

# Check if software is installed
# Usage: if is_installed "docker"; then ...
is_installed() {
    local software_name="$1"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    local installed=$(yq eval ".installations[] | select(.name == \"$software_name\") | .installed" "$lock_file" 2>/dev/null)

    if [ "$installed" = "true" ]; then
        return 0
    fi

    return 1
}

# Get installed version
# Usage: version=$(get_installed_version "docker")
get_installed_version() {
    local software_name="$1"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    local version=$(yq eval ".installations[] | select(.name == \"$software_name\") | .version" "$lock_file" 2>/dev/null)

    if [ -n "$version" ] && [ "$version" != "null" ]; then
        echo "$version"
        return 0
    fi

    return 1
}

# Get installation info
# Usage: get_installation_info "docker"
get_installation_info() {
    local software_name="$1"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    yq eval ".installations[] | select(.name == \"$software_name\")" "$lock_file" 2>/dev/null
    return 0
}

# List all installed software
# Usage: list_installed
list_installed() {
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    yq eval '.installations[] | select(.installed == true) | .name' "$lock_file" 2>/dev/null
    return 0
}
