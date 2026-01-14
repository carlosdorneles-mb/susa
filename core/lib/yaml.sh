#!/bin/bash

# ============================================================
# YAML Parser for Shell Script using yq
# ============================================================
# Parser to read YAML configurations (centralized and decentralized)

# Source registry lib
source "$LIB_DIR/registry.sh"
source "$LIB_DIR/dependencies.sh"

# Make sure yq is installed
ensure_yq_installed || {
    echo "Error: yq is required for Susa CLI to work" >&2
    exit 1
}

# ============================================================
# Lock File Functions
# ============================================================

# Check if lock file exists and is valid
has_valid_lock_file() {
    local cli_dir="${CLI_DIR:-$(dirname "$GLOBAL_CONFIG_FILE")}"
    local lock_file="$cli_dir/susa.lock"

    [ -f "$lock_file" ] && return 0
    return 1
}

# Get categories from lock file
get_categories_from_lock() {
    local cli_dir="${CLI_DIR:-$(dirname "$GLOBAL_CONFIG_FILE")}"
    local lock_file="$cli_dir/susa.lock"

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    yq eval '.categories[].name' "$lock_file" 2>/dev/null
}

# Get category info from lock file
get_category_info_from_lock() {
    local category="$1"
    local field="$2"  # name, description, source
    local cli_dir="${CLI_DIR:-$(dirname "$GLOBAL_CONFIG_FILE")}"
    local lock_file="$cli_dir/susa.lock"

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    yq eval ".categories[] | select(.name == \"$category\") | .$field" "$lock_file" 2>/dev/null
}

# Get commands from a category from lock file
get_category_commands_from_lock() {
    local category="$1"
    local cli_dir="${CLI_DIR:-$(dirname "$GLOBAL_CONFIG_FILE")}"
    local lock_file="$cli_dir/susa.lock"

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    # Get commands that match the exact category path
    yq eval ".commands[] | select(.category == \"$category\") | .name" "$lock_file" 2>/dev/null
}

# Get subcategories from a category from lock file
get_category_subcategories_from_lock() {
    local category="$1"
    local cli_dir="${CLI_DIR:-$(dirname "$GLOBAL_CONFIG_FILE")}"
    local lock_file="$cli_dir/susa.lock"

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    # Find all commands that start with "category/"
    # Extract the next level subcategory name
    local subcats=$(yq eval ".commands[].category" "$lock_file" 2>/dev/null | \
        grep "^${category}/" | \
        sed "s|^${category}/||" | \
        cut -d'/' -f1 | \
        sort -u)

    echo "$subcats"
}

# Get command metadata from lock file
get_command_info_from_lock() {
    local category="$1"
    local command="$2"
    local field="$3"  # description, os, sudo, group
    local cli_dir="${CLI_DIR:-$(dirname "$GLOBAL_CONFIG_FILE")}"
    local lock_file="$cli_dir/susa.lock"

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    yq eval ".commands[] | select(.category == \"$category\" and .name == \"$command\") | .$field" "$lock_file" 2>/dev/null
}

# Check if command is compatible with current OS from lock file
is_command_compatible_from_lock() {
    local category="$1"
    local command="$2"
    local current_os="$3"  # linux or mac
    local cli_dir="${CLI_DIR:-$(dirname "$GLOBAL_CONFIG_FILE")}"
    local lock_file="$cli_dir/susa.lock"

    if [ ! -f "$lock_file" ]; then
        # Fallback: check config.yaml directly if lock file doesn't exist
        local command_dir="$cli_dir/commands/$category/$command"
        local config_file="$command_dir/config.yaml"

        if [ -f "$config_file" ]; then
            local supported_os=$(yq eval '.os[]' "$config_file" 2>/dev/null)

            # If there's no OS restriction, it's compatible
            if [ -z "$supported_os" ]; then
                return 0
            fi

            # Check if current OS is in the list
            if echo "$supported_os" | grep -qw "$current_os"; then
                return 0
            fi

            return 1
        fi

        # If no config file found, assume incompatible
        return 1
    fi

    # Get the OS array for this command
    local supported_os=$(yq eval ".commands[] | select(.category == \"$category\" and .name == \"$command\") | .os[]" "$lock_file" 2>/dev/null)

    # If there's no OS restriction, it's compatible
    if [ -z "$supported_os" ]; then
        return 0
    fi

    # Check if current OS is in the list
    if echo "$supported_os" | grep -qw "$current_os"; then
        return 0
    fi

    return 1
}

# --- Functions for Global Config (cli.yaml) ---

# Function to get global YAML fields (name, description, version)
get_yaml_field() {
    local yaml_file="$1"
    local field="$2"  # name, description, version, commands_dir, plugins_dir

    if [ ! -f "$yaml_file" ]; then
        return 1
    fi

    yq eval ".$field" "$yaml_file" 2>/dev/null
}

# Get all categories from lock file only
get_all_categories() {
    local yaml_file="$1"

    # Only read from lock file - no fallback
    if has_valid_lock_file; then
        get_categories_from_lock
        return 0
    fi

    # If lock file doesn't exist, return empty
    return 1
}

# Function to get information about a category or subcategory from lock file only
get_category_info() {
    local yaml_file="$1"
    local category="$2"
    local field="$3"  # name or description

    # Only read from lock file - no fallback
    if has_valid_lock_file; then
        local value=$(get_category_info_from_lock "$category" "$field")
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
            return 0
        fi
    fi

    # If lock file doesn't exist or value not found, return empty
    return 1
}

# Gets commands from a category from lock file only
get_category_commands() {
    local cli_dir="${CLI_DIR:-$(dirname "$GLOBAL_CONFIG_FILE")}"
    local category="$1"
    local current_os="${2:-}"  # Optional OS filter

    # Only read from lock file - no fallback
    if has_valid_lock_file; then
        local commands=$(get_category_commands_from_lock "$category")

        # If OS filter is provided, filter commands by compatibility
        if [ -n "$current_os" ]; then
            local filtered_commands=""
            for cmd in $commands; do
                if is_command_compatible_from_lock "$category" "$cmd" "$current_os"; then
                    filtered_commands="${filtered_commands}${cmd}"$'\n'
                fi
            done
            echo "$filtered_commands" | grep -v '^$'
        else
            echo "$commands"
        fi
        return 0
    fi

    # If lock file doesn't exist, return empty
    return 1
}

# Gets subcategories from a category from lock file only
get_category_subcategories() {
    local cli_dir="${CLI_DIR:-$(dirname "$GLOBAL_CONFIG_FILE")}"
    local category="$1"

    # Only read from lock file - no fallback
    if has_valid_lock_file; then
        get_category_subcategories_from_lock "$category"
        return 0
    fi

    # If lock file doesn't exist, return empty
    return 1
}

# ============================================================
# CONFIG FILE READING FUNCTIONS
# These functions are used ONLY by 'susa self lock' to generate the lock file
# and for finding the script path when executing commands
# The CLI does NOT read config files for metadata in runtime
# ============================================================

# Reads a field from a command config
# WARNING: Used only by 'susa self lock' and for script path lookup
get_command_config_field() {
    local config_file="$1"
    local field="$2"

    if [ ! -f "$config_file" ]; then
        return 1
    fi

    local value=$(yq eval ".$field" "$config_file" 2>/dev/null)

    # If it's an array or list, convert to compatible format
    if echo "$value" | grep -q '^\['; then
        echo "$value" | sed 's/\[//g' | sed 's/\]//g' | sed 's/, /,/g'
    elif [ "$value" != "null" ]; then
        echo "$value"
    fi
}

# Finds the config file of a command based on directory path
# WARNING: Used only for finding script path when executing commands
find_command_config() {
    local category="$1"       # Can be "install" or "install/python"
    local command_id="$2"
    local cli_dir="${CLI_DIR:-$(dirname "$GLOBAL_CONFIG_FILE")}"

    # Search in commands/
    local config_path="$cli_dir/commands/$category/$command_id/config.yaml"
    if [ -f "$config_path" ]; then
        echo "$config_path"
        return 0
    fi

    # Search in plugins/
    if [ -d "$cli_dir/plugins" ]; then
        for plugin_dir in "$cli_dir/plugins"/*; do
            [ ! -d "$plugin_dir" ] && continue
            local plugin_name=$(basename "$plugin_dir")

            # Ignore special files
            [ "$plugin_name" = "registry.yaml" ] && continue
            [ "$plugin_name" = "README.md" ] && continue

            config_path="$plugin_dir/$category/$command_id/config.yaml"
            if [ -f "$config_path" ]; then
                echo "$config_path"
                return 0
            fi
        done
    fi

    return 1
}

# Checks if a command is from a plugin
is_plugin_command() {
    local category="$1"
    local command_id="$2"
    local config_file=$(find_command_config "$category" "$command_id")

    if [ -n "$config_file" ] && [[ "$config_file" == */plugins/* ]]; then
        return 0
    fi

    return 1
}

# Gets information from a specific command from lock file only
get_command_info() {
    local yaml_file="$1"  # Kept for compatibility, but not used
    local category="$2"
    local command_id="$3"
    local field="$4"  # name, description, script, sudo, os, group

    # Only read from lock file
    if has_valid_lock_file; then
        local value=$(get_command_info_from_lock "$category" "$command_id" "$field")
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
            return 0
        fi
    fi

    # Fallback: read directly from config.yaml if lock file doesn't exist
    local cli_dir="${CLI_DIR:-$(dirname "$GLOBAL_CONFIG_FILE")}"
    local command_dir="$cli_dir/commands/$category/$command_id"
    local config_file="$command_dir/config.yaml"

    if [ -f "$config_file" ]; then
        local value=$(yq eval ".$field" "$config_file" 2>/dev/null)
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
            return 0
        fi
    fi

    # If lock file doesn't exist or value not found, return empty
    return 1
}

# Function to check if command is compatible with current OS from lock file only
is_command_compatible() {
    local yaml_file="$1"  # Kept for compatibility
    local category="$2"
    local command_id="$3"
    local current_os="$4"  # linux or mac

    # Use lock file function directly
    is_command_compatible_from_lock "$category" "$command_id" "$current_os"
}

# Function to check if command requires sudo from lock file only
requires_sudo() {
    local yaml_file="$1"  # Kept for compatibility
    local category="$2"
    local command_id="$3"

    # Only read from lock file
    if has_valid_lock_file; then
        local needs_sudo=$(get_command_info_from_lock "$category" "$command_id" "sudo")
        if [ "$needs_sudo" = "true" ]; then
            return 0
        fi
    fi

    return 1
}

# Function to get the group of a command from lock file only
get_command_group() {
    local yaml_file="$1"  # Kept for compatibility
    local category="$2"
    local command_id="$3"

    # Only read from lock file
    if has_valid_lock_file; then
        local group=$(get_command_info_from_lock "$category" "$command_id" "group")
        if [ -n "$group" ] && [ "$group" != "null" ]; then
            echo "$group"
            return 0
        fi
    fi

    return 1
}

# Function to get unique list of groups in a category
get_category_groups() {
    local yaml_file="$1"  # Kept for compatibility
    local category="$2"
    local current_os="$3"

    local commands=$(get_category_commands "$category")
    local groups=""

    for cmd in $commands; do
        # Skip incompatible commands
        if ! is_command_compatible "$yaml_file" "$category" "$cmd" "$current_os"; then
            continue
        fi

        local group=$(get_command_group "$yaml_file" "$category" "$cmd")

        if [ -n "$group" ]; then
            # Add group if not already in the list
            if ! echo "$groups" | grep -qw "$group"; then
                groups="${groups}${group}"$'\n'
            fi
        fi
    done

    echo "$groups" | grep -v '^$'
}


