#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"

# Constants
ITERM_NAME="iTerm2"
ITERM_BIN_NAME="iterm2"
ITERM_HOMEBREW_CASK="iterm2"
ITERM_GITHUB_REPO="gnachman/iTerm2"
ITERM_HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

SKIP_CONFIRM=false
# Help function
show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  $ITERM_NAME é um substituto para o Terminal do macOS com recursos"
    log_output "  avançados como split panes, busca, autocompletar, histórico,"
    log_output "  notificações e muito mais."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o iTerm2 do sistema"
    log_output "  -y, --yes         Pula confirmação (usar com --uninstall)"
    log_output "  -u, --upgrade     Atualiza o iTerm2 para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup iterm              # Instala o $ITERM_NAME"
    log_output "  susa setup iterm --upgrade    # Atualiza o $ITERM_NAME"
    log_output "  susa setup iterm --uninstall  # Desinstala o $ITERM_NAME"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O iTerm2 estará disponível na pasta Aplicativos."
    log_output "  Configure-o como terminal padrão em: Preferências do Sistema > Geral"
    log_output ""
    log_output "${LIGHT_GREEN}Recursos principais:${NC}"
    log_output "  • Split panes horizontais e verticais"
    log_output "  • Busca em todo o histórico"
    log_output "  • Autocompletar inteligente"
    log_output "  • Suporte a temas e cores"
    log_output "  • Triggers e notificações"
}

# Get latest iTerm2 version
get_latest_version() {
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
get_current_version() {
    if brew list --cask iterm2 &> /dev/null; then
        brew list --cask iterm2 --versions 2> /dev/null | awk '{print $2}' || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if iTerm2 is installed
check_installation() {
    [ "$(uname)" = "Darwin" ] && [ -d "/Applications/iTerm.app" ]
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

# Install iTerm2 using Homebrew
install_iterm() {
    # Check if Homebrew is installed
    if ! check_homebrew; then
        echo ""
        log_output "${YELLOW}Para instalar o Homebrew, execute:${NC}"
        log_output "  /bin/bash -c \"\$(curl -fsSL $ITERM_HOMEBREW_INSTALL_URL)\""
        return 1
    fi

    if check_installation; then
        log_info "iTerm2 $(get_current_version) já está instalado."
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
    if check_installation; then
        local version=$(get_current_version)
        log_success "iTerm2 $version instalado com sucesso!"
        register_or_update_software_in_lock "$COMMAND_NAME" "$version"
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

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    # Get latest version
    local latest_version=$(get_latest_version)
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

    local new_version=$(get_current_version)
    log_success "iTerm2 atualizado de $current_version para $new_version"
    register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"
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
        if check_installation; then
            log_warning "iTerm2 encontrado em /Applications mas não via Homebrew"
            echo ""
            log_output "${YELLOW}Deseja remover manualmente? (s/N)${NC}"
            read -r response

            if [[ "$response" =~ ^[sSyY]$ ]]; then
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

    local version=$(get_current_version)
    log_debug "Versão a ser removida: $version"

    # Confirm uninstallation
    if [ "$SKIP_CONFIRM" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja realmente desinstalar o iTerm2 $version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    # Uninstall iTerm2
    log_info "Removendo iTerm2..."
    log_debug "Executando: brew uninstall --cask iterm2"
    brew uninstall --cask iterm2 2>&1 | while read -r line; do log_debug "brew: $line"; done

    # Verify removal
    if ! check_installation; then
        log_success "iTerm2 desinstalado com sucesso"
        remove_software_in_lock "$COMMAND_NAME"
        log_debug "Aplicativo removido de /Applications"
    else
        log_warning "iTerm2 removido do Homebrew, mas arquivos podem permanecer"
    fi

    # Clean up preferences (optional)
    if [ "$SKIP_CONFIRM" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja remover as preferências e configurações do iTerm2? (s/N)${NC}"
        read -r config_response

        if [[ "$config_response" =~ ^[sSyY]$ ]]; then
            rm -rf "$HOME/Library/Preferences/com.googlecode.iterm2.plist" 2> /dev/null || true
            log_debug "Preferências removidas: ~/Library/Preferences/com.googlecode.iterm2.plist"
            rm -rf "$HOME/Library/Application Support/iTerm2" 2> /dev/null || true
            log_debug "Dados removidos: ~/Library/Application Support/iTerm2"
            rm -rf "$HOME/Library/Saved Application State/com.googlecode.iterm2.savedState" 2> /dev/null || true
            log_debug "Estado removido"
            log_success "Preferências removidas"
        else
            log_info "Preferências mantidas"
        fi
    else
        # Auto-remove when --yes is used
        rm -rf "$HOME/Library/Preferences/com.googlecode.iterm2.plist" 2> /dev/null || true
        log_debug "Preferências removidas: ~/Library/Preferences/com.googlecode.iterm2.plist"
        rm -rf "$HOME/Library/Application Support/iTerm2" 2> /dev/null || true
        log_debug "Dados removidos: ~/Library/Application Support/iTerm2"
        rm -rf "$HOME/Library/Saved Application State/com.googlecode.iterm2.savedState" 2> /dev/null || true
        log_debug "Estado removido"
        log_info "Preferências removidas automaticamente"
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
                shift
                ;;
            -q | --quiet)
                export SILENT=true
                shift
                ;;
            --info)
                show_software_info "$ITERM_BIN_NAME"
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
