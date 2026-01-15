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
    log_output "  susa self plugin remove --help          # Exibe esta ajuda"
    log_output ""
}

# Main function
main() {
    local PLUGIN_NAME="$1"
    local auto_confirm="${2:-false}"

    local REGISTRY_FILE="$PLUGINS_DIR/registry.yaml"
    local is_dev_plugin=false
    local source_path=""

    # Check if plugin exists in registry (could be dev plugin)
    if [ -f "$REGISTRY_FILE" ]; then
        local plugin_count=$(yq eval ".plugins[] | select(.name == \"$PLUGIN_NAME\") | .name" "$REGISTRY_FILE" 2> /dev/null | wc -l)
        if [ "$plugin_count" -gt 0 ]; then
            local dev_flag=$(yq eval ".plugins[] | select(.name == \"$PLUGIN_NAME\") | .dev" "$REGISTRY_FILE" 2> /dev/null | head -1)
            if [ "$dev_flag" = "true" ]; then
                is_dev_plugin=true
                source_path=$(yq eval ".plugins[] | select(.name == \"$PLUGIN_NAME\") | .source" "$REGISTRY_FILE" 2> /dev/null | head -1)
                log_debug "Plugin dev com source: $source_path"
            fi
        fi
    fi

    # Check if the plugin exists in plugins directory or registry
    if [ "$is_dev_plugin" = false ]; then
        if [ ! -d "$PLUGINS_DIR/$PLUGIN_NAME" ]; then
            log_error "Plugin '$PLUGIN_NAME' não encontrado"
            log_output ""
            log_output "Use ${LIGHT_CYAN}susa self plugin list${NC} para ver plugins instalados"
            exit 1
        fi
    fi

    # Confirm removal
    log_warning "Você está prestes a remover o plugin '$PLUGIN_NAME'"
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
        cmd_count=$(find "$source_path" -name "config.yaml" -type f 2> /dev/null | wc -l)
    elif [ -d "$PLUGINS_DIR/$PLUGIN_NAME" ]; then
        cmd_count=$(find "$PLUGINS_DIR/$PLUGIN_NAME" -name "config.yaml" -type f | wc -l)
    fi
    log_output "Comandos que serão removidos: ${GRAY}$cmd_count${NC}"
    log_output ""

    if [ "$auto_confirm" = false ]; then
        read -p "Deseja continuar? (y/N): " -n 1 -r
        echo ""

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
        log_success "Plugin '$PLUGIN_NAME' removido com sucesso!"

        # Update lock file
        update_lock_file

        log_output ""
        log_info "💡 Execute 'susa --help' para ver as categorias atualizadas"
    else
        exit 1
    fi
}

# Parse arguments first, before running main
require_arguments "$@"

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
        *)
            # Argument is the name of the plugin
            PLUGIN_ARG="$1"
            shift
            ;;
    esac
done

# Validate required argument
validate_required_arg "${PLUGIN_ARG:-}" "Nome do plugin" "<plugin-name>"

# Execute main function
main "$PLUGIN_ARG" "$auto_confirm"
