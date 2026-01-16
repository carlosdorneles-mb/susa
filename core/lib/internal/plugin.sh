#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# Plugin Helper Functions
# ============================================================
# Functions for plugin management and metadata

# Source Git functions
source "$LIB_DIR/internal/git.sh"

# --- Plugin Display Functions ---

# Show plugin details in a standardized format
# Usage: show_plugin_details <name> [version] [commands] [categories] [description] [directory] [source] [installedAt] [dev_mode]
show_plugin_details() {
    local name="${1:-}"
    local version="${2:-}"
    local commands="${3:-}"
    local categories="${4:-}"
    local description="${5:-}"
    local directory="${6:-}"
    local source="${7:-}"
    local installedAt="${8:-}"
    local dev_mode="${9:-false}"

    log_output "Detalhes do plugin:"

    if [ -n "$name" ]; then
        log_output "  ${GRAY}Nome:${NC} $name"
    fi

    if [ -n "$version" ]; then
        log_output "  ${GRAY}Versão:${NC} $version"
    fi

    if [ -n "$commands" ] && [ "$commands" != "0" ]; then
        log_output "  ${GRAY}Comandos:${NC} $commands"
    fi

    if [ -n "$categories" ]; then
        log_output "  ${GRAY}Categorias:${NC} $categories"
    fi

    if [ -n "$description" ]; then
        log_output "  ${GRAY}Descrição:${NC} $description"
    fi

    if [ -n "$directory" ]; then
        log_output "  ${GRAY}Diretório:${NC} $directory"
    fi

    if [ -n "$source" ]; then
        if [ "$dev_mode" = "true" ]; then
            log_output "  ${GRAY}Local:${NC} $source"
        else
            log_output "  ${GRAY}Origem:${NC} $source"
        fi
    fi

    if [ -n "$installedAt" ]; then
        log_output "  ${GRAY}Instalado em:${NC} $installedAt"
    fi
}

# --- Plugin Metadata Functions ---

# Validates that a plugin has a valid plugin.json file
validate_plugin_config() {
    local plugin_dir="$1"
    local config_file="$plugin_dir/plugin.json"

    if [ ! -f "$config_file" ]; then
        return 1
    fi

    # Validate JSON syntax
    if ! jq empty "$config_file" 2> /dev/null; then
        return 1
    fi

    # Validate required fields
    local name=$(jq -r '.name // empty' "$config_file" 2> /dev/null)
    local version=$(jq -r '.version // empty' "$config_file" 2> /dev/null)

    if [ -z "$name" ] || [ "$name" = "null" ] || [ "$name" = "empty" ]; then
        return 1
    fi

    if [ -z "$version" ] || [ "$version" = "null" ] || [ "$version" = "empty" ]; then
        return 1
    fi

    return 0
}

# Reads plugin metadata from plugin.json
# Returns: name|version|description|directory
# Note: plugin.json is required and must have name and version fields
read_plugin_config() {
    local plugin_dir="$1"
    local config_file="$plugin_dir/plugin.json"

    if [ ! -f "$config_file" ]; then
        echo "ERROR: plugin.json not found in $plugin_dir" >&2
        return 1
    fi

    local name=$(jq -r '.name // empty' "$config_file" 2> /dev/null)
    local version=$(jq -r '.version // empty' "$config_file" 2> /dev/null)
    local description=$(jq -r '.description // empty' "$config_file" 2> /dev/null)
    local directory=$(jq -r '.directory // empty' "$config_file" 2> /dev/null)

    # Validate required fields
    if [ -z "$name" ] || [ "$name" = "null" ] || [ "$name" = "empty" ]; then
        echo "ERROR: 'name' field is required in plugin.json" >&2
        return 1
    fi

    if [ -z "$version" ] || [ "$version" = "null" ] || [ "$version" = "empty" ]; then
        echo "ERROR: 'version' field is required in plugin.json" >&2
        return 1
    fi

    # Optional fields
    if [ "$description" = "null" ]; then
        description=""
    fi
    if [ "$directory" = "null" ]; then
        directory=""
    fi

    echo "$name|$version|$description|$directory"
}

# Detects the version of a plugin in the directory
# Requires plugin.json to exist
detect_plugin_version() {
    local plugin_dir="$1"
    local config_file="$plugin_dir/plugin.json"

    if [ ! -f "$config_file" ]; then
        echo "ERROR: plugin.json not found in $plugin_dir" >&2
        return 1
    fi

    local version=$(jq -r '.version // empty' "$config_file" 2> /dev/null)

    if [ -z "$version" ] || [ "$version" = "null" ] || [ "$version" = "empty" ]; then
        echo "ERROR: 'version' field is required in plugin.json" >&2
        return 1
    fi

    echo "$version"
}

# Gets the plugin name from plugin.json
# Requires plugin.json to exist
get_plugin_name() {
    local plugin_dir="$1"
    local config_file="$plugin_dir/plugin.json"

    if [ ! -f "$config_file" ]; then
        echo "ERROR: plugin.json not found in $plugin_dir" >&2
        return 1
    fi

    local name=$(jq -r '.name // empty' "$config_file" 2> /dev/null)

    if [ -z "$name" ] || [ "$name" = "null" ] || [ "$name" = "empty" ]; then
        echo "ERROR: 'name' field is required in plugin.json" >&2
        return 1
    fi

    echo "$name"
}

# Gets the plugin description from plugin.json
# Returns empty string if description is not provided (optional field)
get_plugin_description() {
    local plugin_dir="$1"
    local config_file="$plugin_dir/plugin.json"

    if [ ! -f "$config_file" ]; then
        echo "ERROR: plugin.json not found in $plugin_dir" >&2
        return 1
    fi

    local description=$(jq -r '.description // empty' "$config_file" 2> /dev/null)

    if [ "$description" = "null" ] || [ "$description" = "empty" ]; then
        description=""
    fi

    echo "$description"
}

# Gets the plugin directory from plugin.json (where commands are located)
# Returns empty string if directory is not specified (optional field)
get_plugin_directory() {
    local plugin_dir="$1"
    local config_file="$plugin_dir/plugin.json"

    if [ ! -f "$config_file" ]; then
        echo "ERROR: plugin.json not found in $plugin_dir" >&2
        return 1
    fi

    local directory=$(jq -r '.directory // empty' "$config_file" 2> /dev/null)

    if [ "$directory" = "null" ] || [ "$directory" = "empty" ]; then
        directory=""
    fi

    echo "$directory"
}

# Counts commands from a plugin
count_plugin_commands() {
    local plugin_dir="$1"
    local commands_dir="$plugin_dir"

    # Check if plugin has a specific directory configured
    local configured_dir=$(get_plugin_directory "$plugin_dir")
    if [ -n "$configured_dir" ]; then
        commands_dir="$plugin_dir/$configured_dir"
    fi

    # Count main.sh files if directory exists
    if [ -d "$commands_dir" ]; then
        find "$commands_dir" -type f -name "main.sh" 2> /dev/null | wc -l | xargs
    else
        echo "0"
    fi
}

# Gets plugin categories (first-level directories excluding .git)
get_plugin_categories() {
    local plugin_dir="$1"
    local commands_dir="$plugin_dir"

    # Check if plugin has a specific directory configured
    local configured_dir=$(get_plugin_directory "$plugin_dir")
    if [ -n "$configured_dir" ]; then
        commands_dir="$plugin_dir/$configured_dir"
    fi

    # Get categories if directory exists
    if [ -d "$commands_dir" ]; then
        find "$commands_dir" -mindepth 1 -maxdepth 1 -type d ! -name ".git" ! -name ".*" -exec basename {} \; 2> /dev/null | sort | paste -sd "," -
    else
        echo ""
    fi
}

# Updates plugin metadata in the registry
# Args: plugin_name, source_path (local path), is_dev, [source_url] (Git URL for non-dev plugins)
update_plugin_registry() {
    local plugin_name="$1"
    local source_path="$2"
    local is_dev="${3:-false}"
    local source_url="${4:-}" # Optional: Git URL for non-dev plugins
    local REGISTRY_FILE="$PLUGINS_DIR/registry.json"

    log_info "Atualizando o registry..."
    log_debug "Plugin: $plugin_name"
    log_debug "Source path: $source_path"
    log_debug "Dev mode: $is_dev"
    log_debug "Source URL: $source_url"

    # Validate plugin.json
    if ! validate_plugin_config "$source_path"; then
        log_error "Plugin inválido: plugin.json não encontrado ou inválido"
        return 1
    fi

    # Read the actual plugin name from plugin.json
    local actual_plugin_name=$(get_plugin_name "$source_path")
    if [ $? -ne 0 ]; then
        log_error "Não foi possível ler o nome do plugin.json"
        return 1
    fi

    # Remove old entry if name was different
    if [ "$actual_plugin_name" != "$plugin_name" ]; then
        registry_remove_plugin "$REGISTRY_FILE" "$plugin_name"
    fi

    # Use the name from plugin.json
    plugin_name="$actual_plugin_name"

    # Read updated metadata
    local plugin_version=$(detect_plugin_version "$source_path")
    local description=$(get_plugin_description "$source_path")
    local cmd_count=$(count_plugin_commands "$source_path")
    local categories=$(get_plugin_categories "$source_path")
    local directory=$(get_plugin_directory "$source_path")

    log_debug "Versão: $plugin_version"
    log_debug "Descrição: $description"
    log_debug "Comandos: $cmd_count"
    log_debug "Categorias: $categories"
    log_debug "Diretório: $directory"

    # Determine the source value for registry
    local registry_source=""
    if [ "$is_dev" = "true" ]; then
        # For dev plugins, source is the local path
        registry_source="$source_path"
    elif [ -n "$source_url" ]; then
        # For Git plugins, use provided URL
        registry_source="$source_url"
    else
        # Fallback: try to get from existing registry entry
        registry_source=$(jq -r ".plugins[] | select(.name == \"$plugin_name\") | .source // empty" "$REGISTRY_FILE" 2> /dev/null | head -1)
        if [ -z "$registry_source" ]; then
            log_error "Source URL não fornecido e não encontrado no registry"
            return 1
        fi
    fi

    log_debug "Registry source: $registry_source"

    # Update registry - remove old entry and add with updated metadata
    registry_remove_plugin "$REGISTRY_FILE" "$plugin_name"
    registry_add_plugin "$REGISTRY_FILE" "$plugin_name" "$registry_source" "$plugin_version" "$is_dev" "$cmd_count" "$categories" "$description" "$directory"
    log_debug "Registry atualizado com sucesso"

    # Export the updated plugin name for caller to use
    UPDATED_PLUGIN_NAME="$plugin_name"

    return 0
}

# Converts user/repo to full Git URL
# Supports GitHub, GitLab and Bitbucket
# Supports --ssh flag to force SSH URLs
normalize_git_url() {
    local url="$1"
    local force_ssh="${2:-false}"
    local provider="${3:-github}" # Default to GitHub for backwards compatibility

    # If it's user/repo format, convert to full URL
    if [[ "$url" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]; then
        local should_use_ssh="$force_ssh"

        # Auto-detect SSH if not forced
        if [ "$force_ssh" != "true" ]; then
            case "$provider" in
                github)
                    if has_github_ssh_access; then
                        should_use_ssh="true"
                    fi
                    ;;
                gitlab)
                    if has_gitlab_ssh_access; then
                        should_use_ssh="true"
                    fi
                    ;;
                bitbucket)
                    if has_bitbucket_ssh_access; then
                        should_use_ssh="true"
                    fi
                    ;;
            esac
        fi

        # Generate URL based on provider
        if [ "$should_use_ssh" = "true" ]; then
            case "$provider" in
                github)
                    echo "git@github.com:${url}.git"
                    ;;
                gitlab)
                    echo "git@gitlab.com:${url}.git"
                    ;;
                bitbucket)
                    echo "git@bitbucket.org:${url}.git"
                    ;;
            esac
        else
            case "$provider" in
                github)
                    echo "https://github.com/${url}.git"
                    ;;
                gitlab)
                    echo "https://gitlab.com/${url}.git"
                    ;;
                bitbucket)
                    echo "https://bitbucket.org/${url}.git"
                    ;;
            esac
        fi
    else
        # Full URL provided
        local detected_provider=$(detect_git_provider "$url")

        # If force_ssh and it's an HTTPS URL, convert to SSH
        if [ "$force_ssh" = "true" ]; then
            case "$detected_provider" in
                github)
                    if [[ "$url" =~ ^https://github.com/ ]]; then
                        echo "$url" | sed 's|https://github.com/|git@github.com:|'
                    else
                        echo "$url"
                    fi
                    ;;
                gitlab)
                    if [[ "$url" =~ ^https://gitlab.com/ ]]; then
                        echo "$url" | sed 's|https://gitlab.com/|git@gitlab.com:|'
                    else
                        echo "$url"
                    fi
                    ;;
                bitbucket)
                    if [[ "$url" =~ ^https://bitbucket.org/ ]]; then
                        echo "$url" | sed 's|https://bitbucket.org/|git@bitbucket.org:|'
                    else
                        echo "$url"
                    fi
                    ;;
                *)
                    echo "$url"
                    ;;
            esac
        else
            echo "$url"
        fi
    fi
}

# Extracts plugin name from URL
extract_plugin_name() {
    local url="$1"
    basename "$url" .git
}
