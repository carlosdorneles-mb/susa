#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/os.sh"

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
    log_output "  -u, --upgrade     Atualiza o DBeaver para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup dbeaver              # Instala o DBeaver"
    log_output "  susa setup dbeaver --upgrade    # Atualiza o DBeaver"
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

# Get latest version (not implemented)
get_latest_version() {
    github_get_latest_version "$DBEAVER_GITHUB_REPO"
}

# Get installed DBeaver version
get_current_version() {
    # Check version file first (for GitHub releases)
    if [ -f "$DBEAVER_INSTALL_DIR/version.txt" ]; then
        cat "$DBEAVER_INSTALL_DIR/version.txt"
    elif check_installation; then
        local version=$(dbeaver -version 2>&1 | grep -i "Version" | awk '{print $2}' || echo "desconhecida")
        if [ "$version" != "desconhecida" ] && [ -n "$version" ]; then
            echo "$version"
        fi
    else
        echo "desconhecida"
    fi
}

# Check if DBeaver is installed
check_installation() {
    command -v dbeaver &> /dev/null || ([ "$(uname)" = "Linux" ] && dpkg -l 2> /dev/null | grep -q dbeaver)
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

# Install DBeaver on Debian/Ubuntu from GitHub .deb
install_dbeaver_debian_from_github() {
    log_info "Instalando DBeaver via GitHub releases..."

    # Get latest version from GitHub
    local version=$(github_get_latest_version "$DBEAVER_GITHUB_REPO")

    if [ -z "$version" ]; then
        log_error "Não foi possível obter a versão mais recente"
        return 1
    fi

    log_info "Versão mais recente: $version"

    # Determine architecture
    local arch=$(uname -m)
    local deb_arch=""

    case "$arch" in
        x86_64)
            deb_arch="amd64"
            ;;
        aarch64)
            deb_arch="arm64"
            ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    # Construct download URL
    local download_url="https://github.com/${DBEAVER_GITHUB_REPO}/releases/download/${version}/${DBEAVER_PACKAGE_NAME}_${version}_${deb_arch}.deb"

    log_debug "URL de download: $download_url"

    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local deb_file="$temp_dir/dbeaver.deb"

    # Download DBeaver
    if ! github_download_release "$download_url" "$deb_file" "DBeaver"; then
        log_error "Falha ao baixar DBeaver"
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
        log_error "Sistema não suporta pacotes .deb"
        rm -rf "$temp_dir"
        return 1
    fi

    # Save version info
    sudo mkdir -p "$DBEAVER_INSTALL_DIR"
    echo "$version" | sudo tee "$DBEAVER_INSTALL_DIR/version.txt" > /dev/null 2>&1 || true

    # Cleanup
    rm -rf "$temp_dir"

    log_success "DBeaver instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para abrir o DBeaver:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}dbeaver${NC}"
}

# Install DBeaver on Debian/Ubuntu
install_dbeaver_debian() {
    log_info "Instalando DBeaver no Debian/Ubuntu..."

    # Try repository installation first
    log_info "Tentando instalação via repositório oficial..."

    if curl -fsSL "$DBEAVER_APT_KEY_URL" | sudo gpg --dearmor -o /usr/share/keyrings/dbeaver.gpg 2> /dev/null; then
        echo "deb [signed-by=/usr/share/keyrings/dbeaver.gpg] $DBEAVER_APT_REPO /" |
            sudo tee /etc/apt/sources.list.d/dbeaver.list > /dev/null

        if sudo apt-get update -qq 2> /dev/null && sudo apt-get install -y "$DBEAVER_PACKAGE_NAME" 2> /dev/null; then
            log_success "DBeaver instalado com sucesso via repositório!"
            log_output ""
            log_output "${LIGHT_CYAN}Para abrir o DBeaver:${NC}"
            log_output "  • Via menu de aplicativos"
            log_output "  • Via terminal: ${LIGHT_GREEN}dbeaver${NC}"
            return 0
        fi
    fi

    # Fallback to GitHub tar.gz
    log_warning "Repositório não disponível, usando instalação via GitHub..."
    install_dbeaver_debian_from_github
}

# Install DBeaver on RHEL/Fedora
install_dbeaver_rhel() {
    log_info "Instalando DBeaver no RHEL/Fedora..."

    # Get latest version from GitHub
    log_info "Buscando última versão do DBeaver..."
    local version=$(github_get_latest_version "$DBEAVER_GITHUB_REPO")

    if [ -z "$version" ]; then
        log_error "Não foi possível obter a versão mais recente"
        return 1
    fi

    log_info "Versão mais recente: $version"

    # Determine architecture
    local arch=$(uname -m)
    local rpm_arch=""

    case "$arch" in
        x86_64)
            rpm_arch="x86_64"
            ;;
        aarch64)
            rpm_arch="aarch64"
            ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    # Construct download URL
    local rpm_file="${DBEAVER_PACKAGE_NAME}-${version}-stable.${rpm_arch}.rpm"
    local download_url="https://github.com/${DBEAVER_GITHUB_REPO}/releases/download/${version}/${rpm_file}"

    log_debug "URL de download: $download_url"

    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local temp_file="$temp_dir/${rpm_file}"

    # Download DBeaver
    if ! github_download_release "$download_url" "$temp_file" "DBeaver"; then
        log_error "Falha ao baixar DBeaver"
        rm -rf "$temp_dir"
        return 1
    fi

    # Install based on package manager
    if command -v dnf &> /dev/null; then
        log_info "Instalando pacote .rpm via dnf..."
        sudo dnf install -y "$temp_file"
    elif command -v yum &> /dev/null; then
        log_info "Instalando pacote .rpm via yum..."
        sudo yum install -y "$temp_file"
    elif command -v rpm &> /dev/null; then
        log_info "Instalando pacote .rpm..."
        sudo rpm -i "$temp_file"
    else
        log_error "Sistema não suporta pacotes .rpm"
        rm -rf "$temp_dir"
        return 1
    fi

    # Save version info
    sudo mkdir -p "$DBEAVER_INSTALL_DIR"
    echo "$version" | sudo tee "$DBEAVER_INSTALL_DIR/version.txt" > /dev/null 2>&1 || true

    # Cleanup
    rm -rf "$temp_dir"

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
    if check_installation; then
        log_info "DBeaver $(get_current_version) já está instalado."
        exit 0
    fi

    local os_type=$(get_simple_os)

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
    local version=$(get_current_version)
    register_or_update_software_in_lock "dbeaver" "$version"
}

# Update DBeaver
update_dbeaver() {
    log_info "Atualizando DBeaver..."

    if ! check_installation; then
        log_warning "DBeaver não está instalado. Execute sem --upgrade para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    local os_type=$(get_simple_os)

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

    local new_version=$(get_current_version)
    log_success "DBeaver atualizado para versão $new_version"

    # Update lock file
    register_or_update_software_in_lock "dbeaver" "$new_version"
}

# Uninstall DBeaver
uninstall_dbeaver() {
    log_info "Desinstalando DBeaver..."

    if ! check_installation; then
        log_warning "DBeaver não está instalado"
        return 0
    fi

    local os_type=$(get_simple_os)

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
    remove_software_in_lock "dbeaver"
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
                show_software_info
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
        uninstall_dbeaver
    elif [ "$should_update" = true ]; then
        update_dbeaver
    else
        install_dbeaver
    fi
}

# Run main function
main "$@"
