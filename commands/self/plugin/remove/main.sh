#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source necessary libraries
source "$LIB_DIR/internal/registry.sh"
source "$LIB_DIR/internal/plugin.sh"
source "$LIB_DIR/internal/args.sh"

# Help function
show_help() {
    show_description
    log_output ""
    show_usage "<plugin-name>"
    log_output ""
    log_output "${LIGHT_GREEN}Descrição:${NC}"
    log_output "  Remove um plugin instalado do Susa CLI, incluindo"
    log_output "  todos os seus comandos e registro no sistema."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -y, --yes         Pula confirmação e remove automaticamente"
    log_output "  -v, --verbose     Modo verbose (debug)"
    log_output "  -q, --quiet       Modo silencioso (mínimo de output)"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa self plugin remove backup-tools    # Remove o plugin backup-tools"
    log_output "  susa self plugin remove				  # Remove o plugin do diretório atual (dev plugin)"
    log_output "  susa self plugin remove --help          # Exibe esta ajuda"
    log_output ""
}

# Main function
main() {
    local PLUGIN_NAME="$1"
    local auto_confirm="${2:-false}"

    local REGISTRY_FILE="$PLUGINS_DIR/registry.json"
    local is_dev_plugin=false
    local source_path=""

    # Check if plugin exists in registry (could be dev plugin)
    if registry_plugin_exists "$REGISTRY_FILE" "$PLUGIN_NAME"; then
        if registry_is_dev_plugin "$REGISTRY_FILE" "$PLUGIN_NAME"; then
            is_dev_plugin=true
            source_path=$(registry_get_plugin_info "$REGISTRY_FILE" "$PLUGIN_NAME" "source" | head -1)
            log_debug "Plugin dev com source: $source_path"
        fi
    fi

    # Check if the plugin exists in plugins directory or registry
    if [ "$is_dev_plugin" = false ]; then
        if [ ! -d "$PLUGINS_DIR/$PLUGIN_NAME" ]; then
            log_error "Plugin ${BOLD}$PLUGIN_NAME${NC} não encontrado"
            log_output ""
            log_output "Use ${LIGHT_CYAN}susa self plugin list${NC} para ver plugins instalados"
            exit 1
        fi

        # Verify plugin name matches plugin.json
        if [ -f "$PLUGINS_DIR/$PLUGIN_NAME/plugin.json" ]; then
            local actual_name=$(get_plugin_name "$PLUGINS_DIR/$PLUGIN_NAME" 2> /dev/null || echo "")
            if [ -n "$actual_name" ] && [ "$actual_name" != "$PLUGIN_NAME" ]; then
                log_warning "Nome do diretório ($PLUGIN_NAME) difere do nome no plugin.json ($actual_name)"
                log_output ""
                log_output "${LIGHT_YELLOW}O plugin será removido usando o nome correto: $actual_name${NC}"
                PLUGIN_NAME="$actual_name"
            fi
        fi
    fi

    # Confirm removal
    log_warning "Você está prestes a remover o plugin ${BOLD}$PLUGIN_NAME${NC}"
    if [ "$is_dev_plugin" = true ]; then
        log_output ""
        log_output "  ${GRAY}Modo: desenvolvimento${NC}"
        if [ -n "$source_path" ]; then
            log_output "  ${GRAY}Local do plugin: $source_path${NC}"
        fi
    fi
    log_output ""

    # List commands that will be removed
    local cmd_count=0
    if [ "$is_dev_plugin" = true ] && [ -d "$source_path" ]; then
        cmd_count=$(find "$source_path" -name "command.json" -type f 2> /dev/null | wc -l)
    elif [ -d "$PLUGINS_DIR/$PLUGIN_NAME" ]; then
        cmd_count=$(find "$PLUGINS_DIR/$PLUGIN_NAME" -name "command.json" -type f | wc -l)
    fi
    log_output "Comandos que serão removidos: ${GRAY}$cmd_count${NC}"
    log_output ""

    if [ "$auto_confirm" = false ]; then
        read -p "Deseja continuar? (s/N): " -n 1 -r
        log_output ""

        if [[ ! $REPLY =~ ^[YySs]$ ]]; then
            log_info "Operação cancelada"
            exit 0
        fi
    fi

    # Remove o plugin
    log_info "Removendo plugin '$PLUGIN_NAME'..."

    local removal_success=true

    if [ "$is_dev_plugin" = true ]; then
        # Dev plugins are only in registry, not in $PLUGINS_DIR
        # Just remove from registry
        if [ -f "$REGISTRY_FILE" ]; then
            registry_remove_plugin "$REGISTRY_FILE" "$PLUGIN_NAME"
        else
            log_error "Registry file não existe"
            removal_success=false
        fi
    else
        if rm -rf "${PLUGINS_DIR:?}/${PLUGIN_NAME:?}"; then
            # Remove from registry too
            if [ -f "$REGISTRY_FILE" ]; then
                registry_remove_plugin "$REGISTRY_FILE" "$PLUGIN_NAME"
            fi
        else
            log_error "Falha ao remover o plugin"
            removal_success=false
        fi
    fi

    if [ "$removal_success" = true ]; then
        log_success "Plugin ${BOLD}$PLUGIN_NAME${NC} removido com sucesso!"

        # Update lock file
        if ! update_lock_file; then
            log_error "Falha ao atualizar o lock"
            exit 1
        fi

        log_output ""
        log_info "💡 Execute 'susa --help' para ver as categorias atualizadas"
    else
        exit 1
    fi
}

# Parse arguments first, before running main
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
        DETECTED_PLUGIN=$(registry_get_plugin_by_source "$REGISTRY_FILE" "$CURRENT_DIR")

        if [ -n "$DETECTED_PLUGIN" ]; then
            log_debug "Plugin detectado no diretório atual: $DETECTED_PLUGIN"
            PLUGIN_ARG="$DETECTED_PLUGIN"
        else
            log_error "Nenhum plugin especificado e diretório atual não é um plugin em modo desenvolvimento"
            log_output ""
            show_usage "<plugin-name>"
            exit 1
        fi
    else
        log_error "Nenhum plugin especificado"
        log_output ""
        show_usage "<plugin-name>"
        exit 1
    fi
fi

# Execute main function
main "$PLUGIN_ARG" "$auto_confirm"
