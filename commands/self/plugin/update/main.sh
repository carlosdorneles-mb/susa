#!/bin/bash

# ============================================================
# Susa CLI - Comando de Atualização de Plugins
# ============================================================

set -euo pipefail

setup_command_env

source "$CLI_DIR/lib/registry.sh"
source "$CLI_DIR/lib/plugin.sh"

show_help() {
    show_description
    echo ""
    show_usage "<plugin-name>"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo -e "  susa self plugin update backup-tools"
    echo ""
    echo -e "${LIGHT_GREEN}Descrição:${NC}"
    echo -e "  Baixa novamente o plugin da origem registrada e"
    echo -e "  substitui a instalação atual pela versão mais recente."
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

# Verifica se registry existe
if [ ! -f "$REGISTRY_FILE" ]; then
    log_error "Registry não encontrado. Não é possível determinar a origem do plugin."
    echo ""
    echo -e "O plugin não foi instalado via ${LIGHT_CYAN}susa self plugin install${NC}"
    exit 1
fi

# Obtém a URL de origem do registry
SOURCE_URL=$(registry_get_plugin_info "$REGISTRY_FILE" "$PLUGIN_NAME" "source")

if [ -z "$SOURCE_URL" ] || [ "$SOURCE_URL" = "local" ]; then
    log_error "Plugin '$PLUGIN_NAME' não tem origem registrada ou é local"
    echo ""
    echo -e "Apenas plugins instalados via Git podem ser atualizados"
    exit 1
fi

# Verifica se git está instalado
ensure_git_installed || exit 1

log_info "Atualizando plugin: $PLUGIN_NAME"
echo -e "  ${GRAY}Origem: $SOURCE_URL${NC}"
echo ""

# Confirma atualização
read -p "Deseja continuar? (s/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log_info "Operação cancelada"
    exit 0
fi

# Cria diretório temporário
TEMP_DIR=$(mktemp -d)
BACKUP_DIR="${PLUGINS_DIR}/.backup_${PLUGIN_NAME}_$(date +%s)"

# Faz backup do plugin atual
log_info "Criando backup..."
mv "$PLUGINS_DIR/$PLUGIN_NAME" "$BACKUP_DIR"

# Clona a versão mais recente
log_info "Baixando versão mais recente de $SOURCE_URL..."
if git clone "$SOURCE_URL" "$PLUGINS_DIR/$PLUGIN_NAME" 2>&1; then
    # Remove .git para economizar espaço
    rm -rf "$PLUGINS_DIR/$PLUGIN_NAME/.git"
   clone_plugin "$SOURCE_URL" "$PLUGINS_DIR/$PLUGIN_NAME"; then
    # Detecta nova versão
    NEW_VERSION=$(detect_plugin_version "$PLUGINS_DIR/$PLUGIN_NAME")
    
    # Atualiza registry (remove e adiciona novamente)
    registry_remove_plugin "$REGISTRY_FILE" "$PLUGIN_NAME"
    registry_add_plugin "$REGISTRY_FILE" "$PLUGIN_NAME" "$SOURCE_URL" "$NEW_VERSION"
    
    # Remove backup
    rm -rf "$BACKUP_DIR"
    
    # Conta comandos
    cmd_count=$(count_plugin_commands "$PLUGINS_DIR/$PLUGIN_NAME"
    echo -e "  ${GRAY}Nova versão: $NEW_VERSION${NC}"
    echo -e "  ${GRAY}Comandos: $cmd_count${NC}"
else
    log_error "Falha ao baixar atualização"
    
    # Restaura backup
    log_info "Restaurando versão anterior..."
    mv "$BACKUP_DIR" "$PLUGINS_DIR/$PLUGIN_NAME"
    
    exit 1
fi
