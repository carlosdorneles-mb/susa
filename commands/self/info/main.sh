#!/bin/bash
set -euo pipefail
IFS=$'\n\t'


# Source completion library
source "$LIB_DIR/internal/completion.sh"
source "$LIB_DIR/internal/args.sh"

# Help function
show_help() {
    show_description
    echo ""
    show_usage --no-options
    echo ""
    echo -e "${LIGHT_GREEN}Descrição:${NC}"
    echo "  Exibe informações detalhadas sobre a instalação da CLI Susa,"
    echo "  incluindo versão, caminhos, status de completação e dependências."
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  -v, --verbose     Modo verbose (debug)"
    echo "  -h, --help        Exibe esta mensagem de ajuda"
    echo ""
    echo -e "${LIGHT_GREEN}Informações Exibidas:${NC}"
    echo "  • Nome e versão da CLI"
    echo "  • Diretório de instalação"
    echo "  • Localização do link simbólico do executável"
    echo "  • Ambiente de shell atual"
    echo "  • Status de completação do shell"
    echo "  • Detalhes do sistema operacional"
    echo "  • Status das dependências necessárias"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo "  susa self info                # Exibe todas as informações da CLI"
    echo "  susa self info --help         # Exibe esta ajuda"
    echo ""
}

# Main function
main() {
    log_debug "Iniciando coleta de informações do sistema"

    # Find symlink path
    log_debug "Procurando caminho do executável susa"
    SYMLINK_PATH=""
    if command -v susa &> /dev/null; then
        SUSA_BIN=$(command -v susa)
        if [[ -L "$SUSA_BIN" ]]; then
            SYMLINK_PATH="$SUSA_BIN -> $(readlink -f "$SUSA_BIN")"
        else
            SYMLINK_PATH="$SUSA_BIN (direct executable)"
        fi
    else
        SYMLINK_PATH="Not found in PATH"
    fi

    # Get completion status using library functions
    log_debug "Detectando tipo de shell atual"
    CURRENT_SHELL=$(detect_shell_type)
    log_debug "Shell detectado: $CURRENT_SHELL"

    log_debug "Verificando status de completion"
    COMPLETION_STATUS_INFO=$(get_completion_status "$CURRENT_SHELL")

    # Parse completion status (format: status:details:file)
    # Use array to handle details containing colons
    IFS=':' read -r COMPLETION_INSTALLED COMPLETION_DETAILS_REST <<< "$COMPLETION_STATUS_INFO"

    # Split the rest to get details and file (details may contain colons)
    if [[ "$COMPLETION_DETAILS_REST" =~ ^(.*):(/.*)$ ]]; then
        COMPLETION_DETAILS="${BASH_REMATCH[1]}"
        COMPLETION_FILE="${BASH_REMATCH[2]}"
    else
        COMPLETION_DETAILS="$COMPLETION_DETAILS_REST"
        COMPLETION_FILE=""
    fi

    # Display information
    echo -e "${CYAN}╔═════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}           ${BOLD}Informações de Instalação${NC}             ${CYAN}║${NC}"
    echo -e "${CYAN}╚═════════════════════════════════════════════════╝${NC}"
    echo ""

    # Infos
    echo -e "  ${BOLD}📦 Nome:${NC}             ${GREEN}$(get_yaml_field "$GLOBAL_CONFIG_FILE" "name")${NC}"
    echo -e "  ${BOLD}🏷️  Versão:${NC}           ${GREEN}$(show_number_version)${NC}"
    echo -e "  ${BOLD}📂 Instalação:${NC}       ${YELLOW}$CLI_DIR${NC}"
    echo -e "  ${BOLD}🔗 Executável:${NC}       ${YELLOW}$SYMLINK_PATH${NC}"
    echo -e "  ${BOLD}🐚 Shell atual:${NC}      ${CYAN}$CURRENT_SHELL${NC}"

    # Display completion status
    if [[ "$COMPLETION_INSTALLED" == "Installed" ]]; then
        echo -e "  ${BOLD}✨ Autocompletar:${NC}    ${GREEN}Sim${NC} - $COMPLETION_DETAILS"
    elif [[ "$COMPLETION_INSTALLED" == "Not installed" ]]; then
        echo -e "  ${BOLD}✨ Autocompletar:${NC}    ${RED}Não${NC} - $COMPLETION_DETAILS"
    else
        echo -e "  ${BOLD}✨ Autocompletar:${NC}    ${YELLOW}$COMPLETION_INSTALLED${NC} - $COMPLETION_DETAILS"
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            export DEBUG=1
            log_debug "Modo verbose ativado"
            shift
            ;;
        *)
            log_error "Argumento inválido: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
done

# Execute main function
main
