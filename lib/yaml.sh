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

# Function to read YAML categories
parse_yaml_categories() {
    local yaml_file="$1"
    
    if [ ! -f "$yaml_file" ]; then
        return 1
    fi
    
    # Extract category names using yq
    yq eval '.categories | keys | .[]' "$yaml_file" 2>/dev/null
}

# Discover categories/subcategories automatically from directory structure
# Returns only level 1 categories (directories in commands/ and plugins/)
discover_categories() {
    local cli_dir="${CLI_DIR:-$(dirname "$GLOBAL_CONFIG_FILE")}"
    local commands_dir="${cli_dir}/commands"
    local plugins_dir="${cli_dir}/plugins"
    
    local categories=""
    
    # Search in commands/(first level only)
    if [ -d "$commands_dir" ]; then
        for cat_dir in "$commands_dir"/*; do
            [ ! -d "$cat_dir" ] && continue
            local cat_name=$(basename "$cat_dir")
            categories="${categories}${cat_name}"$'\n'
        done
    fi
    
    # Search in plugins/ (first level only for each plugin)
    if [ -d "$plugins_dir" ]; then
        for plugin_dir in "$plugins_dir"/*; do
            [ ! -d "$plugin_dir" ] && continue
            local plugin_name=$(basename "$plugin_dir")
            
            # Ignore special files
            [ "$plugin_name" = "registry.yaml" ] && continue
            [ "$plugin_name" = "README.md" ] && continue
            
            # Add first-level categories of this plugin
            for cat_dir in "$plugin_dir"/*; do
                [ ! -d "$cat_dir" ] && continue
                local cat_name=$(basename "$cat_dir")
                categories="${categories}${cat_name}"$'\n'
            done
        done
    fi
    
    # Remove duplicates and empty lines
    echo "$categories" | grep -v '^$' | sort -u
}

# Get all categories (YAML + discovered)
get_all_categories() {
    local yaml_file="$1"
    local categories=""
    
    # First, try from YAML (optional)
    if [ -f "$yaml_file" ]; then
        categories=$(parse_yaml_categories "$yaml_file" 2>/dev/null || true)
    fi
    
    # Then, discover from filesystem
    local discovered=$(discover_categories)
    
    # Combine and remove duplicates
    echo -e "${categories}\n${discovered}" | grep -v '^$' | sort -u
}

# Function to get information about a category or subcategory
get_category_info() {
    local yaml_file="$1"
    local category="$2"
    local field="$3"  # name or description
    
    local cli_dir="${CLI_DIR:-$(dirname "$yaml_file")}"
    
    # Try reading from the category/subcategory config.yaml in commands/
    local category_config="$cli_dir/commands/$category/config.yaml"
    if [ -f "$category_config" ]; then
        local value=$(yq eval ".$field" "$category_config" 2>/dev/null)
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
            return 0
        fi
    fi
    
    # Search in plugins/ if not found in commands/
    if [ -d "$cli_dir/plugins" ]; then
        for plugin_dir in "$cli_dir/plugins"/*; do
            [ ! -d "$plugin_dir" ] && continue
            local plugin_name=$(basename "$plugin_dir")
            
            # Ignore special files
            [ "$plugin_name" = "registry.yaml" ] && continue
            [ "$plugin_name" = "README.md" ] && continue
            
            category_config="$plugin_dir/$category/config.yaml"
            if [ -f "$category_config" ]; then
                local value=$(yq eval ".$field" "$category_config" 2>/dev/null)
                if [ -n "$value" ] && [ "$value" != "null" ]; then
                    echo "$value"
                    return 0
                fi
            fi
        done
    fi
}

# --- Functions for Discovery of Commands and Subcategories (based on executable script)) ---

# Checks if a directory is a command (has executable script)
is_command_dir() {
    local item_dir="$1"
    
    # Checks if config.yaml exists
    [ ! -f "$item_dir/config.yaml" ] && return 1
    
    # Reads the script field from config.yaml using yq
    local script_name=$(yq eval '.script' "$item_dir/config.yaml" 2>/dev/null)
    
    # If script field exists and the file exists, it's a command
    if [ -n "$script_name" ] && [ "$script_name" != "null" ] && [ -f "$item_dir/$script_name" ]; then
        return 0
    fi
    
    return 1
}

# Discover commands and subcategories in a path (category can be nested)
# Returns: commands (directories with script) and subcategories (directories without script)
discover_items_in_category() {
    local base_dir="$1"
    local category_path="$2"  # Can be "install", "install/python", etc.
    local type="${3:-all}"     # "commands", "subcategories", or "all"
    
    local full_path="$base_dir/$category_path"
    
    if [ ! -d "$full_path" ]; then
        return 0
    fi
    
    # Lists directories at the current level
    for item_dir in "$full_path"/*; do
        [ ! -d "$item_dir" ] && continue
        
        local item_name=$(basename "$item_dir")
        
        # Checks if it is a command (has executable script)
        if is_command_dir "$item_dir"; then
            if [ "$type" = "commands" ] || [ "$type" = "all" ]; then
                echo "command:$item_name"
            fi
        else
            # If it's not a command, it's a subcategory
            if [ "$type" = "subcategories" ] || [ "$type" = "all" ]; then
                echo "subcategory:$item_name"
            fi
        fi
    done
}

# Gets commands from a category (can be nested like "install/python")
get_category_commands() {
    local cli_dir="${CLI_DIR:-$(dirname "$GLOBAL_CONFIG_FILE")}"
    local category="$1"
    
    local commands_dir="${cli_dir}/commands"
    local plugins_dir="${cli_dir}/plugins"
    
    # Search in commands/
    if [ -d "$commands_dir" ]; then
        discover_items_in_category "$commands_dir" "$category" "commands" | sed 's/^command://'
    fi
    
    # Search in plugins/
    if [ -d "$plugins_dir" ]; then
        for plugin_dir in "$plugins_dir"/*; do
            [ ! -d "$plugin_dir" ] && continue
            local plugin_name=$(basename "$plugin_dir")
            
            # Ignore special files
            [ "$plugin_name" = "registry.yaml" ] && continue
            [ "$plugin_name" = "README.md" ] && continue
            
            discover_items_in_category "$plugin_dir" "$category" "commands" | sed 's/^command://'
        done
    fi
}

# Gets subcategories from a category
get_category_subcategories() {
    local cli_dir="${CLI_DIR:-$(dirname "$GLOBAL_CONFIG_FILE")}"
    local category="$1"
    
    local commands_dir="${cli_dir}/commands"
    local plugins_dir="${cli_dir}/plugins"
    
    local subcategories=""
    
    # Search in commands/
    if [ -d "$commands_dir" ]; then
        subcategories=$(discover_items_in_category "$commands_dir" "$category" "subcategories" | sed 's/^subcategory://')
    fi
    
    # Search in plugins/
    if [ -d "$plugins_dir" ]; then
        for plugin_dir in "$plugins_dir"/*; do
            [ ! -d "$plugin_dir" ] && continue
            local plugin_name=$(basename "$plugin_dir")
            
            # Ignore special files
            [ "$plugin_name" = "registry.yaml" ] && continue
            [ "$plugin_name" = "README.md" ] && continue
            
            local plugin_subcats=$(discover_items_in_category "$plugin_dir" "$category" "subcategories" | sed 's/^subcategory://')
            [ -n "$plugin_subcats" ] && subcategories="${subcategories}"$'\n'"${plugin_subcats}"
        done
    fi
    
    # Remove duplicates and empty lines
    echo "$subcategories" | grep -v '^$' | sort -u
}

# ============================================================
# LEGACY - Kept for compatibility
# ============================================================

# Discovers commands in a directory by reading 'id' field from config.yaml
discover_commands_in_dir() {
    local base_dir="$1"
    local category="$2"
    
    if [ ! -d "$base_dir" ]; then
        return 0
    fi
    
    # Legacy function - no longer used
    return 1
}

# --- Functions to read Individual Command Config ---

# Reads a field from a command config
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

# Gets information from a specific command
get_command_info() {
    local yaml_file="$1"  # Kept for compatibility, but not used
    local category="$2"
    local command_id="$3"
    local field="$4"  # name, description, script, sudo, os, group
    
    local config_file=$(find_command_config "$category" "$command_id")
    
    if [ -z "$config_file" ]; then
        return 1
    fi
    
    get_command_config_field "$config_file" "$field"
}

# Function to check if command is compatible with current OS
is_command_compatible() {
    local yaml_file="$1"  # Kept for compatibility
    local category="$2"
    local command_id="$3"
    local current_os="$4"  # linux ou mac
    
    local config_file=$(find_command_config "$category" "$command_id")
    
    if [ -z "$config_file" ]; then
        return 1
    fi
    
    local supported_os=$(get_command_config_field "$config_file" "os")
    
    # If there's no OS restriction, it's compatible
    if [ -z "$supported_os" ]; then
        return 0
    fi
    
    # Checks if current OS is in the list
    if echo "$supported_os" | grep -qw "$current_os"; then
        return 0
    fi
    
    return 1
}

# Function to check if command requires sudo
requires_sudo() {
    local yaml_file="$1"  # Kept for compatibility
    local category="$2"
    local command_id="$3"
    
    local config_file=$(find_command_config "$category" "$command_id")
    
    if [ -z "$config_file" ]; then
        return 1
    fi
    
    local needs_sudo=$(get_command_config_field "$config_file" "sudo")
    
    if [ "$needs_sudo" = "true" ]; then
        return 0
    fi
    
    return 1
}

# Function to get the group of a command
get_command_group() {
    local yaml_file="$1"  # Kept for compatibility
    local category="$2"
    local command_id="$3"
    
    local config_file=$(find_command_config "$category" "$command_id")
    
    if [ -z "$config_file" ]; then
        return 0
    fi
    
    get_command_config_field "$config_file" "group"
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


