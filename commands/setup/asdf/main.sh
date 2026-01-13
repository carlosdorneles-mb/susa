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
    echo "  ASDF é um gerenciador de versões universal que suporta múltiplas"
    echo "  linguagens de programação através de plugins (Node.js, Python, Ruby,"
    echo "  Elixir, Java, e muitos outros)."
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  -h, --help        Mostra esta mensagem de ajuda"
    echo "  -u, --uninstall   Desinstala o ASDF do sistema"
    echo "  --update          Atualiza o ASDF para a versão mais recente"
    echo "  -v, --verbose     Habilita saída detalhada para depuração"
    echo "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo "  susa setup asdf              # Instala o ASDF"
    echo "  susa setup asdf --update     # Atualiza o ASDF"
    echo "  susa setup asdf --uninstall  # Desinstala o ASDF"
    echo ""
    echo -e "${LIGHT_GREEN}Pós-instalação:${NC}"
    echo "  Após a instalação, reinicie o terminal ou execute:"
    echo "    source ~/.bashrc   (para Bash)"
    echo "    source ~/.zshrc    (para Zsh)"
    echo ""
    echo -e "${LIGHT_GREEN}Próximos passos:${NC}"
    echo "  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git"
    echo "  asdf install nodejs latest"
    echo "  asdf global nodejs latest"
}

get_latest_asdf_version() {
    local fallback_version="v0.18.0"

    # Try to get the latest version via GitHub API
    local latest_version=$(curl -s --max-time 10 --connect-timeout 5 https://api.github.com/repos/asdf-vm/asdf/releases/latest 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via API do GitHub: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    # If it fails, try via git ls-remote
    log_debug "API do GitHub falhou, tentando via git ls-remote..." >&2
    latest_version=$(timeout 5 git ls-remote --tags --refs https://github.com/asdf-vm/asdf.git 2>/dev/null | tail -1 | sed 's/.*\///')

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via git ls-remote: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    # If it still fails, use fallback version
    log_debug "Usando versão fallback: $fallback_version" >&2
    echo "$fallback_version"
}

# Detect operating system and architecture
detect_os_and_arch() {
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin) os_name="darwin" ;;
        linux) os_name="linux" ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    local arch=$(uname -m)
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        i386|i686)
            if [ "$os_name" != "linux" ]; then
                log_error "Arquitetura i386/i686 não suportada em $os_name"
                return 1
            fi
            arch="386"
            ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    log_debug "SO: $os_name | Arquitetura: $arch" >&2
    echo "${os_name}:${arch}"
}

# Check if ASDF is already installed and ask about update
check_existing_installation() {
    local asdf_dir="$1"
    local target_version="$2"

    if [ ! -d "$asdf_dir" ] || [ ! -f "$asdf_dir/bin/asdf" ]; then
        return 0
    fi

    local current_version=$("$asdf_dir/bin/asdf" --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "desconhecida")
    log_debug "ASDF já está instalado (versão atual: $current_version)"

    if [ "$current_version" = "$target_version" ]; then
        log_info "Você já possui a versão mais recente instalada ($current_version)"
        return 2
    fi

    echo ""
    echo -e "${YELLOW}ASDF $current_version está instalado. Atualizar para $target_version? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sS]$ ]]; then
        log_info "Instalação cancelada"
        return 1
    fi

    log_info "Atualizando de $current_version para $target_version..."
    return 0
}

# Check if ASDF is already configured in shell
is_asdf_configured() {
    local shell_config="$1"
    grep -q "ASDF_DATA_DIR" "$shell_config" 2>/dev/null
}

# Add ASDF configuration to shell
add_asdf_to_shell() {
    local asdf_dir="$1"
    local shell_config="$2"

    echo "" >> "$shell_config"
    echo "# ASDF Version Manager" >> "$shell_config"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$shell_config"
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

# Download ASDF release
download_asdf_release() {
    local download_url="$1"
    local output_file="/tmp/asdf.tar.gz"

    log_debug "URL: $download_url" >&2
    log_info "Baixando ASDF..." >&2

    curl -L --progress-bar \
        --connect-timeout 30 \
        --max-time 300 \
        --retry 3 \
        --retry-delay 2 \
        "$download_url" -o "$output_file"

    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_error "Falha ao baixar ASDF" >&2
        log_debug "Código de saída: $exit_code" >&2
        rm -f "$output_file"
        return 1
    fi

    echo "$output_file"
}

# Extract and setup ASDF binary
extract_and_setup_binary() {
    local tar_file="$1"
    local asdf_dir="$2"

    log_info "Extraindo ASDF..."

    local extract_error=$(tar -xzf "$tar_file" -C "$HOME" 2>&1)
    local exit_code=$?
    rm -f "$tar_file"

    if [ $exit_code -ne 0 ]; then
        log_error "Falha ao extrair ASDF"
        log_debug "Detalhes: $extract_error"
        return 1
    fi

    # Create directory structure
    mkdir -p "$asdf_dir/bin"

    # Move binary to correct directory
    if [ -f "$HOME/asdf" ]; then
        mv "$HOME/asdf" "$asdf_dir/bin/asdf"
        log_debug "Binário instalado em $asdf_dir/bin/asdf"
    fi

    # Check if binary was installed
    if [ ! -f "$asdf_dir/bin/asdf" ]; then
        log_error "Binário não encontrado em $asdf_dir/bin"
        return 1
    fi

    chmod +x "$asdf_dir/bin/asdf"
}

# Configure environment variables for current session
setup_asdf_environment() {
    local asdf_dir="$1"

    export PATH="$HOME/.local/bin:$PATH"
    export ASDF_DATA_DIR="$asdf_dir"
    export PATH="$ASDF_DATA_DIR/bin:$ASDF_DATA_DIR/shims:$PATH"

    log_debug "Ambiente configurado para sessão atual"
}

# Main installation function
install_asdf_release() {
    local asdf_dir="$HOME/.asdf"

    log_debug "Obtendo última versão..."
    local asdf_version=$(get_latest_asdf_version)

    # Detect OS and architecture
    local os_arch=$(detect_os_and_arch)
    [ $? -ne 0 ] && return 1

    local os_name="${os_arch%:*}"
    local arch="${os_arch#*:}"

    log_info "Instalando ASDF $asdf_version..."

    # Build release URL
    local download_url="https://github.com/asdf-vm/asdf/releases/download/${asdf_version}/asdf-${asdf_version}-${os_name}-${arch}.tar.gz"

    # Download release
    local tar_file=$(download_asdf_release "$download_url")
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
    local asdf_dir="$HOME/.asdf"

    # Check if ASDF is already installed
    if [ -d "$asdf_dir" ] && [ -f "$asdf_dir/bin/asdf" ]; then
        local current_version=$("$asdf_dir/bin/asdf" --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "desconhecida")
        log_info "ASDF $current_version já está instalado."

        log_debug "Obtendo última versão..."
        local asdf_version=$(get_latest_asdf_version)

        if [ "$current_version" != "$asdf_version" ]; then
            echo ""
            echo -e "${YELLOW}Uma versão mais recente está disponível ($asdf_version).${NC}"
            echo -e "Para atualizar, execute: ${LIGHT_CYAN}susa setup asdf --update${NC}"
        fi

        return 0
    fi

    log_info "Iniciando instalação do ASDF..."

    install_asdf_release

    # Verify installation
    local shell_config=$(detect_shell_config)

    if command -v asdf &>/dev/null; then
        log_success "ASDF instalado com sucesso!"
        echo ""
        echo "Próximos passos:"
        echo -e "  1. Reinicie o terminal ou execute: ${LIGHT_CYAN}source $shell_config${NC}"
        echo -e "  2. Liste plugins disponíveis: ${LIGHT_CYAN}asdf plugin list all${NC}"
        echo -e "  3. Use ${LIGHT_CYAN}susa setup asdf --help${NC} para mais informações"
    else
        log_error "ASDF foi instalado mas não está disponível no PATH"
        log_info "Tente reiniciar o terminal ou executar: source $shell_config"
        return 1
    fi
}

update_asdf() {
    local asdf_dir="$HOME/.asdf"

    log_info "Atualizando ASDF..."

    # Check if ASDF is installed
    if [ ! -d "$asdf_dir" ] || [ ! -f "$asdf_dir/bin/asdf" ]; then
        log_error "ASDF não está instalado. Use 'susa setup asdf' para instalar."
        return 1
    fi

    local current_version=$("$asdf_dir/bin/asdf" --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "desconhecida")
    log_info "Versão atual: $current_version"

    # Get latest version
    log_debug "Obtendo última versão..."
    local asdf_version=$(get_latest_asdf_version)

    if [ "$current_version" = "$asdf_version" ]; then
        log_info "Você já possui a versão mais recente instalada ($current_version)"
        return 0
    fi

    log_info "Atualizando de $current_version para $asdf_version..."

    # Detect OS and architecture
    local os_arch=$(detect_os_and_arch)
    [ $? -ne 0 ] && return 1

    local os_name="${os_arch%:*}"
    local arch="${os_arch#*:}"

    # Backup plugins and tool versions
    local backup_dir="/tmp/asdf-backup-$$"
    mkdir -p "$backup_dir"

    if [ -d "$asdf_dir/plugins" ]; then
        log_debug "Fazendo backup dos plugins..."
        cp -r "$asdf_dir/plugins" "$backup_dir/" 2>/dev/null || true
    fi

    if [ -f "$HOME/.tool-versions" ]; then
        log_debug "Fazendo backup de .tool-versions..."
        cp "$HOME/.tool-versions" "$backup_dir/" 2>/dev/null || true
    fi

    # Remove old installation (plugins e versões de ferramentas serão preservados)
    log_info "Removendo versão anterior (plugins e versões de ferramentas serão preservados)..."
    rm -rf "$asdf_dir"

    # Build release URL
    local download_url="https://github.com/asdf-vm/asdf/releases/download/${asdf_version}/asdf-${asdf_version}-${os_name}-${arch}.tar.gz"

    # Download release
    local tar_file=$(download_asdf_release "$download_url")
    if [ $? -ne 0 ]; then
        # Restore backup on failure
        if [ -d "$backup_dir/plugins" ]; then
            mkdir -p "$asdf_dir"
            cp -r "$backup_dir/plugins" "$asdf_dir/" 2>/dev/null || true
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
        log_debug "Restaurando plugins..."
        cp -r "$backup_dir/plugins" "$asdf_dir/" 2>/dev/null || true
    fi

    if [ -f "$backup_dir/.tool-versions" ]; then
        log_debug "Restaurando .tool-versions..."
        cp "$backup_dir/.tool-versions" "$HOME/" 2>/dev/null || true
    fi

    # Cleanup backup
    rm -rf "$backup_dir"

    # Configure environment for current session
    setup_asdf_environment "$asdf_dir"

    # Verify update
    if command -v asdf &>/dev/null; then
        local new_version=$(asdf --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "desconhecida")
        log_success "ASDF atualizado com sucesso para versão $new_version!"
        echo ""
        echo "Plugins e versões de ferramentas foram preservados."
    else
        log_error "Falha na atualização do ASDF"
        return 1
    fi
}

uninstall_asdf() {
    local asdf_dir="$HOME/.asdf"
    local shell_config=$(detect_shell_config)

    log_info "Desinstalando ASDF..."

    # Remove ASDF directory
    if [ -d "$asdf_dir" ]; then
        rm -rf "$asdf_dir"
        log_debug "Diretório removido: $asdf_dir"
    else
        log_debug "ASDF não está instalado em $asdf_dir"
    fi

    # Remove shell configurations
    if [ -f "$shell_config" ] && is_asdf_configured "$shell_config"; then
        local backup_file="${shell_config}.backup.$(date +%Y%m%d%H%M%S)"

        log_debug "Removendo configurações de $shell_config..."

        # Create backup
        cp "$shell_config" "$backup_file"

        # Remove ASDF lines
        sed -i.tmp '/# ASDF Version Manager/d' "$shell_config"
        sed -i.tmp '/ASDF_DATA_DIR/d' "$shell_config"
        sed -i.tmp '/asdf\.sh/d' "$shell_config"
        sed -i.tmp '/asdf\.bash/d' "$shell_config"
        rm -f "${shell_config}.tmp"

        log_debug "Configurações removidas (backup: $backup_file)"
    else
        log_debug "Nenhuma configuração encontrada em $shell_config"
    fi

    log_success "ASDF desinstalado com sucesso!"
    echo ""
    log_info "Reinicie o terminal ou execute: source $shell_config"
}

# Main function
main() {
    local action="${1:-install}" # Default action is install

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                export DEBUG=1
                log_debug "Modo verbose ativado"
                shift
                ;;
            -q|--quiet)
                export SILENT=1
                shift
                ;;
            -u|--uninstall)
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
