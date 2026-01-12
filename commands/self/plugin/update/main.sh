#!/bin/bash
set -euo pipefail

setup_command_env

# Source necessary libraries
source "$CLI_DIR/lib/registry.sh"
source "$CLI_DIR/lib/plugin.sh"

# Help function
show_help() {
    show_description
    echo ""
    show_usage "<plugin-name>"
    echo ""
    echo -e "${LIGHT_GREEN}Descrição:${NC}"
    echo "  Baixa novamente o plugin da origem registrada e"
    echo "  substitui a instalação atual pela versão mais recente."
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  -h, --help    Mostra esta mensagem de ajuda"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo "  susa self plugin update backup-tools    # Atualiza o plugin backup-tools"
    echo "  susa self plugin update --help          # Exibe esta ajuda"
    echo ""
}

# Main function
main() {
    local PLUGIN_NAME="$1"
    
    # Check if the plugin exists
    if [ ! -d "$PLUGINS_DIR/$PLUGIN_NAME" ]; then
        log_error "Plugin '$PLUGIN_NAME' não encontrado"
        echo ""
        echo -e "Use ${LIGHT_CYAN}susa self plugin list${NC} para ver plugins instalados"
        exit 1
    fi
    
    # Check if registry exists
    if [ ! -f "$REGISTRY_FILE" ]; then
        log_error "Registry não encontrado. Não é possível determinar a origem do plugin."
        echo ""
        echo -e "O plugin não foi instalado via ${LIGHT_CYAN}susa self plugin install${NC}"
        exit 1
    fi
    
    # Gets the registry source URL
    local SOURCE_URL=$(registry_get_plugin_info "$REGISTRY_FILE" "$PLUGIN_NAME" "source")
    
    if [ -z "$SOURCE_URL" ] || [ "$SOURCE_URL" = "local" ]; then
        log_error "Plugin '$PLUGIN_NAME' não tem origem registrada ou é local"
        echo ""
        echo -e "Apenas plugins instalados via Git podem ser atualizados"
        exit 1
    fi
    
    # Check if git is installed
    ensure_git_installed || exit 1
    
    log_info "Atualizando plugin: $PLUGIN_NAME"
    echo -e "  ${GRAY}Origem: $SOURCE_URL${NC}"
    echo ""
    
    # Confirm update
    read -p "Deseja continuar? (s/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        log_info "Operação cancelada"
        exit 0
    fi
    
    # Create backup of current plugin
    local BACKUP_DIR="${PLUGINS_DIR}/.backup_${PLUGIN_NAME}_$(date +%s)"
    
    log_info "Criando backup..."
    mv "$PLUGINS_DIR/$PLUGIN_NAME" "$BACKUP_DIR"
    
    # Clones the latest version
    log_info "Baixando versão mais recente de $SOURCE_URL..."
    if clone_plugin "$SOURCE_URL" "$PLUGINS_DIR/$PLUGIN_NAME"; then
        # Detect new version
        local NEW_VERSION=$(detect_plugin_version "$PLUGINS_DIR/$PLUGIN_NAME")
        
        # Update registry (remove and add again)
        registry_remove_plugin "$REGISTRY_FILE" "$PLUGIN_NAME"
        registry_add_plugin "$REGISTRY_FILE" "$PLUGIN_NAME" "$SOURCE_URL" "$NEW_VERSION"
        
        # Remove backup
        rm -rf "$BACKUP_DIR"
        
        # Count commands
        local cmd_count=$(count_plugin_commands "$PLUGINS_DIR/$PLUGIN_NAME")
        
        echo ""
        log_success "Plugin '$PLUGIN_NAME' atualizado com sucesso!"
        echo -e "  ${GRAY}Nova versão: $NEW_VERSION${NC}"
        echo -e "  ${GRAY}Comandos: $cmd_count${NC}"
    else
        log_error "Falha ao baixar atualização"
        
        # Restore backup
        log_info "Restaurando versão anterior..."
        mv "$BACKUP_DIR" "$PLUGINS_DIR/$PLUGIN_NAME"
        
        exit 1
    fi
}

# Parse arguments first, before running main
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            # Argument is the name of the plugin
            PLUGIN_ARG="$1"
            shift
            break
            ;;
    esac
done

# Checks if plugin name was provided
if [ -z "${PLUGIN_ARG:-}" ]; then
    log_error "Nome do plugin não fornecido"
    show_usage
    exit 1
fi

# Execute main function
main "$PLUGIN_ARG"
