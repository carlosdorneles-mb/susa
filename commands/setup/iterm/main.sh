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
    echo "  iTerm2 é um substituto para o Terminal do macOS com recursos"
    echo "  avançados como split panes, busca, autocompletar, histórico,"
    echo "  notificações e muito mais."
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  -h, --help        Mostra esta mensagem de ajuda"
    echo "  -u, --uninstall   Desinstala o iTerm2 do sistema"
    echo "  --update          Atualiza o iTerm2 para a versão mais recente"
    echo "  -v, --verbose     Habilita saída detalhada para depuração"
    echo "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo "  susa setup iterm              # Instala o iTerm2"
    echo "  susa setup iterm --update     # Atualiza o iTerm2"
    echo "  susa setup iterm --uninstall  # Desinstala o iTerm2"
    echo ""
    echo -e "${LIGHT_GREEN}Pós-instalação:${NC}"
    echo "  O iTerm2 estará disponível na pasta Aplicativos."
    echo "  Configure-o como terminal padrão em: Preferências do Sistema > Geral"
    echo ""
    echo -e "${LIGHT_GREEN}Recursos principais:${NC}"
    echo "  • Split panes horizontais e verticais"
    echo "  • Busca em todo o histórico"
    echo "  • Autocompletar inteligente"
    echo "  • Suporte a temas e cores"
    echo "  • Triggers e notificações"
}

# Check if iTerm2 is already installed
check_existing_installation() {
    log_debug "Verificando instalação existente do iTerm2..."
    
    if ! brew list --cask iterm2 &>/dev/null; then
        log_debug "iTerm2 não está instalado"
        return 0
    fi

    local current_version=$(brew info --cask iterm2 2>/dev/null | grep -E "^iterm2:" | sed -E 's/^iterm2: ([^ ]+).*/\1/' || echo "desconhecida")
    log_debug "iTerm2 já está instalado (versão atual: $current_version)"

    log_info "iTerm2 $current_version já está instalado."
    return 1
}

# Install iTerm2 using Homebrew
install_iterm() {
    log_info "Iniciando instalação do iTerm2..."

    # Check if Homebrew is installed
    log_debug "Verificando instalação do Homebrew..."
    if ! command -v brew &>/dev/null; then
        log_error "Homebrew não está instalado"
        echo ""
        echo -e "${YELLOW}Para instalar o Homebrew, execute:${NC}"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi
    log_debug "Homebrew encontrado: $(brew --version | head -1)"

    # Update Homebrew
    log_info "Atualizando Homebrew..."
    log_debug "Executando: brew update"
    brew update 2>&1 | while read -r line; do log_debug "brew: $line"; done || true

    # Install or reinstall iTerm2
    if brew list --cask iterm2 &>/dev/null; then
        log_info "Reinstalando iTerm2 via Homebrew..."
        log_debug "Executando: brew reinstall --cask iterm2"
        brew reinstall --cask iterm2 2>&1 | while read -r line; do log_debug "brew: $line"; done
    else
        log_info "Instalando iTerm2 via Homebrew..."
        log_debug "Executando: brew install --cask iterm2"
        brew install --cask iterm2 2>&1 | while read -r line; do log_debug "brew: $line"; done
    fi

    # Verify installation
    log_debug "Verificando instalação..."
    if [ -d "/Applications/iTerm.app" ]; then
        local version=$(brew info --cask iterm2 2>/dev/null | grep -E "^iterm2:" | sed -E 's/^iterm2: ([^ ]+).*/\1/' || echo "desconhecida")
        log_success "iTerm2 $version instalado com sucesso!"
        log_debug "Localização: /Applications/iTerm.app"
        return 0
    else
        log_error "Falha ao verificar instalação do iTerm2"
        return 1
    fi
}

# Update iTerm2
update_iterm() {
    log_info "Atualizando iTerm2..."

    # Check if Homebrew is installed
    log_debug "Verificando instalação do Homebrew..."
    if ! command -v brew &>/dev/null; then
        log_error "Homebrew não está instalado"
        return 1
    fi

    # Check if iTerm2 is installed
    log_debug "Verificando se iTerm2 está instalado..."
    if ! brew list --cask iterm2 &>/dev/null; then
        log_error "iTerm2 não está instalado"
        echo ""
        echo -e "${YELLOW}Para instalar, execute:${NC}"
        echo "  susa setup iterm"
        return 1
    fi

    local current_version=$(brew info --cask iterm2 2>/dev/null | grep -E "^iterm2:" | sed -E 's/^iterm2: ([^ ]+).*/\1/' || echo "desconhecida")
    log_debug "Versão atual: $current_version"

    # Update Homebrew
    log_info "Atualizando Homebrew..."
    log_debug "Executando: brew update"
    brew update 2>&1 | while read -r line; do log_debug "brew: $line"; done || true

    # Check for updates
    log_debug "Verificando atualizações disponíveis..."
    local outdated=$(brew outdated --cask iterm2 2>/dev/null)
    
    if [ -z "$outdated" ]; then
        log_info "iTerm2 já está na versão mais recente ($current_version)"
        return 0
    fi

    # Upgrade iTerm2
    log_info "Atualizando iTerm2 para a versão mais recente..."
    log_debug "Executando: brew upgrade --cask iterm2"
    brew upgrade --cask iterm2 2>&1 | while read -r line; do log_debug "brew: $line"; done

    local new_version=$(brew info --cask iterm2 2>/dev/null | grep -E "^iterm2:" | sed -E 's/^iterm2: ([^ ]+).*/\1/' || echo "desconhecida")
    log_success "iTerm2 atualizado de $current_version para $new_version"
    log_debug "Atualização concluída com sucesso"
}

# Uninstall iTerm2
uninstall_iterm() {
    log_info "Desinstalando iTerm2..."

    # Check if Homebrew is installed
    log_debug "Verificando instalação do Homebrew..."
    if ! command -v brew &>/dev/null; then
        log_error "Homebrew não está instalado"
        return 1
    fi

    # Check if iTerm2 is installed
    log_debug "Verificando se iTerm2 está instalado..."
    if ! brew list --cask iterm2 &>/dev/null; then
        log_warning "iTerm2 não está instalado via Homebrew"
        
        # Check if app exists manually
        if [ -d "/Applications/iTerm.app" ]; then
            log_warning "iTerm2 encontrado em /Applications mas não via Homebrew"
            echo ""
            echo -e "${YELLOW}Deseja remover manualmente? (s/N)${NC}"
            read -r response
            
            if [[ "$response" =~ ^[sS]$ ]]; then
                log_debug "Removendo /Applications/iTerm.app"
                rm -rf "/Applications/iTerm.app"
                log_success "iTerm2 removido com sucesso"
                return 0
            else
                log_info "Remoção cancelada"
                return 1
            fi
        else
            log_info "iTerm2 não está instalado"
            return 0
        fi
    fi

    local version=$(brew info --cask iterm2 2>/dev/null | grep -E "^iterm2:" | sed -E 's/^iterm2: ([^ ]+).*/\1/' || echo "desconhecida")
    log_debug "Versão a ser removida: $version"

    # Confirm uninstallation
    echo ""
    echo -e "${YELLOW}Deseja realmente desinstalar o iTerm2 $version? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sS]$ ]]; then
        log_info "Desinstalação cancelada"
        return 1
    fi

    # Uninstall iTerm2
    log_info "Removendo iTerm2..."
    log_debug "Executando: brew uninstall --cask iterm2"
    brew uninstall --cask iterm2 2>&1 | while read -r line; do log_debug "brew: $line"; done

    # Verify removal
    log_debug "Verificando remoção..."
    if [ ! -d "/Applications/iTerm.app" ]; then
        log_success "iTerm2 desinstalado com sucesso"
        log_debug "Aplicativo removido de /Applications"
    else
        log_warning "iTerm2 removido do Homebrew, mas arquivos podem permanecer"
    fi

    # Clean up preferences (optional)
    echo ""
    echo -e "${YELLOW}Deseja remover as preferências e configurações do iTerm2? (s/N)${NC}"
    read -r response

    if [[ "$response" =~ ^[sS]$ ]]; then
        log_debug "Removendo preferências..."
        rm -rf "$HOME/Library/Preferences/com.googlecode.iterm2.plist" 2>/dev/null || true
        rm -rf "$HOME/Library/Application Support/iTerm2" 2>/dev/null || true
        rm -rf "$HOME/Library/Saved Application State/com.googlecode.iterm2.savedState" 2>/dev/null || true
        log_success "Preferências removidas"
    else
        log_info "Preferências mantidas"
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

    # Verify it's macOS
    log_debug "Verificando sistema operacional..."
    if [[ "$(uname -s)" != "Darwin" ]]; then
        log_error "iTerm2 só está disponível para macOS"
        exit 1
    fi
    log_debug "Sistema operacional: macOS $(sw_vers -productVersion)"

    # Execute action
    log_debug "Ação selecionada: $action"
  
    case "$action" in
        install)
            if ! check_existing_installation; then
                exit 0
            fi
            install_iterm
            ;;
        update)
            update_iterm
            ;;
        uninstall)
            uninstall_iterm
            ;;
    esac
}

# Execute main function
main "$@"