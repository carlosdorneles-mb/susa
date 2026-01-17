#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"

# Constants
POSTMAN_BIN_NAME="postman"
POSTMAN_HOMEBREW_CASK="postman"
POSTMAN_INSTALL_DIR="/opt/Postman"
POSTMAN_DESKTOP_FILE="/usr/share/applications/postman.desktop"
POSTMAN_DOWNLOAD_URL="https://dl.pstmn.io/download/latest/linux64"
POSTMAN_HOMEBREW_CASK="postman"
POSTMAN_DOWNLOAD_URL="https://dl.pstmn.io/download/latest/linux64"
POSTMAN_INSTALL_DIR="/opt/Postman"
POSTMAN_DESKTOP_FILE="/usr/share/applications/postman.desktop"
POSTMAN_ICON_URL="https://www.postman.com/_ar-assets/images/favicon-1-48.png"

SKIP_CONFIRM=false
# Help function
show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Postman é uma plataforma completa para desenvolvimento de APIs."
    log_output "  Permite criar, testar, documentar e monitorar APIs de forma"
    log_output "  colaborativa. Suporta REST, SOAP, GraphQL e WebSocket."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o Postman do sistema"
    log_output "  -y, --yes         Pula confirmação (usar com --uninstall)"
    log_output "  -u, --upgrade     Atualiza o Postman para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup postman              # Instala o Postman"
    log_output "  susa setup postman --upgrade    # Atualiza o Postman"
    log_output "  susa setup postman --uninstall  # Desinstala o Postman"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O Postman estará disponível no menu de aplicativos ou via:"
    log_output "    postman                 # Abre o Postman"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Construtor de requisições HTTP/HTTPS"
    log_output "  • Collections para organizar requests"
    log_output "  • Testes automatizados e scripts"
    log_output "  • Mock servers"
    log_output "  • Documentação automática de APIs"
    log_output "  • Monitoramento de APIs"
    log_output "  • Colaboração em equipe"
}

# Get latest version (not implemented)
get_latest_version() {
    # Postman doesn't provide version API publicly
    # Return empty for now - version is determined after download
    echo "N/A"
}

# Get installed version (not implemented)
get_current_version() {
    local os_type=$(get_simple_os)

    if [ "$os_type" = "mac" ]; then
        # Try to get version via Homebrew
        if command -v brew &> /dev/null && brew list --cask "$POSTMAN_HOMEBREW_CASK" &> /dev/null; then
            brew list --cask "$POSTMAN_HOMEBREW_CASK" --versions 2> /dev/null | awk '{print $2}' || echo "desconhecida"
        else
            echo "desconhecida"
        fi
    elif [ "$os_type" = "linux" ]; then
        # Try to read version from installed directory
        if [ -f "$POSTMAN_INSTALL_DIR/app/resources/app/package.json" ]; then
            grep -oP '"version":\s*"\K[^"]+' "$POSTMAN_INSTALL_DIR/app/resources/app/package.json" 2> /dev/null || echo "desconhecida"
        else
            echo "desconhecida"
        fi
    else
        echo "desconhecida"
    fi
}

# Check if Postman is installed
check_installation() {
    command -v $POSTMAN_BIN_NAME &> /dev/null || { [ "$(uname)" = "Darwin" ] && [ -d "/Applications/Postman.app" ]; }
}

# Install Postman on macOS using Homebrew
install_postman_macos() {
    log_info "Instalando Postman no macOS..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    # Install or upgrade Postman
    log_debug "Executando: brew install --cask $POSTMAN_HOMEBREW_CASK"
    if brew list --cask "$POSTMAN_HOMEBREW_CASK" &> /dev/null; then
        log_info "Atualizando Postman via Homebrew..."
        brew upgrade --cask "$POSTMAN_HOMEBREW_CASK" || {
            log_warning "Postman já está na versão mais recente"
        }
    else
        log_info "Instalando Postman via Homebrew..."
        brew install --cask "$POSTMAN_HOMEBREW_CASK"
    fi

    log_success "Postman instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para abrir o Postman:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}postman${NC}"
}

# Install Postman on Linux
install_postman_linux() {
    log_info "Instalando Postman no Linux..."

    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local tarball="$temp_dir/$POSTMAN_BIN_NAME.tar.gz"

    # Download Postman
    log_info "Baixando Postman..."
    log_debug "URL: $POSTMAN_DOWNLOAD_URL"
    if ! curl -L --progress-bar \
        --connect-timeout 30 \
        --max-time 300 \
        --retry 3 \
        --retry-delay 2 \
        "$POSTMAN_DOWNLOAD_URL" -o "$tarball"; then
        log_error "Falha ao baixar Postman"
        rm -rf "$temp_dir"
        return 1
    fi

    # Remove old installation if exists
    if [ -d "$POSTMAN_INSTALL_DIR" ]; then
        log_info "Removendo instalação anterior..."
        sudo rm -rf "$POSTMAN_INSTALL_DIR"
    fi

    # Extract to /opt
    log_info "Extraindo Postman..."
    sudo tar -xzf "$tarball" -C /opt

    # Create symbolic link
    log_info "Criando link simbólico..."
    sudo ln -sf "$POSTMAN_INSTALL_DIR/Postman" /usr/local/bin/$POSTMAN_BIN_NAME

    # Create desktop entry
    log_info "Criando entrada no menu de aplicativos..."
    sudo tee "$POSTMAN_DESKTOP_FILE" > /dev/null << EOF
[Desktop Entry]
Name=Postman
GenericName=API Development Environment
Comment=Postman makes API development easy
Exec=$POSTMAN_INSTALL_DIR/Postman
Terminal=false
Type=Application
Icon=$POSTMAN_INSTALL_DIR/app/resources/app/assets/icon.png
Categories=Development;
EOF

    # Set permissions
    sudo chmod +x "$POSTMAN_DESKTOP_FILE"

    # Cleanup
    rm -rf "$temp_dir"

    log_success "Postman instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para abrir o Postman:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}postman${NC}"
}

# Main installation function
install_postman() {
    if check_installation; then
        log_info "$POSTMAN_BIN_NAME $(get_current_version) já está instalado."
        exit 0
    fi

    local os_type=$(get_simple_os)

    if [ "$os_type" = "mac" ]; then
        install_postman_macos
    elif [ "$os_type" = "linux" ]; then
        install_postman_linux
    else
        log_error "Sistema operacional não suportado: $os_type"
        return 1
    fi

    # Mark as installed
    local version=$(get_current_version)
    register_or_update_software_in_lock "$COMMAND_NAME" "$version"
}

# Update Postman
update_postman() {
    log_info "Atualizando Postman..."

    if ! check_installation; then
        log_warning "$POSTMAN_BIN_NAME não está instalado. Execute sem --upgrade para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    local os_type=$(get_simple_os)

    if [ "$os_type" = "mac" ]; then
        log_info "Atualizando via Homebrew..."
        brew upgrade --cask "$POSTMAN_HOMEBREW_CASK" || {
            log_info "$POSTMAN_BIN_NAME já está na versão mais recente"
        }
    elif [ "$os_type" = "linux" ]; then
        log_info "Reinstalando $POSTMAN_BIN_NAME com a versão mais recente..."
        install_postman_linux
    fi

    local new_version=$(get_current_version)
    log_success "$POSTMAN_BIN_NAME atualizado para versão $new_version"

    # Update lock file
    register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"
}

# Uninstall Postman
uninstall_postman() {
    log_info "Desinstalando Postman..."

    if ! check_installation; then
        log_warning "$POSTMAN_BIN_NAME não está instalado"
        return 0
    fi

    local current_version=$(get_current_version 2> /dev/null || echo "unknown")

    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja realmente desinstalar o Postman $current_version? (s/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    local os_type=$(get_simple_os)

    if [ "$os_type" = "mac" ]; then
        log_info "Desinstalando via Homebrew..."
        brew uninstall --cask "$POSTMAN_HOMEBREW_CASK"
    elif [ "$os_type" = "linux" ]; then
        log_info "Removendo arquivos do $POSTMAN_BIN_NAME..."
        sudo rm -rf "$POSTMAN_INSTALL_DIR"
        sudo rm -f /usr/local/bin/$POSTMAN_BIN_NAME
        sudo rm -f "$POSTMAN_DESKTOP_FILE"
    fi

    log_success "$POSTMAN_BIN_NAME desinstalado com sucesso!"

    # Remove from lock file
    remove_software_in_lock "$COMMAND_NAME"
}

# Main execution
main() {
    # Parse arguments
    local should_update=false
    local should_uninstall=false

    for arg in "$@"; do
        case "$arg" in
            -h | --help)
                show_help
                exit 0
                ;;
            -v | --verbose)
                log_debug "Modo verbose ativado"
                export DEBUG=true
                ;;
            -q | --quiet)
                export SILENT=true
                ;;
            --info)
                show_software_info "$POSTMAN_BIN_NAME"
                exit 0
                ;;
            --get-current-version)
                get_current_version
                exit 0
                ;;
            --get-latest-version)
                get_latest_version
                exit 0
                ;;
            --check-installation)
                check_installation
                exit $?
                ;;
            -y | --yes)
                SKIP_CONFIRM=true
                shift
                ;;
            -u | --upgrade)
                should_update=true
                ;;
            --uninstall)
                should_uninstall=true
                ;;
            *)
                log_error "Opção desconhecida: $arg"
                log_output "Use -h ou --help para ver as opções disponíveis"
                exit 1
                ;;
        esac
    done

    # Execute requested action
    if [ "$should_uninstall" = true ]; then
        uninstall_postman
    elif [ "$should_update" = true ]; then
        update_postman
    else
        install_postman
    fi
}

# Run main function
main "$@"
