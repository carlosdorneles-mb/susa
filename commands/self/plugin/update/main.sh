#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source necessary libraries
source "$LIB_DIR/internal/registry.sh"
source "$LIB_DIR/internal/plugin.sh"
source "$LIB_DIR/internal/args.sh"
source "$LIB_DIR/internal/lock.sh"

# Help function
show_help() {
    show_description
    log_output ""
    show_usage "<plugin-name> [opções]"
    log_output ""
    log_output "${LIGHT_GREEN}Descrição:${NC}"
    log_output "  Baixa novamente o plugin da origem registrada e"
    log_output "  substitui a instalação atual pela versão mais recente."
    log_output "  Suporta GitHub, GitLab e Bitbucket."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -y, --yes         Pula confirmação e atualiza automaticamente"
    log_output "  -v, --verbose     Modo verbose (debug)"
    log_output "  -q, --quiet       Modo silencioso (mínimo de output)"
    log_output "  --ssh             Força uso de SSH (recomendado para repos privados)"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa self plugin update backup-tools           # Atualiza o plugin"
    log_output "  susa self plugin update private-plugin --ssh   # Força SSH"
    log_output "  susa self plugin update --help                 # Exibe esta ajuda"
    log_output ""
    log_output "${GRAY}Nota: O provedor Git é detectado automaticamente da URL registrada.${NC}"
    log_output ""
}

# Main function
main() {
    local PLUGIN_NAME="$1"
    local USE_SSH="${2:-false}"
    local auto_confirm="${3:-false}"
    local REGISTRY_FILE="$PLUGINS_DIR/registry.yaml"

    # Check if plugin exists in registry (could be dev plugin)
    if [ -f "$REGISTRY_FILE" ]; then
        local plugin_count=$(yq eval ".plugins[] | select(.name == \"$PLUGIN_NAME\") | .name" "$REGISTRY_FILE" 2> /dev/null | wc -l)
        if [ "$plugin_count" -gt 0 ]; then
            local dev_flag=$(yq eval ".plugins[] | select(.name == \"$PLUGIN_NAME\") | .dev" "$REGISTRY_FILE" 2> /dev/null | head -1)
            if [ "$dev_flag" = "true" ]; then
                log_error "Plugin '$PLUGIN_NAME' está em modo desenvolvimento"
                log_output ""
                log_output "${YELLOW}Plugins em modo desenvolvimento não podem ser atualizados.${NC}"
                log_output "As alterações no código já refletem imediatamente!"
                log_output ""
                local source_path=$(yq eval ".plugins[] | select(.name == \"$PLUGIN_NAME\") | .source" "$REGISTRY_FILE" 2> /dev/null | head -1)
                if [ -n "$source_path" ]; then
                    log_output "${GRAY}Local do plugin: $source_path${NC}"
                fi
                exit 1
            fi
        fi
    fi

    # Check if the plugin exists in plugins directory
    if [ ! -d "$PLUGINS_DIR/$PLUGIN_NAME" ]; then
        log_error "Plugin '$PLUGIN_NAME' não encontrado"
        log_output ""
        log_output "Use ${LIGHT_CYAN}susa self plugin list${NC} para ver plugins instalados"
        exit 1
    fi

    # Check if registry exists
    if [ ! -f "$REGISTRY_FILE" ]; then
        log_error "Registry não encontrado. Não é possível determinar a origem do plugin."
        log_output ""
        log_output "O plugin não foi instalado via ${LIGHT_CYAN}susa self plugin add${NC}"
        exit 1
    fi

    # Gets the registry source URL
    local SOURCE_URL=$(registry_get_plugin_info "$REGISTRY_FILE" "$PLUGIN_NAME" "source")
    log_debug "Source URL: $SOURCE_URL"

    if [ -z "$SOURCE_URL" ] || [ "$SOURCE_URL" = "local" ]; then
        log_error "Plugin '$PLUGIN_NAME' não tem origem registrada ou é local"
        log_output ""
        log_output "Apenas plugins instalados via Git podem ser atualizados"
        exit 1
    fi

    # Check if git is installed
    ensure_git_installed || exit 1

    # Detect provider from source URL
    local provider=$(detect_git_provider "$SOURCE_URL")
    log_debug "Provider detectado: $provider"

    # Normalize URL (apply SSH if forced or auto-detected)
    SOURCE_URL=$(normalize_git_url "$SOURCE_URL" "$USE_SSH" "$provider")
    log_debug "URL normalizada: $SOURCE_URL"

    if ! validate_repo_access "$SOURCE_URL"; then
        log_error "Não foi possível acessar o repositório"
        log_debug "Falha na validação de acesso"
        log_output ""
        log_output "${LIGHT_YELLOW}Possíveis causas:${NC}"
        log_output "  • Repositório foi removido ou renomeado"
        log_output "  • Você perdeu acesso ao repositório privado"
        log_output "  • Credenciais Git não estão mais válidas"
        log_output ""
        log_output "${LIGHT_YELLOW}Soluções:${NC}"
        log_output "  • Verifique se o repositório ainda existe"
        log_output "  • Use --ssh se for repositório privado"
        log_output "  • Reconfigure suas credenciais Git"
        exit 1
    fi
    log_debug "Acesso ao repositório validado"

    log_info "Atualizando plugin: $PLUGIN_NAME"
    log_output "  ${GRAY}Origem: $SOURCE_URL${NC}"
    log_output ""

    # Confirm update
    if [ "$auto_confirm" = false ]; then
        read -p "Deseja continuar? (y/N): " -n 1 -r
        echo ""

        if [[ ! $REPLY =~ ^[YySs]$ ]]; then
            log_info "Operação cancelada"
            exit 0
        fi
    fi

    # Create backup of current plugin
    local BACKUP_DIR="${PLUGINS_DIR}/.backup_${PLUGIN_NAME}_$(date +%s)"

    mv "$PLUGINS_DIR/$PLUGIN_NAME" "$BACKUP_DIR"

    # Clones the latest version
    log_debug "Clonando para: $PLUGINS_DIR/$PLUGIN_NAME"
    if clone_plugin "$SOURCE_URL" "$PLUGINS_DIR/$PLUGIN_NAME"; then

        # Detect new version
        local NEW_VERSION=$(detect_plugin_version "$PLUGINS_DIR/$PLUGIN_NAME")
        log_debug "Nova versão: $NEW_VERSION"

        # Count commands and get categories
        local cmd_count=$(count_plugin_commands "$PLUGINS_DIR/$PLUGIN_NAME")

        local categories=$(get_plugin_categories "$PLUGINS_DIR/$PLUGIN_NAME")
        log_debug "Categorias: $categories"

        # Update registry (remove and add again with metadata)
        registry_remove_plugin "$REGISTRY_FILE" "$PLUGIN_NAME"
        registry_add_plugin "$REGISTRY_FILE" "$PLUGIN_NAME" "$SOURCE_URL" "$NEW_VERSION" "false" "$cmd_count" "$categories"
        log_debug "Registry atualizado"

        # Remove backup
        rm -rf "$BACKUP_DIR"
        log_debug "Backup removido"

        # Update lock file if it exists
        update_lock_file

        # Get information from lock file
        local lock_version=$(get_plugin_info_from_lock "$PLUGIN_NAME" "version")
        local lock_commands=$(get_plugin_info_from_lock "$PLUGIN_NAME" "commands")
        local lock_categories=$(get_plugin_info_from_lock "$PLUGIN_NAME" "categories")

        # Use lock info if available, fallback to detected values
        local display_version="${lock_version:-$NEW_VERSION}"
        local display_commands="${lock_commands:-$cmd_count}"
        local display_categories="${lock_categories:-$categories}"

        log_success "Plugin '$PLUGIN_NAME' atualizado com sucesso!"
        log_output ""
        log_output "Detalhes da atualização:"
        log_output "  ${GRAY}Nova versão: $display_version${NC}"
        log_output "  ${GRAY}Comandos: $display_commands${NC}"
        if [ -n "$display_categories" ]; then
            log_output "  ${GRAY}Categorias: $display_categories${NC}"
        fi

        log_output ""
        log_info "💡 Os comandos atualizados já estão disponíveis!"
    else
        log_error "Falha ao baixar atualização"

        # Restore backup
        log_info "Restaurando versão anterior..."
        mv "$BACKUP_DIR" "$PLUGINS_DIR/$PLUGIN_NAME"

        exit 1
    fi
}

# Parse arguments first, before running main
require_arguments "$@"

USE_SSH="false"
auto_confirm=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h | --help)
            show_help
            exit 0
            ;;
        -y | --yes)
            auto_confirm=true
            shift
            ;;
        -v | --verbose)
            export DEBUG=1
            shift
            ;;
        -q | --quiet)
            export SILENT=1
            shift
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

# Validate required argument
validate_required_arg "${PLUGIN_ARG:-}" "Nome do plugin" "<plugin-name> [opções]"

# Execute main function
main "$PLUGIN_ARG" "$USE_SSH" "$auto_confirm"
