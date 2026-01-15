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
    log_output "  JetBrains Toolbox é um aplicativo que facilita o gerenciamento"
    log_output "  de todas as IDEs da JetBrains (IntelliJ IDEA, PyCharm, WebStorm,"
    log_output "  GoLand, etc.) a partir de uma única interface."
    echo ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o JetBrains Toolbox do sistema"
    log_output "  --update          Atualiza o JetBrains Toolbox para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    echo ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup jetbrains-toolbox              # Instala o JetBrains Toolbox"
    log_output "  susa setup jetbrains-toolbox --update     # Atualiza o JetBrains Toolbox"
    log_output "  susa setup jetbrains-toolbox --uninstall  # Desinstala o JetBrains Toolbox"
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

get_latest_toolbox_version() {
    # Try to get the latest version from JetBrains data service
    local latest_version=$(curl -s --max-time ${TOOLBOX_API_MAX_TIME:-10} --connect-timeout ${TOOLBOX_API_CONNECT_TIMEOUT:-5} ${TOOLBOX_API_URL:-https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release} 2>/dev/null | grep -oP '"build"\s*:\s*"\K[^"]+' | head -1)

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via API JetBrains: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    # If it fails, notify user
    log_error "Não foi possível obter a versão mais recente do JetBrains Toolbox" >&2
    log_error "Verifique sua conexão com a internet e tente novamente" >&2
    return 1
}

# Detect OS and architecture
detect_os_and_arch() {
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)

    case "$os_name" in
        linux) os_name="linux" ;;
        darwin) os_name="mac" ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    case "$arch" in
        x86_64) arch="x64" ;;
        aarch64 | arm64) arch="arm64" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    log_output "${os_name}:${arch}"
}

# Get installation directory based on OS
get_install_dir() {
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        linux)
            echo "$HOME/.local/share/JetBrains/Toolbox"
            ;;
        darwin)
            log_output "$HOME/Library/Application Support/JetBrains/Toolbox"
            ;;
    esac
}

# Get binary location
get_binary_location() {
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        linux)
            echo "$(get_local_bin_dir)/jetbrains-toolbox"
            ;;
        darwin)
            echo "/Applications/JetBrains Toolbox.app"
            ;;
    esac
}

# Get local bin directory
get_local_bin_dir() {
    echo "$HOME/.local/bin"
}

# Check if Toolbox is installed
check_toolbox_installed() {
    local binary_location=$(get_binary_location)
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    if [ "$os_name" = "darwin" ]; then
        [ -d "$binary_location" ] && return 0
    else
        [ -f "$binary_location" ] && return 0
    fi

    return 1
}

# Get current installed version
get_installed_version() {
    local install_dir=$(get_install_dir)
    local version_file="$install_dir/.version"

    if [ -f "$version_file" ]; then
        cat "$version_file"
    else
        echo "desconhecida"
    fi
}

# Check if JetBrains Toolbox is already installed
check_existing_installation() {
    log_debug "Verificando instalação existente do JetBrains Toolbox..."

    if ! check_toolbox_installed; then
        log_debug "JetBrains Toolbox não está instalado"
        return 0
    fi

    local current_version=$(get_installed_version)
    log_info "JetBrains Toolbox $current_version já está instalado."

    # Mark as installed in lock file
    mark_installed "toolbox" "$current_version"

    # Check for updates
    log_debug "Obtendo última versão..."
    local latest_version=$(get_latest_toolbox_version)
    if [ $? -eq 0 ] && [ -n "$latest_version" ]; then
        if [ "$current_version" != "$latest_version" ] && [ "$current_version" != "desconhecida" ]; then
            echo ""
            log_output "${YELLOW}Nova versão disponível ($latest_version).${NC}"
            log_output "Para atualizar, execute: ${LIGHT_CYAN}susa setup jetbrains-toolbox --update${NC}"
        fi
    else
        log_warning "Não foi possível verificar atualizações"
    fi

    return 1
}

# Install Toolbox on Linux
install_toolbox_linux() {
    local version="$1"
    local os_arch="$2"

    if ! check_existing_installation; then
        exit 0
    fi

    log_info "Instalando JetBrains Toolbox $version no Linux..."

    local arch="${os_arch#*:}"
    local download_url="https://download.jetbrains.com/toolbox/jetbrains-toolbox-${version}.tar.gz"
    local temp_dir="/tmp/jetbrains-toolbox-$$"
    local install_dir=$(get_install_dir)
    local bin_dir=$(get_local_bin_dir)

    log_debug "URL: $download_url"

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
    if ! tar -xzf "$temp_dir/toolbox.tar.gz" -C "$temp_dir" 2>/dev/null; then
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

    log_debug "Diretório extraído: $extracted_dir"

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
    echo "$version" >"$install_dir/.version"

    # Clean up
    rm -rf "$temp_dir"

    # Configure PATH if needed
    local shell_config=$(detect_shell_config)
    local local_bin=$(get_local_bin_dir)
    if ! grep -q ".local/bin" "$shell_config" 2>/dev/null; then
        echo "" >>"$shell_config"
        echo "# Local binaries PATH" >>"$shell_config"
        echo "export PATH=\"$local_bin:\$PATH\"" >>"$shell_config"
        log_debug "PATH configurado em $shell_config"
    fi

    # Update current session PATH
    export PATH="$local_bin:$PATH"

    # Create desktop entry
    create_desktop_entry

    log_info "Iniciando JetBrains Toolbox..."
    nohup "$bin_dir/jetbrains-toolbox" >/dev/null 2>&1 &

    return 0
}

# Install Toolbox on macOS
install_toolbox_macos() {
    local version="$1"

    log_info "Instalando JetBrains Toolbox $version no macOS..."

    local download_url="https://download.jetbrains.com/toolbox/jetbrains-toolbox-${version}.dmg"
    local temp_dir="/tmp/jetbrains-toolbox-$$"
    local install_dir=$(get_install_dir)

    log_debug "URL: $download_url"

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
        hdiutil detach "$mount_point" -quiet 2>/dev/null
        rm -rf "$temp_dir"
        return 1
    fi

    # Unmount DMG
    log_debug "Desmontando DMG..."
    hdiutil detach "$mount_point" -quiet 2>/dev/null || true

    # Save version
    mkdir -p "$install_dir"
    echo "$version" >"$install_dir/.version"

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

    log_debug "Criando atalho desktop..."

    mkdir -p "$(dirname "$desktop_file")"
    mkdir -p "$(dirname "$icon_path")"

    # Download icon if not exists
    if [ ! -f "$icon_path" ]; then
        curl -s -o "$icon_path" "https://resources.jetbrains.com/storage/products/toolbox/img/meta/toolbox_logo_300x300.png" 2>/dev/null || log_debug "Falha ao baixar ícone"
    fi

    local toolbox_bin=$(get_local_bin_dir)/jetbrains-toolbox
    cat >"$desktop_file" <<EOF
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
    log_info "Iniciando instalação do JetBrains Toolbox..."

    # Get latest version
    log_debug "Obtendo última versão..."
    local toolbox_version=$(get_latest_toolbox_version)
    if [ $? -ne 0 ] || [ -z "$toolbox_version" ]; then
        return 1
    fi

    # Detect OS and architecture
    log_debug "Detectando SO e arquitetura..."
    local os_arch=$(detect_os_and_arch)
    if [ $? -ne 0 ]; then
        return 1
    fi

    local os_name="${os_arch%:*}"
    log_debug "SO: $os_name | Arquitetura: ${os_arch#*:}"

    log_info "Instalando JetBrains Toolbox $toolbox_version..."

    # Install based on OS
    case "$os_name" in
        linux)
            install_toolbox_linux "$toolbox_version" "$os_arch"
            ;;
        mac)
            install_toolbox_macos "$toolbox_version"
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        log_success "JetBrains Toolbox $toolbox_version instalado com sucesso!"
        mark_installed "toolbox" "$toolbox_version"
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
    if ! check_toolbox_installed; then
        log_error "JetBrains Toolbox não está instalado. Use 'susa setup jetbrains-toolbox' para instalar."
        return 1
    fi

    local current_version=$(get_installed_version)
    log_info "Versão atual: $current_version"
    log_debug "Localização: $(get_binary_location)"

    # Get latest version
    log_debug "Obtendo última versão..."
    local latest_version=$(get_latest_toolbox_version)
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
    log_debug "Removendo versão anterior..."
    local binary_location=$(get_binary_location)

    if [ "$os_name" = "mac" ]; then
        rm -rf "$binary_location"
    else
        rm -f "$binary_location"
    fi

    # Install new version
    case "$os_name" in
        linux)
            install_toolbox_linux "$latest_version" "$os_arch"
            ;;
        mac)
            install_toolbox_macos "$latest_version"
            ;;
    esac

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        log_success "JetBrains Toolbox atualizado com sucesso para versão $latest_version!"
        update_version "toolbox" "$latest_version"
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
    if ! check_toolbox_installed; then
        log_info "JetBrains Toolbox não está instalado"
        return 0
    fi

    local current_version=$(get_installed_version)
    log_debug "Versão a ser removida: $current_version"
    log_debug "Localização: $(get_binary_location)"

    echo ""
    log_output "${YELLOW}Deseja realmente desinstalar o JetBrains Toolbox $current_version? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sS]$ ]]; then
        log_info "Desinstalação cancelada"
        return 0
    fi

    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    # Stop Toolbox if running
    log_debug "Encerrando JetBrains Toolbox..."
    if [ "$os_name" = "darwin" ]; then
        osascript -e 'quit app "JetBrains Toolbox"' 2>/dev/null || true
    else
        pkill -9 -f jetbrains-toolbox 2>/dev/null || true
    fi

    # Remove binary/app
    local binary_location=$(get_binary_location)
    if [ "$os_name" = "darwin" ]; then
        if [ -d "$binary_location" ]; then
            rm -rf "$binary_location"
            log_debug "Aplicativo removido: $binary_location"
        fi
    else
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
    local install_dir=$(get_install_dir)
    if [ -d "$install_dir" ]; then
        rm -rf "$install_dir"
        log_debug "Diretório de instalação removido: $install_dir"
    fi

    # Verify removal
    if ! check_toolbox_installed; then
        log_success "JetBrains Toolbox desinstalado com sucesso!"
        mark_uninstalled "toolbox"
        log_debug "Remoção verificada"
    else
        log_error "Falha ao desinstalar JetBrains Toolbox completamente"
        return 1
    fi

    echo ""
    log_output "${YELLOW}Deseja remover também os dados das IDEs instaladas pelo Toolbox? (s/N)${NC}"
    read -r response

    if [[ "$response" =~ ^[sS]$ ]]; then
        log_info "Removendo dados das IDEs..."

        if [ "$os_name" = "darwin" ]; then
            rm -rf "$HOME/Library/Application Support/JetBrains" 2>/dev/null || log_debug "Diretório não encontrado"
            rm -rf "$HOME/Library/Caches/JetBrains" 2>/dev/null || log_debug "Cache não encontrado"
            rm -rf "$HOME/Library/Logs/JetBrains" 2>/dev/null || log_debug "Logs não encontrados"
        else
            rm -rf "$HOME/.local/share/JetBrains" 2>/dev/null || log_debug "Diretório não encontrado"
            rm -rf "$HOME/.cache/JetBrains" 2>/dev/null || log_debug "Cache não encontrado"
        fi

        log_info "Dados removidos"
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
