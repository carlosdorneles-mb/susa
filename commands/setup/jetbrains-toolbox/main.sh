#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source installations library
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/shell.sh"

# Constants
TOOLBOX_NAME="JetBrains Toolbox"
TOOLBOX_BIN_NAME="jetbrains-toolbox"
TOOLBOX_GITHUB_REPO="jetbrains/toolbox-app"
TOOLBOX_API_URL="https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release"
TOOLBOX_API_MAX_TIME=10
TOOLBOX_API_CONNECT_TIMEOUT=5
TOOLBOX_LINUX_INSTALL_DIR="$HOME/.local/share/JetBrains/Toolbox"
TOOLBOX_MAC_INSTALL_DIR="$HOME/Library/Application Support/JetBrains/Toolbox"
TOOLBOX_LOCAL_BIN_DIR="$HOME/.local/bin"
LOCAL_BIN_DIR="$HOME/.local/bin"

SKIP_CONFIRM=false
# Help function
show_help() {
    show_description
    echo ""
    show_usage
    echo ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  $TOOLBOX_NAME é um aplicativo que facilita o gerenciamento"
    log_output "  de todas as IDEs da JetBrains (IntelliJ IDEA, PyCharm, WebStorm,"
    log_output "  GoLand, etc.) a partir de uma única interface."
    echo ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o JetBrains Toolbox do sistema"
    log_output "  -y, --yes         Pula confirmação (usar com --uninstall)"
    log_output "  -u, --upgrade     Atualiza o JetBrains Toolbox para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    echo ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup jetbrains-toolbox              # Instala o $TOOLBOX_NAME"
    log_output "  susa setup jetbrains-toolbox --upgrade    # Atualiza o $TOOLBOX_NAME"
    log_output "  susa setup jetbrains-toolbox --uninstall  # Desinstala o $TOOLBOX_NAME"
    echo ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  O JetBrains Toolbox será iniciado automaticamente."
    log_output "  Use-o para instalar e gerenciar suas IDEs JetBrains."
    echo ""
    log_output "${LIGHT_GREEN}Próximos passos:${NC}"
    log_output "  1. Execute o Toolbox a partir do menu de aplicativos"
    log_output "  2. Faça login com sua conta JetBrains"
    echo "  3. Instale as IDEs que desejar"
}

get_latest_version() {
    # Fetches the correct version of JetBrains Toolbox from the API response
    local api_response=$(curl -s --max-time "$TOOLBOX_API_MAX_TIME" --connect-timeout "$TOOLBOX_API_CONNECT_TIMEOUT" "$TOOLBOX_API_URL" 2> /dev/null)

    if [ -z "$api_response" ]; then
        log_error "Não foi possível obter a versão mais recente do JetBrains Toolbox" >&2
        log_error "Verifique sua conexão com a internet e tente novamente" >&2
        return 1
    fi

    # Extract version (e.g., "3.2.0.65851") - using sed for better compatibility
    local latest_version=$(echo "$api_response" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p' | head -1)

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via API JetBrains: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    # If it fails, notify the user
    log_error "Não foi possível obter a versão mais recente do JetBrains Toolbox" >&2
    log_error "Verifique sua conexão com a internet e tente novamente" >&2
    return 1
}

# Get current installed version
get_current_version() {
    local install_dir=$(get_install_dir)
    local version_file="$install_dir/.version"

    if [ -f "$version_file" ]; then
        cat "$version_file"
    else
        echo "desconhecida"
    fi
}

# Check if JetBrains Toolbox is installed
check_installation() {
    command -v jetbrains-toolbox &> /dev/null || [ -f "$HOME/.local/bin/jetbrains-toolbox" ]
}

# Get download URL from API based on OS and architecture
get_download_url() {
    local os_arch="$1"
    local os_name="${os_arch%:*}"
    local arch="${os_arch#*:}"

    local api_response=$(curl -s --max-time "$TOOLBOX_API_MAX_TIME" --connect-timeout "$TOOLBOX_API_CONNECT_TIMEOUT" "$TOOLBOX_API_URL" 2> /dev/null)

    if [ -z "$api_response" ]; then
        log_error "Não foi possível obter informações de download" >&2
        return 1
    fi

    local download_key
    if [ "$os_name" = "linux" ]; then
        if [ "$arch" = "arm64" ]; then
            download_key="linuxARM64"
        else
            download_key="linux"
        fi
    elif [ "$os_name" = "mac" ]; then
        if [ "$arch" = "arm64" ]; then
            download_key="macM1"
        else
            download_key="mac"
        fi
    else
        log_error "Sistema operacional não suportado" >&2
        return 1
    fi

    local download_url=$(echo "$api_response" | sed -n "s/.*\"$download_key\":{[^}]*\"link\":\"\\([^\"]*\\)\".*/\\1/p")

    if [ -n "$download_url" ]; then
        log_debug "URL de download: $download_url" >&2
        echo "$download_url"
        return 0
    fi

    log_error "Não foi possível obter URL de download para $os_name $arch" >&2
    return 1
}

# Detect OS and architecture
detect_os_and_arch() {
    local os_name
    if is_mac; then
        os_name="mac"
    elif is_linux; then
        os_name="linux"
    else
        log_error "Sistema operacional não suportado: $(uname -s)"
        return 1
    fi

    local arch=$(uname -m)

    case "$arch" in
        x86_64) arch="x64" ;;
        aarch64 | arm64) arch="arm64" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    echo "${os_name}:${arch}"
}

# Get installation directory based on OS
get_install_dir() {
    if is_mac; then
        echo "$HOME/Library/Application Support/JetBrains/Toolbox"
    else
        echo "$HOME/.local/share/JetBrains/Toolbox"
    fi
}

# Get binary location
get_binary_location() {
    if is_mac; then
        echo "/Applications/JetBrains Toolbox.app"
    else
        echo "$LOCAL_BIN_DIR/jetbrains-toolbox"
    fi
}

# Install Toolbox on Linux
install_toolbox_linux() {
    local version="$1"
    local os_arch="$2"

    local arch="${os_arch#*:}"
    local download_url=$(get_download_url "$os_arch")

    if [ -z "$download_url" ]; then
        log_error "Falha ao obter URL de download"
        return 1
    fi

    local temp_dir="/tmp/jetbrains-toolbox-$$"
    local install_dir=$(get_install_dir)
    local bin_dir="$LOCAL_BIN_DIR"

    # Create temp directory
    mkdir -p "$temp_dir"

    # Download
    log_info "Baixando JetBrains Toolbox..."
    if ! curl -L --progress-bar \
        --connect-timeout 30 \
        --max-time 300 \
        --retry 3 \
        --retry-delay 2 \
        "$download_url" -o "$temp_dir/toolbox.tar.gz"; then
        log_error "Falha ao baixar JetBrains Toolbox"
        rm -rf "$temp_dir"
        return 1
    fi

    # Extract
    log_info "Extraindo JetBrains Toolbox..."
    if ! tar -xzf "$temp_dir/toolbox.tar.gz" -C "$temp_dir" 2> /dev/null; then
        log_error "Falha ao extrair JetBrains Toolbox"
        rm -rf "$temp_dir"
        return 1
    fi

    # Find the extracted directory (it has a timestamp in the name)
    local extracted_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "jetbrains-toolbox-*" | head -1)

    if [ -z "$extracted_dir" ]; then
        log_error "Diretório extraído não encontrado"
        rm -rf "$temp_dir"
        return 1
    fi

    # Create installation directory
    mkdir -p "$install_dir/bin"
    mkdir -p "$bin_dir"

    # Copy all contents to installation directory
    log_info "Copiando arquivos para $install_dir..."
    cp -r "$extracted_dir"/* "$install_dir/"

    # Find the binary in the installation directory
    local toolbox_binary=$(find "$install_dir" -type f -name "jetbrains-toolbox" | head -1)

    if [ -z "$toolbox_binary" ]; then
        log_error "Binário do JetBrains Toolbox não encontrado"
        rm -rf "$temp_dir"
        return 1
    fi

    log_debug "Binário encontrado: $toolbox_binary"
    chmod +x "$toolbox_binary"

    # Create symlink in ~/.local/bin
    ln -sf "$toolbox_binary" "$bin_dir/jetbrains-toolbox"
    log_debug "Link simbólico criado: $bin_dir/jetbrains-toolbox -> $toolbox_binary"

    # Save version
    echo "$version" > "$install_dir/.version"

    # Clean up
    rm -rf "$temp_dir"

    # Configure PATH if needed
    local shell_config=$(detect_shell_config)
    local local_bin="$LOCAL_BIN_DIR"
    if ! grep -q ".local/bin" "$shell_config" 2> /dev/null; then
        echo "" >> "$shell_config"
        echo "# Local binaries PATH" >> "$shell_config"
        echo "export PATH=\"$local_bin:\$PATH\"" >> "$shell_config"
        log_debug "PATH configurado em $shell_config"
    fi

    # Update current session PATH
    export PATH="$local_bin:$PATH"

    # Create desktop entry
    create_desktop_entry

    log_info "Iniciando JetBrains Toolbox..."
    nohup "$bin_dir/jetbrains-toolbox" > /dev/null 2>&1 &

    return 0
}

# Install Toolbox on macOS
install_toolbox_macos() {
    local version="$1"
    local os_arch="$2"

    local download_url=$(get_download_url "$os_arch")

    if [ -z "$download_url" ]; then
        log_error "Falha ao obter URL de download"
        return 1
    fi

    local temp_dir="/tmp/jetbrains-toolbox-$$"
    local install_dir=$(get_install_dir)

    # Create temp directory
    mkdir -p "$temp_dir"

    # Download
    log_info "Baixando JetBrains Toolbox..."
    if ! curl -L --progress-bar \
        --connect-timeout 30 \
        --max-time 300 \
        --retry 3 \
        --retry-delay 2 \
        "$download_url" -o "$temp_dir/toolbox.dmg"; then
        log_error "Falha ao baixar JetBrains Toolbox"
        rm -rf "$temp_dir"
        return 1
    fi

    # Mount DMG
    log_info "Montando imagem DMG..."
    local mount_point="/Volumes/JetBrains Toolbox"
    if ! hdiutil attach "$temp_dir/toolbox.dmg" -quiet; then
        log_error "Falha ao montar DMG"
        rm -rf "$temp_dir"
        return 1
    fi

    # Copy app to Applications
    log_info "Copiando para Applications..."
    if [ -d "$mount_point/JetBrains Toolbox.app" ]; then
        cp -R "$mount_point/JetBrains Toolbox.app" /Applications/
    else
        log_error "Aplicativo não encontrado no DMG"
        hdiutil detach "$mount_point" -quiet 2> /dev/null
        rm -rf "$temp_dir"
        return 1
    fi

    # Unmount DMG
    log_debug "Desmontando DMG..."
    hdiutil detach "$mount_point" -quiet 2> /dev/null || true

    # Save version
    mkdir -p "$install_dir"
    echo "$version" > "$install_dir/.version"

    # Clean up
    rm -rf "$temp_dir"

    log_info "Iniciando JetBrains Toolbox..."
    open -a "JetBrains Toolbox"

    return 0
}

# Create desktop entry for Linux
create_desktop_entry() {
    local desktop_file="$HOME/.local/share/applications/jetbrains-toolbox.desktop"
    local icon_path="$HOME/.local/share/JetBrains/Toolbox/toolbox.svg"

    mkdir -p "$(dirname "$desktop_file")"
    mkdir -p "$(dirname "$icon_path")"

    # Download icon if not exists
    if [ ! -f "$icon_path" ]; then
        curl -s -o "$icon_path" "https://resources.jetbrains.com/storage/products/toolbox/img/meta/toolbox_logo_300x300.png" 2> /dev/null || log_debug "Falha ao baixar ícone"
    fi

    local toolbox_bin="$LOCAL_BIN_DIR/jetbrains-toolbox"
    cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=JetBrains Toolbox
Icon=$icon_path
Exec=$toolbox_bin
Comment=JetBrains IDEs Manager
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-toolbox
StartupNotify=false
EOF

    chmod +x "$desktop_file"
    log_debug "Atalho criado: $desktop_file"
}

# Main installation function
install_toolbox() {
    if check_installation; then
        log_info "JetBrains Toolbox $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do JetBrains Toolbox..."

    # Get latest version
    local toolbox_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$toolbox_version" ]; then
        return 1
    fi

    # Detect OS and architecture
    local os_arch=$(detect_os_and_arch)
    if [ $? -ne 0 ]; then
        return 1
    fi

    local os_name="${os_arch%:*}"

    log_info "Instalando JetBrains Toolbox $toolbox_version..."

    # Install based on OS
    case "$os_name" in
        linux)
            install_toolbox_linux "$toolbox_version" "$os_arch"
            ;;
        mac)
            install_toolbox_macos "$toolbox_version" "$os_arch"
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        log_success "JetBrains Toolbox $toolbox_version instalado com sucesso!"
        register_or_update_software_in_lock "$COMMAND_NAME" "$toolbox_version"
        log_debug "Instalação concluída"

        echo ""
        echo "Próximos passos:"
        log_output "  1. O JetBrains Toolbox foi iniciado automaticamente"
        log_output "  2. Faça login com sua conta JetBrains"
        log_output "  3. Instale as IDEs que desejar através do Toolbox"
        log_output "  4. Use ${LIGHT_CYAN}susa setup jetbrains-toolbox --help${NC} para mais informações"
    else
        log_error "Falha na instalação do JetBrains Toolbox"
        return $install_result
    fi
}

# Update Toolbox
update_toolbox() {
    log_info "Atualizando JetBrains Toolbox..."

    # Check if installed
    if ! check_installation; then
        log_error "JetBrains Toolbox não está instalado. Use 'susa setup jetbrains-toolbox' para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"
    if is_mac; then
        log_debug "Localização: /Applications/JetBrains Toolbox.app"
    else
        log_debug "Localização: $LOCAL_BIN_DIR/jetbrains-toolbox"
    fi

    # Get latest version
    local latest_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$latest_version" ]; then
        return 1
    fi

    if [ "$current_version" = "$latest_version" ]; then
        log_info "Você já possui a versão mais recente instalada ($current_version)"
        return 0
    fi

    log_info "Atualizando de $current_version para $latest_version..."

    # Detect OS
    local os_arch=$(detect_os_and_arch)
    if [ $? -ne 0 ]; then
        return 1
    fi

    local os_name="${os_arch%:*}"

    # Stop Toolbox if running
    # Note about stopping Toolbox
    log_info "Nota: Feche o JetBrains Toolbox se estiver em execução antes de continuar."
    sleep 5

    # Remove old installation
    if [ "$os_name" = "mac" ]; then
        local binary_location="/Applications/JetBrains Toolbox.app"
        rm -rf "$binary_location"
    else
        local binary_location="$LOCAL_BIN_DIR/jetbrains-toolbox"
        rm -f "$binary_location"
    fi

    # Install new version
    case "$os_name" in
        linux)
            install_toolbox_linux "$latest_version" "$os_arch"
            ;;
        mac)
            install_toolbox_macos "$latest_version" "$os_arch"
            ;;
    esac

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        log_success "JetBrains Toolbox atualizado com sucesso para versão $latest_version!"
        register_or_update_software_in_lock "$COMMAND_NAME" "$latest_version"
        log_debug "Atualização concluída"
    else
        log_error "Falha na atualização do JetBrains Toolbox"
        return $install_result
    fi
}

# Uninstall Toolbox
uninstall_toolbox() {
    log_info "Desinstalando JetBrains Toolbox..."

    # Check if installed
    if ! check_installation; then
        log_info "JetBrains Toolbox não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)
    log_debug "Versão a ser removida: $current_version"
    if is_mac; then
        log_debug "Localização: /Applications/JetBrains Toolbox.app"
    else
        log_debug "Localização: $LOCAL_BIN_DIR/jetbrains-toolbox"
    fi

    echo ""
    if [ "$SKIP_CONFIRM" = false ]; then
        log_output "${YELLOW}Deseja realmente desinstalar o JetBrains Toolbox $current_version? (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi

    # Stop Toolbox if running
    log_debug "Encerrando JetBrains Toolbox..."
    if is_mac; then
        osascript -e 'quit app "JetBrains Toolbox"' 2> /dev/null || true
    else
        # Kill only the jetbrains-toolbox binary, not this script
        pkill -9 -f "^$LOCAL_BIN_DIR/jetbrains-toolbox" 2> /dev/null || true
    fi

    # Remove binary/app
    if is_mac; then
        local binary_location="/Applications/JetBrains Toolbox.app"
        if [ -d "$binary_location" ]; then
            rm -rf "$binary_location"
            log_debug "Aplicativo removido: $binary_location"
        fi
    else
        local binary_location="$LOCAL_BIN_DIR/jetbrains-toolbox"
        if [ -f "$binary_location" ]; then
            rm -f "$binary_location"
            log_debug "Binário removido: $binary_location"
        fi

        # Remove desktop entry
        local desktop_file="$HOME/.local/share/applications/jetbrains-toolbox.desktop"
        if [ -f "$desktop_file" ]; then
            rm -f "$desktop_file"
            log_debug "Atalho removido: $desktop_file"
        fi
    fi

    # Remove installation directory with version file
    local install_dir
    if is_mac; then
        install_dir="$TOOLBOX_MAC_INSTALL_DIR"
    else
        install_dir="$TOOLBOX_LINUX_INSTALL_DIR"
    fi

    if [ -d "$install_dir" ]; then
        rm -rf "$install_dir"
    fi

    # Verify removal
    if ! check_installation; then
        log_success "JetBrains Toolbox desinstalado com sucesso!"
        remove_software_in_lock "$COMMAND_NAME"
    else
        log_error "Falha ao desinstalar JetBrains Toolbox completamente"
        return 1
    fi

    # Ask about removing IDEs installed by Toolbox
    if [ "$SKIP_CONFIRM" = false ]; then
        echo ""
        log_output "${YELLOW}Deseja remover também as IDEs instaladas pelo Toolbox (IntelliJ, PyCharm, etc)? (s/N)${NC}"
        read -r ides_response

        if [[ "$ides_response" =~ ^[sSyY]$ ]]; then
            log_info "Removendo IDEs instaladas..."

            if is_mac; then
                # Remove IDEs directory
                rm -rf "$HOME/Library/Application Support/JetBrains/Toolbox" 2> /dev/null || true
                log_debug "IDEs removidas: ~/Library/Application Support/JetBrains/Toolbox"

                # Remove logs
                rm -rf "$HOME/Library/Logs/JetBrains" 2> /dev/null || true
                log_debug "Logs removidos: ~/Library/Logs/JetBrains"
            else
                # Remove IDEs directory (apps, channels, etc)
                rm -rf "$HOME/.local/share/JetBrains/Toolbox" 2> /dev/null || true
                log_debug "IDEs removidas: ~/.local/share/JetBrains/Toolbox"

                # Remove cache
                rm -rf "$HOME/.cache/JetBrains/Toolbox" 2> /dev/null || true
                log_debug "Cache removido: ~/.cache/JetBrains/Toolbox"

                # Remove logs
                rm -rf "$HOME/.local/share/JetBrains/Toolbox/logs" 2> /dev/null || true
                log_debug "Logs removidos"
            fi

            log_success "IDEs instaladas removidas"
        else
            log_info "IDEs mantidas"
        fi
    else
        # Auto-remove when --yes is used
        log_info "Removendo IDEs instaladas automaticamente..."

        if is_mac; then
            rm -rf "$HOME/Library/Application Support/JetBrains/Toolbox" 2> /dev/null || true
            log_debug "IDEs removidas: ~/Library/Application Support/JetBrains/Toolbox"
            rm -rf "$HOME/Library/Logs/JetBrains" 2> /dev/null || true
            log_debug "Logs removidos: ~/Library/Logs/JetBrains"
        else
            rm -rf "$HOME/.local/share/JetBrains/Toolbox" 2> /dev/null || true
            log_debug "IDEs removidas: ~/.local/share/JetBrains/Toolbox"
            rm -rf "$HOME/.cache/JetBrains/Toolbox" 2> /dev/null || true
            log_debug "Cache removido: ~/.cache/JetBrains/Toolbox"
        fi

        log_info "IDEs instaladas removidas automaticamente"
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
                show_software_info "$TOOLBOX_BIN_NAME"
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
            install_toolbox
            ;;
        update)
            update_toolbox
            ;;
        uninstall)
            uninstall_toolbox
            ;;
        *)
            log_error "Ação desconhecida: $action"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
