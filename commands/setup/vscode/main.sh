#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/os.sh"

# Constants
VSCODE_NAME="Visual Studio Code"
VSCODE_REPO="microsoft/vscode"
VSCODE_BIN_NAME="code"
VSCODE_HOMEBREW_CASK="visual-studio-code"
VSCODE_APT_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
VSCODE_APT_REPO="https://packages.microsoft.com/repos/code"
VSCODE_RPM_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
VSCODE_RPM_REPO_URL="https://packages.microsoft.com/yumrepos/vscode"
VSCODE_DEB_PACKAGE="code"
VSCODE_RPM_PACKAGE="code"
VSCODE_ARCH_AUR="visual-studio-code-bin"
VSCODE_ARCH_COMMUNITY="code"

SKIP_CONFIRM=false
# Help function
show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Visual Studio Code é um editor de código-fonte desenvolvido pela Microsoft."
    log_output "  Gratuito e open-source, oferece depuração integrada, controle Git,"
    log_output "  syntax highlighting, IntelliSense, snippets e refatoração de código."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o VS Code do sistema"
    log_output "  -y, --yes         Pula confirmação (usar com --uninstall)"
    log_output "  -u, --upgrade     Atualiza o VS Code para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup vscode              # Instala o VS Code"
    log_output "  susa setup vscode --upgrade    # Atualiza o VS Code"
    log_output "  susa setup vscode --uninstall  # Desinstala o VS Code"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O VS Code estará disponível no menu de aplicativos ou via:"
    log_output "    code                    # Abre o editor"
    log_output "    code arquivo.txt        # Abre arquivo específico"
    log_output "    code pasta/             # Abre pasta como workspace"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • IntelliSense (autocompletar inteligente)"
    log_output "  • Depurador integrado"
    log_output "  • Controle Git nativo"
    log_output "  • Extensões e temas"
    log_output "  • Terminal integrado"
    log_output "  • Remote Development"
}

# Get latest version
get_latest_version() {
    # VS Code releases are available on GitHub
    local version=$(github_get_latest_version "$VSCODE_REPO" 2> /dev/null)

    if [ -n "$version" ] && [ "$version" != "null" ]; then
        echo "$version"
    else
        echo "desconhecida"
    fi
}

# Get installed VS Code version
get_current_version() {
    if check_installation; then
        local version=$($VSCODE_BIN_NAME --version 2> /dev/null | head -1 || echo "desconhecida")
        if [ "$version" != "desconhecida" ]; then
            echo "$version"
        fi
    else
        echo "desconhecida"
    fi
}

# Check if VS Code is installed
check_installation() {
    command -v $VSCODE_BIN_NAME &> /dev/null
}

# Install VS Code on macOS using Homebrew
install_vscode_macos() {
    log_info "Instalando VS Code no macOS..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    # Install or upgrade VS Code
    if brew list --cask $VSCODE_HOMEBREW_CASK &> /dev/null 2>&1; then
        log_info "Atualizando VS Code via Homebrew..."
        brew upgrade --cask $VSCODE_HOMEBREW_CASK || true
    else
        log_info "Instalando VS Code via Homebrew..."
        brew install --cask $VSCODE_HOMEBREW_CASK
    fi

    return 0
}

# Install VS Code on Debian/Ubuntu
install_vscode_debian() {
    log_info "Instalando VS Code no Debian/Ubuntu..."

    # Install dependencies
    log_info "Instalando dependências..."
    sudo apt-get install -y wget gpg apt-transport-https > /dev/null 2>&1

    # Install GPG key
    log_info "Adicionando chave GPG da Microsoft..."
    wget -qO- $VSCODE_APT_KEY_URL | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

    log_info "Adicionando repositório..."
    echo "deb [arch=amd64,arm64,armhf] $VSCODE_APT_REPO stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

    log_info "Atualizando lista de pacotes..."
    sudo apt-get update > /dev/null 2>&1

    log_info "Instalando VS Code..."
    sudo apt-get install -y $VSCODE_DEB_PACKAGE > /dev/null 2>&1

    return $?
}

# Install VS Code on RHEL/Fedora/CentOS
install_vscode_rhel() {
    log_info "Instalando VS Code no RHEL/Fedora/CentOS..."

    # Import GPG key
    log_info "Importando chave GPG da Microsoft..."
    enabled=1
    gpgcheck=1
    gpgkey=$VSCODE_RPM_KEY_URL
    sudo rpm --import $VSCODE_RPM_KEY_URL > /dev/null 2>&1

    log_info "Adicionando repositório..."
    sudo tee /etc/yum.repos.d/vscode.repo > /dev/null << EOF
[code]
name=Visual Studio Code
baseurl=$VSCODE_RPM_REPO_URL
enabled=1
gpgcheck=1
gpgkey=$VSCODE_RPM_KEY_URL
EOF

    log_info "Instalando VS Code..."
    if command -v dnf &> /dev/null; then
        sudo dnf install -y $VSCODE_RPM_PACKAGE > /dev/null 2>&1
    else
        sudo yum install -y $VSCODE_RPM_PACKAGE > /dev/null 2>&1
    fi

    return $?
}

# Install VS Code on Arch Linux
install_vscode_arch() {
    log_info "Instalando VS Code no Arch Linux..."

    # Install from official repository or AUR
    if command -v yay &> /dev/null; then
        log_info "Instalando via yay..."
        yay -S --noconfirm $VSCODE_ARCH_AUR > /dev/null 2>&1
    elif command -v paru &> /dev/null; then
        log_info "Instalando via paru..."
        paru -S --noconfirm $VSCODE_ARCH_AUR > /dev/null 2>&1
    else
        log_info "Instalando via pacman (repositório comunitário)..."
        sudo pacman -S --noconfirm $VSCODE_ARCH_COMMUNITY > /dev/null 2>&1 || {
            log_warning "VS Code não encontrado no repositório oficial"
            log_info "Tentando instalar helper AUR..."
            log_error "Considere instalar yay ou paru primeiro:"
            log_output "  sudo pacman -S --needed git base-devel"
            log_output "  git clone https://aur.archlinux.org/yay.git"
            log_output "  cd yay && makepkg -si"
            return 1
        }
    fi

    return 0
}

# Install VS Code on Linux
install_vscode_linux() {
    local distro=$(get_distro_id)
    log_debug "Distribuição detectada: $distro"

    case "$distro" in
        ubuntu | debian | pop | linuxmint | elementary)
            install_vscode_debian
            ;;
        fedora | rhel | centos | rocky | almalinux)
            install_vscode_rhel
            ;;
        arch | manjaro | endeavouros)
            install_vscode_arch
            ;;
        *)
            log_error "Distribuição não suportada: $distro"
            log_info "Visite https://code.visualstudio.com/docs/setup/linux para instruções manuais"
            return 1
            ;;
    esac

    return $?
}

# Main installation function
install_vscode() {
    if check_installation; then
        log_info "VS Code $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do VS Code..."

    # Detect OS
    case "$OS_TYPE" in
        macos)
            install_vscode_macos
            ;;
        debian | fedora)
            install_vscode_linux
            ;;
        *)
            log_error "Sistema operacional não suportado: $OS_TYPE"
            return 1
            ;;
    esac

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        # Verify installation
        if check_installation; then
            local installed_version=$(get_current_version)

            # Mark as installed in lock file
            register_or_update_software_in_lock "$COMMAND_NAME" "$installed_version"

            log_success "VS Code $installed_version instalado com sucesso!"
            log_output ""
            log_output "Próximos passos:"
            log_output "  1. Execute: ${LIGHT_CYAN}code${NC} para abrir o editor"
            log_output "  2. Instale extensões: Ctrl/Cmd+Shift+X"
            log_output "  3. Use ${LIGHT_CYAN}susa setup vscode --help${NC} para mais informações"
            log_output ""
            log_output "${LIGHT_GREEN}Dica:${NC} Explore extensões em https://marketplace.visualstudio.com"
        else
            log_error "VS Code foi instalado mas não está disponível no PATH"
            return 1
        fi
    else
        return $install_result
    fi
}

# Update VS Code
update_vscode() {
    log_info "Atualizando VS Code..."

    # Check if VS Code is installed
    if ! check_installation; then
        log_error "VS Code não está instalado. Use 'susa setup vscode' para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    # Detect OS and update
    case "$OS_TYPE" in
        macos)
            if ! command -v brew &> /dev/null; then
                log_error "Homebrew não está instalado"
                return 1
            fi

            log_info "Atualizando VS Code via Homebrew..."
            brew upgrade --cask $VSCODE_HOMEBREW_CASK || {
                log_info "VS Code já está na versão mais recente"
                return 0
            }
            ;;
        debian | fedora)
            local distro=$(get_distro_id)
            log_debug "Distribuição detectada: $distro"

            case "$distro" in
                ubuntu | debian | pop | linuxmint | elementary)
                    log_info "Atualizando VS Code via apt..."
                    sudo apt-get update > /dev/null 2>&1
                    sudo apt-get install --only-upgrade -y $VSCODE_DEB_PACKAGE > /dev/null 2>&1
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    log_info "Atualizando VS Code via dnf/yum..."
                    if command -v dnf &> /dev/null; then
                        sudo dnf upgrade -y $VSCODE_RPM_PACKAGE > /dev/null 2>&1
                    else
                        sudo yum update -y $VSCODE_RPM_PACKAGE > /dev/null 2>&1
                    fi
                    ;;
                arch | manjaro | endeavouros)
                    log_info "Atualizando VS Code via pacman/AUR..."
                    if command -v yay &> /dev/null; then
                        yay -Syu --noconfirm $VSCODE_ARCH_AUR > /dev/null 2>&1
                    elif command -v paru &> /dev/null; then
                        paru -Syu --noconfirm $VSCODE_ARCH_AUR > /dev/null 2>&1
                    else
                        sudo pacman -Syu --noconfirm $VSCODE_ARCH_COMMUNITY > /dev/null 2>&1
                    fi
                    ;;
                *)
                    log_error "Distribuição não suportada: $distro"
                    return 1
                    ;;
            esac
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    # Verify update
    if check_installation; then
        local new_version=$(get_current_version)

        # Update version in lock file
        register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"

        if [ "$current_version" = "$new_version" ]; then
            log_info "VS Code já estava na versão mais recente ($current_version)"
        else
            log_success "VS Code atualizado com sucesso para versão $new_version!"
        fi
    else
        log_error "Falha na atualização do VS Code"
        return 1
    fi
}

# Uninstall VS Code
uninstall_vscode() {
    log_info "Desinstalando VS Code..."

    # Check if VS Code is installed
    if ! check_installation; then
        log_info "VS Code não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)
    log_debug "Versão a ser removida: $current_version"

    log_output ""
    if [ "$SKIP_CONFIRM" = false ]; then
        log_output "${YELLOW}Deseja realmente desinstalar o VS Code $current_version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    case "$OS_TYPE" in
        macos)
            # Uninstall via Homebrew
            if command -v brew &> /dev/null; then
                log_info "Removendo VS Code via Homebrew..."
                brew uninstall --cask $VSCODE_HOMEBREW_CASK 2> /dev/null || log_debug "VS Code não instalado via Homebrew"
            fi
            ;;
        debian | fedora)
            local distro=$(get_distro_id)
            log_debug "Distribuição detectada: $distro"

            case "$distro" in
                ubuntu | debian | pop | linuxmint | elementary)
                    log_info "Removendo VS Code via apt..."
                    sudo apt-get purge -y $VSCODE_DEB_PACKAGE > /dev/null 2>&1
                    sudo apt-get autoremove -y > /dev/null 2>&1

                    # Remove repository
                    sudo rm -f /etc/apt/sources.list.d/vscode.list
                    sudo rm -f /etc/apt/trusted.gpg.d/microsoft.gpg
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    log_info "Removendo VS Code via dnf/yum..."
                    if command -v dnf &> /dev/null; then
                        sudo dnf remove -y code > /dev/null 2>&1
                    else
                        sudo yum remove -y code > /dev/null 2>&1
                    fi

                    # Remove repository
                    sudo rm -f /etc/yum.repos.d/vscode.repo
                    ;;
                arch | manjaro | endeavouros)
                    log_info "Removendo VS Code via pacman..."
                    if command -v yay &> /dev/null; then
                        yay -Rns --noconfirm $VSCODE_ARCH_AUR > /dev/null 2>&1 || sudo pacman -Rns --noconfirm $VSCODE_ARCH_COMMUNITY > /dev/null 2>&1
                    elif command -v paru &> /dev/null; then
                        paru -Rns --noconfirm $VSCODE_ARCH_AUR > /dev/null 2>&1 || sudo pacman -Rns --noconfirm $VSCODE_ARCH_COMMUNITY > /dev/null 2>&1
                    else
                        sudo pacman -Rns --noconfirm $VSCODE_ARCH_COMMUNITY > /dev/null 2>&1
                    fi
                    ;;
            esac
            ;;
    esac

    # Verify uninstallation
    if ! check_installation; then
        # Mark as uninstalled in lock file
        remove_software_in_lock "$COMMAND_NAME"

        log_success "VS Code desinstalado com sucesso!"
    else
        log_error "Falha ao desinstalar VS Code completamente"
        return 1
    fi

    # Detect OS for configuration paths
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    # Ask about configuration removal
    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja remover também as configurações e extensões do VS Code? (s/N)${NC}"
        read -r config_response

        if [[ "$config_response" =~ ^[sSyY]$ ]]; then
            log_info "Removendo configurações e extensões..."

            case "$os_name" in
                darwin)
                    rm -rf "$HOME/Library/Application Support/Code" 2> /dev/null || true
                    log_debug "Configurações removidas: ~/Library/Application Support/Code"
                    rm -rf "$HOME/.vscode" 2> /dev/null || true
                    log_debug "Extensões removidas: ~/.vscode"
                    rm -rf "$HOME/Library/Caches/com.microsoft.VSCode" 2> /dev/null || true
                    log_debug "Cache removido"
                    ;;
                linux)
                    rm -rf "$HOME/.config/Code" 2> /dev/null || true
                    log_debug "Configurações removidas: ~/.config/Code"
                    rm -rf "$HOME/.vscode" 2> /dev/null || true
                    log_debug "Extensões removidas: ~/.vscode"
                    rm -rf "$HOME/.cache/vscode" 2> /dev/null || true
                    log_debug "Cache removido: ~/.cache/vscode"
                    ;;
            esac

            log_success "Configurações e extensões removidas"
        else
            log_info "Configurações mantidas"
        fi
    else
        # Auto-remove when --yes is used
        log_info "Removendo configurações e extensões automaticamente..."

        case "$os_name" in
            darwin)
                rm -rf "$HOME/Library/Application Support/Code" 2> /dev/null || true
                log_debug "Configurações removidas: ~/Library/Application Support/Code"
                rm -rf "$HOME/.vscode" 2> /dev/null || true
                log_debug "Extensões removidas: ~/.vscode"
                rm -rf "$HOME/Library/Caches/com.microsoft.VSCode" 2> /dev/null || true
                log_debug "Cache removido"
                ;;
            linux)
                rm -rf "$HOME/.config/Code" 2> /dev/null || true
                log_debug "Configurações removidas: ~/.config/Code"
                rm -rf "$HOME/.vscode" 2> /dev/null || true
                log_debug "Extensões removidas: ~/.vscode"
                rm -rf "$HOME/.cache/vscode" 2> /dev/null || true
                log_debug "Cache removido: ~/.cache/vscode"
                ;;
        esac

        log_info "Configurações e extensões removidas automaticamente"
    fi
}

# Main function
main() {
    local action="install"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
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
                show_software_info "$VSCODE_BIN_NAME"
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
            --uninstall)
                action="uninstall"
                shift
                ;;
            -y | --yes)
                SKIP_CONFIRM=true
                shift
                ;;
            -u | --upgrade)
                action="update"
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Execute action
    case "$action" in
        install)
            install_vscode
            ;;
        update)
            update_vscode
            ;;
        uninstall)
            uninstall_vscode
            ;;
        *)
            log_error "Ação desconhecida: $action"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
