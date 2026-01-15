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
    log_output "  UV (by Astral) é um gerenciador de pacotes e projetos Python extremamente"
    log_output "  rápido, escrito em Rust. Substitui pip, pip-tools, pipx, poetry, pyenv,"
    log_output "  virtualenv e muito mais, com velocidade 10-100x mais rápida."
    echo ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o UV do sistema"
    log_output "  --update          Atualiza o UV para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    echo ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup uv              # Instala o UV"
    log_output "  susa setup uv --update     # Atualiza o UV"
    log_output "  susa setup uv --uninstall  # Desinstala o UV"
    echo ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Após a instalação, reinicie o terminal ou execute:"
    echo "    source ~/.bashrc   (para Bash)"
    echo "    source ~/.zshrc    (para Zsh)"
    echo ""
    log_output "${LIGHT_GREEN}Próximos passos:${NC}"
    log_output "  uv init meu-projeto                 # Criar novo projeto"
    log_output "  uv add requests                     # Adicionar dependência"
    log_output "  uv sync                             # Instalar dependências"
    log_output "  uv run python script.py             # Executar script"
}
# Get latest UV version
get_latest_uv_version() {
    # Try to get the latest version via GitHub API
    local latest_version=$(curl -s --max-time 10 --connect-timeout 5 https://api.github.com/repos/astral-sh/uv/releases/latest 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via API do GitHub: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    # If it fails, try via git ls-remote with semantic version sorting
    log_debug "API do GitHub falhou, tentando via git ls-remote..." >&2
    latest_version=$(timeout 5 git ls-remote --tags --refs https://github.com/astral-sh/uv.git 2>/dev/null |
        grep -oE '[0-9]+\.[0-9]+\.[0-9]+$' |
        sort -V |
        tail -1)

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via git ls-remote: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    # If both methods fail, notify user
    log_error "Não foi possível obter a versão mais recente do UV" >&2
    log_error "Verifique sua conexão com a internet e tente novamente" >&2
    return 1
}

# Get installed UV version
get_uv_version() {
    if command -v uv &>/dev/null; then
        uv --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Get UV installation path
get_local_bin_dir() {
    echo "$HOME/.local/bin"
}

# Check if UV is already installed
check_existing_installation() {
    log_debug "Verificando instalação existente do UV..."

    if ! command -v uv &>/dev/null; then
        log_debug "UV não está instalado"
        return 0
    fi

    local current_version=$(get_uv_version)
    log_info "UV $current_version já está instalado."

    # Mark as installed in lock file
    mark_installed "uv" "$current_version"

    # Check for updates
    log_debug "Obtendo última versão..."
    local latest_version=$(get_latest_uv_version)
    if [ $? -eq 0 ] && [ -n "$latest_version" ]; then
        if [ "$current_version" != "$latest_version" ]; then
            echo ""
            log_output "${YELLOW}Nova versão disponível ($latest_version).${NC}"
            log_output "Para atualizar, execute: ${LIGHT_CYAN}susa setup uv --update${NC}"
        fi
    else
        log_warning "Não foi possível verificar atualizações"
    fi

    return 1
}

# Configure shell to use UV
configure_shell() {
    local bin_dir="$1"
    local shell_config=$(detect_shell_config)

    log_debug "Arquivo de configuração: $shell_config"

    # Check if .local/bin is already in PATH
    if grep -q ".local/bin" "$shell_config" 2>/dev/null; then
        log_debug ".local/bin já configurado em $shell_config"
        return 0
    fi

    log_debug "Configurando $shell_config..."

    echo "" >>"$shell_config"
    echo "# Local binaries PATH" >>"$shell_config"
    echo "export PATH=\"$(get_local_bin_dir):\$PATH\"" >>"$shell_config"

    log_debug "Configuração adicionada ao shell"
}

# Setup UV environment for current session
setup_uv_environment() {
    local bin_dir="$1"

    export PATH="$bin_dir:$PATH"

    log_debug "Ambiente configurado para sessão atual"
    log_debug "PATH atualizado com: $bin_dir"
}

# Install UV
install_uv() {
    if ! check_existing_installation; then
        exit 0
    fi

    log_info "Iniciando instalação do UV..."

    local bin_dir=$(get_local_bin_dir)
    log_debug "Diretório de instalação: $bin_dir"

    # Create bin directory if it doesn't exist
    mkdir -p "$bin_dir"
    log_debug "Diretório criado/verificado: $bin_dir"

    # Download and install UV using official installer
    log_info "Baixando instalador do UV..."
    log_debug "URL: ${UV_INSTALL_URL:-https://astral.sh/uv/install.sh}"

    local install_script="/tmp/uv-installer-$$.sh"

    if ! curl -sSfL ${UV_INSTALL_URL:-https://astral.sh/uv/install.sh} -o "$install_script"; then
        log_error "Falha ao baixar o instalador do UV"
        rm -f "$install_script"
        return 1
    fi

    log_debug "Instalador baixado em: $install_script"

    # Run installer
    log_info "Instalando UV..."
    log_debug "Executando instalador..."

    if bash "$install_script" 2>&1 | while read -r line; do log_debug "installer: $line"; done; then
        log_debug "Instalação concluída com sucesso"
    else
        log_error "Falha ao executar o instalador do UV"
        rm -f "$install_script"
        return 1
    fi

    rm -f "$install_script"
    log_debug "Instalador removido"

    # Configure shell
    configure_shell "$bin_dir"

    # Setup environment for current session
    setup_uv_environment "$bin_dir"

    # Verify installation
    log_debug "Verificando instalação..."

    if command -v uv &>/dev/null; then
        local version=$(get_uv_version)
        log_success "UV $version instalado com sucesso!"
        mark_installed "uv" "$version"
        log_debug "Executável: $(which uv)"

        echo ""
        echo "Próximos passos:"
        local shell_config=$(detect_shell_config)
        log_output "  1. Reinicie o terminal ou execute: ${LIGHT_CYAN}source $shell_config${NC}"
        log_output "  2. Crie um novo projeto: ${LIGHT_CYAN}uv init meu-projeto${NC}"
        log_output "  3. Use ${LIGHT_CYAN}susa setup uv --help${NC} para mais informações"

        # Show uvx info
        echo ""
        log_output "${LIGHT_GREEN}Dica:${NC} Use ${LIGHT_CYAN}uvx${NC} para executar ferramentas Python sem instalação:"
        echo "  uvx ruff check .    # Executar ruff"
        log_output "  uvx black .         # Executar black"

        return 0
    else
        log_error "UV foi instalado mas não está disponível no PATH"
        local shell_config=$(detect_shell_config)
        log_info "Tente reiniciar o terminal ou executar: source $shell_config"
        return 1
    fi
}

# Update UV
update_uv() {
    log_info "Atualizando UV..."

    # Check if UV is installed
    log_debug "Verificando se UV está instalado..."

    if ! command -v uv &>/dev/null; then
        log_error "UV não está instalado"
        echo ""
        log_output "${YELLOW}Para instalar, execute:${NC} ${LIGHT_CYAN}susa setup uv${NC}"
        return 1
    fi

    local current_version=$(get_uv_version)
    log_info "Versão atual: $current_version"
    log_debug "Executável: $(which uv)"

    # Update UV using self update command
    log_info "Executando atualização do UV..."
    log_debug "Comando: uv self update"

    if uv self update 2>&1 | while read -r line; do log_debug "uv: $line"; done; then
        log_debug "Comando de atualização executado com sucesso"
    else
        log_error "Falha ao atualizar o UV"
        return 1
    fi

    # Verify update
    log_debug "Verificando nova versão..."

    if command -v uv &>/dev/null; then
        local new_version=$(get_uv_version)

        if [ "$current_version" = "$new_version" ]; then
            log_info "UV já está na versão mais recente ($current_version)"
        else
            log_success "UV atualizado de $current_version para $new_version!"
            update_version "uv" "$new_version"
            log_debug "Atualização concluída com sucesso"
        fi

        return 0
    else
        log_error "Falha na atualização do UV"
        return 1
    fi
}

# Uninstall UV
uninstall_uv() {
    log_info "Desinstalando UV..."

    # Check if UV is installed
    log_debug "Verificando se UV está instalado..."

    if ! command -v uv &>/dev/null; then
        log_warning "UV não está instalado"
        log_info "Nada a fazer"
        return 0
    fi

    local version=$(get_uv_version)
    log_debug "Versão a ser removida: $version"
    log_debug "Executável: $(which uv)"

    # Confirm uninstallation
    echo ""
    log_output "${YELLOW}Deseja realmente desinstalar o UV $version? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sS]$ ]]; then
        log_info "Desinstalação cancelada"
        return 1
    fi

    local bin_dir=$(get_local_bin_dir)
    log_debug "Diretório de instalação: $bin_dir"

    # Remove UV binary and related tools
    log_info "Removendo binários do UV..."

    if [ -f "$bin_dir/uv" ]; then
        rm -f "$bin_dir/uv"
        log_debug "Removido: $bin_dir/uv"
    fi

    if [ -f "$bin_dir/uvx" ]; then
        rm -f "$bin_dir/uvx"
        log_debug "Removido: $bin_dir/uvx"
    fi

    # Remove UV data directory
    local uv_data_dir="$HOME/.local/share/uv"
    if [ -d "$uv_data_dir" ]; then
        log_debug "Removendo diretório de dados: $uv_data_dir"
        rm -rf "$uv_data_dir"
    fi

    # Remove shell configurations (only UV-specific, not .local/bin)
    local shell_config=$(detect_shell_config)

    if [ -f "$shell_config" ]; then
        # Only remove if the PATH export was added specifically for UV
        # Since .local/bin might be used by other tools, we don't remove it
        log_debug "Mantendo configuração do PATH em $shell_config (usado por outras ferramentas)"
    fi

    # Verify removal
    log_debug "Verificando remoção..."

    if ! command -v uv &>/dev/null; then
        log_success "UV desinstalado com sucesso!"
        mark_uninstalled "uv"
        log_debug "Executável removido"

        echo ""
        log_info "Reinicie o terminal ou execute: source $shell_config"
    else
        log_warning "UV removido, mas executável ainda encontrado no PATH"
        log_debug "Pode ser necessário remover manualmente de: $(which uv)"
    fi

    # Ask about cache removal
    echo ""
    log_output "${YELLOW}Deseja remover também o cache do UV? (s/N)${NC}"
    read -r cache_response

    if [[ "$cache_response" =~ ^[sS]$ ]]; then
        log_debug "Removendo cache..."

        local cache_dir="$HOME/.cache/uv"
        if [ -d "$cache_dir" ]; then
            rm -rf "$cache_dir" 2>/dev/null || true
            log_debug "Cache removido: $cache_dir"
        fi

        log_success "Cache removido"
    else
        log_info "Cache mantido em ~/.cache/uv"
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
                export DEBUG=1
                log_debug "Modo verbose ativado"
                shift
                ;;
            -q | --quiet)
                export SILENT=1
                shift
                ;;
            --uninstall)
                action="uninstall"
                shift
                ;;
            --update)
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
    log_debug "Ação selecionada: $action"

    case "$action" in
        install)
            install_uv
            ;;
        update)
            update_uv
            ;;
        uninstall)
            uninstall_uv
            ;;
        *)
            log_error "Ação desconhecida: $action"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
