#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"

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
    github_get_latest_version "astral-sh/uv"
}

# Get installed UV version
get_uv_version() {
    if command -v uv &> /dev/null; then
        uv --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Get UV installation path
get_local_bin_dir() {
    echo "$HOME/.local/bin"
}

# Detect OS and architecture for UV (uses specific naming)
detect_uv_platform() {
    local os_name=$(uname -s)
    local arch=$(uname -m)

    # Convert OS name
    case "$os_name" in
        Linux) os_name="unknown-linux-gnu" ;;
        Darwin) os_name="apple-darwin" ;;
        *)
            log_error "Sistema operacional não suportado: $os_name" >&2
            return 1
            ;;
    esac

    # Convert architecture
    case "$arch" in
        x86_64) arch="x86_64" ;;
        aarch64 | arm64) arch="aarch64" ;;
        armv7l) arch="armv7" ;;
        *)
            log_error "Arquitetura não suportada: $arch" >&2
            return 1
            ;;
    esac

    echo "${arch}-${os_name}"
}

# Check if UV is already installed
check_existing_installation() {

    if ! command -v uv &> /dev/null; then
        log_debug "UV não está instalado"
        return 0
    fi

    local current_version=$(get_uv_version)
    log_info "UV $current_version já está instalado."

    # Mark as installed in lock file
    mark_installed "uv" "$current_version"

    # Check for updates
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
    if grep -q ".local/bin" "$shell_config" 2> /dev/null; then
        log_debug ".local/bin já configurado em $shell_config"
        return 0
    fi

    log_debug "Configurando $shell_config..."

    echo "" >> "$shell_config"
    echo "# Local binaries PATH" >> "$shell_config"
    echo "export PATH=\"$(get_local_bin_dir):\$PATH\"" >> "$shell_config"

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
    log_info "Iniciando instalação do UV..."

    # Get latest version
    local uv_version=$(get_latest_uv_version)
    if [ $? -ne 0 ] || [ -z "$uv_version" ]; then
        return 1
    fi

    # Detect platform
    local platform=$(detect_uv_platform)
    if [ $? -ne 0 ]; then
        return 1
    fi

    local bin_dir=$(get_local_bin_dir)
    mkdir -p "$bin_dir"

    # Build download URL
    local filename="uv-${platform}.tar.gz"
    local download_url="https://github.com/astral-sh/uv/releases/download/${uv_version}/${filename}"
    local checksum_filename="${filename}.sha256"
    local output_file="/tmp/${filename}"

    log_info "Baixando e verificando UV ${uv_version}..."
    log_debug "Plataforma: $platform" >&2
    log_debug "URL: $download_url" >&2

    # Download and verify with checksum
    if ! github_download_and_verify "astral-sh/uv" "$uv_version" "$download_url" "$output_file" "$checksum_filename" "sha256"; then
        log_error "Falha ao baixar ou verificar UV" >&2
        return 1
    fi

    # Extract binary
    log_info "Extraindo UV..."
    local temp_dir="/tmp/uv-extract-$$"
    mkdir -p "$temp_dir"

    if ! tar -xzf "$output_file" -C "$temp_dir" 2> /dev/null; then
        log_error "Falha ao extrair UV" >&2
        rm -rf "$temp_dir" "$output_file"
        return 1
    fi
    rm -f "$output_file"

    # Find and install binaries
    local uv_binary=$(find "$temp_dir" -type f -name "uv" -o -name "uvx" | grep -E "/uv$" | head -1)
    local uvx_binary=$(find "$temp_dir" -type f -name "uvx" | head -1)

    if [ -z "$uv_binary" ]; then
        log_error "Binário do UV não encontrado no arquivo" >&2
        rm -rf "$temp_dir"
        return 1
    fi

    log_debug "Binário UV encontrado: $uv_binary" >&2
    mv "$uv_binary" "$bin_dir/uv"
    chmod +x "$bin_dir/uv"

    if [ -n "$uvx_binary" ]; then
        log_debug "Binário UVX encontrado: $uvx_binary" >&2
        mv "$uvx_binary" "$bin_dir/uvx"
        chmod +x "$bin_dir/uvx"
    fi

    rm -rf "$temp_dir"
    log_debug "Binários instalados em $bin_dir" >&2

    # Configure shell
    configure_shell "$bin_dir"

    # Setup environment for current session
    setup_uv_environment "$bin_dir"

    # Verify installation

    if command -v uv &> /dev/null; then
        local version=$(get_uv_version)
        log_success "UV $version instalado com sucesso!"
        mark_installed "uv" "$version"

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

    if ! command -v uv &> /dev/null; then
        log_error "UV não está instalado"
        echo ""
        log_output "${YELLOW}Para instalar, execute:${NC} ${LIGHT_CYAN}susa setup uv${NC}"
        return 1
    fi

    local current_version=$(get_uv_version)
    log_info "Versão atual: $current_version"

    # Update UV using self update command
    log_info "Executando atualização do UV..."

    if uv self update 2>&1 | while read -r line; do log_debug "uv: $line"; done; then
        log_debug "Comando de atualização executado com sucesso"
    else
        log_error "Falha ao atualizar o UV"
        return 1
    fi

    # Verify update

    if command -v uv &> /dev/null; then
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

    if ! command -v uv &> /dev/null; then
        log_warning "UV não está instalado"
        log_info "Nada a fazer"
        return 0
    fi

    local version=$(get_uv_version)
    log_debug "Versão a ser removida: $version"

    # Confirm uninstallation
    echo ""
    log_output "${YELLOW}Deseja realmente desinstalar o UV $version? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sSyY]$ ]]; then
        log_info "Desinstalação cancelada"
        return 1
    fi

    local bin_dir=$(get_local_bin_dir)

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

    if ! command -v uv &> /dev/null; then
        log_success "UV desinstalado com sucesso!"
        mark_uninstalled "uv"

        echo ""
        log_info "Reinicie o terminal ou execute: source $shell_config"
    else
        log_warning "UV removido, mas executável ainda encontrado no PATH"
        local uv_path=$(command -v uv 2> /dev/null || echo "desconhecido")
        log_debug "Pode ser necessário remover manualmente de: $uv_path"
    fi

    # Ask about cache removal
    echo ""
    log_output "${YELLOW}Deseja remover também o cache do UV? (s/N)${NC}"
    read -r cache_response

    if [[ "$cache_response" =~ ^[sSyY]$ ]]; then

        local cache_dir="$HOME/.cache/uv"
        if [ -d "$cache_dir" ]; then
            rm -rf "$cache_dir" 2> /dev/null || true
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

    case "$action" in
        install)
            if ! check_existing_installation; then
                exit 0
            fi
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
