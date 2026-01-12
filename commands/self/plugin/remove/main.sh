#!/bin/bash

# ============================================================
# Susa CLI - Comando de Remoção de Plugins
# ============================================================

set -euo pipefail

setup_command_env

source "$CLI_DIR/lib/registry.sh"

show_help() {
    show_description
    echo ""
    show_usage "<plugin-name>"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo -e "  susa self plugin remove backup-tools"
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo -e "  -h, --help    Mostra esta mensagem de ajuda"
}

# Verifica argumentos
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

PLUGIN_NAME="$1"

# Verifica se plugin existe
if [ ! -d "$PLUGINS_DIR/$PLUGIN_NAME" ]; then
    log_error "Plugin '$PLUGIN_NAME' não encontrado"
    echo ""
    echo -e "Use ${LIGHT_CYAN}susa self plugin list${NC} para ver plugins instalados"
    exit 1
fi

# Confirma remoção
echo -e "${YELLOW}Atenção:${NC} Você está prestes a remover o plugin '$PLUGIN_NAME'"
echo ""

# Lista comandos que serão removidos
cmd_count=$(find "$PLUGINS_DIR/$PLUGIN_NAME" -name "config.yaml" -type f | wc -l)
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

REGISTRY_FILE="$PLUGINS_DIR/registry.yaml"

if rm -rf "$PLUGINS_DIR/$PLUGIN_NAME"; then
    # Remove do registry também
    if [ -f "$REGISTRY_FILE" ]; then
        registry_remove_plugin "$REGISTRY_FILE" "$PLUGIN_NAME"
        log_debug "Plugin removido do registry.yaml"
    fi
    
    echo ""
    log_success "Plugin '$PLUGIN_NAME' removido com sucesso!"
else
    log_error "Falha ao remover o plugin"
    exit 1
fi
