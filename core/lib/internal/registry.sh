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

# Checks if a plugin exists in registry by name
# Returns: 0 if exists, 1 if not
registry_plugin_exists() {
    local registry_file="$1"
    local plugin_name="$2"

    if [ ! -f "$registry_file" ]; then
        return 1
    fi

    local count=$(jq -r ".plugins[] | select(.name == \"$plugin_name\") | .name // empty" "$registry_file" 2> /dev/null | wc -l)
    [ "$count" -gt 0 ] && return 0
    return 1
}

# Finds a plugin by source path (useful for dev plugins)
# Returns: plugin name if found, empty if not found
registry_get_plugin_by_source() {
    local registry_file="$1"
    local source_path="$2"

    if [ ! -f "$registry_file" ]; then
        return 1
    fi

    # Normalize paths for comparison
    local normalized_source="$(cd "$(dirname "$source_path")" 2> /dev/null && pwd)/$(basename "$source_path")" || normalized_source="$source_path"

    # Find plugin with matching source
    jq -r ".plugins[] | select(.source == \"$normalized_source\" or .source == \"$source_path\") | .name // empty" "$registry_file" 2> /dev/null | head -1
}

# Checks if a plugin is in dev mode
# Returns: 0 if dev mode, 1 if not
registry_is_dev_plugin() {
    local registry_file="$1"
    local plugin_name="$2"

    if [ ! -f "$registry_file" ]; then
        return 1
    fi

    local dev_flag=$(jq -r ".plugins[] | select(.name == \"$plugin_name\") | .dev // false" "$registry_file" 2> /dev/null | head -1)
    [ "$dev_flag" = "true" ] && return 0
    return 1
}

# Counts total number of plugins in registry
# Returns: number of plugins
registry_count_plugins() {
    local registry_file="$1"

    if [ ! -f "$registry_file" ]; then
        echo "0"
        return 0
    fi

    jq '.plugins | length' "$registry_file" 2> /dev/null || echo "0"
}

# Gets all plugin names from registry
# Returns: newline-separated list of plugin names
registry_get_all_plugin_names() {
    local registry_file="$1"

    if [ ! -f "$registry_file" ]; then
        return 0
    fi

    jq -r '.plugins[].name // empty' "$registry_file" 2> /dev/null
}
