#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# Plugin Registry Management
# ============================================================
# Functions to manage the plugins registry.yaml file

# --- Registry Helper Functions ---

# Adds a plugin to the registry
registry_add_plugin() {
    local registry_file="$1"
    local plugin_name="$2"
    local source_url="$3"
    local version="${4:-1.0.0}"
    local is_dev="${5:-false}"
    local cmd_count="${6:-}"
    local categories="${7:-}"

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Create file if it doesn't exist
    if [ ! -f "$registry_file" ]; then
        cat > "$registry_file" << EOF
# Plugin Registry
version: "1.0.0"

plugins: []
EOF
    fi

    # Check if plugin already exists
    if grep -q "name: \"$plugin_name\"" "$registry_file" 2> /dev/null; then
        return 1
    fi

    # Build plugin entry using yq
    local plugin_index=$(yq eval '.plugins | length' "$registry_file" 2> /dev/null || echo 0)

    # Add basic plugin info
    yq eval -i ".plugins[$plugin_index].name = \"$plugin_name\"" "$registry_file"
    yq eval -i ".plugins[$plugin_index].source = \"$source_url\"" "$registry_file"
    yq eval -i ".plugins[$plugin_index].version = \"$version\"" "$registry_file"
    yq eval -i ".plugins[$plugin_index].installed_at = \"$timestamp\"" "$registry_file"

    # Add commands count if provided
    if [ -n "$cmd_count" ] && [ "$cmd_count" != "0" ]; then
        yq eval -i ".plugins[$plugin_index].commands = $cmd_count" "$registry_file"
    fi

    # Add categories if provided
    if [ -n "$categories" ]; then
        yq eval -i ".plugins[$plugin_index].categories = \"$categories\"" "$registry_file"
    fi

    # Add dev flag if it's a dev plugin
    if [ "$is_dev" = "true" ]; then
        yq eval -i ".plugins[$plugin_index].dev = true" "$registry_file"
    fi
}

# Removes a plugin from the registry
registry_remove_plugin() {
    local registry_file="$1"
    local plugin_name="$2"

    if [ ! -f "$registry_file" ]; then
        return 1
    fi

    # Use yq to remove the plugin entry
    yq eval -i "del(.plugins[] | select(.name == \"$plugin_name\"))" "$registry_file" 2> /dev/null || return 1

    return 0
}

# Lists all plugins from the registry
registry_list_plugins() {
    local registry_file="$1"

    if [ ! -f "$registry_file" ]; then
        return 0
    fi

    awk '
    /- name:/ {
        gsub(/.*name: "|".*/, "")
        name=$0
        getline; gsub(/.*source: "|".*/, ""); source=$0
        getline; gsub(/.*version: "|".*/, ""); version=$0
        getline; gsub(/.*installed_at: "|".*/, ""); installed=$0
        print name"|"source"|"version"|"installed
    }
    ' "$registry_file"
}

# Gets information about a specific plugin
registry_get_plugin_info() {
    local registry_file="$1"
    local plugin_name="$2"
    local field="$3" # source, version, installed_at

    if [ ! -f "$registry_file" ]; then
        return 1
    fi

    # Use yq to get the field value
    yq eval ".plugins[] | select(.name == \"$plugin_name\") | .$field" "$registry_file" 2> /dev/null
}
