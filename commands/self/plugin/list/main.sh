#!/bin/bash
set -euo pipefail

setup_command_env

# Source libs
source "$CLI_DIR/lib/color.sh"
source "$CLI_DIR/lib/logger.sh"
source "$CLI_DIR/lib/registry.sh"

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
    
    if [ ! -d "$PLUGINS_DIR" ]; then
        log_warning "Diretório de plugins não encontrado"
        return 0
    fi
    
    REGISTRY_FILE="$PLUGINS_DIR/registry.yaml"
    
    # Find all plugins
    local plugin_count=0
    for plugin_dir in "$PLUGINS_DIR"/*; do
        [ ! -d "$plugin_dir" ] && continue
        [ "$(basename "$plugin_dir")" = "registry.yaml" ] && continue
        [ "$(basename "$plugin_dir")" = "README.md" ] && continue
        
        local plugin_name=$(basename "$plugin_dir")
        
        # Counts plugin commands
        local cmd_count=$(find "$plugin_dir" -name "config.yaml" -type f | wc -l)
        
        # List categories
        local categories=$(find "$plugin_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | tr '\n' ', ' | sed 's/,$//')
        
        # Get registry information if it exists
        local source_url version installed_at
        if [ -f "$REGISTRY_FILE" ]; then
            source_url=$(registry_get_plugin_info "$REGISTRY_FILE" "$plugin_name" "source")
            version=$(registry_get_plugin_info "$REGISTRY_FILE" "$plugin_name" "version")
            installed_at=$(registry_get_plugin_info "$REGISTRY_FILE" "$plugin_name" "installed_at")
        else
            source_url="${GRAY}(não registrado)${NC}"
            version="${GRAY}(desconhecida)${NC}"
            installed_at="${GRAY}(desconhecida)${NC}"
        fi
        
        echo -e "${LIGHT_CYAN}📦 $plugin_name${NC}"
        [ -n "$source_url" ] && echo -e "   Origem: ${GRAY}$source_url${NC}"
        [ -n "$version" ] && echo -e "   Versão: ${GRAY}$version${NC}"
        echo -e "   Comandos: ${GRAY}$cmd_count${NC}"
        echo -e "   Categorias: ${GRAY}$categories${NC}"
        [ -n "$installed_at" ] && echo -e "   Instalado: ${GRAY}$installed_at${NC}"
        echo ""
        
        ((plugin_count++))
    done
    
    if [ $plugin_count -eq 0 ]; then
        log_info "Nenhum plugin instalado"
        echo ""
        echo -e "Para instalar plugins, use: ${LIGHT_CYAN}susa self plugin install <url>${NC}"
    else
        echo -e "${GREEN}Total: $plugin_count plugin(s)${NC}"
    fi
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
