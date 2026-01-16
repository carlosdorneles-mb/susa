#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# Config Parser for Shell Script using jq
# ============================================================
# Parser to read JSON configurations (centralized and decentralized)

# Source registry lib
source "$LIB_DIR/internal/registry.sh"
source "$LIB_DIR/internal/json.sh"
source "$LIB_DIR/internal/cache.sh"
source "$LIB_DIR/internal/plugin.sh"

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
    cache_get_categories
}

# Get category info from lock file
get_category_info_from_lock() {
    local category="$1"
    local field="$2" # name, description, source

    cache_get_category_info "$category" "$field"
}

# Get commands from a category from lock file
get_category_commands_from_lock() {
    local category="$1"

    cache_get_category_commands "$category"
}

# Get subcategories from a category from lock file
get_category_subcategories_from_lock() {
    local category="$1"

    # Find all commands that start with "category/"
    # Extract the next level subcategory name
    local subcats=$(cache_query '.commands[].category' |
        grep "^${category}/" |
        sed "s|^${category}/||" |
        cut -d'/' -f1 |
        sort -u)

    echo "$subcats"
}

# Get command metadata from lock file
get_command_info_from_lock() {
    local category="$1"
    local command="$2"
    local field="$3" # description, os, sudo, group

    cache_get_command_info "$category" "$command" "$field"
}

# Check if command is compatible with current OS from lock file
is_command_compatible_from_lock() {
    local category="$1"
    local command="$2"
    local current_os="$3" # linux or mac

    # Get the OS array for this command from cache
    local supported_os=$(cache_query ".commands[] | select(.category == \"$category\" and .name == \"$command\") | .os[]" 2> /dev/null)

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

# --- Functions for Global Config (cli.json) ---

# Function to get global config fields (name, description, version)
get_config_field() {
    local config_file="$1"
    local field="$2" # name, description, version

    if [ ! -f "$config_file" ]; then
        return 1
    fi

    # Use JSON parser (all configs are now JSON)
    json_get_config_field "$config_file" "$field"
}

# Get CLI name and version formatted
# Usage: show_version
show_version() {
    local name=$(get_config_field "$GLOBAL_CONFIG_FILE" "name")
    local version=$(get_config_field "$GLOBAL_CONFIG_FILE" "version")
    echo -e "${BOLD}$name${NC} (versão ${GRAY}$version${NC})"
}

# Get CLI version number only
# Usage: show_number_version
show_number_version() {
    local version=$(get_config_field "$GLOBAL_CONFIG_FILE" "version")
    echo "$version"
}

# Get all categories from lock file only
get_all_categories() {
    local config_file="$1"

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
    local config_file="$1"
    local category="$2"
    local field="$3" # name or description

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
    local current_os="${2:-}" # Optional OS filter

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

# Check if a category has an entrypoint script
category_has_entrypoint() {
    local category="$1"

    if ! has_valid_lock_file; then
        return 1
    fi

    local entrypoint=$(jq -r ".categories[] | select(.name == \"$category\") | .entrypoint // empty" "$CLI_DIR/susa.lock" 2> /dev/null)

    if [ -n "$entrypoint" ] && [ "$entrypoint" != "null" ]; then
        return 0
    fi

    return 1
}

# Get the entrypoint path for a category
get_category_entrypoint_path() {
    local category="$1"

    if ! category_has_entrypoint "$category"; then
        return 1
    fi

    local lock_file="$CLI_DIR/susa.lock"
    local entrypoint=$(jq -r ".categories[] | select(.name == \"$category\") | .entrypoint // empty" "$lock_file" 2> /dev/null)

    if [ -z "$entrypoint" ] || [ "$entrypoint" = "null" ]; then
        return 1
    fi

    # Check if category belongs to a plugin by looking at commands in that category
    local plugin_name=$(jq -r ".commands[] | select(.category == \"$category\" or (.category | startswith(\"$category/\"))) | .plugin.name // empty" "$lock_file" 2> /dev/null | head -1)

    if [ -n "$plugin_name" ] && [ "$plugin_name" != "null" ]; then
        # Category is from a plugin
        local plugin_source=$(jq -r ".commands[] | select(.category == \"$category\" or (.category | startswith(\"$category/\"))) | .plugin.source // empty" "$lock_file" 2> /dev/null | head -1)

        # Determine plugin directory
        local plugin_dir=""
        if [ -n "$plugin_source" ] && [ "$plugin_source" != "null" ] && [ "$plugin_source" != "" ]; then
            # Dev plugin or plugin with source path
            plugin_dir="$plugin_source"
        else
            # Regular installed plugin
            plugin_dir="$CLI_DIR/plugins/$plugin_name"
        fi

        # Check if plugin has a custom commands directory
        local commands_subdir=$(get_plugin_directory "$plugin_dir")
        local script_path=""

        if [ -n "$commands_subdir" ] && [ "$commands_subdir" != "" ]; then
            script_path="$plugin_dir/$commands_subdir/$category/$entrypoint"
        else
            script_path="$plugin_dir/$category/$entrypoint"
        fi

        if [ -f "$script_path" ]; then
            echo "$script_path"
            return 0
        fi
    else
        # Category is from commands/
        local script_path="$CLI_DIR/commands/$category/$entrypoint"

        if [ -f "$script_path" ]; then
            echo "$script_path"
            return 0
        fi
    fi

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

    # Use jq to read JSON config
    local value=$(jq -r ".$field // empty" "$config_file" 2> /dev/null)

    if [ -n "$value" ]; then
        echo "$value"
    fi
}

# Finds the config file of a command based on directory path
# WARNING: Used only for finding script path when executing commands
find_command_config() {
    local category="$1" # Can be "install" or "install/python"
    local command_id="$2"
    local cli_dir="${CLI_DIR:-$(dirname "$GLOBAL_CONFIG_FILE")}"

    # First check if it's a plugin command in lock (has source)
    if has_valid_lock_file; then
        local plugin_source=$(cache_query ".commands[] | select(.category == \"$category\" and .name == \"$command_id\" and .plugin != null) | .plugin.source" 2> /dev/null | head -1)
        local plugin_name=$(cache_query ".commands[] | select(.category == \"$category\" and .name == \"$command_id\" and .plugin != null) | .plugin.name" 2> /dev/null | head -1)

        # Get directory from the plugins array using the plugin name
        local plugin_directory=""
        if [ -n "$plugin_name" ] && [ "$plugin_name" != "null" ]; then
            plugin_directory=$(cache_get_plugin_info "$plugin_name" "directory")
        fi

        if [ -n "$plugin_source" ] && [ "$plugin_source" != "null" ]; then
            local config_path=""
            if [ -n "$plugin_directory" ] && [ "$plugin_directory" != "null" ] && [ "$plugin_directory" != "" ]; then
                # Plugin has a specific directory configured
                config_path="$plugin_source/$plugin_directory/$category/$command_id/command.json"
            else
                # Plugin uses root directory
                config_path="$plugin_source/$category/$command_id/command.json"
            fi

            if [ -f "$config_path" ]; then
                echo "$config_path"
                return 0
            fi
        fi
    fi

    # Search in commands/
    local config_path="$cli_dir/commands/$category/$command_id/command.json"
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
            [ "$plugin_name" = "registry.json" ] && continue
            [ "$plugin_name" = "README.md" ] && continue

            config_path="$plugin_dir/$category/$command_id/command.json"
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

    # First, try to check via lock file (faster)
    if has_valid_lock_file; then
        local plugin_name=$(cache_query ".commands[] | select(.category == \"$category\" and .name == \"$command_id\") | .plugin.name" 2> /dev/null)

        if [ -n "$plugin_name" ] && [ "$plugin_name" != "null" ]; then
            return 0
        fi
    fi

    # Fallback: check via file path
    local config_file=$(find_command_config "$category" "$command_id")

    if [ -n "$config_file" ] && [[ "$config_file" == */plugins/* ]]; then
        return 0
    fi

    return 1
}

# Checks if a command is from a dev plugin
is_dev_plugin_command() {
    local category="$1"
    local command_id="$2"

    # Check via lock file only (dev flag is only in lock)
    if has_valid_lock_file; then
        local is_dev=$(cache_query ".commands[] | select(.category == \"$category\" and .name == \"$command_id\") | .dev" 2> /dev/null)

        if [ "$is_dev" = "true" ]; then
            return 0
        fi
    fi

    return 1
}

# Gets information from a specific command from lock file only
get_command_info() {
    local config_file="$1" # Kept for compatibility, but not used
    local category="$2"
    local command_id="$3"
    local field="$4" # name, description, script, sudo, os, group

    # Only read from lock file
    if has_valid_lock_file; then
        local value=$(get_command_info_from_lock "$category" "$command_id" "$field")
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
            return 0
        fi
    fi

    # Fallback: read directly from command.json if lock file doesn't exist
    local cli_dir="${CLI_DIR:-$(dirname "$GLOBAL_CONFIG_FILE")}"
    local command_dir="$cli_dir/commands/$category/$command_id"
    local config_file="$command_dir/command.json"

    if [ -f "$config_file" ]; then
        local value=$(jq -r ".$field // empty" "$config_file" 2> /dev/null)
        if [ -n "$value" ]; then
            echo "$value"
            return 0
        fi
    fi

    # If lock file doesn't exist or value not found, return empty
    return 1
}

# Function to check if command is compatible with current OS from lock file only
is_command_compatible() {
    local config_file="$1" # Kept for compatibility
    local category="$2"
    local command_id="$3"
    local current_os="$4" # linux or mac

    # Use lock file function directly
    is_command_compatible_from_lock "$category" "$command_id" "$current_os"
}

# Function to check if command requires sudo from lock file only
requires_sudo() {
    local config_file="$1" # Kept for compatibility
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
    local config_file="$1" # Kept for compatibility
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
    local config_file="$1" # Kept for compatibility
    local category="$2"
    local current_os="$3"

    local commands=$(get_category_commands "$category")
    local groups=""

    for cmd in $commands; do
        # Skip incompatible commands
        if ! is_command_compatible "$config_file" "$category" "$cmd" "$current_os"; then
            continue
        fi

        local group=$(get_command_group "$config_file" "$category" "$cmd")

        if [ -n "$group" ]; then
            # Add group if not already in the list
            if ! echo "$groups" | grep -qw "$group"; then
                groups="${groups}${group}"$'\n'
            fi
        fi
    done

    echo "$groups" | grep -v '^$'
}

# ============================================================
# Environment Variables Functions
# ============================================================

# Load environment variables from .env files
# Arguments:
#   $1 - Base directory to resolve relative paths
#   $@ - List of .env file paths (can be relative or absolute)
load_env_files() {
    local base_dir="$1"
    shift

    # Iterate through all .env file paths provided
    for env_file in "$@"; do
        # Resolve relative paths
        if [[ ! "$env_file" =~ ^/ ]]; then
            env_file="$base_dir/$env_file"
        fi

        # Skip if file doesn't exist
        if [ ! -f "$env_file" ]; then
            continue
        fi

        # Read and export variables from .env file
        while IFS= read -r line || [ -n "$line" ]; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

            # Extract key=value pairs
            if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
                local key="${BASH_REMATCH[1]}"
                local value="${BASH_REMATCH[2]}"

                # Remove leading/trailing whitespace and quotes
                value="${value#"${value%%[![:space:]]*}"}" # Leading spaces
                value="${value%"${value##*[![:space:]]}"}" # Trailing spaces

                # Remove surrounding quotes if present
                if [[ "$value" =~ ^[\'\"](.*)[\'\"]$ ]]; then
                    value="${BASH_REMATCH[1]}"
                fi

                # Only set if not already defined (respects system env vars and config envs)
                if [ -z "${!key:-}" ]; then
                    # Expand variables like $HOME in the value
                    value=$(eval echo "$value")
                    export "$key=$value"
                fi
            fi
        done < "$env_file"
    done
}

# Load environment variables from command.json
load_command_envs() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        return 0
    fi

    # Get base directory for resolving relative .env file paths
    local config_dir="$(dirname "$config_file")"

    # Load environment variables from .env files first (lowest priority)
    if jq -e '.env_files' "$config_file" &> /dev/null; then
        local env_files=()
        while IFS= read -r env_file; do
            [ -n "$env_file" ] && env_files+=("$env_file")
        done < <(jq -r '.env_files[]? // empty' "$config_file" 2> /dev/null)

        if [ ${#env_files[@]} -gt 0 ]; then
            load_env_files "$config_dir" "${env_files[@]}"
        fi
    fi

    # Load environment variables from envs section (higher priority than .env files)
    if jq -e '.envs' "$config_file" &> /dev/null; then
        # Get all env keys and values, export them
        while IFS='=' read -r key value; do
            if [ -n "$key" ] && [ -n "$value" ]; then
                # Only set if not already defined (respects system env vars)
                if [ -z "${!key:-}" ]; then
                    # Expand variables like $HOME in the value
                    value=$(eval echo "$value")
                    export "$key=$value"
                fi
            fi
        done < <(jq -r '.envs | to_entries[] | "\(.key)=\(.value)"' "$config_file" 2> /dev/null)
    fi
}
