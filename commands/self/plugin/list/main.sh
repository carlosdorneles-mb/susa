#!/bin/bash
set -euo pipefail

setup_command_env

# Source libs
source "$LIB_DIR/color.sh"
source "$LIB_DIR/logger.sh"
source "$LIB_DIR/registry.sh"
source "$LIB_DIR/plugin.sh"

# Help function
show_help() {
    show_description
    echo ""
    show_usage "[options]"
    echo ""
    echo -e "${LIGHT_GREEN}Descrição:${NC}"
    echo "  Lista todos os plugins instalados no Susa CLI,"
    echo "  incluindo origem, versão, comandos e categorias."
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  -h, --help        Exibe esta mensagem de ajuda"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo "  susa self plugin list         # Lista todos os plugins"
    echo "  susa self plugin list --help  # Exibe esta ajuda"
    echo ""
}

# Main function
main() {
    echo -e "${BOLD}Plugins Instalados${NC}"
    echo ""

    REGISTRY_FILE="$PLUGINS_DIR/registry.yaml"

    if [ ! -f "$REGISTRY_FILE" ]; then
        log_info "Nenhum plugin instalado"
        echo ""
        echo -e "Para instalar plugins, use: ${LIGHT_CYAN}susa self plugin add <url>${NC}"
        return 0
    fi

    # Read plugins from registry using yq
    local plugin_count=$(yq eval '.plugins | length' "$REGISTRY_FILE" 2>/dev/null || echo 0)

    if [ "$plugin_count" -eq 0 ]; then
        log_info "Nenhum plugin instalado"
        echo ""
        echo -e "Para instalar plugins, use: ${LIGHT_CYAN}susa self plugin add <url>${NC}"
        return 0
    fi

    # Iterate through plugins in registry
    for ((i=0; i<plugin_count; i++)); do
        local plugin_name=$(yq eval ".plugins[$i].name" "$REGISTRY_FILE" 2>/dev/null)
        local source_url=$(yq eval ".plugins[$i].source" "$REGISTRY_FILE" 2>/dev/null)
        local version=$(yq eval ".plugins[$i].version" "$REGISTRY_FILE" 2>/dev/null)
        local installed_at=$(yq eval ".plugins[$i].installed_at" "$REGISTRY_FILE" 2>/dev/null)
        local is_dev=$(yq eval ".plugins[$i].dev" "$REGISTRY_FILE" 2>/dev/null)
        local cmd_count=$(yq eval ".plugins[$i].commands" "$REGISTRY_FILE" 2>/dev/null)
        local categories=$(yq eval ".plugins[$i].categories" "$REGISTRY_FILE" 2>/dev/null)

        # Skip if plugin name is null
        [ "$plugin_name" = "null" ] && continue

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
            echo -e "${LIGHT_CYAN}📦 $plugin_name ${MAGENTA}[DEV]${NC}"
        else
            echo -e "${LIGHT_CYAN}📦 $plugin_name${NC}"
        fi

        [ "$source_url" != "null" ] && echo -e "   Origem: ${GRAY}$source_url${NC}"
        [ "$version" != "null" ] && echo -e "   Versão: ${GRAY}$version${NC}"
        echo -e "   Comandos: ${GRAY}$cmd_count${NC}"
        [ -n "$categories" ] && echo -e "   Categorias: ${GRAY}$categories${NC}"
        [ "$installed_at" != "null" ] && echo -e "   Instalado: ${GRAY}$installed_at${NC}"
        echo ""
    done

    echo -e "${GREEN}Total: $plugin_count plugin(s)${NC}"
}

# Parse arguments first, before running main
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Opção desconhecida: $1"
            show_usage
            exit 1
            ;;
    esac
    shift
done

# Execute main function
main
