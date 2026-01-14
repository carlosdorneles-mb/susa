#!/bin/bash
set -euo pipefail


# Source necessary libraries
source "$LIB_DIR/internal/registry.sh"
source "$LIB_DIR/internal/plugin.sh"
source "$LIB_DIR/internal/args.sh"

# Help function
show_help() {
    show_description
    echo ""
    show_usage "<plugin-name>"
    echo ""
    echo -e "${LIGHT_GREEN}Descrição:${NC}"
    echo "  Remove um plugin instalado do Susa CLI, incluindo"
    echo "  todos os seus comandos e registro no sistema."
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  -h, --help    Mostra esta mensagem de ajuda"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo "  susa self plugin remove backup-tools    # Remove o plugin backup-tools"
    echo "  susa self plugin remove --help          # Exibe esta ajuda"
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

    # Confirm removal
    echo -e "${YELLOW}Atenção:${NC} Você está prestes a remover o plugin '$PLUGIN_NAME'"
    echo ""

    # List commands that will be removed
    local cmd_count=$(find "$PLUGINS_DIR/$PLUGIN_NAME" -name "config.yaml" -type f | wc -l)
    echo -e "Comandos que serão removidos: ${GRAY}$cmd_count${NC}"
    echo ""

    read -p "Deseja continuar? (s/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        log_info "Operação cancelada"
        exit 0
    fi

    # Remove o plugin
    log_info "Removendo plugin '$PLUGIN_NAME'..."

    local REGISTRY_FILE="$PLUGINS_DIR/registry.yaml"

    if rm -rf "$PLUGINS_DIR/$PLUGIN_NAME"; then
        # Remove from registry too
        if [ -f "$REGISTRY_FILE" ]; then
            registry_remove_plugin "$REGISTRY_FILE" "$PLUGIN_NAME"
            log_debug "Plugin removido do registry.yaml"
        fi

        log_success "Plugin '$PLUGIN_NAME' removido com sucesso!"

        # Update lock file if it exists
        update_lock_file
    else
        log_error "Falha ao remover o plugin"
        exit 1
    fi
}

# Parse arguments first, before running main
require_arguments "$@"

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

# Validate required argument
validate_required_arg "${PLUGIN_ARG:-}" "Nome do plugin" "<plugin-name>"

# Execute main function
main "$PLUGIN_ARG"
