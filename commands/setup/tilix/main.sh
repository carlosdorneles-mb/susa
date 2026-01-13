#!/bin/bash
set -euo pipefail

setup_command_env

# Help function
show_help() {
    show_description
    echo ""
    show_usage
    echo ""
    echo -e "${LIGHT_GREEN}O que é:${NC}"
    echo "  Tilix é um emulador de terminal avançado para Linux usando GTK+ 3."
    echo "  Oferece recursos como tiles (painéis lado a lado), notificações,"
    echo "  transparência, temas personalizáveis e muito mais."
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  -h, --help        Mostra esta mensagem de ajuda"
    echo "  -u, --uninstall   Desinstala o Tilix do sistema"
    echo "  --update          Atualiza o Tilix para a versão mais recente"
    echo "  -v, --verbose     Habilita saída detalhada para depuração"
    echo "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo "  susa setup tilix              # Instala o Tilix"
    echo "  susa setup tilix --update     # Atualiza o Tilix"
    echo "  susa setup tilix --uninstall  # Desinstala o Tilix"
    echo ""
    echo -e "${LIGHT_GREEN}Pós-instalação:${NC}"
    echo "  O Tilix estará disponível no menu de aplicativos."
    echo "  Para configurá-lo como terminal padrão:"
    echo "    sudo update-alternatives --config x-terminal-emulator"
    echo ""
    echo -e "${LIGHT_GREEN}Recursos principais:${NC}"
    echo "  • Tiles (painéis lado a lado)"
    echo "  • Transparência e efeitos visuais"
    echo "  • Drag and drop de arquivos"
    echo "  • Hyperlinks clicáveis"
    echo "  • Temas e esquemas de cores"
}

# Detect package manager
detect_package_manager() {
    log_debug "Detectando gerenciador de pacotes..."
    
    if command -v apt-get &>/dev/null; then
        echo "apt"
        log_debug "Gerenciador de pacotes: apt (Debian/Ubuntu)"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
        log_debug "Gerenciador de pacotes: dnf (Fedora)"
    elif command -v yum &>/dev/null; then
        echo "yum"
        log_debug "Gerenciador de pacotes: yum (RHEL/CentOS)"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
        log_debug "Gerenciador de pacotes: pacman (Arch Linux)"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
        log_debug "Gerenciador de pacotes: zypper (openSUSE)"
    else
        echo "unknown"
        log_debug "Nenhum gerenciador de pacotes conhecido detectado"
    fi
}

# Check if Tilix is already installed
check_existing_installation() {
    log_debug "Verificando instalação existente do Tilix..."
    
    if ! command -v tilix &>/dev/null; then
        log_debug "Tilix não está instalado"
        return 0
    fi

    local current_version=$(tilix --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida")
    log_debug "Tilix já está instalado (versão atual: $current_version)"

    log_info "Tilix $current_version já está instalado."
    return 1
}

# Install Tilix using system package manager
install_tilix() {
    log_info "Iniciando instalação do Tilix..."

    local pkg_manager=$(detect_package_manager)
    log_debug "Gerenciador de pacotes detectado: $pkg_manager"

    if [ "$pkg_manager" = "unknown" ]; then
        log_error "Gerenciador de pacotes não suportado"
        echo ""
        echo -e "${YELLOW}Instalação manual necessária:${NC}"
        echo "  Visite: https://gnunn1.github.io/tilix-web/"
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
            log_debug "Executando: sudo apt-get install -y tilix"
            if sudo apt-get install -y tilix 2>&1 | while read -r line; do log_debug "apt: $line"; done; then
                install_success=true
            fi
            ;;
        dnf)
            log_debug "Executando: sudo dnf install -y tilix"
            if sudo dnf install -y tilix 2>&1 | while read -r line; do log_debug "dnf: $line"; done; then
                install_success=true
            fi
            ;;
        yum)
            log_debug "Executando: sudo yum install -y tilix"
            if sudo yum install -y tilix 2>&1 | while read -r line; do log_debug "yum: $line"; done; then
                install_success=true
            fi
            ;;
        pacman)
            log_debug "Executando: sudo pacman -S --noconfirm tilix"
            if sudo pacman -S --noconfirm tilix 2>&1 | while read -r line; do log_debug "pacman: $line"; done; then
                install_success=true
            fi
            ;;
        zypper)
            log_debug "Executando: sudo zypper install -y tilix"
            if sudo zypper install -y tilix 2>&1 | while read -r line; do log_debug "zypper: $line"; done; then
                install_success=true
            fi
            ;;
    esac

    # Verify installation
    log_debug "Verificando instalação..."
    if command -v tilix &>/dev/null; then
        local version=$(tilix --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida")
        log_success "Tilix $version instalado com sucesso!"
        log_debug "Executável: $(which tilix)"
        
        # Check for VTE configuration
        log_debug "Verificando configuração VTE..."
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
    log_debug "Verificando se Tilix está instalado..."
    if ! command -v tilix &>/dev/null; then
        log_error "Tilix não está instalado"
        echo ""
        echo -e "${YELLOW}Para instalar, execute:${NC}"
        echo "  susa setup tilix"
        return 1
    fi

    local current_version=$(tilix --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida")
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
            log_debug "Executando: sudo apt-get upgrade -y tilix"
            sudo apt-get upgrade -y tilix 2>&1 | while read -r line; do log_debug "apt: $line"; done
            ;;
        dnf)
            log_debug "Executando: sudo dnf upgrade -y tilix"
            sudo dnf upgrade -y tilix 2>&1 | while read -r line; do log_debug "dnf: $line"; done
            ;;
        yum)
            log_debug "Executando: sudo yum update -y tilix"
            sudo yum update -y tilix 2>&1 | while read -r line; do log_debug "yum: $line"; done
            ;;
        pacman)
            log_debug "Executando: sudo pacman -S tilix"
            sudo pacman -S tilix 2>&1 | while read -r line; do log_debug "pacman: $line"; done
            ;;
        zypper)
            log_debug "Executando: sudo zypper update -y tilix"
            sudo zypper update -y tilix 2>&1 | while read -r line; do log_debug "zypper: $line"; done
            ;;
    esac

    local new_version=$(tilix --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida")
    
    if [ "$current_version" = "$new_version" ]; then
        log_info "Tilix já está na versão mais recente ($current_version)"
    else
        log_success "Tilix atualizado de $current_version para $new_version"
    fi
    
    log_debug "Atualização concluída"
}

# Uninstall Tilix
uninstall_tilix() {
    log_info "Desinstalando Tilix..."

    local pkg_manager=$(detect_package_manager)
    log_debug "Gerenciador de pacotes detectado: $pkg_manager"

    # Check if Tilix is installed
    log_debug "Verificando se Tilix está instalado..."
    if ! command -v tilix &>/dev/null; then
        log_warning "Tilix não está instalado via gerenciador de pacotes"
        log_info "Nada a fazer"
        return 0
    fi

    local version=$(tilix --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida")
    log_debug "Versão a ser removida: $version"

    # Confirm uninstallation
    echo ""
    echo -e "${YELLOW}Deseja realmente desinstalar o Tilix $version? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sS]$ ]]; then
        log_info "Desinstalação cancelada"
        return 1
    fi

    # Uninstall Tilix
    log_info "Removendo Tilix via $pkg_manager..."
    case "$pkg_manager" in
        apt)
            log_debug "Executando: sudo apt-get remove -y tilix"
            sudo apt-get remove -y tilix 2>&1 | while read -r line; do log_debug "apt: $line"; done
            
            # Ask about purge
            echo ""
            echo -e "${YELLOW}Deseja remover também os arquivos de configuração? (s/N)${NC}"
            read -r purge_response
            
            if [[ "$purge_response" =~ ^[sS]$ ]]; then
                log_debug "Executando: sudo apt-get purge -y tilix"
                sudo apt-get purge -y tilix 2>&1 | while read -r line; do log_debug "apt: $line"; done
                log_debug "Executando: sudo apt-get autoremove -y"
                sudo apt-get autoremove -y 2>&1 | while read -r line; do log_debug "apt: $line"; done
            fi
            ;;
        dnf)
            log_debug "Executando: sudo dnf remove -y tilix"
            sudo dnf remove -y tilix 2>&1 | while read -r line; do log_debug "dnf: $line"; done
            ;;
        yum)
            log_debug "Executando: sudo yum remove -y tilix"
            sudo yum remove -y tilix 2>&1 | while read -r line; do log_debug "yum: $line"; done
            ;;
        pacman)
            log_debug "Executando: sudo pacman -R tilix"
            sudo pacman -R tilix 2>&1 | while read -r line; do log_debug "pacman: $line"; done
            ;;
        zypper)
            log_debug "Executando: sudo zypper remove -y tilix"
            sudo zypper remove -y tilix 2>&1 | while read -r line; do log_debug "zypper: $line"; done
            ;;
    esac

    # Verify removal
    log_debug "Verificando remoção..."
    if ! command -v tilix &>/dev/null; then
        log_success "Tilix desinstalado com sucesso"
        log_debug "Executável removido"
    else
        log_warning "Tilix removido do gerenciador de pacotes, mas executável ainda encontrado"
    fi

    # Clean up user configurations (optional)
    echo ""
    echo -e "${YELLOW}Deseja remover as configurações de usuário do Tilix? (s/N)${NC}"
    read -r config_response

    if [[ "$config_response" =~ ^[sS]$ ]]; then
        log_debug "Removendo configurações de usuário..."
        rm -rf "$HOME/.config/tilix" 2>/dev/null || true
        rm -rf "$HOME/.local/share/tilix" 2>/dev/null || true
        dconf reset -f /com/gexperts/Tilix/ 2>/dev/null || true
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
            --help|-h)
                show_help
                exit 0
                ;;
            --uninstall|-u)
                action="uninstall"
                shift
                ;;
            --update)
                action="update"
                shift
                ;;
            --verbose|-v)
                export SUSA_DEBUG=1
                log_debug "Modo verbose ativado"
                shift
                ;;
            --quiet|-q)
                export SUSA_QUIET=1
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
    log_debug "Verificando sistema operacional..."
    if [[ "$(uname -s)" != "Linux" ]]; then
        log_error "Tilix só está disponível para Linux"
        exit 1
    fi
    log_debug "Sistema operacional: Linux $(uname -r)"

    # Execute action
    case "$action" in
        install)
            log_debug "Ação selecionada: instalação"
            if ! check_existing_installation; then
                exit 0
            fi
            install_tilix
            ;;
        update)
            log_debug "Ação selecionada: atualização"
            update_tilix
            ;;
        uninstall)
            log_debug "Ação selecionada: desinstalação"
            uninstall_tilix
            ;;
    esac
}

# Execute main function
main "$@"