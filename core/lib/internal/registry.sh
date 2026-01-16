#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# Plugin Registry Management
# ============================================================
# Functions to manage the plugins registry.json file

# --- Registry Helper Functions ---

# Ensure registry.json file exists
ensure_registry_exists() {
    local registry_file="$1"

    if [ -f "$registry_file" ]; then
        return 0
    fi

    log_debug "Creating registry.json file"
    cat > "$registry_file" << 'EOF'
{
  "version": "1.0.0",
  "plugins": []
}
EOF
}

# Adds a plugin to the registry
registry_add_plugin() {
    local registry_file="$1"
    local plugin_name="$2"
    local source_url="$3"
    local version="${4:-1.0.0}"
    local is_dev="${5:-false}"
    local cmd_count="${6:-}"
    local categories="${7:-}"
    local description="${8:-}"
    local directory="${9:-}"

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Create file if it doesn't exist
    if [ ! -f "$registry_file" ]; then
        cat > "$registry_file" << EOF
{
  "version": "1.0.0",
  "plugins": []
}
EOF
    fi

    # Check if plugin already exists
    if jq -e ".plugins[] | select(.name == \"$plugin_name\")" "$registry_file" &> /dev/null; then
        return 1
    fi

    # Build plugin entry using jq
    local new_plugin=$(jq -n \
        --arg name "$plugin_name" \
        --arg source "$source_url" \
        --arg version "$version" \
        --arg installed "$timestamp" \
        '{name: $name, source: $source, version: $version, installedAt: $installed}')

    # Add description if provided
    if [ -n "$description" ]; then
        new_plugin=$(echo "$new_plugin" | jq --arg desc "$description" '. + {description: $desc}')
    fi

    # Add commands count if provided
    if [ -n "$cmd_count" ] && [ "$cmd_count" != "0" ]; then
        new_plugin=$(echo "$new_plugin" | jq --argjson cmds "$cmd_count" '. + {commands: $cmds}')
    fi

    # Add categories if provided
    if [ -n "$categories" ]; then
        new_plugin=$(echo "$new_plugin" | jq --arg cats "$categories" '. + {categories: $cats}')
    fi

    # Add directory if provided
    if [ -n "$directory" ]; then
        new_plugin=$(echo "$new_plugin" | jq --arg dir "$directory" '. + {directory: $dir}')
    fi

    # Add dev flag if it's a dev plugin
    if [ "$is_dev" = "true" ]; then
        new_plugin=$(echo "$new_plugin" | jq '. + {dev: true}')
    fi

    # Add the new plugin to the registry
    jq ".plugins += [$new_plugin]" "$registry_file" > "$registry_file.tmp" && mv "$registry_file.tmp" "$registry_file"
}

# Removes a plugin from the registry
registry_remove_plugin() {
    local registry_file="$1"
    local plugin_name="$2"

    if [ ! -f "$registry_file" ]; then
        return 1
    fi

    # Use jq to remove the plugin entry
    jq "del(.plugins[] | select(.name == \"$plugin_name\"))" "$registry_file" > "$registry_file.tmp" && mv "$registry_file.tmp" "$registry_file"

    return 0
}

# Lists all plugins from the registry
registry_list_plugins() {
    local registry_file="$1"

    if [ ! -f "$registry_file" ]; then
        return 0
    fi

    # Use jq to format output
    jq -r '.plugins[] | "\(.name)|\(.source)|\(.version)|\(.installedAt)"' "$registry_file" 2> /dev/null
}

# Gets information about a specific plugin
registry_get_plugin_info() {
    local registry_file="$1"
    local plugin_name="$2"
    local field="$3" # source, version, installedAt

    if [ ! -f "$registry_file" ]; then
        return 1
    fi

    # Use jq to get the field value
    jq -r ".plugins[] | select(.name == \"$plugin_name\") | .$field // empty" "$registry_file" 2> /dev/null
}
