#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libs
source "$LIB_DIR/color.sh"
source "$LIB_DIR/logger.sh"
source "$LIB_DIR/internal/registry.sh"
source "$LIB_DIR/internal/plugin.sh"
source "$LIB_DIR/internal/args.sh"

# Help function
show_help() {
    show_description
    log_output ""
    show_usage "[options]"
    log_output ""
    log_output "${LIGHT_GREEN}Descrição:${NC}"
    log_output "  Lista todos os plugins instalados no Susa CLI,"
    log_output "  incluindo origem, versão, comandos e categorias."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -v, --verbose     Modo verbose (debug)"
    log_output "  -q, --quiet       Modo silencioso (mínimo de output)"
    log_output "  -h, --help        Exibe esta mensagem de ajuda"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa self plugin list         # Lista todos os plugins"
    log_output "  susa self plugin list --help  # Exibe esta ajuda"
    log_output ""
}

# Main function
main() {
    log_output "${BOLD}Plugins Instalados${NC}"
    log_output ""

    REGISTRY_FILE="$PLUGINS_DIR/registry.yaml"

    if [ ! -f "$REGISTRY_FILE" ]; then
        log_info "Nenhum plugin instalado"
        log_output ""
        log_output "Para instalar plugins, use: ${LIGHT_CYAN}susa self plugin add <url>${NC}"
        return 0
    fi

    # Read plugins from registry using yq
    local plugin_count=$(yq eval '.plugins | length' "$REGISTRY_FILE" 2> /dev/null || echo 0)
    log_debug "Total de plugins no registry: $plugin_count"

    if [ "$plugin_count" -eq 0 ]; then
        log_info "Nenhum plugin instalado"
        log_output ""
        log_output "Para instalar plugins, use: ${LIGHT_CYAN}susa self plugin add <url>${NC}"
        return 0
    fi

    # Iterate through plugins in registry
    for ((i = 0; i < plugin_count; i++)); do
        local plugin_name=$(yq eval ".plugins[$i].name" "$REGISTRY_FILE" 2> /dev/null)

        local source_url=$(yq eval ".plugins[$i].source" "$REGISTRY_FILE" 2> /dev/null)
        local version=$(yq eval ".plugins[$i].version" "$REGISTRY_FILE" 2> /dev/null)
        local installed_at=$(yq eval ".plugins[$i].installed_at" "$REGISTRY_FILE" 2> /dev/null)
        local is_dev=$(yq eval ".plugins[$i].dev" "$REGISTRY_FILE" 2> /dev/null)
        local cmd_count=$(yq eval ".plugins[$i].commands" "$REGISTRY_FILE" 2> /dev/null)
        local categories=$(yq eval ".plugins[$i].categories" "$REGISTRY_FILE" 2> /dev/null)

        # Skip if plugin name is null
        if [ "$plugin_name" = "null" ]; then
            continue
        fi

        # If commands not in registry, count from directory (fallback)
        if [ "$cmd_count" = "null" ] || [ -z "$cmd_count" ]; then
            if [ -d "$PLUGINS_DIR/$plugin_name" ]; then
                cmd_count=$(find "$PLUGINS_DIR/$plugin_name" -name "config.yaml" -type f | wc -l)
            else
                cmd_count=0
            fi
        fi

        # If categories not in registry, get from directory (fallback)
        if [ "$categories" = "null" ] || [ -z "$categories" ]; then
            if [ -d "$PLUGINS_DIR/$plugin_name" ]; then
                categories=$(get_plugin_categories "$PLUGINS_DIR/$plugin_name")
            else
                categories="${GRAY}(não disponível)${NC}"
            fi
        fi

        # Display plugin information
        if [ "$is_dev" = "true" ]; then
            log_output "${LIGHT_CYAN}📦 $plugin_name ${MAGENTA}[DEV]${NC}"
        else
            log_output "${LIGHT_CYAN}📦 $plugin_name${NC}"
        fi

        [ "$source_url" != "null" ] && log_output "   Origem: ${GRAY}$source_url${NC}"
        [ "$version" != "null" ] && log_output "   Versão: ${GRAY}$version${NC}"
        log_output "   Comandos: ${GRAY}$cmd_count${NC}"
        [ -n "$categories" ] && log_output "   Categorias: ${GRAY}$categories${NC}"
        [ "$installed_at" != "null" ] && log_output "   Instalado: ${GRAY}$installed_at${NC}"
        log_output ""
    done

    log_output "${GREEN}Total: $plugin_count plugin(s)${NC}"
}

# Parse arguments first, before running main
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h | --help)
            show_help
            exit 0
            ;;
        -v | --verbose)
            export DEBUG=1
            shift
            ;;
        -q | --quiet)
            export SILENT=1
            shift
            ;;
        *)
            log_error "Argumento inválido: $1"
            log_output ""
            show_help
            exit 1
            ;;
    esac
done

# Execute main function
main
