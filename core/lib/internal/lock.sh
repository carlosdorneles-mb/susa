#!/bin/bash

source "$LIB_DIR/internal/json.sh"
source "$LIB_DIR/internal/cache.sh"

# Lock cache configuration
LOCK_FILE="${CLI_DIR:-$HOME/.susa}/susa.lock"
LOCK_CACHE_NAME="lock"

# ============================================================
# Lock Cache Helper Functions
# ============================================================

# Load lock cache (with auto-update from lock file)
cache_load() {
    cache_named_load "$LOCK_CACHE_NAME" "$LOCK_FILE"
}

# Query lock cache with jq
# Args: jq_query
cache_query() {
    cache_named_query "$LOCK_CACHE_NAME" "$1"
}

# Get categories from cache
cache_get_categories() {
    cache_query '.categories[].name'
}

# Get category info from cache
# Args: category field
cache_get_category_info() {
    local category="$1"
    local field="$2"
    cache_query ".categories[] | select(.name == \"$category\") | .$field"
}

# Get commands from category from cache
# Args: category
cache_get_category_commands() {
    local category="$1"
    cache_query ".commands[] | select(.category == \"$category\") | .name"
}

# Get command info from cache
# Args: category command field
cache_get_command_info() {
    local category="$1"
    local command="$2"
    local field="$3"
    cache_query ".commands[] | select(.category == \"$category\" and .name == \"$command\") | .$field"
}

# Get plugin info from cache
# Args: plugin_name field
cache_get_plugin_info() {
    local plugin_name="$1"
    local field="$2"
    cache_query ".plugins[] | select(.name == \"$plugin_name\") | .$field"
}

# Get all plugins from cache
cache_get_plugins() {
    cache_query '.plugins[].name'
}

# Force cache refresh
cache_refresh() {
    cache_named_clear "$LOCK_CACHE_NAME"
    cache_named_load "$LOCK_CACHE_NAME" "$LOCK_FILE"
}

# Clear cache
cache_clear() {
    cache_named_clear "$LOCK_CACHE_NAME"
}

# Check if cache exists and is valid
cache_exists() {
    local cache_file="${XDG_RUNTIME_DIR:-/tmp}/susa-$USER/${LOCK_CACHE_NAME}.cache"
    [ ! -f "$LOCK_FILE" ] && return 1
    [ ! -f "$cache_file" ] && return 1
    [ "$cache_file" -nt "$LOCK_FILE" ] && return 0
    return 1
}

# Get cache info for debugging
cache_info() {
    local cache_file="${XDG_RUNTIME_DIR:-/tmp}/susa-$USER/${LOCK_CACHE_NAME}.cache"

    if command -v log_output &> /dev/null; then
        log_output "${BOLD}${CYAN}Informações do Cache${NC}"
        log_output "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        log_output "${BOLD}Localização:${NC}"
        log_output "  ${GRAY}Diretório:${NC} ${XDG_RUNTIME_DIR:-/tmp}/susa-$USER"
        log_output "  ${GRAY}Arquivo:${NC}   $cache_file"
        log_output "  ${GRAY}Lock:${NC}      $LOCK_FILE"
        echo ""

        log_output "${BOLD}Status do Cache:${NC}"
        if [ -f "$cache_file" ]; then
            local cache_size=$(du -h "$cache_file" | cut -f1)
            local cache_date=$(stat -c %y "$cache_file" 2> /dev/null || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$cache_file" 2> /dev/null)
            log_output "  ${GRAY}Existe:${NC}      ${GREEN}✓ Sim${NC}"
            log_output "  ${GRAY}Tamanho:${NC}     $cache_size"
            log_output "  ${GRAY}Modificado:${NC}  $cache_date"
        else
            log_output "  ${GRAY}Existe:${NC}      ${RED}✗ Não${NC}"
        fi
        echo ""

        log_output "${BOLD}Status do Lock File:${NC}"
        if [ -f "$LOCK_FILE" ]; then
            local lock_date=$(stat -c %y "$LOCK_FILE" 2> /dev/null || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$LOCK_FILE" 2> /dev/null)
            log_output "  ${GRAY}Existe:${NC}      ${GREEN}✓ Sim${NC}"
            log_output "  ${GRAY}Modificado:${NC}  $lock_date"
        else
            log_output "  ${GRAY}Existe:${NC}      ${RED}✗ Não${NC}"
        fi
        echo ""

        log_output "${BOLD}Validação:${NC}"
        if cache_exists; then
            log_output "  ${GRAY}Status:${NC}      ${GREEN}✓ Válido${NC}"
            log_output "  ${GRAY}Descrição:${NC}   Cache está atualizado e pronto para uso"
        else
            log_output "  ${GRAY}Status:${NC}      ${YELLOW}⚠ Inválido ou Desatualizado${NC}"
            log_output "  ${GRAY}Descrição:${NC}   Cache será regenerado na próxima execução"
        fi
    fi
}

# ============================================================
# Lock File Management Functions
# ============================================================

# Updates the lock file (creates if doesn't exist)
update_lock_file() {
    log_info "Atualizando o lock..."
    log_debug "Executando: $CORE_DIR/susa self lock"

    if "$CORE_DIR/susa" self lock > /dev/null 2>&1; then
        log_debug "Lock file atualizado com sucesso"
        return 0
    else
        log_error "Não foi possível atualizar o susa.lock"
        log_debug "Você pode precisar executar: susa self lock"
        return 1
    fi
}

# Adds all plugins from registry to lock JSON
# Args: json_data
# Returns: updated json_data with plugins added
add_plugins_to_lock() {
    local json_data="$1"
    local registry_file="$PLUGINS_DIR/registry.json"

    # Check if registry exists
    if [ ! -f "$registry_file" ]; then
        echo "$json_data"
        return 0
    fi

    # Get all plugins from registry
    local all_plugins=$(jq -r '.plugins[] | .name + "|" + (.dev // false | tostring) + "|" + (.source // "") + "|" + (.directory // "")' "$registry_file" 2> /dev/null)

    while IFS='|' read -r plugin_name is_dev_str plugin_source_path plugin_directory; do
        [ -z "$plugin_name" ] && continue

        local is_dev="false"
        [ "$is_dev_str" = "true" ] && is_dev="true"

        local plugin_dir=""
        if [ "$is_dev" = "true" ]; then
            plugin_dir="$plugin_source_path"
        else
            plugin_dir="$PLUGINS_DIR/$plugin_name"
        fi

        # Skip if directory doesn't exist
        [ ! -d "$plugin_dir" ] && continue

        # Get plugin metadata (version, commands, categories from detection)
        # These functions are expected to be available from plugin.sh when this is called
        local plugin_version=$(detect_plugin_version "$plugin_dir")
        local plugin_cmd_count=$(count_plugin_commands "$plugin_dir")
        local plugin_categories=$(get_plugin_categories "$plugin_dir")

        # Ensure cmd_count is a valid number
        if [ -z "$plugin_cmd_count" ] || ! [[ "$plugin_cmd_count" =~ ^[0-9]+$ ]]; then
            plugin_cmd_count=0
        fi

        # Build plugin object based on available metadata
        if [ -n "$plugin_categories" ] && [ "$is_dev" = "true" ] && [ -n "$plugin_directory" ]; then
            json_data=$(echo "$json_data" | jq \
                --arg name "$plugin_name" \
                --arg version "$plugin_version" \
                --argjson commands "$plugin_cmd_count" \
                --arg cats "$plugin_categories" \
                --arg dir "$plugin_directory" \
                '.plugins += [{name: $name, version: $version, commands: $commands, categories: $cats, directory: $dir, dev: true}]')
        elif [ -n "$plugin_categories" ] && [ "$is_dev" = "true" ]; then
            json_data=$(echo "$json_data" | jq \
                --arg name "$plugin_name" \
                --arg version "$plugin_version" \
                --argjson commands "$plugin_cmd_count" \
                --arg cats "$plugin_categories" \
                '.plugins += [{name: $name, version: $version, commands: $commands, categories: $cats, dev: true}]')
        elif [ -n "$plugin_categories" ] && [ -n "$plugin_directory" ]; then
            json_data=$(echo "$json_data" | jq \
                --arg name "$plugin_name" \
                --arg version "$plugin_version" \
                --argjson commands "$plugin_cmd_count" \
                --arg cats "$plugin_categories" \
                --arg dir "$plugin_directory" \
                '.plugins += [{name: $name, version: $version, commands: $commands, categories: $cats, directory: $dir}]')
        elif [ -n "$plugin_categories" ]; then
            json_data=$(echo "$json_data" | jq \
                --arg name "$plugin_name" \
                --arg version "$plugin_version" \
                --argjson commands "$plugin_cmd_count" \
                --arg cats "$plugin_categories" \
                '.plugins += [{name: $name, version: $version, commands: $commands, categories: $cats}]')
        elif [ "$is_dev" = "true" ] && [ -n "$plugin_directory" ]; then
            json_data=$(echo "$json_data" | jq \
                --arg name "$plugin_name" \
                --arg version "$plugin_version" \
                --argjson commands "$plugin_cmd_count" \
                --arg dir "$plugin_directory" \
                '.plugins += [{name: $name, version: $version, commands: $commands, directory: $dir, dev: true}]')
        elif [ "$is_dev" = "true" ]; then
            json_data=$(echo "$json_data" | jq \
                --arg name "$plugin_name" \
                --arg version "$plugin_version" \
                --argjson commands "$plugin_cmd_count" \
                '.plugins += [{name: $name, version: $version, commands: $commands, dev: true}]')
        elif [ -n "$plugin_directory" ]; then
            json_data=$(echo "$json_data" | jq \
                --arg name "$plugin_name" \
                --arg version "$plugin_version" \
                --argjson commands "$plugin_cmd_count" \
                --arg dir "$plugin_directory" \
                '.plugins += [{name: $name, version: $version, commands: $commands, directory: $dir}]')
        else
            json_data=$(echo "$json_data" | jq \
                --arg name "$plugin_name" \
                --arg version "$plugin_version" \
                --argjson commands "$plugin_cmd_count" \
                '.plugins += [{name: $name, version: $version, commands: $commands}]')
        fi
    done <<< "$all_plugins"

    echo "$json_data"
}

# Get plugin info from lock file
get_plugin_info_from_lock() {
    local plugin_name="$1"
    local field="$2"

    cache_get_plugin_info "$plugin_name" "$field"
}
