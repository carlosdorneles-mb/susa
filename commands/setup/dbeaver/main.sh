#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"

# Help function
show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  DBeaver é uma ferramenta universal de gerenciamento de banco de dados,"
    log_output "  gratuita e open-source. Suporta MySQL, PostgreSQL, SQLite, Oracle,"
    log_output "  SQL Server, DB2, Sybase, MS Access, Teradata, Firebird, Apache Hive,"
    log_output "  Phoenix, Presto e mais de 80 tipos de bancos de dados."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o DBeaver do sistema"
    log_output "  --update          Atualiza o DBeaver para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup dbeaver              # Instala o DBeaver"
    log_output "  susa setup dbeaver --update     # Atualiza o DBeaver"
    log_output "  susa setup dbeaver --uninstall  # Desinstala o DBeaver"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O DBeaver estará disponível no menu de aplicativos ou via:"
    log_output "    dbeaver                 # Abre o DBeaver"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Suporte a 80+ tipos de bancos de dados"
    log_output "  • Editor SQL com syntax highlighting e autocompletar"
    log_output "  • Navegador de schema e metadata"
    log_output "  • Editor ER Diagram"
    log_output "  • Transferência de dados entre databases"
    log_output "  • Execução de scripts e queries"
    log_output "  • Geração de dados mock"
}

# Get installed DBeaver version
get_dbeaver_version() {
    if command -v dbeaver &> /dev/null; then
        local version=$(dbeaver -version 2>&1 | grep -i "Version" | awk '{print $2}' || echo "desconhecida")
        if [ "$version" != "desconhecida" ] && [ -n "$version" ]; then
            echo "$version"
        else
            echo "instalada"
        fi
    else
        echo "desconhecida"
    fi
}

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# Check if DBeaver is already installed
check_existing_installation() {
    if ! command -v dbeaver &> /dev/null; then
        log_debug "DBeaver não está instalado"
        return 0
    fi

    local current_version=$(get_dbeaver_version)
    log_info "DBeaver $current_version já está instalado."

    # Mark as installed in lock file
    mark_installed "dbeaver" "$current_version"

    log_output ""
    log_output "${YELLOW}Para atualizar, execute:${NC} ${LIGHT_CYAN}susa setup dbeaver --update${NC}"

    return 1
}

# Install DBeaver on macOS using Homebrew
install_dbeaver_macos() {
    log_info "Instalando DBeaver no macOS..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    # Install or upgrade DBeaver
    log_debug "Executando: brew install --cask $DBEAVER_HOMEBREW_CASK"
    if brew list --cask "$DBEAVER_HOMEBREW_CASK" &> /dev/null; then
        log_info "Atualizando DBeaver via Homebrew..."
        brew upgrade --cask "$DBEAVER_HOMEBREW_CASK" || {
            log_warning "DBeaver já está na versão mais recente"
        }
    else
        log_info "Instalando DBeaver via Homebrew..."
        brew install --cask "$DBEAVER_HOMEBREW_CASK"
    fi

    log_success "DBeaver instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para abrir o DBeaver:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}dbeaver${NC}"
}

# Install DBeaver on Debian/Ubuntu
install_dbeaver_debian() {
    log_info "Instalando DBeaver no Debian/Ubuntu..."

    # Add DBeaver repository key
    log_debug "Adicionando chave GPG do repositório DBeaver..."
    curl -fsSL "$DBEAVER_APT_KEY_URL" | sudo gpg --dearmor -o /usr/share/keyrings/dbeaver.gpg

    # Add DBeaver repository
    log_debug "Adicionando repositório DBeaver..."
    echo "deb [signed-by=/usr/share/keyrings/dbeaver.gpg] $DBEAVER_APT_REPO /" |
        sudo tee /etc/apt/sources.list.d/dbeaver.list > /dev/null

    # Update package list
    log_debug "Atualizando lista de pacotes..."
    sudo apt-get update -qq

    # Install DBeaver
    log_info "Instalando pacote $DBEAVER_PACKAGE_NAME..."
    sudo apt-get install -y "$DBEAVER_PACKAGE_NAME"

    log_success "DBeaver instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para abrir o DBeaver:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}dbeaver${NC}"
}

# Install DBeaver on RHEL/Fedora
install_dbeaver_rhel() {
    log_info "Instalando DBeaver no RHEL/Fedora..."

    # Get latest version from GitHub
    log_info "Obtendo informações da versão mais recente..."
    local latest_version=$(github_get_latest_version "$DBEAVER_GITHUB_REPO")

    if [ -z "$latest_version" ]; then
        log_error "Não foi possível determinar a versão mais recente"
        return 1
    fi

    log_info "Versão mais recente: $latest_version"

    # Determine architecture
    local arch=$(uname -m)
    local rpm_arch=""

    if [ "$arch" = "x86_64" ]; then
        rpm_arch="x86_64"
    elif [ "$arch" = "aarch64" ]; then
        rpm_arch="aarch64"
    else
        log_error "Arquitetura não suportada: $arch"
        return 1
    fi

    # Construct download URL
    local rpm_file="${DBEAVER_PACKAGE_NAME}-${latest_version}-stable.${rpm_arch}.rpm"
    local download_url="https://github.com/${DBEAVER_GITHUB_REPO}/releases/download/${latest_version}/${rpm_file}"

    log_info "Baixando DBeaver..."
    log_debug "URL: $download_url"

    # Download and install
    local temp_file="/tmp/${rpm_file}"
    curl -L -o "$temp_file" "$download_url"

    log_info "Instalando DBeaver..."
    sudo rpm -i "$temp_file" || sudo dnf install -y "$temp_file"

    # Cleanup
    rm -f "$temp_file"

    log_success "DBeaver instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para abrir o DBeaver:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}dbeaver${NC}"
}

# Install DBeaver on Arch Linux
install_dbeaver_arch() {
    log_info "Instalando DBeaver no Arch Linux..."

    # Check if yay or paru is available
    if command -v yay &> /dev/null; then
        log_info "Instalando DBeaver via yay (AUR)..."
        yay -S --noconfirm dbeaver
    elif command -v paru &> /dev/null; then
        log_info "Instalando DBeaver via paru (AUR)..."
        paru -S --noconfirm dbeaver
    else
        log_error "É necessário um AUR helper (yay ou paru) para instalar o DBeaver"
        log_output "Instale yay ou paru primeiro:"
        log_output "  sudo pacman -S --needed git base-devel"
        log_output "  git clone https://aur.archlinux.org/yay.git"
        log_output "  cd yay && makepkg -si"
        return 1
    fi

    log_success "DBeaver instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para abrir o DBeaver:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}dbeaver${NC}"
}

# Main installation function
install_dbeaver() {
    local os_type=$(get_os)

    if [ "$os_type" = "mac" ]; then
        install_dbeaver_macos
    elif [ "$os_type" = "linux" ]; then
        local distro=$(detect_distro)
        log_debug "Distribuição detectada: $distro"

        case "$distro" in
            ubuntu | debian | pop | linuxmint | elementary)
                install_dbeaver_debian
                ;;
            fedora | rhel | centos | rocky | alma)
                install_dbeaver_rhel
                ;;
            arch | manjaro | endeavouros)
                install_dbeaver_arch
                ;;
            *)
                log_error "Distribuição Linux não suportada: $distro"
                log_output "Distribuições suportadas: Ubuntu, Debian, Fedora, RHEL, CentOS, Arch"
                return 1
                ;;
        esac
    else
        log_error "Sistema operacional não suportado: $os_type"
        return 1
    fi

    # Mark as installed
    local version=$(get_dbeaver_version)
    mark_installed "dbeaver" "$version"
}

# Update DBeaver
update_dbeaver() {
    log_info "Atualizando DBeaver..."

    if ! command -v dbeaver &> /dev/null; then
        log_warning "DBeaver não está instalado. Execute sem --update para instalar."
        return 1
    fi

    local current_version=$(get_dbeaver_version)
    log_info "Versão atual: $current_version"

    local os_type=$(get_os)

    if [ "$os_type" = "mac" ]; then
        log_info "Atualizando via Homebrew..."
        brew upgrade --cask "$DBEAVER_HOMEBREW_CASK" || {
            log_info "DBeaver já está na versão mais recente"
        }
    elif [ "$os_type" = "linux" ]; then
        local distro=$(detect_distro)

        case "$distro" in
            ubuntu | debian | pop | linuxmint | elementary)
                log_info "Atualizando via apt..."
                sudo apt-get update -qq
                sudo apt-get install --only-upgrade -y "$DBEAVER_PACKAGE_NAME"
                ;;
            fedora | rhel | centos | rocky | alma)
                log_info "Atualizando via dnf/yum..."
                sudo dnf upgrade -y "$DBEAVER_PACKAGE_NAME" || sudo yum update -y "$DBEAVER_PACKAGE_NAME"
                ;;
            arch | manjaro | endeavouros)
                log_info "Atualizando via AUR helper..."
                if command -v yay &> /dev/null; then
                    yay -Syu --noconfirm dbeaver
                elif command -v paru &> /dev/null; then
                    paru -Syu --noconfirm dbeaver
                fi
                ;;
        esac
    fi

    local new_version=$(get_dbeaver_version)
    log_success "DBeaver atualizado para versão $new_version"

    # Update lock file
    mark_installed "dbeaver" "$new_version"
}

# Uninstall DBeaver
uninstall_dbeaver() {
    log_info "Desinstalando DBeaver..."

    if ! command -v dbeaver &> /dev/null; then
        log_warning "DBeaver não está instalado"
        return 0
    fi

    local os_type=$(get_os)

    if [ "$os_type" = "mac" ]; then
        log_info "Desinstalando via Homebrew..."
        brew uninstall --cask "$DBEAVER_HOMEBREW_CASK"
    elif [ "$os_type" = "linux" ]; then
        local distro=$(detect_distro)

        case "$distro" in
            ubuntu | debian | pop | linuxmint | elementary)
                log_info "Desinstalando via apt..."
                sudo apt-get remove --purge -y "$DBEAVER_PACKAGE_NAME"
                sudo rm -f /etc/apt/sources.list.d/dbeaver.list
                sudo rm -f /usr/share/keyrings/dbeaver.gpg
                ;;
            fedora | rhel | centos | rocky | alma)
                log_info "Desinstalando via dnf/yum..."
                sudo dnf remove -y "$DBEAVER_PACKAGE_NAME" || sudo yum remove -y "$DBEAVER_PACKAGE_NAME"
                ;;
            arch | manjaro | endeavouros)
                log_info "Desinstalando via AUR helper..."
                if command -v yay &> /dev/null; then
                    yay -Rns --noconfirm dbeaver
                elif command -v paru &> /dev/null; then
                    paru -Rns --noconfirm dbeaver
                fi
                ;;
        esac
    fi

    log_success "DBeaver desinstalado com sucesso!"

    # Remove from lock file
    mark_uninstalled "dbeaver"
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
            --update)
                should_update=true
                ;;
            --uninstall)
                should_uninstall=true
                ;;
            -v | --verbose)
                # Verbose already handled by CLI framework
                ;;
            -q | --quiet)
                # Quiet already handled by CLI framework
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
        uninstall_dbeaver
    elif [ "$should_update" = true ]; then
        update_dbeaver
    else
        # Check if already installed before attempting installation
        if check_existing_installation; then
            install_dbeaver
        fi
    fi
}

# Run main function
main "$@"
