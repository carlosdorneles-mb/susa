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
    show_usage "<git-url|user/repo>"
    echo ""
    echo -e "${LIGHT_GREEN}Formato:${NC}"
    echo -e "  susa self plugin install ${GRAY}<git-url>${NC}"
    echo -e "  susa self plugin install ${GRAY}<github-user>/<repo>${NC}"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo -e "  susa self plugin install https://github.com/user/susa-plugin-name"
    echo -e "  susa self plugin install user/susa-plugin-name"
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo -e "  -h, --help    Mostra esta mensagem de ajuda"
}

# Main function
main() {
    local PLUGIN_URL="$1"
    
    # Normaliza URL (converte user/repo para URL completa)
    PLUGIN_URL=$(normalize_git_url "$PLUGIN_URL")
    
    # Extrai nome do plugin da URL
    PLUGIN_NAME=$(extract_plugin_name "$PLUGIN_URL")
    
    log_info "Instalando plugin: $PLUGIN_NAME"
    echo ""
    
    # Verifica se git está instalado
    ensure_git_installed || exit 1
    
    # Verifica se plugin já existe
    if [ -d "$PLUGINS_DIR/$PLUGIN_NAME" ]; then
        log_error "Plugin '$PLUGIN_NAME' já está instalado"
        echo ""
        echo -e "Para atualizar, use: ${LIGHT_CYAN}susa self plugin update $PLUGIN_NAME${NC}"
        exit 1
    fi
    
    # Cria diretório de plugins se não existir
    mkdir -p "$PLUGINS_DIR"
    
    # Clona o repositório
    log_info "Clonando de $PLUGIN_URL..."
    if clone_plugin "$PLUGIN_URL" "$PLUGINS_DIR/$PLUGIN_NAME"; then
        # Detecta versão do plugin
        PLUGIN_VERSION=$(detect_plugin_version "$PLUGINS_DIR/$PLUGIN_NAME")
        
        # Registra no registry.yaml
        REGISTRY_FILE="$PLUGINS_DIR/registry.yaml"
        if registry_add_plugin "$REGISTRY_FILE" "$PLUGIN_NAME" "$PLUGIN_URL" "$PLUGIN_VERSION"; then
            log_debug "Plugin registrado no registry.yaml"
        else
            log_warning "Não foi possível registrar no registry (plugin pode já existir)"
        fi
        
        # Conta comandos instalados
        cmd_count=$(count_plugin_commands "$PLUGINS_DIR/$PLUGIN_NAME")
        
        echo ""
        log_success "Plugin '$PLUGIN_NAME' instalado com sucesso!"
        echo -e "  ${GRAY}Origem: $PLUGIN_URL${NC}"
        echo -e "  ${GRAY}Versão: $PLUGIN_VERSION${NC}"
        echo -e "  ${GRAY}Comandos: $cmd_count${NC}"
        echo ""
        echo -e "Use ${LIGHT_CYAN}susa self plugin list${NC} para ver todos os plugins"
    else
        log_error "Falha ao clonar o repositório"
        rm -rf "$PLUGINS_DIR/$PLUGIN_NAME"
        exit 1
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
            # Argumento é a URL/nome do plugin
            PLUGIN_ARG="$1"
            shift
            break
            ;;
    esac
done

# Checks if URL was provided
if [ -z "${PLUGIN_ARG:-}" ]; then
    log_error "URL ou nome do plugin não fornecido"
    show_usage
    exit 1
fi

# Execute main function
main "$PLUGIN_ARG"
