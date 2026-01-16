#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"

# Help function
show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Flameshot é uma ferramenta poderosa e simples de captura de tela."
    log_output "  Oferece recursos de anotação, edição e compartilhamento de screenshots"
    log_output "  com interface intuitiva e atalhos de teclado customizáveis."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o Flameshot do sistema"
    log_output "  -u, --upgrade     Atualiza o Flameshot para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup flameshot              # Instala o Flameshot"
    log_output "  susa setup flameshot --upgrade    # Atualiza o Flameshot"
    log_output "  susa setup flameshot --uninstall  # Desinstala o Flameshot"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O Flameshot estará disponível no menu de aplicativos ou via:"
    log_output "    flameshot gui           # Abre captura interativa"
    log_output "    flameshot full          # Captura tela inteira"
    log_output "    flameshot screen        # Captura tela específica"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Captura de tela com seleção de área"
    log_output "  • Editor de imagens integrado"
    log_output "  • Anotações: setas, linhas, texto, formas"
    log_output "  • Desfoque e pixelização de áreas"
    log_output "  • Upload para Imgur"
    log_output "  • Atalhos de teclado customizáveis"
    log_output "  • Suporte a multi-monitor"
    log_output ""
    log_output "${LIGHT_GREEN}Configuração de atalho (Linux):${NC}"
    log_output "  Configure um atalho global (ex: Print Screen) para executar:"
    log_output "    flameshot gui"
}

# Get installed Flameshot version
get_flameshot_version() {
    if command -v flameshot &> /dev/null; then
        local version=$(flameshot --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "instalada")
        echo "$version"
    else
        echo "desconhecida"
    fi
}

# Check if Flameshot is already installed
check_existing_installation() {
    if ! command -v flameshot &> /dev/null; then
        log_debug "Flameshot não está instalado"
        return 0
    fi

    local current_version=$(get_flameshot_version)
    log_info "Flameshot $current_version já está instalado."

    # Mark as installed in lock file
    mark_installed "flameshot" "$current_version"

    log_output ""
    log_output "${YELLOW}Para atualizar, execute:${NC} ${LIGHT_CYAN}susa setup flameshot --upgrade${NC}"

    return 1
}

# Install Flameshot on macOS using Homebrew
install_flameshot_macos() {
    log_info "Instalando Flameshot no macOS..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    # Install or upgrade Flameshot
    log_debug "Executando: brew install $FLAMESHOT_HOMEBREW_FORMULA"
    if brew list "$FLAMESHOT_HOMEBREW_FORMULA" &> /dev/null; then
        log_info "Atualizando Flameshot via Homebrew..."
        brew upgrade "$FLAMESHOT_HOMEBREW_FORMULA" || {
            log_warning "Flameshot já está na versão mais recente"
        }
    else
        log_info "Instalando Flameshot via Homebrew..."
        brew install "$FLAMESHOT_HOMEBREW_FORMULA"
    fi

    log_success "Flameshot instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para usar o Flameshot:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}flameshot gui${NC}"
    log_output ""
    log_output "${YELLOW}Nota:${NC} Configure permissões de captura de tela em:"
    log_output "  System Preferences → Security & Privacy → Screen Recording"
}

# Install Flameshot on Debian/Ubuntu
install_flameshot_debian() {
    log_info "Instalando Flameshot no Debian/Ubuntu..."

    # Update package list
    log_debug "Atualizando lista de pacotes..."
    sudo apt-get update -qq

    # Install Flameshot
    log_info "Instalando pacote flameshot..."
    sudo apt-get install -y flameshot

    log_success "Flameshot instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para usar o Flameshot:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}flameshot gui${NC}"
    log_output ""
    log_output "${LIGHT_CYAN}Configure atalho de teclado:${NC}"
    log_output "  Settings → Keyboard → Shortcuts → Custom Shortcuts"
    log_output "  Adicione: flameshot gui (recomendado: Print Screen)"
}

# Install Flameshot on RHEL/Fedora
install_flameshot_rhel() {
    log_info "Instalando Flameshot no RHEL/Fedora..."

    # Install Flameshot
    if command -v dnf &> /dev/null; then
        log_info "Instalando via dnf..."
        sudo dnf install -y flameshot
    else
        log_info "Instalando via yum..."
        sudo yum install -y flameshot
    fi

    log_success "Flameshot instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para usar o Flameshot:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}flameshot gui${NC}"
    log_output ""
    log_output "${LIGHT_CYAN}Configure atalho de teclado:${NC}"
    log_output "  Settings → Keyboard → Shortcuts → Custom Shortcuts"
    log_output "  Adicione: flameshot gui (recomendado: Print Screen)"
}

# Install Flameshot on Arch Linux
install_flameshot_arch() {
    log_info "Instalando Flameshot no Arch Linux..."

    # Check if yay or paru is available for AUR, otherwise use pacman
    if command -v pacman &> /dev/null; then
        log_info "Instalando via pacman..."
        sudo pacman -S --noconfirm flameshot
    elif command -v yay &> /dev/null; then
        log_info "Instalando via yay..."
        yay -S --noconfirm flameshot
    elif command -v paru &> /dev/null; then
        log_info "Instalando via paru..."
        paru -S --noconfirm flameshot
    else
        log_error "Pacman não encontrado"
        return 1
    fi

    log_success "Flameshot instalado com sucesso!"
    log_output ""
    log_output "${LIGHT_CYAN}Para usar o Flameshot:${NC}"
    log_output "  • Via menu de aplicativos"
    log_output "  • Via terminal: ${LIGHT_GREEN}flameshot gui${NC}"
}

# Detect Linux distribution
detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# Install Flameshot on Linux
install_flameshot_linux() {
    local distro=$(detect_linux_distro)
    log_debug "Distribuição detectada: $distro"

    case "$distro" in
        ubuntu | debian | pop | linuxmint | elementary)
            install_flameshot_debian
            ;;
        fedora | rhel | centos | rocky | almalinux)
            install_flameshot_rhel
            ;;
        arch | manjaro | endeavouros)
            install_flameshot_arch
            ;;
        *)
            log_warning "Distribuição não reconhecida: $distro"
            log_info "Tentando instalar via gerenciador de pacotes genérico..."

            if command -v apt-get &> /dev/null; then
                install_flameshot_debian
            elif command -v dnf &> /dev/null || command -v yum &> /dev/null; then
                install_flameshot_rhel
            elif command -v pacman &> /dev/null; then
                install_flameshot_arch
            else
                log_error "Nenhum gerenciador de pacotes suportado encontrado"
                log_info "Visite https://flameshot.org para instruções manuais"
                return 1
            fi
            ;;
    esac
}

# Main installation function
install_flameshot() {
    local os_type=$(get_simple_os)

    if [ "$os_type" = "mac" ]; then
        install_flameshot_macos
    elif [ "$os_type" = "linux" ]; then
        install_flameshot_linux
    else
        log_error "Sistema operacional não suportado: $os_type"
        return 1
    fi

    # Mark as installed
    local version=$(get_flameshot_version)
    mark_installed "flameshot" "$version"
}

# Update Flameshot
update_flameshot() {
    log_info "Atualizando Flameshot..."

    if ! command -v flameshot &> /dev/null; then
        log_warning "Flameshot não está instalado. Execute sem --upgrade para instalar."
        return 1
    fi

    local current_version=$(get_flameshot_version)
    log_info "Versão atual: $current_version"

    local os_type=$(get_simple_os)

    if [ "$os_type" = "mac" ]; then
        log_info "Atualizando via Homebrew..."
        brew upgrade "$FLAMESHOT_HOMEBREW_FORMULA" || {
            log_info "Flameshot já está na versão mais recente"
        }
    elif [ "$os_type" = "linux" ]; then
        local distro=$(detect_linux_distro)

        case "$distro" in
            ubuntu | debian | pop | linuxmint | elementary)
                log_info "Atualizando via apt-get..."
                sudo apt-get update -qq
                sudo apt-get install --only-upgrade -y flameshot
                ;;
            fedora | rhel | centos | rocky | almalinux)
                if command -v dnf &> /dev/null; then
                    log_info "Atualizando via dnf..."
                    sudo dnf upgrade -y flameshot
                else
                    log_info "Atualizando via yum..."
                    sudo yum update -y flameshot
                fi
                ;;
            arch | manjaro | endeavouros)
                log_info "Atualizando via pacman..."
                sudo pacman -Syu --noconfirm flameshot
                ;;
            *)
                log_warning "Distribuição não reconhecida, tentando atualização genérica..."
                if command -v apt-get &> /dev/null; then
                    sudo apt-get update -qq && sudo apt-get install --only-upgrade -y flameshot
                elif command -v dnf &> /dev/null; then
                    sudo dnf upgrade -y flameshot
                elif command -v pacman &> /dev/null; then
                    sudo pacman -Syu --noconfirm flameshot
                fi
                ;;
        esac
    fi

    local new_version=$(get_flameshot_version)
    log_success "Flameshot atualizado para versão $new_version"

    # Update lock file
    mark_installed "flameshot" "$new_version"
}

# Uninstall Flameshot
uninstall_flameshot() {
    log_info "Desinstalando Flameshot..."

    if ! command -v flameshot &> /dev/null; then
        log_warning "Flameshot não está instalado"
        return 0
    fi

    local os_type=$(get_simple_os)

    if [ "$os_type" = "mac" ]; then
        log_info "Desinstalando via Homebrew..."
        brew uninstall "$FLAMESHOT_HOMEBREW_FORMULA"
    elif [ "$os_type" = "linux" ]; then
        local distro=$(detect_linux_distro)

        case "$distro" in
            ubuntu | debian | pop | linuxmint | elementary)
                log_info "Desinstalando via apt-get..."
                sudo apt-get remove -y flameshot
                ;;
            fedora | rhel | centos | rocky | almalinux)
                if command -v dnf &> /dev/null; then
                    log_info "Desinstalando via dnf..."
                    sudo dnf remove -y flameshot
                else
                    log_info "Desinstalando via yum..."
                    sudo yum remove -y flameshot
                fi
                ;;
            arch | manjaro | endeavouros)
                log_info "Desinstalando via pacman..."
                sudo pacman -R --noconfirm flameshot
                ;;
            *)
                log_warning "Distribuição não reconhecida, tentando desinstalação genérica..."
                if command -v apt-get &> /dev/null; then
                    sudo apt-get remove -y flameshot
                elif command -v dnf &> /dev/null; then
                    sudo dnf remove -y flameshot
                elif command -v pacman &> /dev/null; then
                    sudo pacman -R --noconfirm flameshot
                fi
                ;;
        esac
    fi

    log_success "Flameshot desinstalado com sucesso!"

    # Remove from lock file
    mark_uninstalled "flameshot"
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
            -u | --upgrade)
                should_update=true
                ;;
            --uninstall)
                should_uninstall=true
                ;;
            -v | --verbose)
                export VERBOSE=true
                ;;
            -q | --quiet)
                export QUIET=true
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
        uninstall_flameshot
    elif [ "$should_update" = true ]; then
        update_flameshot
    else
        check_existing_installation || exit 0
        install_flameshot
    fi
}

# Run main function
main "$@"
