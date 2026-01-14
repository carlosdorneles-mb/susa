#!/bin/bash

# Get the lib directory
source "$LIB_DIR/color.sh"
source "$LIB_DIR/internal/yaml.sh"

# --- CLI Helper Functions ---

# Builds the command path based on the script directory
# Example: commands/self/plugin/add -> self plugin add
build_command_path() {
    # Use BASH_SOURCE to walk up the call stack and find the main.sh script
    local i=1
    local script_path=""
    
    # Walk up the call stack to find a main.sh file
    while [ -n "${BASH_SOURCE[$i]:-}" ]; do
        if [[ "${BASH_SOURCE[$i]}" == */main.sh ]]; then
            script_path="${BASH_SOURCE[$i]}"
            break
        fi
        ((i++))
    done
    
    # If no script path found, return empty
    [ -z "$script_path" ] && return 0
    
    local script_dir="$(cd "$(dirname "$script_path")" && pwd)"

    # Remove the prefix up to /commands/
    local relative_path="${script_dir#*commands/}"

    # If it didn't change, try removing /plugins/
    if [ "$relative_path" = "$script_dir" ]; then
        relative_path="${script_dir#*plugins/*/}"
    fi

    # Convert / to space
    echo "$relative_path" | tr '/' ' '
}

# Gets the config file path for the calling script
get_command_config_file() {
    # Use BASH_SOURCE to walk up the call stack and find the main.sh script
    local i=1
    local script_path=""
    
    # Walk up the call stack to find a main.sh file
    while [ -n "${BASH_SOURCE[$i]:-}" ]; do
        if [[ "${BASH_SOURCE[$i]}" == */main.sh ]]; then
            script_path="${BASH_SOURCE[$i]}"
            break
        fi
        ((i++))
    done
    
    if [ -z "$script_path" ]; then
        return 1
    fi
    
    local script_dir="$(cd "$(dirname "$script_path")" && pwd)"
    echo "$script_dir/config.yaml"
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
show_description() {
    local config_file=$(get_command_config_file)
    local cmd_desc=$(get_yaml_field "$config_file" "description")
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
