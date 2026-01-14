#!/bin/bash

# Get the lib directory
source "$LIB_DIR/color.sh"
source "$LIB_DIR/yaml.sh"

# --- CLI Helper Functions ---

# Sets up the command environment by determining SCRIPT_DIR and CONFIG_FILE
setup_command_env() {
    # BASH_SOURCE[1] points to the script that called this function
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    CONFIG_FILE="$SCRIPT_DIR/config.yaml"
    
    # Export so that subprocesses also have access
    export SCRIPT_DIR
    export CONFIG_FILE
}

# Builds the command path based on SCRIPT_DIR
# Example: commands/self/plugin/add -> self plugin add
build_command_path() {
    local script_dir="${SCRIPT_DIR:-${1:-}}"
    
    # If no script_dir is available, return empty
    [ -z "$script_dir" ] && return 0
    
    # Remove the prefix up to /commands/
    local relative_path="${script_dir#*commands/}"
    
    # If it didn't change, try removing /plugins/
    if [ "$relative_path" = "$script_dir" ]; then
        relative_path="${script_dir#*plugins/*/}"
    fi
    
    # Convert / to space
    echo "$relative_path" | tr '/' ' '
}

# Displays the command usage information with customizable arguments
# Usage:
#   show_usage
#   show_usage "<file> <destination>"
#   show_usage --no-options
show_usage() {
    local cli_name="susa"
    local command_path=$(build_command_path)
    local show_options=true
    local custom_args=""
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --no-options)
                show_options=false
                shift
                ;;
            *)
                custom_args="$custom_args $1"
                shift
                ;;
        esac
    done
    
    # Trim leading space from custom_args
    custom_args="${custom_args# }"
    
    # If no custom arguments and show_options is true, use [opções]
    if [ -z "$custom_args" ] && [ "$show_options" = true ]; then
        custom_args="[opções]"
    fi
    
    # Build usage string
    local usage_string="${LIGHT_GREEN}Uso:${NC} ${LIGHT_CYAN}${cli_name}${NC}"
    
    # Add command path if available
    if [ -n "$command_path" ]; then
        usage_string="$usage_string ${CYAN}${command_path}${NC}"
    else
        usage_string="$usage_string ${CYAN}<comando>${NC}"
    fi
    
    # Add custom args if available
    if [ -n "$custom_args" ]; then
        usage_string="$usage_string ${GRAY}${custom_args}${NC}"
    fi
    
    echo -e "$usage_string"
}

# Get and display the command description from config.yaml
# The file config.yaml must have a "description" field.
# The config.yaml file is loaded from the command directory.
show_description() {
    local cmd_desc=$(get_yaml_field "$CONFIG_FILE" "description")
    echo -e "$cmd_desc"
}

# Displays the CLI name and version
show_version() {
    local name=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "name")
    local version=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "version")
    echo -e "${BOLD}$name${NC} (versão ${GRAY}$version${NC})"
}

# Displays the CLI version number only
show_number_version() {
    local version=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "version")
    echo "$version"
}