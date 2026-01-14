#!/bin/bash
set -euo pipefail

setup_command_env

# Source completion library
source "$LIB_DIR/completion.sh"

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
    # Find symlink path
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
    CURRENT_SHELL=$(detect_shell_type)
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
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
    shift
done

# Execute main function
main
