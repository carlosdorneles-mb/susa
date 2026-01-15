#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source installations library
source "$LIB_DIR/internal/installations.sh"

# Help function
show_help() {
    show_description
    echo ""
    show_usage
    echo ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  iTerm2 é um substituto para o Terminal do macOS com recursos"
    log_output "  avançados como split panes, busca, autocompletar, histórico,"
    echo "  notificações e muito mais."
    echo ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o iTerm2 do sistema"
    log_output "  --update          Atualiza o iTerm2 para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    echo ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup iterm              # Instala o iTerm2"
    log_output "  susa setup iterm --update     # Atualiza o iTerm2"
    log_output "  susa setup iterm --uninstall  # Desinstala o iTerm2"
    echo ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O iTerm2 estará disponível na pasta Aplicativos."
    echo "  Configure-o como terminal padrão em: Preferências do Sistema > Geral"
    echo ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Split panes horizontais e verticais"
    echo "  • Busca em todo o histórico"
    echo "  • Autocompletar inteligente"
    echo "  • Suporte a temas e cores"
    echo "  • Triggers e notificações"
}

# Get latest iTerm2 version
get_latest_iterm_version() {
    # Check if Homebrew is available
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado" >&2
        return 1
    fi

    # Try to get the latest version via Homebrew
    local latest_version=$(brew info --cask iterm2 2> /dev/null | grep -E "^iterm2:" | sed -E 's/^iterm2: ([^ ]+).*/\1/' | head -1)

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via Homebrew: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    # If Homebrew fails, try via GitHub API as fallback
    log_debug "Homebrew falhou, tentando via API do GitHub..." >&2
    latest_version=$(curl -s --max-time 10 --connect-timeout 5 https://api.github.com/repos/gnachman/iTerm2/releases/latest 2> /dev/null | grep '"tag_name":' | sed -E 's/.*"v([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via API do GitHub: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    # If both methods fail, notify user
    log_error "Não foi possível obter a versão mais recente do iTerm2" >&2
    log_error "Verifique sua conexão com a internet e o Homebrew" >&2
    return 1
}

# Get installed iTerm2 version
get_iterm_version() {
    if brew list --cask iterm2 &> /dev/null; then
        brew list --cask iterm2 --versions 2> /dev/null | awk '{print $2}' || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if Homebrew is installed
check_homebrew() {
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado"
        return 1
    fi
    log_debug "Homebrew encontrado: $(brew --version | head -1)"
    return 0
}

# Check if iTerm2 is already installed
check_existing_installation() {

    if ! brew list --cask iterm2 &> /dev/null; then
        log_debug "iTerm2 não está instalado"
        return 0
    fi

    local current_version=$(get_iterm_version)
    log_info "iTerm2 $current_version já está instalado."

    # Mark as installed in lock file
    mark_installed "iterm" "$current_version"

    # Check for updates
    local latest_version=$(get_latest_iterm_version)
    if [ $? -eq 0 ] && [ -n "$latest_version" ]; then
        if [ "$current_version" != "$latest_version" ]; then
            echo ""
            log_output "${YELLOW}Nova versão disponível ($latest_version).${NC}"
            log_output "Para atualizar, execute: ${LIGHT_CYAN}susa setup iterm --update${NC}"
        fi
    else
        log_warning "Não foi possível verificar atualizações"
    fi

    return 1
}

# Install iTerm2 using Homebrew
install_iterm() {
    # Check if Homebrew is installed
    if ! check_homebrew; then
        echo ""
        log_output "${YELLOW}Para instalar o Homebrew, execute:${NC}"
        log_output "  /bin/bash -c \"\$(curl -fsSL ${ITERM_HOMEBREW_INSTALL_URL:-https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh})\""
        return 1
    fi

    if ! check_existing_installation; then
        exit 0
    fi

    log_info "Iniciando instalação do iTerm2..."

    # Update Homebrew
    log_info "Atualizando Homebrew..."
    log_debug "Executando: brew update"
    brew update 2>&1 | while read -r line; do log_debug "brew: $line"; done || true

    # Install or reinstall iTerm2
    log_info "Instalando iTerm2 via Homebrew..."
    log_debug "Executando: brew install --cask iterm2"
    brew install --cask iterm2 2>&1 | while read -r line; do log_debug "brew: $line"; done

    # Verify installation
    if [ -d "/Applications/iTerm.app" ]; then
        local version=$(get_iterm_version)
        log_success "iTerm2 $version instalado com sucesso!"
        mark_installed "iterm" "$version"
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
    if ! check_homebrew; then
        return 1
    fi

    # Check if iTerm2 is installed
    if ! brew list --cask iterm2 &> /dev/null; then
        log_error "iTerm2 não está instalado"
        echo ""
        log_output "${YELLOW}Para instalar, execute:${NC}"
        echo "  susa setup iterm"
        return 1
    fi

    local current_version=$(get_iterm_version)
    log_info "Versão atual: $current_version"

    # Get latest version
    local latest_version=$(get_latest_iterm_version)
    if [ $? -ne 0 ] || [ -z "$latest_version" ]; then
        log_warning "Não foi possível verificar a última versão. Continuando com atualização via Homebrew..."
    elif [ "$current_version" = "$latest_version" ]; then
        log_info "Você já possui a versão mais recente instalada ($current_version)"
        return 0
    else
        log_info "Atualizando de $current_version para $latest_version..."
    fi

    # Update Homebrew
    log_info "Atualizando Homebrew..."
    log_debug "Executando: brew update"
    brew update 2>&1 | while read -r line; do log_debug "brew: $line"; done || true

    # Upgrade iTerm2
    log_info "Atualizando iTerm2 para a versão mais recente..."
    log_debug "Executando: brew upgrade --cask iterm2"
    brew upgrade --cask iterm2 2>&1 | while read -r line; do log_debug "brew: $line"; done

    local new_version=$(get_iterm_version)
    log_success "iTerm2 atualizado de $current_version para $new_version"
    update_version "iterm" "$new_version"
    log_debug "Atualização concluída com sucesso"
}

# Uninstall iTerm2
uninstall_iterm() {
    log_info "Desinstalando iTerm2..."

    # Check if Homebrew is installed
    if ! check_homebrew; then
        return 1
    fi

    # Check if iTerm2 is installed
    if ! brew list --cask iterm2 &> /dev/null; then
        log_warning "iTerm2 não está instalado via Homebrew"

        # Check if app exists manually
        if [ -d "/Applications/iTerm.app" ]; then
            log_warning "iTerm2 encontrado em /Applications mas não via Homebrew"
            echo ""
            log_output "${YELLOW}Deseja remover manualmente? (s/N)${NC}"
            read -r response

            if [[ "$response" =~ ^[sS]$ ]]; then
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

    local version=$(get_iterm_version)
    log_debug "Versão a ser removida: $version"

    # Confirm uninstallation
    echo ""
    log_output "${YELLOW}Deseja realmente desinstalar o iTerm2 $version? (s/N)${NC}"
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
    if [ ! -d "/Applications/iTerm.app" ]; then
        log_success "iTerm2 desinstalado com sucesso"
        mark_uninstalled "iterm"
        log_debug "Aplicativo removido de /Applications"
    else
        log_warning "iTerm2 removido do Homebrew, mas arquivos podem permanecer"
    fi

    # Clean up preferences (optional)
    echo ""
    log_output "${YELLOW}Deseja remover as preferências e configurações do iTerm2? (s/N)${NC}"
    read -r response

    if [[ "$response" =~ ^[sS]$ ]]; then
        rm -rf "$HOME/Library/Preferences/com.googlecode.iterm2.plist" 2> /dev/null || true
        rm -rf "$HOME/Library/Application Support/iTerm2" 2> /dev/null || true
        rm -rf "$HOME/Library/Saved Application State/com.googlecode.iterm2.savedState" 2> /dev/null || true
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
            --help | -h)
                show_help
                exit 0
                ;;
            --uninstall | -u)
                action="uninstall"
                shift
                ;;
            --update)
                action="update"
                shift
                ;;
            --verbose | -v)
                export DEBUG=1
                shift
                ;;
            --quiet | -q)
                export SILENT=1
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
    if [[ "$(uname -s)" != "Darwin" ]]; then
        log_error "iTerm2 só está disponível para macOS"
        exit 1
    fi
    log_debug "Sistema operacional: macOS $(sw_vers -productVersion)"

    # Execute action

    case "$action" in
        install)
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
