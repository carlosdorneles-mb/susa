#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/os.sh"

# Constants
SUBLIME_NAME="Sublime Text"
SUBLIME_REPO="sublimehq/sublime_text"
SUBLIME_BIN_NAME="subl"
SUBLIME_HOMEBREW_CASK="sublime-text"
SUBLIME_APT_KEY_URL="https://download.sublimetext.com/sublimehq-pub.gpg"
SUBLIME_APT_REPO="https://download.sublimetext.com/"
SUBLIME_RPM_KEY_URL="https://download.sublimetext.com/sublimehq-rpm-pub.gpg"
SUBLIME_DEB_PACKAGE="sublime-text"
SUBLIME_RPM_PACKAGE="sublime-text"
SUBLIME_ARCH_AUR="sublime-text-4"
SUBLIME_ARCH_COMMUNITY="sublime-text-dev"

SKIP_CONFIRM=false
# Help function
show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  $SUBLIME_NAME é um editor de texto sofisticado para código, markup e prosa."
    log_output "  Conhecido por sua velocidade, interface limpa e recursos poderosos como"
    log_output "  múltiplos cursores, busca avançada, e extensa biblioteca de plugins."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o Sublime Text do sistema"
    log_output "  -y, --yes         Pula confirmação (usar com --uninstall)"
    log_output "  -u, --upgrade     Atualiza o Sublime Text para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup sublime-text              # Instala o $SUBLIME_NAME"
    log_output "  susa setup sublime-text --upgrade    # Atualiza o $SUBLIME_NAME"
    log_output "  susa setup sublime-text --uninstall  # Desinstala o $SUBLIME_NAME"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O Sublime Text estará disponível no menu de aplicativos ou via:"
    log_output "    subl                    # Abre o editor"
    log_output "    subl arquivo.txt        # Abre arquivo específico"
    log_output "    subl pasta/             # Abre pasta como projeto"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Múltiplos cursores e seleções"
    log_output "  • Command Palette para acesso rápido"
    log_output "  • Goto Anything (Ctrl/Cmd+P)"
    log_output "  • Distraction Free Mode"
    log_output "  • Syntax Highlighting avançado"
    log_output "  • Package Control para plugins"
}

# Get latest version (not implemented)
get_latest_version() {
    # Tenta obter a versão mais recente da API oficial do Sublime Text
    local api_url="https://www.sublimetext.com/updates/4/stable_update_check"
    local latest_version

    # Usa jq para extrair o campo latest_version corretamente
    if command -v jq &> /dev/null; then
        latest_version=$(curl -fsSL "$api_url" | jq -r '.latest_version // empty')
    else
        # Fallback para grep se jq não estiver disponível
        latest_version=$(curl -fsSL "$api_url" | grep -oE '"latest_version"\s*:\s*"[^"]+"' | head -1 | sed -E 's/.*: *"([^"]+)"/\1/')
    fi

    if [ -n "$latest_version" ]; then
        echo "$latest_version"
        return 0
    fi

    echo "N/A"
}

# Get installed Sublime Text version
get_current_version() {
    if check_installation; then
        local version=$($SUBLIME_BIN_NAME --version 2> /dev/null | grep -oE '[0-9]+' | head -1 || echo "desconhecida")
        if [ "$version" != "desconhecida" ]; then
            echo "$version"
        fi
    else
        echo "desconhecida"
    fi
}

# Check if Sublime Text is installed
check_installation() {
    command -v $SUBLIME_BIN_NAME &> /dev/null
}

# Install Sublime Text on macOS using Homebrew
install_sublime_macos() {
    log_info "Instalando Sublime Text no macOS..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    # Install or upgrade Sublime Text
    if brew list --cask $SUBLIME_HOMEBREW_CASK &> /dev/null 2>&1; then
        log_info "Atualizando Sublime Text via Homebrew..."
        brew upgrade --cask $SUBLIME_HOMEBREW_CASK || true
    else
        log_info "Instalando Sublime Text via Homebrew..."
        brew install --cask $SUBLIME_HOMEBREW_CASK
    fi

    return 0
}

# Install Sublime Text on Debian/Ubuntu
install_sublime_debian() {
    log_info "Instalando Sublime Text no Debian/Ubuntu..."

    # Install GPG key
    log_info "Adicionando chave GPG..."
    wget -qO - $SUBLIME_APT_KEY_URL | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null

    log_info "Adicionando repositório..."
    echo "deb $SUBLIME_APT_REPO apt/stable/" | sudo tee /etc/apt/sources.list.d/${SUBLIME_DEB_PACKAGE}.list > /dev/null

    log_info "Atualizando lista de pacotes..."
    sudo apt-get update > /dev/null 2>&1

    log_info "Instalando Sublime Text..."
    sudo apt-get install -y $SUBLIME_DEB_PACKAGE > /dev/null 2>&1

    return $?
}

# Install Sublime Text on RHEL/Fedora/CentOS
install_sublime_rhel() {
    log_info "Instalando Sublime Text no RHEL/Fedora/CentOS..."

    # Import GPG key
    log_info "Importando chave GPG..."
    enabled=1
    gpgcheck=1
    gpgkey=$SUBLIME_RPM_KEY_URL
    sudo rpm -v --import $SUBLIME_RPM_KEY_URL > /dev/null 2>&1

    log_info "Adicionando repositório..."
    sudo tee /etc/yum.repos.d/${SUBLIME_RPM_PACKAGE}.repo > /dev/null << EOF
[$SUBLIME_RPM_PACKAGE]
name=Sublime Text
baseurl=https://download.sublimetext.com/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=$SUBLIME_RPM_KEY_URL
EOF

    log_info "Instalando Sublime Text..."
    if command -v dnf &> /dev/null; then
        sudo dnf install -y $SUBLIME_RPM_PACKAGE > /dev/null 2>&1
    else
        sudo yum install -y $SUBLIME_RPM_PACKAGE > /dev/null 2>&1
    fi

    return $?
}

# Install Sublime Text on Arch Linux
install_sublime_arch() {
    log_info "Instalando Sublime Text no Arch Linux..."

    # Install from AUR (requires yay or another AUR helper)
    if command -v yay &> /dev/null; then
        log_info "Instalando via yay (AUR)..."
        yay -S --noconfirm $SUBLIME_ARCH_AUR > /dev/null 2>&1
    elif command -v paru &> /dev/null; then
        log_info "Instalando via paru (AUR)..."
        paru -S --noconfirm $SUBLIME_ARCH_AUR > /dev/null 2>&1
    else
        log_warning "Nenhum helper AUR detectado (yay, paru)"
        log_info "Instalando manualmente via pacman (repositório comunitário)..."
        sudo pacman -S --noconfirm $SUBLIME_ARCH_COMMUNITY > /dev/null 2>&1 || {
            log_error "Falha ao instalar. Considere instalar um helper AUR como yay:"
            log_output "  sudo pacman -S --needed git base-devel"
            log_output "  git clone https://aur.archlinux.org/yay.git"
            log_output "  cd yay && makepkg -si"
            return 1
        }
    fi

    return 0
}

# Install Sublime Text on Linux
install_sublime_linux() {
    local distro=$(get_distro_id)
    log_debug "Distribuição detectada: $distro"

    case "$distro" in
        ubuntu | debian | pop | linuxmint | elementary)
            install_sublime_debian
            ;;
        fedora | rhel | centos | rocky | almalinux)
            install_sublime_rhel
            ;;
        arch | manjaro | endeavouros)
            install_sublime_arch
            ;;
        *)
            log_error "Distribuição não suportada: $distro"
            log_info "Visite https://www.sublimetext.com/docs/linux_repositories.html para instruções manuais"
            return 1
            ;;
    esac

    return $?
}

# Main installation function
install_sublime() {
    if check_installation; then
        log_info "Sublime Text $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do Sublime Text..."

    # Detect OS
    case "$OS_TYPE" in
        macos)
            install_sublime_macos
            ;;
        debian | fedora)
            install_sublime_linux
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

            log_success "Sublime Text $installed_version instalado com sucesso!"
            log_output ""
            log_output "Próximos passos:"
            log_output "  1. Execute: ${LIGHT_CYAN}subl${NC} para abrir o editor"
            log_output "  2. Instale o Package Control: Ctrl/Cmd+Shift+P → Install Package Control"
            log_output "  3. Use ${LIGHT_CYAN}susa setup sublime-text --help${NC} para mais informações"
            log_output ""
            log_output "${LIGHT_GREEN}Dica:${NC} Explore os temas e plugins em https://packagecontrol.io"
        else
            log_error "Sublime Text foi instalado mas não está disponível no PATH"
            return 1
        fi
    else
        return $install_result
    fi
}

# Update Sublime Text
update_sublime() {
    log_info "Atualizando Sublime Text..."

    # Check if Sublime Text is installed
    if ! check_installation; then
        log_error "Sublime Text não está instalado. Use 'susa setup sublime-text' para instalar."
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

            log_info "Atualizando Sublime Text via Homebrew..."
            brew upgrade --cask $SUBLIME_HOMEBREW_CASK || {
                log_info "Sublime Text já está na versão mais recente"
                return 0
            }
            ;;
        debian | fedora)
            local distro=$(get_distro_id)
            log_debug "Distribuição detectada: $distro"

            case "$distro" in
                ubuntu | debian | pop | linuxmint | elementary)
                    log_info "Atualizando Sublime Text via apt..."
                    sudo apt-get update > /dev/null 2>&1
                    sudo apt-get install --only-upgrade -y $SUBLIME_DEB_PACKAGE > /dev/null 2>&1
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    log_info "Atualizando Sublime Text via dnf/yum..."
                    if command -v dnf &> /dev/null; then
                        sudo dnf upgrade -y $SUBLIME_RPM_PACKAGE > /dev/null 2>&1
                    else
                        sudo yum update -y $SUBLIME_RPM_PACKAGE > /dev/null 2>&1
                    fi
                    ;;
                arch | manjaro | endeavouros)
                    log_info "Atualizando Sublime Text via pacman/AUR..."
                    if command -v yay &> /dev/null; then
                        yay -Syu --noconfirm $SUBLIME_ARCH_AUR > /dev/null 2>&1
                    elif command -v paru &> /dev/null; then
                        paru -Syu --noconfirm $SUBLIME_ARCH_AUR > /dev/null 2>&1
                    else
                        sudo pacman -Syu --noconfirm $SUBLIME_ARCH_COMMUNITY > /dev/null 2>&1
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
            log_info "Sublime Text já estava na versão mais recente ($current_version)"
        else
            log_success "Sublime Text atualizado com sucesso para versão $new_version!"
        fi
    else
        log_error "Falha na atualização do Sublime Text"
        return 1
    fi
}

# Uninstall Sublime Text
uninstall_sublime() {
    log_info "Desinstalando Sublime Text..."

    # Check if Sublime Text is installed
    if ! check_installation; then
        log_info "Sublime Text não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)
    log_debug "Versão a ser removida: $current_version"

    log_output ""
    if [ "$SKIP_CONFIRM" = false ]; then
        log_output "${YELLOW}Deseja realmente desinstalar o Sublime Text $current_version? (s/N)${NC}"
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
                log_info "Removendo Sublime Text via Homebrew..."
                brew uninstall --cask $SUBLIME_HOMEBREW_CASK 2> /dev/null || log_debug "Sublime Text não instalado via Homebrew"
            fi
            ;;
        debian | fedora)
            local distro=$(get_distro_id)
            log_debug "Distribuição detectada: $distro"

            case "$distro" in
                ubuntu | debian | pop | linuxmint | elementary)
                    log_info "Removendo Sublime Text via apt..."
                    sudo apt-get purge -y $SUBLIME_DEB_PACKAGE > /dev/null 2>&1
                    sudo apt-get autoremove -y > /dev/null 2>&1

                    # Remove repository
                    sudo rm -f /etc/apt/sources.list.d/${SUBLIME_DEB_PACKAGE}.list
                    sudo rm -f /etc/apt/trusted.gpg.d/sublimehq-archive.gpg
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    log_info "Removendo Sublime Text via dnf/yum..."
                    if command -v dnf &> /dev/null; then
                        sudo dnf remove -y sublime-text > /dev/null 2>&1
                    else
                        sudo yum remove -y sublime-text > /dev/null 2>&1
                    fi

                    # Remove repository
                    sudo rm -f /etc/yum.repos.d/${SUBLIME_RPM_PACKAGE}.repo
                    ;;
                arch | manjaro | endeavouros)
                    log_info "Removendo Sublime Text via pacman..."
                    if command -v yay &> /dev/null; then
                        yay -Rns --noconfirm $SUBLIME_ARCH_AUR > /dev/null 2>&1 || sudo pacman -Rns --noconfirm $SUBLIME_ARCH_COMMUNITY > /dev/null 2>&1
                    elif command -v paru &> /dev/null; then
                        paru -Rns --noconfirm $SUBLIME_ARCH_AUR > /dev/null 2>&1 || sudo pacman -Rns --noconfirm $SUBLIME_ARCH_COMMUNITY > /dev/null 2>&1
                    else
                        sudo pacman -Rns --noconfirm $SUBLIME_ARCH_COMMUNITY > /dev/null 2>&1
                    fi
                    ;;
            esac
            ;;
    esac

    # Verify uninstallation
    if ! check_installation; then
        # Mark as uninstalled in lock file
        remove_software_in_lock "$COMMAND_NAME"

        log_success "Sublime Text desinstalado com sucesso!"
    else
        log_error "Falha ao desinstalar Sublime Text completamente"
        return 1
    fi

    # Ask about configuration removal
    log_output ""
    log_output "${YELLOW}Deseja remover também as configurações e pacotes do Sublime Text? (s/N)${NC}"
    read -r response

    if [[ "$response" =~ ^[sSyY]$ ]]; then
        log_info "Removendo configurações..."

        case "$os_name" in
            darwin)
                rm -rf "$HOME/Library/Application Support/Sublime Text" 2> /dev/null || true
                rm -rf "$HOME/Library/Caches/Sublime Text" 2> /dev/null || true
                ;;
            linux)
                rm -rf "$HOME/.config/sublime-text" 2> /dev/null || true
                rm -rf "$HOME/.config/sublime-text-3" 2> /dev/null || true
                rm -rf "$HOME/.cache/sublime-text" 2> /dev/null || true
                ;;
        esac

        log_info "Configurações removidas"
    else
        log_info "Configurações mantidas"
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
                show_software_info "$SUBLIME_BIN_NAME"
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
            install_sublime
            ;;
        update)
            update_sublime
            ;;
        uninstall)
            uninstall_sublime
            ;;
        *)
            log_error "Ação desconhecida: $action"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
