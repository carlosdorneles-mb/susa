#!/bin/bash
set -euo pipefail

setup_command_env

# Source necessary libraries
source "$LIB_DIR/registry.sh"
source "$LIB_DIR/plugin.sh"

# Help function
show_help() {
    show_description
    echo ""
    show_usage "<plugin-name> [opções]"
    echo ""
    echo -e "${LIGHT_GREEN}Descrição:${NC}"
    echo "  Baixa novamente o plugin da origem registrada e"
    echo "  substitui a instalação atual pela versão mais recente."
    echo "  Suporta GitHub, GitLab e Bitbucket."
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  --ssh         Força uso de SSH (recomendado para repos privados)"
    echo "  -h, --help    Mostra esta mensagem de ajuda"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo "  susa self plugin update backup-tools           # Atualiza o plugin"
    echo "  susa self plugin update private-plugin --ssh   # Força SSH"
    echo "  susa self plugin update --help                 # Exibe esta ajuda"
    echo ""
    echo -e "${GRAY}Nota: O provedor Git é detectado automaticamente da URL registrada.${NC}"
    echo ""
}

# Main function
main() {
    local PLUGIN_NAME="$1"
    local USE_SSH="${2:-false}"
    local REGISTRY_FILE="$PLUGINS_DIR/registry.yaml"

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
        echo -e "O plugin não foi instalado via ${LIGHT_CYAN}susa self plugin add${NC}"
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

    # Detect provider from source URL
    local provider=$(detect_git_provider "$SOURCE_URL")
    log_debug "Provider detectado: $provider"

    # Normalize URL (apply SSH if forced or auto-detected)
    SOURCE_URL=$(normalize_git_url "$SOURCE_URL" "$USE_SSH" "$provider")
    if ! validate_repo_access "$SOURCE_URL"; then
        log_error "Não foi possível acessar o repositório"
        echo ""
        echo -e "${LIGHT_YELLOW}Possíveis causas:${NC}"
        echo -e "  • Repositório foi removido ou renomeado"
        echo -e "  • Você perdeu acesso ao repositório privado"
        echo -e "  • Credenciais Git não estão mais válidas"
        echo ""
        echo -e "${LIGHT_YELLOW}Soluções:${NC}"
        echo -e "  • Verifique se o repositório ainda existe"
        echo -e "  • Use --ssh se for repositório privado"
        echo -e "  • Reconfigure suas credenciais Git"
        exit 1
    fi

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

        # Count commands and get categories
        local cmd_count=$(count_plugin_commands "$PLUGINS_DIR/$PLUGIN_NAME")
        local categories=$(get_plugin_categories "$PLUGINS_DIR/$PLUGIN_NAME")

        # Update registry (remove and add again with metadata)
        registry_remove_plugin "$REGISTRY_FILE" "$PLUGIN_NAME"
        registry_add_plugin "$REGISTRY_FILE" "$PLUGIN_NAME" "$SOURCE_URL" "$NEW_VERSION" "false" "$cmd_count" "$categories"

        # Remove backup
        rm -rf "$BACKUP_DIR"

        echo ""
        log_success "Plugin '$PLUGIN_NAME' atualizado com sucesso!"
        echo -e "  ${GRAY}Nova versão: $NEW_VERSION${NC}"
        echo -e "  ${GRAY}Comandos: $cmd_count${NC}"
        if [ -n "$categories" ]; then
            echo -e "  ${GRAY}Categorias: $categories${NC}"
        fi

        # Update lock file if it exists
        update_lock_file
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

USE_SSH="false"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        --ssh)
            USE_SSH="true"
            shift
            ;;
        *)
            # Argument is the name of the plugin
            PLUGIN_ARG="$1"
            shift
            ;;
    esac
done

# Checks if plugin name was provided
if [ -z "${PLUGIN_ARG:-}" ]; then
    log_error "Nome do plugin não fornecido"
    show_usage "<plugin-name> [opções]"
    exit 1
fi

# Execute main function
main "$PLUGIN_ARG" "$USE_SSH"
