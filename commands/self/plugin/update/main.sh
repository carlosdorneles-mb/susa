#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source necessary libraries
source "$LIB_DIR/internal/registry.sh"
source "$LIB_DIR/internal/plugin.sh"
source "$LIB_DIR/internal/lock.sh"
source "$LIB_DIR/internal/args.sh"

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
    log_output "  susa self plugin update 						 # Atualiza o plugin do diretório atual (dev plugin)"
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
    local REGISTRY_FILE="$PLUGINS_DIR/registry.json"

    # Check if registry exists
    if [ ! -f "$REGISTRY_FILE" ]; then
        log_error "Registry não encontrado. Não é possível determinar a origem do plugin."
        log_output ""
        log_output "O plugin não foi instalado via ${LIGHT_CYAN}susa self plugin add${NC}"
        exit 1
    fi

    # Check if plugin exists in registry (could be dev plugin)
    local plugin_count=$(jq -r ".plugins[] | select(.name == \"$PLUGIN_NAME\") | .name // empty" "$REGISTRY_FILE" 2> /dev/null | wc -l)
    if [ "$plugin_count" -gt 0 ]; then
        local dev_flag=$(jq -r ".plugins[] | select(.name == \"$PLUGIN_NAME\") | .dev // false" "$REGISTRY_FILE" 2> /dev/null | head -1)
        if [ "$dev_flag" = "true" ]; then
            log_info "Plugin ${BOLD}$PLUGIN_NAME${NC} está em modo desenvolvimento."

            local source_path=$(jq -r ".plugins[] | select(.name == \"$PLUGIN_NAME\") | .source // empty" "$REGISTRY_FILE" 2> /dev/null | head -1)
            if [ -z "$source_path" ] || [ ! -d "$source_path" ]; then
                log_error "Caminho do plugin dev não encontrado: $source_path"
                exit 1
            fi

            # Validate plugin.json still exists and is valid
            if ! validate_plugin_config "$source_path"; then
                log_error "Plugin inválido: plugin.json não encontrado ou inválido"
                log_output ""
                log_output "${LIGHT_YELLOW}O plugin deve ter um plugin.json válido.${NC}"
                exit 1
            fi

            # Update plugin registry with latest metadata
            if ! update_plugin_registry "$PLUGIN_NAME" "$source_path" "true"; then
                log_error "Falha ao atualizar o registry"
                exit 1
            fi

            # Use the updated name from global variable (may have changed in plugin.json)
            PLUGIN_NAME="$UPDATED_PLUGIN_NAME"

            # Update lock file to reflect any changes
            if ! update_lock_file; then
                log_error "Falha ao atualizar o lock"
                exit 1
            fi

            # Read metadata for display
            local plugin_version=$(detect_plugin_version "$source_path")
            local cmd_count=$(count_plugin_commands "$source_path")
            local categories=$(get_plugin_categories "$source_path")
            local description=$(get_plugin_description "$source_path")
            local directory=$(get_plugin_directory "$source_path")

            # Show success message
            log_success "Plugin ${BOLD}$PLUGIN_NAME${NC} atualizado em modo desenvolvimento!"
            log_output ""
            show_plugin_details "$PLUGIN_NAME" "$plugin_version" "$cmd_count" "$categories" "$description" "$directory" "$source_path" "" "true"
            log_output ""

            log_info "💡 As alterações no código já refletem imediatamente!"

            exit 0
        fi
    fi

    # Check if the plugin exists in plugins directory
    if [ ! -d "$PLUGINS_DIR/$PLUGIN_NAME" ]; then
        log_error "Plugin ${BOLD}$PLUGIN_NAME${NC} não encontrado."
        log_output ""
        log_output "Use ${LIGHT_CYAN}susa self plugin list${NC} para ver plugins instalados."
        exit 1
    fi

    # Gets the registry source URL
    local SOURCE_URL=$(registry_get_plugin_info "$REGISTRY_FILE" "$PLUGIN_NAME" "source")
    log_debug "Source URL: $SOURCE_URL"

    if [ -z "$SOURCE_URL" ] || [ "$SOURCE_URL" = "local" ]; then
        log_error "Plugin ${BOLD}$PLUGIN_NAME${NC} não tem origem registrada ou é local"
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
        read -p "Deseja continuar? (s/N): " -n 1 -r
        log_output ""

        if [[ ! $REPLY =~ ^[YySs]$ ]]; then
            log_info "Operação cancelada"
            exit 0
        fi
    fi

    # Create backup of current plugin
    local BACKUP_DIR="${PLUGINS_DIR}/.backup_${PLUGIN_NAME}_$(date +%s)"

    mv "$PLUGINS_DIR/$PLUGIN_NAME" "$BACKUP_DIR"

    # Extract temp name from URL for cloning
    local temp_plugin_name=$(extract_plugin_name "$SOURCE_URL")
    log_debug "Nome temporário para clone: $temp_plugin_name"

    # Clones the latest version
    log_debug "Clonando para: $PLUGINS_DIR/$temp_plugin_name"
    if clone_plugin "$SOURCE_URL" "$PLUGINS_DIR/$temp_plugin_name"; then

        # Validate plugin.json
        if ! validate_plugin_config "$PLUGINS_DIR/$temp_plugin_name"; then
            log_error "Plugin atualizado inválido: plugin.json não encontrado ou inválido"
            log_output ""
            log_output "${LIGHT_YELLOW}O plugin atualizado não contém um plugin.json válido.${NC}"
            log_info "Restaurando versão anterior..."
            rm -rf "${PLUGINS_DIR:?}/${temp_plugin_name:?}"
            mv "$BACKUP_DIR" "$PLUGINS_DIR/$PLUGIN_NAME"
            exit 1
        fi
        log_debug "plugin.json validado com sucesso"

        # Get actual plugin name from plugin.json
        local actual_plugin_name=$(get_plugin_name "$PLUGINS_DIR/$temp_plugin_name")
        if [ $? -ne 0 ]; then
            log_error "Não foi possível ler o nome do plugin.json"
            log_info "Restaurando versão anterior..."
            rm -rf "${PLUGINS_DIR:?}/${temp_plugin_name:?}"
            mv "$BACKUP_DIR" "$PLUGINS_DIR/$PLUGIN_NAME"
            exit 1
        fi
        log_debug "Nome do plugin (do plugin.json): $actual_plugin_name"

        # Store old name in case it changed
        local old_plugin_name="$PLUGIN_NAME"

        # Check if name changed
        if [ "$actual_plugin_name" != "$PLUGIN_NAME" ]; then
            log_warning "Nome do plugin mudou: $PLUGIN_NAME → $actual_plugin_name"
            log_output ""
            log_output "${LIGHT_YELLOW}O plugin foi renomeado no plugin.json.${NC}"
            log_output "O plugin será registrado com o novo nome."
            log_output ""

            # Remove old entry from registry
            registry_remove_plugin "$REGISTRY_FILE" "$PLUGIN_NAME"

            # Update PLUGIN_NAME to new name
            PLUGIN_NAME="$actual_plugin_name"
        fi

        # Rename if temp name differs from actual name
        if [ "$temp_plugin_name" != "$PLUGIN_NAME" ]; then
            log_debug "Renomeando de $temp_plugin_name para $PLUGIN_NAME"
            mv "$PLUGINS_DIR/$temp_plugin_name" "$PLUGINS_DIR/$PLUGIN_NAME"
        fi

        # Update registry with new metadata (handles version, description, directory, etc)
        # Pass SOURCE_URL as 4th parameter for Git plugins
        if ! update_plugin_registry "$PLUGIN_NAME" "$PLUGINS_DIR/$PLUGIN_NAME" "false" "$SOURCE_URL"; then
            log_error "Falha ao atualizar o registry"
            log_info "Restaurando versão anterior..."
            rm -rf "${PLUGINS_DIR:?}/${PLUGIN_NAME:?}"
            mv "$BACKUP_DIR" "$PLUGINS_DIR/$old_plugin_name"
            # Restore old registry entry if name changed
            if [ "$old_plugin_name" != "$PLUGIN_NAME" ]; then
                registry_remove_plugin "$REGISTRY_FILE" "$PLUGIN_NAME"
            fi
            exit 1
        fi
        log_debug "Registry atualizado via update_plugin_registry"

        # Detect new version for display
        local NEW_VERSION=$(detect_plugin_version "$PLUGINS_DIR/$PLUGIN_NAME")
        log_debug "Nova versão: $NEW_VERSION"

        # Count commands and get categories for display
        local cmd_count=$(count_plugin_commands "$PLUGINS_DIR/$PLUGIN_NAME")
        local categories=$(get_plugin_categories "$PLUGINS_DIR/$PLUGIN_NAME")
        log_debug "Categorias: $categories"

        # Remove backup
        rm -rf "$BACKUP_DIR"
        log_debug "Backup removido"

        # Update lock file if it exists
        if ! update_lock_file; then
            log_error "Falha ao atualizar o lock"
            exit 1
        fi

        # Get information from lock file
        local lock_version=$(get_plugin_info_from_lock "$PLUGIN_NAME" "version")
        local lock_commands=$(get_plugin_info_from_lock "$PLUGIN_NAME" "commands")
        local lock_categories=$(get_plugin_info_from_lock "$PLUGIN_NAME" "categories")

        # Use lock info if available, fallback to detected values
        local display_version="${lock_version:-$NEW_VERSION}"
        local display_commands="${lock_commands:-$cmd_count}"
        local display_categories="${lock_categories:-$categories}"

        log_success "Plugin ${BOLD}$PLUGIN_NAME${NC} atualizado com sucesso!"
        log_output ""
        show_plugin_details "$PLUGIN_NAME" "$display_version" "$display_commands" "$display_categories"
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
USE_SSH="false"
auto_confirm=false
PLUGIN_ARG=""

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

# If no plugin argument provided, try to detect from current directory
if [ -z "$PLUGIN_ARG" ]; then
    CURRENT_DIR="$(pwd)"
    REGISTRY_FILE="$PLUGINS_DIR/registry.json"

    # Try to find plugin name from registry by matching current directory
    if [ -f "$REGISTRY_FILE" ]; then
        DETECTED_PLUGIN=$(jq -r ".plugins[] | select(.dev == true and .source == \"$CURRENT_DIR\") | .name // empty" "$REGISTRY_FILE" 2> /dev/null | head -1)

        if [ -n "$DETECTED_PLUGIN" ]; then
            log_debug "Plugin detectado no diretório atual: $DETECTED_PLUGIN"
            PLUGIN_ARG="$DETECTED_PLUGIN"
        else
            log_error "Nenhum plugin especificado e diretório atual não é um plugin em modo desenvolvimento"
            log_output ""
            show_usage "<plugin-name> [opções]"
            exit 1
        fi
    else
        log_error "Nenhum plugin especificado"
        log_output ""
        show_usage "<plugin-name> [opções]"
        exit 1
    fi
fi

# Execute main function
main "$PLUGIN_ARG" "$USE_SSH" "$auto_confirm"
