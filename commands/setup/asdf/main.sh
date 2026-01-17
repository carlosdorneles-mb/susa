#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"

# Constants
ASDF_NAME="ASDF"
ASDF_BIN_NAME="asdf"
ASDF_REPO="asdf-vm/asdf"
ASDF_INSTALL_DIR="$HOME/.asdf"
LOCAL_BIN_DIR="$HOME/.local/bin"

SKIP_CONFIRM=false
# Help function
show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  $ASDF_NAME é um gerenciador de versões universal que suporta múltiplas"
    log_output "  linguagens de programação através de plugins (Node.js, Python, Ruby,"
    log_output "  Elixir, Java, e muitos outros)."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --info            Mostra informações sobre a instalação do ASDF"
    log_output "  --uninstall       Desinstala o ASDF do sistema"
    log_output "  -y, --yes         Pula confirmação (usar com --uninstall)"
    log_output "  -u, --upgrade     Atualiza o ASDF para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup asdf              # Instala o $ASDF_NAME"
    log_output "  susa setup asdf --upgrade    # Atualiza o $ASDF_NAME"
    log_output "  susa setup asdf --uninstall  # Desinstala o $ASDF_NAME"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Após a instalação, reinicie o terminal ou execute:"
    log_output "    source ~/.bashrc   (para Bash)"
    log_output "    source ~/.zshrc    (para Zsh)"
    log_output ""
    log_output "${LIGHT_GREEN}Próximos passos:${NC}"
    log_output "  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git"
    log_output "  asdf install nodejs latest"
    log_output "  asdf global nodejs latest"
}

get_latest_version() {
    github_get_latest_version "$ASDF_REPO"
}

# Get installed ASDF version
get_current_version() {
    local asdf_dir="${1:-$ASDF_INSTALL_DIR}"

    if [ -f "$asdf_dir/bin/$ASDF_BIN_NAME" ]; then
        "$asdf_dir/bin/$ASDF_BIN_NAME" --version 2> /dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "desconhecida"
    elif check_installation; then
        $ASDF_BIN_NAME --version 2> /dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if ASDF is installed
check_installation() {
    command -v $ASDF_BIN_NAME &> /dev/null
}

# Detect operating system and architecture
detect_os_and_arch() {
    local os_arch
    os_arch=$(github_detect_os_arch "darwin-macos")
    [ $? -ne 0 ] && return 1

    local os_name="${os_arch%:*}"
    local arch="${os_arch#*:}"

    # ASDF usa amd64 em vez de x64
    [ "$arch" = "x64" ] && arch="amd64"

    echo "${os_name}:${arch}"
}

# Check if ASDF is already configured in shell
is_asdf_configured() {
    local shell_config="$1"
    grep -q "ASDF_DATA_DIR" "$shell_config" 2> /dev/null
}

# Add ASDF configuration to shell
add_asdf_to_shell() {
    local asdf_dir="$1"
    local shell_config="$2"

    echo "" >> "$shell_config"
    echo "# ASDF Version Manager" >> "$shell_config"
    echo "export PATH=\"$LOCAL_BIN_DIR:\$PATH\"" >> "$shell_config"
    echo "export ASDF_DATA_DIR=\"$asdf_dir\"" >> "$shell_config"
    echo "export PATH=\"\$ASDF_DATA_DIR/bin:\$ASDF_DATA_DIR/shims:\$PATH\"" >> "$shell_config"
}

# Configure shell to use ASDF
configure_shell() {
    local asdf_dir="$1"
    local shell_config=$(detect_shell_config)

    log_debug "Arquivo de configuração: $shell_config"

    if is_asdf_configured "$shell_config"; then
        log_debug "ASDF já configurado em $shell_config"
        return 0
    fi

    log_debug "Configurando $shell_config..."
    add_asdf_to_shell "$asdf_dir" "$shell_config"
    log_debug "Configuração adicionada"
}

# Download ASDF release with checksum verification
download_asdf_release() {
    local download_url="$1"
    local checksum_url="$2"
    local output_file="/tmp/asdf.tar.gz"

    if github_download_and_verify \
        "$download_url" \
        "$checksum_url" \
        "$output_file" \
        "md5" \
        "ASDF"; then
        echo "$output_file"
        return 0
    else
        return 1
    fi
}

# Extract and setup ASDF binary
extract_and_setup_binary() {
    local tar_file="$1"
    local asdf_dir="$2"

    # Extract tarball
    local extracted_dir
    extracted_dir=$(github_extract_tarball "$tar_file" "/tmp/asdf-extract-$$")
    if [ $? -ne 0 ]; then
        rm -f "$tar_file"
        return 1
    fi

    rm -f "$tar_file"

    # Create directory structure
    mkdir -p "$asdf_dir/bin"

    # Find and move binary
    local asdf_binary=$(find "$extracted_dir" -type f -name "asdf" | head -1)

    if [ -z "$asdf_binary" ]; then
        log_error "Binário do ASDF não encontrado no arquivo"
        rm -rf "$extracted_dir"
        return 1
    fi

    log_debug "Binário encontrado: $asdf_binary"
    mv "$asdf_binary" "$asdf_dir/bin/asdf"
    chmod +x "$asdf_dir/bin/asdf"

    # Cleanup
    rm -rf "$extracted_dir"

    log_debug "Binário instalado em $asdf_dir/bin/asdf"
}

# Configure environment variables for current session
setup_asdf_environment() {
    local asdf_dir="$1"

    export PATH="$LOCAL_BIN_DIR:$PATH"
    export ASDF_DATA_DIR="$asdf_dir"
    export PATH="$ASDF_DATA_DIR/bin:$ASDF_DATA_DIR/shims:$PATH"

    log_debug "Ambiente configurado para sessão atual"
}

# Main installation function
install_asdf_release() {
    local asdf_dir="$ASDF_INSTALL_DIR"

    local asdf_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$asdf_version" ]; then
        return 1
    fi

    # Detect OS and architecture
    local os_arch=$(detect_os_and_arch)
    [ $? -ne 0 ] && return 1

    local os_name="${os_arch%:*}"
    local arch="${os_arch#*:}"

    log_info "Instalando ASDF $asdf_version..."

    # Build release URLs
    local download_url
    download_url=$(github_build_download_url \
        "asdf-vm/asdf" \
        "$asdf_version" \
        "$os_name" \
        "$arch" \
        "asdf-v{version}-{os}-{arch}.tar.gz")

    local checksum_url
    checksum_url=$(github_build_download_url \
        "asdf-vm/asdf" \
        "$asdf_version" \
        "$os_name" \
        "$arch" \
        "asdf-v{version}-{os}-{arch}.tar.gz.md5")

    # Download and verify release
    local tar_file=$(download_asdf_release "$download_url" "$checksum_url")
    [ $? -ne 0 ] && return 1

    # Extract and setup binary
    extract_and_setup_binary "$tar_file" "$asdf_dir"
    [ $? -ne 0 ] && return 1

    # Configure shell
    configure_shell "$asdf_dir"

    # Configure environment for current session
    setup_asdf_environment "$asdf_dir"
}

install_asdf() {
    if check_installation; then
        log_info "ASDF $(get_current_version) já está instalado."
        exit 0
    fi

    install_asdf_release

    # Verify installation
    if check_installation; then
        local version=$(get_current_version)
        log_success "ASDF instalado com sucesso!"
        register_or_update_software_in_lock "$COMMAND_NAME" "$version"
    else
        log_error "ASDF foi instalado mas não está disponível no PATH"
        local shell_config=$(detect_shell_config)
        log_info "Tente reiniciar o terminal ou executar: source $shell_config"
        return 1
    fi
}

update_asdf() {
    local asdf_dir="$ASDF_INSTALL_DIR"

    # Check if ASDF is installed
    if [ ! -d "$asdf_dir" ] || [ ! -f "$asdf_dir/bin/asdf" ]; then
        log_error "ASDF não está instalado. Use 'susa setup asdf' para instalar."
        return 1
    fi

    local current_version=$(get_current_version "$asdf_dir")

    # Get latest version
    local asdf_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$asdf_version" ]; then
        return 1
    fi

    if [ "$current_version" = "$asdf_version" ]; then
        log_info "Você já possui a versão mais recente instalada ($current_version)"
        return 0
    fi

    log_info "Atualizando ASDF de $current_version para $asdf_version..."

    # Detect OS and architecture
    local os_arch=$(detect_os_and_arch)
    [ $? -ne 0 ] && return 1

    local os_name="${os_arch%:*}"
    local arch="${os_arch#*:}"

    # Backup plugins and tool versions
    local backup_dir="/tmp/asdf-backup-$$"
    mkdir -p "$backup_dir"

    if [ -d "$asdf_dir/plugins" ]; then
        cp -r "$asdf_dir/plugins" "$backup_dir/" 2> /dev/null || true
    fi

    if [ -f "$HOME/.tool-versions" ]; then
        cp "$HOME/.tool-versions" "$backup_dir/" 2> /dev/null || true
    fi

    # Remove old installation (plugins e versões de ferramentas serão preservados)
    rm -rf "$asdf_dir"

    # Build release URLs
    local download_url
    download_url=$(github_build_download_url \
        "asdf-vm/asdf" \
        "$asdf_version" \
        "$os_name" \
        "$arch" \
        "asdf-v{version}-{os}-{arch}.tar.gz")

    local checksum_url
    checksum_url=$(github_build_download_url \
        "asdf-vm/asdf" \
        "$asdf_version" \
        "$os_name" \
        "$arch" \
        "asdf-v{version}-{os}-{arch}.tar.gz.md5")

    # Download and verify release
    local tar_file=$(download_asdf_release "$download_url" "$checksum_url")
    if [ $? -ne 0 ]; then
        # Restore backup on failure
        if [ -d "$backup_dir/plugins" ]; then
            mkdir -p "$asdf_dir"
            cp -r "$backup_dir/plugins" "$asdf_dir/" 2> /dev/null || true
        fi
        rm -rf "$backup_dir"
        return 1
    fi

    # Extract and setup binary
    extract_and_setup_binary "$tar_file" "$asdf_dir"
    if [ $? -ne 0 ]; then
        rm -rf "$backup_dir"
        return 1
    fi

    # Restore plugins
    if [ -d "$backup_dir/plugins" ]; then
        cp -r "$backup_dir/plugins" "$asdf_dir/" 2> /dev/null || true
    fi

    if [ -f "$backup_dir/.tool-versions" ]; then
        cp "$backup_dir/.tool-versions" "$HOME/" 2> /dev/null || true
    fi

    # Cleanup backup
    rm -rf "$backup_dir"

    # Configure environment for current session
    setup_asdf_environment "$asdf_dir"

    # Verify update
    if check_installation; then
        local new_version=$(get_current_version)
        log_success "ASDF atualizado para versão $new_version!"
        register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"
    else
        log_error "Falha na atualização do ASDF"
        return 1
    fi
}

uninstall_asdf() {
    local asdf_dir="$ASDF_INSTALL_DIR"
    local shell_config=$(detect_shell_config)

    # Check if installed
    if [ ! -d "$asdf_dir" ]; then
        log_warning "ASDF não está instalado"
        return 0
    fi

    local current_version="unknown"
    if command -v asdf &> /dev/null; then
        current_version=$(asdf --version 2> /dev/null | awk '{print $1}' || echo "unknown")
    fi

    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja realmente desinstalar o ASDF $current_version? (s/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    log_info "Desinstalando ASDF..."

    # Ask about removing installed tools (Node, Python, Ruby, etc)
    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja remover também as linguagens gerenciadas pelo ASDF (Node, Python, Ruby, etc)? (s/N)${NC}"
        read -r tools_response

        if [[ "$tools_response" =~ ^[sSyY]$ ]]; then
            rm -rf "$asdf_dir"
            log_debug "ASDF e linguagens removidos: $asdf_dir"
            log_success "ASDF e linguagens gerenciadas removidos"
        else
            log_info "Linguagens mantidas em $asdf_dir"
            log_warning "ASDF desinstalado mas linguagens mantidas (não funcionarão sem ASDF)"
        fi
    else
        # Auto-remove when --yes is used
        rm -rf "$asdf_dir"
        log_debug "ASDF e linguagens removidos: $asdf_dir"
        log_info "ASDF e linguagens gerenciadas removidos automaticamente"
    fi

    # Remove shell configurations
    if [ -f "$shell_config" ] && is_asdf_configured "$shell_config"; then
        local backup_file="${shell_config}.backup.$(date +%Y%m%d%H%M%S)"

        # Create backup
        cp "$shell_config" "$backup_file"

        # Remove ASDF lines
        sed -i.tmp '/# ASDF Version Manager/d' "$shell_config"
        sed -i.tmp '/ASDF_DATA_DIR/d' "$shell_config"
        sed -i.tmp '/asdf\.sh/d' "$shell_config"
        sed -i.tmp '/asdf\.bash/d' "$shell_config"
        rm -f "${shell_config}.tmp"
    fi

    log_success "ASDF desinstalado com sucesso!"
    remove_software_in_lock "$COMMAND_NAME"
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
                show_software_info "$ASDF_BIN_NAME"
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
            install_asdf
            ;;
        update)
            update_asdf
            ;;
        uninstall)
            uninstall_asdf
            ;;
        *)
            log_error "Ação desconhecida: $action"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
