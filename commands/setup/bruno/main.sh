#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/github.sh"

# Constants
BRUNO_NAME="Bruno"
BRUNO_REPO="usebruno/bruno"
BRUNO_BIN_NAME="bruno"
BRUNO_HOMEBREW_CASK="bruno"
BRUNO_GITHUB_REPO="usebruno/bruno"
BRUNO_INSTALL_DIR="/opt/bruno"
BRUNO_DESKTOP_FILE="/usr/share/applications/bruno.desktop"
BRUNO_BIN_NAME_LINK="/usr/local/bin/bruno"

SKIP_CONFIRM=false
# Help function
show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  $BRUNO_NAME é um cliente de API open-source rápido e amigável para Git."
    log_output "  Alternativa ao Postman/Insomnia, armazena coleções diretamente"
    log_output "  em uma pasta no seu sistema de arquivos. Usa linguagem de"
    log_output "  marcação própria (Bru) para salvar informações sobre requisições API."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o Bruno do sistema"
    log_output "  -y, --yes         Pula confirmação (usar com --uninstall)"
    log_output "  -u, --upgrade     Atualiza o Bruno para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup bruno              # Instala o $BRUNO_NAME"
    log_output "  susa setup bruno --upgrade    # Atualiza o $BRUNO_NAME"
    log_output "  susa setup bruno --uninstall  # Desinstala o $BRUNO_NAME"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O Bruno estará disponível no menu de aplicativos ou via:"
    log_output "    bruno                   # Abre o Bruno"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Offline-first - sem sincronização em nuvem"
    log_output "  • Armazena coleções em pastas no sistema de arquivos"
    log_output "  • Versionamento com Git"
    log_output "  • Linguagem de marcação própria (Bru)"
    log_output "  • Suporte a REST, GraphQL e gRPC"
    log_output "  • Variáveis de ambiente"
    log_output "  • Scripts e testes"
    log_output "  • Colaboração via Git"
    log_output ""
    log_output "${LIGHT_GREEN}Diferencial:${NC}"
    log_output "  Ao contrário do Postman, Bruno armazena suas coleções diretamente"
    log_output "  no sistema de arquivos, permitindo usar Git para controle de versão"
    log_output "  e colaboração sem depender de sincronização em nuvem."
}

# Get latest version (not implemented)
get_latest_version() {
    github_get_latest_version "$BRUNO_REPO"
}

# Get installed Bruno version
get_current_version() {
    local os_type=$(get_simple_os)

    if [ "$os_type" = "mac" ]; then
        if brew list --cask "$BRUNO_HOMEBREW_CASK" &> /dev/null; then
            brew list --cask "$BRUNO_HOMEBREW_CASK" --versions | awk '{print $2}'
        else
            echo "desconhecida"
        fi
    elif [ "$os_type" = "linux" ]; then
        # Try version file first
        if [ -f "$BRUNO_INSTALL_DIR/version.txt" ]; then
            cat "$BRUNO_INSTALL_DIR/version.txt"
        # Try dpkg for deb packages
        elif command -v dpkg &> /dev/null && dpkg -l bruno 2> /dev/null | grep -q '^ii'; then
            dpkg -l bruno 2> /dev/null | grep '^ii' | awk '{print $3}' | cut -d'-' -f1
        # Try rpm for rpm packages
        elif command -v rpm &> /dev/null && rpm -q bruno &> /dev/null; then
            rpm -q --queryformat '%{VERSION}' bruno 2> /dev/null
        else
            echo "desconhecida"
        fi
    else
        echo "desconhecida"
    fi
}

# Check if Bruno is installed
check_installation() {
    command -v bruno &> /dev/null
}

# Check if Bruno is already installed
check_existing_installation() {
    local os_type=$(get_simple_os)
    local is_installed=false

    if [ "$os_type" = "mac" ]; then
        if brew list --cask "$BRUNO_HOMEBREW_CASK" &> /dev/null; then
            is_installed=true
        fi
    elif [ "$os_type" = "linux" ]; then
        if check_installation || [ -x "$BRUNO_BIN_NAME_LINK" ]; then
            is_installed=true
        fi
    fi

    if [ "$is_installed" = false ]; then
        log_debug "Bruno não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)
    log_info "Bruno $current_version já está instalado."

    # Mark as installed in lock file
    register_or_update_software_in_lock "$COMMAND_NAME" "$current_version"

    log_output ""
    log_output "${YELLOW}Para atualizar, execute:${NC} ${LIGHT_CYAN}susa setup bruno --upgrade${NC}"

    return 1
}

# Install Bruno on macOS using Homebrew
install_bruno_macos() {
    log_info "Instalando Bruno no macOS..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    # Install or upgrade Bruno
    log_debug "Executando: brew install --cask $BRUNO_HOMEBREW_CASK"
    if brew list --cask "$BRUNO_HOMEBREW_CASK" &> /dev/null; then
        log_info "Atualizando Bruno via Homebrew..."
        brew upgrade --cask "$BRUNO_HOMEBREW_CASK" || {
            log_warning "Bruno já está na versão mais recente"
        }
    else
        log_info "Instalando Bruno via Homebrew..."
        brew install --cask "$BRUNO_HOMEBREW_CASK"
    fi

    log_success "Bruno instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para abrir o Bruno:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}open -a Bruno${NC}"
}

# Install Bruno on Linux
install_bruno_linux() {
    log_info "Instalando Bruno no Linux..."

    # Get latest version from GitHub
    log_info "Buscando última versão do Bruno..."
    local version=$(github_get_latest_version "$BRUNO_GITHUB_REPO")

    if [ -z "$version" ]; then
        log_error "Não foi possível obter a versão mais recente"
        return 1
    fi

    log_info "Versão mais recente: $version"

    # Determine architecture and build download URL
    local arch=$(uname -m)
    local download_url=""
    local deb_pattern=""

    case "$arch" in
        x86_64)
            deb_pattern="amd64_linux.deb"
            ;;
        aarch64)
            deb_pattern="arm64_linux.deb"
            ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    # Construct download URL
    download_url="https://github.com/${BRUNO_GITHUB_REPO}/releases/download/${version}/bruno_${version#v}_${deb_pattern}"

    log_debug "URL de download: $download_url"

    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local deb_file="$temp_dir/bruno.deb"

    # Download Bruno
    if ! github_download_release "$download_url" "$deb_file" "Bruno"; then
        log_error "Falha ao baixar Bruno"
        rm -rf "$temp_dir"
        return 1
    fi

    # Install based on package manager
    if command -v apt-get &> /dev/null; then
        log_info "Instalando pacote .deb..."
        sudo apt-get install -y "$deb_file"
    elif command -v dpkg &> /dev/null; then
        log_info "Instalando pacote .deb..."
        sudo dpkg -i "$deb_file"
        sudo apt-get install -f -y 2> /dev/null || true
    else
        log_error "Sistema não suporta pacotes .deb. Instale manualmente ou use outra distribuição."
        rm -rf "$temp_dir"
        return 1
    fi

    # Save version info
    echo "$version" | sudo tee "$BRUNO_INSTALL_DIR/version.txt" > /dev/null 2>&1 || true

    # Cleanup
    rm -rf "$temp_dir"

    log_success "Bruno instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para abrir o Bruno:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}bruno${NC}"
}

# Main installation function
install_bruno() {
    local os_type=$(get_simple_os)

    if [ "$os_type" = "mac" ]; then
        install_bruno_macos
    elif [ "$os_type" = "linux" ]; then
        install_bruno_linux
    else
        log_error "Sistema operacional não suportado: $os_type"
        return 1
    fi

    # Mark as installed
    local version=$(get_current_version)
    register_or_update_software_in_lock "$COMMAND_NAME" "$version"
}

# Update Bruno
update_bruno() {
    log_info "Atualizando Bruno..."

    local os_type=$(get_simple_os)
    local is_installed=false

    if [ "$os_type" = "mac" ]; then
        if brew list --cask "$BRUNO_HOMEBREW_CASK" &> /dev/null; then
            is_installed=true
        fi
    elif [ "$os_type" = "linux" ]; then
        if check_installation || [ -x "$BRUNO_BIN_NAME_LINK" ]; then
            is_installed=true
        fi
    fi

    if [ "$is_installed" = false ]; then
        log_warning "Bruno não está instalado. Execute sem --upgrade para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    if [ "$os_type" = "mac" ]; then
        log_info "Atualizando via Homebrew..."
        brew upgrade --cask "$BRUNO_HOMEBREW_CASK" || {
            log_info "Bruno já está na versão mais recente"
        }
    elif [ "$os_type" = "linux" ]; then
        log_info "Reinstalando Bruno com a versão mais recente..."
        install_bruno_linux
    fi

    local new_version=$(get_current_version)
    log_success "Bruno atualizado para versão $new_version"

    # Update lock file
    register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"
}

# Uninstall Bruno
uninstall_bruno() {
    log_info "Desinstalando Bruno..."

    local os_type=$(get_simple_os)
    local is_installed=false

    if [ "$os_type" = "mac" ]; then
        if brew list --cask "$BRUNO_HOMEBREW_CASK" &> /dev/null; then
            is_installed=true
        fi
    elif [ "$os_type" = "linux" ]; then
        if check_installation || [ -x "$BRUNO_BIN_NAME_LINK" ]; then
            is_installed=true
        fi
    fi

    if [ "$is_installed" = false ]; then
        log_warning "Bruno não está instalado"
        return 0
    fi

    local current_version=$(get_current_version 2> /dev/null || echo "unknown")

    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja realmente desinstalar o Bruno $current_version? (s/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    if [ "$os_type" = "mac" ]; then
        log_info "Desinstalando via Homebrew..."
        brew uninstall --cask "$BRUNO_HOMEBREW_CASK"
    elif [ "$os_type" = "linux" ]; then
        if command -v apt-get &> /dev/null; then
            log_info "Desinstalando via apt-get..."
            sudo apt-get remove -y bruno
        elif command -v dpkg &> /dev/null; then
            log_info "Desinstalando via dpkg..."
            sudo dpkg -r bruno
        fi

        # Cleanup additional files
        sudo rm -f "$BRUNO_DESKTOP_FILE" 2> /dev/null || true
        sudo rm -rf "$BRUNO_INSTALL_DIR" 2> /dev/null || true
    fi

    log_success "Bruno desinstalado com sucesso!"

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
                show_software_info "$BRUNO_BIN_NAME"
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
                show_help
                exit 1
                ;;
        esac
    done

    # Execute requested action
    if [ "$should_uninstall" = true ]; then
        uninstall_bruno
    elif [ "$should_update" = true ]; then
        update_bruno
    else
        check_existing_installation || exit 0
        install_bruno
    fi
}

# Run main function
main "$@"
