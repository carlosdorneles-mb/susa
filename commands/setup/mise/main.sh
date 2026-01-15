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
    log_output "  Mise (anteriormente rtx) é um gerenciador de versões de ferramentas"
    log_output "  de desenvolvimento polyglot, escrito em Rust. É compatível com ASDF,"
    log_output "  mas oferece melhor performance e recursos adicionais como task runner."
    echo ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o Mise do sistema"
    log_output "  --update          Atualiza o Mise para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    echo ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup mise              # Instala o Mise"
    log_output "  susa setup mise --update     # Atualiza o Mise"
    log_output "  susa setup mise --uninstall  # Desinstala o Mise"
    echo ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Após a instalação, reinicie o terminal ou execute:"
    echo "    source ~/.bashrc   (para Bash)"
    echo "    source ~/.zshrc    (para Zsh)"
    echo ""
    log_output "${LIGHT_GREEN}Próximos passos:${NC}"
    log_output "  mise use --global node@20    # Instalar e usar Node.js 20"
    log_output "  mise use --global python@3.12 # Instalar e usar Python 3.12"
    log_output "  mise install                  # Instalar ferramentas do .mise.toml"
}

# Get latest Mise version from GitHub
get_latest_mise_version() {
    # Try to get the latest version via GitHub API
    local latest_version=$(curl -s --max-time ${MISE_API_MAX_TIME:-10} --connect-timeout ${MISE_API_CONNECT_TIMEOUT:-5} ${MISE_GITHUB_API_URL:-https://api.github.com/repos/jdx/mise/releases/latest} 2> /dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via API do GitHub: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    # If it fails, try via git ls-remote with semantic version sorting
    log_debug "API do GitHub falhou, tentando via git ls-remote..." >&2
    latest_version=$(timeout ${MISE_GIT_TIMEOUT:-5} git ls-remote --tags --refs ${MISE_GITHUB_REPO_URL:-https://github.com/jdx/mise.git} 2> /dev/null |
        grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+$' |
        sort -V |
        tail -1)

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via git ls-remote: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    # If both methods fail, notify user
    log_error "Não foi possível obter a versão mais recente do Mise" >&2
    log_error "Verifique sua conexão com a internet e tente novamente" >&2
    return 1
}

# Get installed Mise version
get_mise_version() {
    if command -v mise &> /dev/null; then
        mise --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Get local bin directory path
get_local_bin_dir() {
    log_output "${MISE_LOCAL_BIN_DIR:-$HOME/.local/bin}"
}

# Detect operating system and architecture
detect_os_and_arch() {
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin) os_name="macos" ;;
        linux) os_name="linux" ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    local arch=$(uname -m)
    case "$arch" in
        x86_64) arch="x64" ;;
        aarch64 | arm64) arch="arm64" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    log_debug "SO: $os_name | Arquitetura: $arch" >&2
    log_output "${os_name}:${arch}"
}

# Check if Mise is already installed
check_existing_installation() {
    log_debug "Verificando instalação existente do Mise..."

    if ! command -v mise &> /dev/null; then
        log_debug "Mise não está instalado"
        return 0
    fi

    local current_version=$(get_mise_version)
    log_info "Mise $current_version já está instalado."

    # Mark as installed in lock file
    mark_installed "mise" "$current_version"

    # Check for updates
    log_debug "Obtendo última versão..."
    local latest_version=$(get_latest_mise_version)
    if [ $? -eq 0 ] && [ -n "$latest_version" ]; then
        # Remove 'v' prefix if present
        local latest_clean="${latest_version#v}"
        if [ "$current_version" != "$latest_clean" ]; then
            echo ""
            log_output "${YELLOW}Nova versão disponível ($latest_clean).${NC}"
            log_output "Para atualizar, execute: ${LIGHT_CYAN}susa setup mise --update${NC}"
        fi
    else
        log_warning "Não foi possível verificar atualizações"
    fi

    return 1
}

# Check if Mise is already configured in shell
is_mise_configured() {
    local shell_config="$1"
    grep -q "mise activate" "$shell_config" 2> /dev/null
}

# Add Mise configuration to shell
add_mise_to_shell() {
    local shell_config="$1"
    local shell_type="bash"

    if [[ "$shell_config" == *"zshrc"* ]]; then
        shell_type="zsh"
    fi

    echo "" >> "$shell_config"
    echo "# Mise (polyglot version manager)" >> "$shell_config"
    echo "export PATH=\"$(get_local_bin_dir):\$PATH\"" >> "$shell_config"
    echo "eval \"\$(mise activate $shell_type)\"" >> "$shell_config"
}

# Configure shell to use Mise
configure_shell() {
    local shell_config=$(detect_shell_config)

    log_debug "Arquivo de configuração: $shell_config"

    if is_mise_configured "$shell_config"; then
        log_debug "Mise já configurado em $shell_config"
        return 0
    fi

    log_debug "Configurando $shell_config..."
    add_mise_to_shell "$shell_config"
    log_debug "Configuração adicionada"
}

# Download Mise release
download_mise_release() {
    local download_url="$1"
    local output_file="/tmp/mise.tar.gz"

    log_debug "URL: $download_url" >&2
    log_info "Baixando Mise..." >&2

    curl -L --progress-bar \
        --connect-timeout 30 \
        --max-time 300 \
        --retry 3 \
        --retry-delay 2 \
        "$download_url" -o "$output_file"

    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_error "Falha ao baixar Mise" >&2
        log_debug "Código de saída: $exit_code" >&2
        rm -f "$output_file"
        return 1
    fi

    echo "$output_file"
}

# Extract and setup Mise binary
extract_and_setup_binary() {
    local tar_file="$1"
    local bin_dir="$2"

    log_info "Extraindo Mise..."

    # Create bin directory
    mkdir -p "$bin_dir"
    log_debug "Diretório criado: $bin_dir"

    # Extract binary
    local temp_dir="/tmp/mise-extract-$$"
    mkdir -p "$temp_dir"

    tar -xzf "$tar_file" -C "$temp_dir" 2>&1 | while read -r line; do log_debug "tar: $line"; done || true
    local exit_code=$?
    rm -f "$tar_file"

    if [ $exit_code -ne 0 ]; then
        log_error "Falha ao extrair Mise"
        rm -rf "$temp_dir"
        return 1
    fi

    # Find and move binary
    local mise_binary=$(find "$temp_dir" -type f -name "mise" | head -1)

    if [ -z "$mise_binary" ]; then
        log_error "Binário do Mise não encontrado no arquivo"
        rm -rf "$temp_dir"
        return 1
    fi

    log_debug "Binário encontrado: $mise_binary"

    local mise_bin="$(get_local_bin_dir)/mise"
    mv "$mise_binary" "$mise_bin"
    chmod +x "$mise_bin"
    rm -rf "$temp_dir"

    log_debug "Binário instalado em $mise_bin"
}

# Setup Mise environment for current session
setup_mise_environment() {
    local bin_dir="$1"

    export PATH="$bin_dir:$PATH"

    log_debug "Ambiente configurado para sessão atual"
    log_debug "PATH atualizado com: $bin_dir"
}

# Main installation function
install_mise_release() {
    local bin_dir=$(get_local_bin_dir)
    local mise_bin="$bin_dir/mise"

    log_debug "Obtendo última versão..."
    local mise_version=$(get_latest_mise_version)
    if [ $? -ne 0 ] || [ -z "$mise_version" ]; then
        return 1
    fi

    # Detect OS and architecture
    local os_arch=$(detect_os_and_arch)
    [ $? -ne 0 ] && return 1

    local os_name="${os_arch%:*}"
    local arch="${os_arch#*:}"

    log_info "Instalando Mise $mise_version..."

    # Build release URL
    local download_url="${MISE_RELEASES_BASE_URL:-https://github.com/jdx/mise/releases/download}/${mise_version}/mise-${mise_version}-${os_name}-${arch}.tar.gz"

    # Download release
    local tar_file=$(download_mise_release "$download_url")
    [ $? -ne 0 ] && return 1

    # Extract and setup binary
    extract_and_setup_binary "$tar_file" "$bin_dir"
    [ $? -ne 0 ] && return 1

    # Configure shell
    configure_shell

    # Setup environment for current session
    setup_mise_environment "$bin_dir"
}

install_mise() {
    log_info "Iniciando instalação do Mise..."

    if ! check_existing_installation; then
        exit 0
    fi

    install_mise_release

    # Verify installation
    local shell_config=$(detect_shell_config)

    if command -v mise &> /dev/null; then
        local version=$(get_mise_version)
        log_success "Mise $version instalado com sucesso!"
        mark_installed "mise" "$version"
        log_debug "Executável: $(which mise)"
        echo ""
        echo "Próximos passos:"
        log_output "  1. Reinicie o terminal ou execute: ${LIGHT_CYAN}source $shell_config${NC}"
        log_output "  2. Instale ferramentas: ${LIGHT_CYAN}mise use --global node@20${NC}"
        log_output "  3. Use ${LIGHT_CYAN}susa setup mise --help${NC} para mais informações"
    else
        log_error "Mise foi instalado mas não está disponível no PATH"
        log_info "Tente reiniciar o terminal ou executar: source $shell_config"
        return 1
    fi
}

update_mise() {
    log_info "Atualizando Mise..."

    # Check if Mise is installed
    if ! command -v mise &> /dev/null; then
        log_error "Mise não está instalado. Use 'susa setup mise' para instalar."
        return 1
    fi

    local current_version=$(get_mise_version)
    log_info "Versão atual: $current_version"
    log_debug "Executável: $(which mise)"

    # Get latest version
    log_debug "Obtendo última versão..."
    local mise_version=$(get_latest_mise_version)
    if [ $? -ne 0 ] || [ -z "$mise_version" ]; then
        return 1
    fi
    local latest_version=$(echo "$mise_version" | sed 's/^v//')

    if [ "$current_version" = "$latest_version" ]; then
        log_info "Você já possui a versão mais recente instalada ($current_version)"
        return 0
    fi

    log_info "Atualizando de $current_version para $latest_version..."

    # Detect OS and architecture
    local os_arch=$(detect_os_and_arch)
    [ $? -ne 0 ] && return 1

    local os_name="${os_arch%:*}"
    local arch="${os_arch#*:}"

    local bin_dir=$(get_local_bin_dir)
    local mise_bin="$bin_dir/mise"

    # Build release URL
    local download_url="https://github.com/jdx/mise/releases/download/${mise_version}/mise-${mise_version}-${os_name}-${arch}.tar.gz"

    # Download release
    local tar_file=$(download_mise_release "$download_url")
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Backup current binary
    if [ -f "$mise_bin" ]; then
        log_debug "Fazendo backup do binário atual..."
        cp "$mise_bin" "${mise_bin}.backup"
    fi

    # Extract and setup binary
    extract_and_setup_binary "$tar_file" "$bin_dir"
    if [ $? -ne 0 ]; then
        # Restore backup on failure
        if [ -f "${mise_bin}.backup" ]; then
            mv "${mise_bin}.backup" "$mise_bin"
        fi
        return 1
    fi

    # Remove backup
    rm -f "${mise_bin}.backup"

    # Setup environment for current session
    setup_mise_environment "$bin_dir"

    # Verify update
    if command -v mise &> /dev/null; then
        local new_version=$(get_mise_version)
        log_success "Mise atualizado com sucesso para versão $new_version!"
        update_version "mise" "$new_version"
        log_debug "Atualização concluída"
    else
        log_error "Falha na atualização do Mise"
        return 1
    fi
}

uninstall_mise() {
    local mise_bin="$(get_local_bin_dir)/mise"
    local shell_config=$(detect_shell_config)

    log_info "Desinstalando Mise..."

    # Check if Mise is installed
    if ! command -v mise &> /dev/null; then
        log_warning "Mise não está instalado"
        log_info "Nada a fazer"
        return 0
    fi

    local version=$(get_mise_version)
    log_debug "Versão a ser removida: $version"
    log_debug "Executável: $(which mise)"

    # Confirm uninstallation
    echo ""
    log_output "${YELLOW}Deseja realmente desinstalar o Mise $version? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sS]$ ]]; then
        log_info "Desinstalação cancelada"
        return 1
    fi

    # Remove Mise binary
    if [ -f "$mise_bin" ]; then
        rm -f "$mise_bin"
        log_debug "Binário removido: $mise_bin"
    fi

    # Remove Mise data directory
    local mise_data_dir="$HOME/.local/share/mise"
    if [ -d "$mise_data_dir" ]; then
        log_debug "Removendo diretório de dados: $mise_data_dir"
        rm -rf "$mise_data_dir"
    fi

    local mise_config_dir="${MISE_CONFIG_DIR:-$HOME/.config/mise}"
    if [ -d "$mise_config_dir" ]; then
        log_debug "Removendo diretório de configuração: $mise_config_dir"
        rm -rf "$mise_config_dir"
    fi

    # Remove shell configurations
    if [ -f "$shell_config" ] && is_mise_configured "$shell_config"; then
        local backup_file="${shell_config}.backup.$(date +%Y%m%d%H%M%S)"

        log_debug "Removendo configurações de $shell_config..."

        # Create backup
        cp "$shell_config" "$backup_file"

        # Remove Mise lines
        sed -i.tmp '/# Mise (polyglot version manager)/d' "$shell_config"
        sed -i.tmp '/mise activate/d' "$shell_config"
        rm -f "${shell_config}.tmp"

        log_debug "Configurações removidas (backup: $backup_file)"
    else
        log_debug "Nenhuma configuração encontrada em $shell_config"
    fi

    # Verify removal
    log_debug "Verificando remoção..."

    if ! command -v mise &> /dev/null; then
        log_success "Mise desinstalado com sucesso!"
        mark_uninstalled "mise"
        log_debug "Executável removido"

        echo ""
        log_info "Reinicie o terminal ou execute: source $shell_config"
    else
        log_warning "Mise removido, mas executável ainda encontrado no PATH"
        log_debug "Pode ser necessário remover manualmente de: $(which mise)"
    fi

    # Ask about cache removal
    echo ""
    log_output "${YELLOW}Deseja remover também o cache do Mise? (s/N)${NC}"
    read -r cache_response

    if [[ "$cache_response" =~ ^[sS]$ ]]; then
        log_debug "Removendo cache..."

        local cache_dir="$HOME/.cache/mise"
        if [ -d "$cache_dir" ]; then
            rm -rf "$cache_dir" 2> /dev/null || true
            log_debug "Cache removido: $cache_dir"
        fi

        log_success "Cache removido"
    else
        log_info "Cache mantido em ~/.cache/mise"
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
            install_mise
            ;;
        update)
            update_mise
            ;;
        uninstall)
            uninstall_mise
            ;;
        *)
            log_error "Ação desconhecida: $action"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
