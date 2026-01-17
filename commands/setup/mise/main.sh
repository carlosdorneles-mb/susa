#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/shell.sh"

# Constants
REPO_SLUG="jdx/mise"
MISCACHE_DIR="$HOME/.cache/mise"
MISE_DATA_DIR="$HOME/.local/share/mise"
MISE_BIN_NAME="mise"
MISE_CONFIG_COMMENT="# Mise (polyglot version manager)"
MISE_ACTIVATE_PATTERN="mise activate"
MISE_TAR_PATTERN="mise-v{version}-{os}-{arch}.tar.gz"
MISE_CHECKSUM_FILE="SHASUMS256.txt"
LOCAL_BIN_DIR="$HOME/.local/bin"
MISE_CONFIG_DIR="$HOME/.config/mise"

SKIP_CONFIRM=false
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
    log_output "  -y, --yes         Pula confirmação (usar com --uninstall)"
    log_output "  -u, --upgrade     Atualiza o Mise para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    echo ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup mise              # Instala o Mise"
    log_output "  susa setup mise --upgrade    # Atualiza o Mise"
    log_output "  susa setup mise --uninstall  # Desinstala o Mise"
    echo ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Após a instalação, reinicie o terminal ou execute:"
    echo "    source ~/.bashrc   (para Bash)"
    echo "    source ~/.zshrc    (para Zsh)"
    echo ""
    log_output "${LIGHT_GREEN}Próximos passos:${NC}"
    log_output "  mise use --global node@20    	# Instalar e usar Node.js 20"
    log_output "  mise use --global python@3.12 # Instalar e usar Python 3.12"
    log_output "  mise use --global go@latest   # Instalar e usar Go (latest)"
    log_output "  mise list                    	# Listar ferramentas instaladas"
    log_output "  mise install                  # Instalar ferramentas do .mise.toml"
}

# Get latest Mise version from GitHub
get_latest_version() {
    github_get_latest_version "$REPO_SLUG"
}

# Get installed Mise version
get_current_version() {
    if check_installation; then
        $MISE_BIN_NAME --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if Mise is installed
check_installation() {
    command -v $MISE_BIN_NAME &> /dev/null
}

# Detect operating system and architecture
detect_os_and_arch() {
    github_detect_os_arch "standard"
}

# Check if Mise is already configured in shell
is_mise_configured() {
    local shell_config="$1"
    grep -q "$MISE_ACTIVATE_PATTERN" "$shell_config" 2> /dev/null
}

# Add Mise configuration to shell
add_mise_to_shell() {
    local shell_config="$1"
    local shell_type="bash"
    if [[ "$shell_config" == *"zshrc"* ]]; then
        shell_type="zsh"
    fi
    echo "" >> "$shell_config"
    echo "$MISE_CONFIG_COMMENT" >> "$shell_config"
    echo "export PATH=\"$LOCAL_BIN_DIR:\$PATH\"" >> "$shell_config"
    echo "eval \"\$($MISE_BIN_NAME activate $shell_type)\"" >> "$shell_config"
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

# Download and verify Mise release
download_and_verify_mise() {
    local version="$1"
    local os_name="$2"
    local arch="$3"
    local output_file="/tmp/${MISE_BIN_NAME}-${version}.tar.gz"
    local download_url=$(github_build_download_url "$REPO_SLUG" "$version" "$os_name" "$arch" "$MISE_TAR_PATTERN")

    log_info "Baixando e verificando Mise..." >&2
    log_debug "URL: $download_url" >&2

    # Download with checksum verification (SHA256)
    if ! github_download_and_verify "$REPO_SLUG" "$version" "$download_url" "$output_file" "$MISE_CHECKSUM_FILE" "sha256"; then
        log_error "Falha ao baixar ou verificar Mise" >&2
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
    local mise_binary=$(find "$temp_dir" -type f -name "$MISE_BIN_NAME" | head -1)
    if [ -z "$mise_binary" ]; then
        log_error "Binário do Mise não encontrado no arquivo"
        rm -rf "$temp_dir"
        return 1
    fi
    log_debug "Binário encontrado: $mise_binary"
    local mise_bin="$LOCAL_BIN_DIR/$MISE_BIN_NAME"
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
    local bin_dir="$LOCAL_BIN_DIR"
    local mise_bin="$bin_dir/$MISE_BIN_NAME"
    local mise_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$mise_version" ]; then
        return 1
    fi
    # Detect OS and architecture
    local os_arch=$(detect_os_and_arch)
    [ $? -ne 0 ] && return 1
    local os_name="${os_arch%:*}"
    local arch="${os_arch#*:}"
    log_info "Instalando Mise $mise_version..."
    # Download and verify release
    local tar_file=$(download_and_verify_mise "$mise_version" "$os_name" "$arch")
    if [ $? -ne 0 ] || [ -z "$tar_file" ]; then
        log_error "Não foi possível baixar o Mise. Tente novamente mais tarde."
        return 1
    fi
    # Extract and setup binary
    extract_and_setup_binary "$tar_file" "$bin_dir"
    [ $? -ne 0 ] && return 1
    # Configure shell
    configure_shell
    # Setup environment for current session
    setup_mise_environment "$bin_dir"
}

install_mise() {
    if check_installation; then
        log_info "Mise $(get_current_version) já está instalado."
        exit 0
    fi
    log_info "Iniciando instalação do Mise..."
    install_mise_release
    # Verify installation
    local shell_config=$(detect_shell_config)
    if check_installation; then
        local version=$(get_current_version)
        log_success "Mise $version instalado com sucesso!"
        register_or_update_software_in_lock "$COMMAND_NAME" "$version"
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
    if ! command -v $MISE_BIN_NAME &> /dev/null; then
        log_error "Mise não está instalado. Use 'susa setup mise' para instalar."
        return 1
    fi
    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"
    # Update using Mise's built-in self-update command
    log_info "Executando atualização do Mise..."
    if $MISE_BIN_NAME self-update --yes 2>&1 | while read -r line; do log_debug "mise: $line"; done; then
        log_debug "Comando de atualização executado com sucesso"
    else
        log_error "Falha ao atualizar o Mise"
        return 1
    fi
    # Verify update
    if check_installation; then
        local new_version=$(get_current_version)
        if [ "$current_version" = "$new_version" ]; then
            log_info "Mise já está na versão mais recente ($current_version)"
        else
            log_success "Mise atualizado de $current_version para $new_version!"
            register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"
            log_debug "Atualização concluída com sucesso"
        fi
        return 0
    else
        log_error "Falha na atualização do Mise"
        return 1
    fi
}

uninstall_mise() {
    local mise_bin="$LOCAL_BIN_DIR/$MISE_BIN_NAME"
    local shell_config=$(detect_shell_config)
    log_info "Desinstalando Mise..."

    # Check if Mise is installed
    if ! check_installation; then
        log_warning "Mise não está instalado"
        log_info "Nada a fazer"
        return 0
    fi
    local version=$(get_current_version)
    log_debug "Versão a ser removida: $version"

    # Confirm uninstallation
    if [ "$SKIP_CONFIRM" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja realmente desinstalar o Mise $version? (s/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    # Remove Mise binary
    if [ -f "$mise_bin" ]; then
        rm -f "$mise_bin"
        log_debug "Binário removido: $mise_bin"
    fi

    # Ask about removing managed tools (Node, Python, etc)
    if [ "$SKIP_CONFIRM" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja remover também as ferramentas gerenciadas pelo Mise (Node, Python, Go, etc)? (s/N)${NC}"
        read -r tools_response

        if [[ "$tools_response" =~ ^[sSyY]$ ]]; then
            if [ -d "$MISE_DATA_DIR" ]; then
                rm -rf "$MISE_DATA_DIR"
                log_debug "Ferramentas removidas: $MISE_DATA_DIR"
            fi
            log_success "Ferramentas gerenciadas removidas"
        else
            log_info "Ferramentas mantidas em $MISE_DATA_DIR"
        fi
    else
        # Auto-remove when --yes is used
        if [ -d "$MISE_DATA_DIR" ]; then
            rm -rf "$MISE_DATA_DIR"
            log_debug "Ferramentas removidas: $MISE_DATA_DIR"
        fi
        log_info "Ferramentas gerenciadas removidas automaticamente"
    fi

    # Remove Mise config directory
    local mise_config_dir="$MISE_CONFIG_DIR"
    if [ -d "$mise_config_dir" ]; then
        rm -rf "$mise_config_dir"
        log_debug "Configurações removidas: $mise_config_dir"
    fi

    # Remove shell configurations
    if [ -f "$shell_config" ] && is_mise_configured "$shell_config"; then
        local backup_file="${shell_config}.backup.$(date +%Y%m%d%H%M%S)"
        # Create backup
        cp "$shell_config" "$backup_file"
        # Remove Mise lines
        sed -i.tmp "/$MISE_CONFIG_COMMENT/d" "$shell_config"
        sed -i.tmp "/$MISE_ACTIVATE_PATTERN/d" "$shell_config"
        rm -f "${shell_config}.tmp"
        log_debug "Configurações removidas (backup: $backup_file)"
    else
        log_debug "Nenhuma configuração encontrada em $shell_config"
    fi

    # Verify removal
    if ! check_installation; then
        log_success "Mise desinstalado com sucesso!"
        remove_software_in_lock "$COMMAND_NAME"
        echo ""
        log_info "Reinicie o terminal ou execute: source $shell_config"
    else
        log_warning "Mise removido, mas executável ainda encontrado no PATH"
        log_debug "Pode ser necessário remover manualmente de: $(which $MISE_BIN_NAME)"
    fi

    # Ask about cache removal
    if [ "$SKIP_CONFIRM" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja remover também o cache do Mise? (s/N)${NC}"
        read -r cache_response

        if [[ "$cache_response" =~ ^[sSyY]$ ]]; then
            if [ -d "$MISCACHE_DIR" ]; then
                rm -rf "$MISCACHE_DIR" 2> /dev/null || true
                log_debug "Cache removido: $MISCACHE_DIR"
            fi
            log_success "Cache removido"
        else
            log_info "Cache mantido em $MISCACHE_DIR"
        fi
    else
        # Auto-remove cache when --yes is used
        if [ -d "$MISCACHE_DIR" ]; then
            rm -rf "$MISCACHE_DIR" 2> /dev/null || true
            log_debug "Cache removido: $MISCACHE_DIR"
        fi
        log_info "Cache removido automaticamente"
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
                ;;
            -q | --quiet)
                export SILENT=true
                ;;
            --info)
                show_software_info "$MISE_BIN_NAME"
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
