#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"

# Constants
TILIX_NAME="Tilix"
TILIX_REPO="gnunn1/tilix"
TILIX_BIN_NAME="tilix"
TILIX_PKG_DEB="tilix"
TILIX_PKG_RPM="tilix"
TILIX_PKG_ARCH="tilix"
TILIX_PKG_ZYPPER="tilix"

SKIP_CONFIRM=false
# Help function
show_help() {
    show_description
    echo ""
    show_usage
    echo ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  $TILIX_NAME é um emulador de terminal avançado para Linux usando GTK+ 3."
    log_output "  Oferece recursos como tiles (painéis lado a lado), notificações,"
    log_output "  transparência, temas personalizáveis e muito mais."
    echo ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o Tilix do sistema"
    log_output "  -y, --yes         Pula confirmação (usar com --uninstall)"
    log_output "  -u, --upgrade     Atualiza o Tilix para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    echo ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup tilix              # Instala o $TILIX_NAME"
    log_output "  susa setup tilix --upgrade    # Atualiza o $TILIX_NAME"
    log_output "  susa setup tilix --uninstall  # Desinstala o $TILIX_NAME"
    echo ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O Tilix estará disponível no menu de aplicativos."
    log_output "  Para configurá-lo como terminal padrão:"
    log_output "    sudo update-alternatives --config x-terminal-emulator"
    echo ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    echo "  • Tiles (painéis lado a lado)"
    echo "  • Transparência e efeitos visuais"
    echo "  • Drag and drop de arquivos"
    echo "  • Hyperlinks clicáveis"
    echo "  • Temas e esquemas de cores"
}

# Get latest Tilix version
get_latest_version() {
    github_get_latest_version "$TILIX_REPO"
}

# Get installed Tilix version
get_current_version() {
    if check_installation; then
        # Try to get version from package manager instead of executing binary
        if command -v dpkg &> /dev/null && dpkg -l $TILIX_PKG_DEB 2> /dev/null | grep -q '^ii'; then
            dpkg -l $TILIX_PKG_DEB 2> /dev/null | grep '^ii' | awk '{print $3}' | cut -d'-' -f1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
        elif command -v rpm &> /dev/null && rpm -q $TILIX_PKG_RPM &> /dev/null; then
            rpm -q --queryformat '%{VERSION}' $TILIX_PKG_RPM 2> /dev/null || echo "desconhecida"
        elif command -v pacman &> /dev/null && pacman -Q $TILIX_PKG_ARCH &> /dev/null; then
            pacman -Q $TILIX_PKG_ARCH 2> /dev/null | awk '{print $2}' | cut -d'-' -f1 || echo "desconhecida"
        elif command -v zypper &> /dev/null && zypper se --installed-only $TILIX_PKG_ZYPPER &> /dev/null; then
            zypper info $TILIX_PKG_ZYPPER 2> /dev/null | grep -E '^Version' | awk '{print $2}' || echo "desconhecida"
        else
            # Fallback: try executing binary (may fail)
            $TILIX_BIN_NAME --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
        fi
    else
        echo "desconhecida"
    fi
}

# Check if Tilix is installed
check_installation() {
    command -v $TILIX_BIN_NAME &> /dev/null || ([ "$(uname)" = "Linux" ] && dpkg -l 2> /dev/null | grep -q $TILIX_PKG_DEB)
}

# Detect package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
        log_debug "Gerenciador de pacotes: apt (Debian/Ubuntu)"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
        log_debug "Gerenciador de pacotes: dnf (Fedora)"
    elif command -v yum &> /dev/null; then
        echo "yum"
        log_debug "Gerenciador de pacotes: yum (RHEL/CentOS)"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
        log_debug "Gerenciador de pacotes: pacman (Arch Linux)"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
        log_debug "Gerenciador de pacotes: zypper (openSUSE)"
    else
        echo "unknown"
        log_debug "Nenhum gerenciador de pacotes conhecido detectado"
    fi
}

# Install Tilix using system package manager
install_tilix() {
    if check_installation; then
        log_info "Tilix $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do Tilix..."

    local pkg_manager=$(detect_package_manager)
    log_debug "Gerenciador de pacotes detectado: $pkg_manager"

    if [ "$pkg_manager" = "unknown" ]; then
        log_error "Gerenciador de pacotes não suportado"
        echo ""
        log_output "${YELLOW}Instalação manual necessária:${NC}"
        log_output "  Visite: https://gnunn1.github.io/tilix-web/"
        return 1
    fi

    # Update package lists first
    log_info "Atualizando lista de pacotes..."
    case "$pkg_manager" in
        apt)
            log_debug "Executando: sudo apt-get update"
            sudo apt-get update 2>&1 | while read -r line; do log_debug "apt: $line"; done || true
            ;;
        dnf)
            log_debug "Executando: sudo dnf check-update"
            sudo dnf check-update 2>&1 | while read -r line; do log_debug "dnf: $line"; done || true
            ;;
        yum)
            log_debug "Executando: sudo yum check-update"
            sudo yum check-update 2>&1 | while read -r line; do log_debug "yum: $line"; done || true
            ;;
        pacman)
            log_debug "Executando: sudo pacman -Sy"
            sudo pacman -Sy 2>&1 | while read -r line; do log_debug "pacman: $line"; done || true
            ;;
        zypper)
            log_debug "Executando: sudo zypper refresh"
            sudo zypper refresh 2>&1 | while read -r line; do log_debug "zypper: $line"; done || true
            ;;
    esac

    # Install Tilix
    log_info "Instalando Tilix via $pkg_manager..."
    local install_success=false

    case "$pkg_manager" in
        apt)
            log_debug "Executando: sudo apt-get install -y $TILIX_PKG_DEB"
            if sudo apt-get install -y $TILIX_PKG_DEB 2>&1 | while read -r line; do log_debug "apt: $line"; done; then
                install_success=true
            fi
            ;;
        dnf)
            log_debug "Executando: sudo dnf install -y $TILIX_PKG_RPM"
            if sudo dnf install -y $TILIX_PKG_RPM 2>&1 | while read -r line; do log_debug "dnf: $line"; done; then
                install_success=true
            fi
            ;;
        yum)
            log_debug "Executando: sudo yum install -y $TILIX_PKG_RPM"
            if sudo yum install -y $TILIX_PKG_RPM 2>&1 | while read -r line; do log_debug "yum: $line"; done; then
                install_success=true
            fi
            ;;
        pacman)
            log_debug "Executando: sudo pacman -S --noconfirm $TILIX_PKG_ARCH"
            if sudo pacman -S --noconfirm $TILIX_PKG_ARCH 2>&1 | while read -r line; do log_debug "pacman: $line"; done; then
                install_success=true
            fi
            ;;
        zypper)
            log_debug "Executando: sudo zypper install -y $TILIX_PKG_ZYPPER"
            if sudo zypper install -y $TILIX_PKG_ZYPPER 2>&1 | while read -r line; do log_debug "zypper: $line"; done; then
                install_success=true
            fi
            ;;
    esac

    # Verify installation
    if check_installation; then
        local version=$(get_current_version)
        log_success "Tilix $version instalado com sucesso!"
        register_or_update_software_in_lock "$COMMAND_NAME" "$version"

        # Check for VTE configuration
        if [ -f /etc/profile.d/vte.sh ]; then
            log_debug "VTE config encontrado: /etc/profile.d/vte.sh"
            echo ""
            log_info "Para melhor integração, adicione ao seu ~/.bashrc ou ~/.zshrc:"
            echo "  source /etc/profile.d/vte.sh"
        fi

        return 0
    else
        log_error "Falha ao verificar instalação do Tilix"
        return 1
    fi
}

# Update Tilix
update_tilix() {
    log_info "Atualizando Tilix..."

    local pkg_manager=$(detect_package_manager)
    log_debug "Gerenciador de pacotes detectado: $pkg_manager"

    # Check if Tilix is installed
    if ! check_installation; then
        log_error "Tilix não está instalado"
        echo ""
        log_output "${YELLOW}Para instalar, execute:${NC}"
        echo "  susa setup tilix"
        return 1
    fi

    local current_version=$(get_current_version)
    log_debug "Versão atual: $current_version"

    # Update package lists
    log_info "Atualizando lista de pacotes..."
    case "$pkg_manager" in
        apt)
            log_debug "Executando: sudo apt-get update"
            sudo apt-get update 2>&1 | while read -r line; do log_debug "apt: $line"; done || true
            ;;
        dnf)
            log_debug "Executando: sudo dnf check-update"
            sudo dnf check-update 2>&1 | while read -r line; do log_debug "dnf: $line"; done || true
            ;;
        yum)
            log_debug "Executando: sudo yum check-update"
            sudo yum check-update 2>&1 | while read -r line; do log_debug "yum: $line"; done || true
            ;;
        pacman)
            log_debug "Executando: sudo pacman -Sy"
            sudo pacman -Sy 2>&1 | while read -r line; do log_debug "pacman: $line"; done || true
            ;;
        zypper)
            log_debug "Executando: sudo zypper refresh"
            sudo zypper refresh 2>&1 | while read -r line; do log_debug "zypper: $line"; done || true
            ;;
    esac

    # Update Tilix
    log_info "Atualizando Tilix via $pkg_manager..."
    case "$pkg_manager" in
        apt)
            log_debug "Executando: sudo apt-get upgrade -y $TILIX_PKG_DEB"
            sudo apt-get upgrade -y $TILIX_PKG_DEB 2>&1 | while read -r line; do log_debug "apt: $line"; done
            ;;
        dnf)
            log_debug "Executando: sudo dnf upgrade -y $TILIX_PKG_RPM"
            sudo dnf upgrade -y $TILIX_PKG_RPM 2>&1 | while read -r line; do log_debug "dnf: $line"; done
            ;;
        yum)
            log_debug "Executando: sudo yum update -y $TILIX_PKG_RPM"
            sudo yum update -y $TILIX_PKG_RPM 2>&1 | while read -r line; do log_debug "yum: $line"; done
            ;;
        pacman)
            log_debug "Executando: sudo pacman -S $TILIX_PKG_ARCH"
            sudo pacman -S $TILIX_PKG_ARCH 2>&1 | while read -r line; do log_debug "pacman: $line"; done
            ;;
        zypper)
            log_debug "Executando: sudo zypper update -y $TILIX_PKG_ZYPPER"
            sudo zypper update -y $TILIX_PKG_ZYPPER 2>&1 | while read -r line; do log_debug "zypper: $line"; done
            ;;
    esac

    local new_version=$(get_current_version)

    if [ "$current_version" = "$new_version" ]; then
        log_info "Tilix já está na versão mais recente ($current_version)"
    else
        log_success "Tilix atualizado de $current_version para $new_version"
        register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"
    fi

    log_debug "Atualização concluída"
}

# Uninstall Tilix
uninstall_tilix() {
    log_info "Desinstalando Tilix..."

    local pkg_manager=$(detect_package_manager)
    log_debug "Gerenciador de pacotes detectado: $pkg_manager"

    # Check if Tilix is installed
    if ! check_installation; then
        log_warning "Tilix não está instalado via gerenciador de pacotes"
        log_info "Nada a fazer"
        return 0
    fi

    local version=$(get_current_version)
    log_debug "Versão a ser removida: $version"

    # Confirm uninstallation
    if [ "$SKIP_CONFIRM" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja realmente desinstalar o Tilix $version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    # Uninstall Tilix
    log_info "Removendo Tilix via $pkg_manager..."
    case "$pkg_manager" in
        apt)
            log_debug "Executando: sudo apt-get remove -y $TILIX_PKG_DEB"
            sudo apt-get remove -y $TILIX_PKG_DEB 2>&1 | while read -r line; do log_debug "apt: $line"; done

            # Ask about purge
            if [ "$SKIP_CONFIRM" = false ]; then
                echo ""
                log_output "${YELLOW}Deseja remover também os arquivos de configuração? (s/N)${NC}"
                read -r purge_response

                if [[ "$purge_response" =~ ^[sSyY]$ ]]; then
                    log_debug "Executando: sudo apt-get purge -y $TILIX_PKG_DEB"
                    sudo apt-get purge -y $TILIX_PKG_DEB 2>&1 | while read -r line; do log_debug "apt: $line"; done
                    log_debug "Executando: sudo apt-get autoremove -y"
                    sudo apt-get autoremove -y 2>&1 | while read -r line; do log_debug "apt: $line"; done
                fi
            else
                # Auto-purge when --yes is used
                log_debug "Executando: sudo apt-get purge -y $TILIX_PKG_DEB"
                sudo apt-get purge -y $TILIX_PKG_DEB 2>&1 | while read -r line; do log_debug "apt: $line"; done
                log_debug "Executando: sudo apt-get autoremove -y"
                sudo apt-get autoremove -y 2>&1 | while read -r line; do log_debug "apt: $line"; done
            fi
            ;;
        dnf)
            log_debug "Executando: sudo dnf remove -y $TILIX_PKG_RPM"
            sudo dnf remove -y $TILIX_PKG_RPM 2>&1 | while read -r line; do log_debug "dnf: $line"; done
            ;;
        yum)
            log_debug "Executando: sudo yum remove -y $TILIX_PKG_RPM"
            sudo yum remove -y $TILIX_PKG_RPM 2>&1 | while read -r line; do log_debug "yum: $line"; done
            ;;
        pacman)
            log_debug "Executando: sudo pacman -R $TILIX_PKG_ARCH"
            sudo pacman -R $TILIX_PKG_ARCH 2>&1 | while read -r line; do log_debug "pacman: $line"; done
            ;;
        zypper)
            log_debug "Executando: sudo zypper remove -y $TILIX_PKG_ZYPPER"
            sudo zypper remove -y $TILIX_PKG_ZYPPER 2>&1 | while read -r line; do log_debug "zypper: $line"; done
            ;;
    esac

    # Verify removal
    if ! check_installation; then
        log_success "Tilix desinstalado com sucesso"
        remove_software_in_lock "$COMMAND_NAME"
    else
        log_warning "Tilix removido do gerenciador de pacotes, mas executável ainda encontrado"
    fi

    # Clean up user configurations (optional)
    echo ""
    log_output "${YELLOW}Deseja remover as configurações de usuário do Tilix? (s/N)${NC}"
    read -r config_response

    if [[ "$config_response" =~ ^[sSyY]$ ]]; then
        rm -rf "$HOME/.config/tilix" 2> /dev/null || true
        rm -rf "$HOME/.local/share/tilix" 2> /dev/null || true
        dconf reset -f /com/gexperts/Tilix/ 2> /dev/null || true
        log_success "Configurações removidas"
    else
        log_info "Configurações mantidas em ~/.config/tilix"
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
                logger_debug "Modo verbose ativado"
                export DEBUG=1
                shift
                ;;
            -q | --quiet)
                export SILENT=1
                shift
                ;;
            --info)
                show_software_info "$TILIX_BIN_NAME"
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

    # Verify it's Linux
    if [[ "$(uname -s)" != "Linux" ]]; then
        log_error "Tilix só está disponível para Linux"
        exit 1
    fi
    log_debug "Sistema operacional: Linux $(uname -r)"

    # Execute action
    case "$action" in
        install)
            install_tilix
            ;;
        update)
            update_tilix
            ;;
        uninstall)
            uninstall_tilix
            ;;
    esac
}

# Execute main function
main "$@"
