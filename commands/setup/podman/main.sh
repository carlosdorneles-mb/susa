#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"

# Help function
show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Podman é um motor de container open-source para desenvolvimento,"
    log_output "  gerenciamento e execução de containers OCI. É uma alternativa"
    log_output "  daemon-less e rootless ao Docker."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o Podman do sistema"
    log_output "  -u, --upgrade     Atualiza o Podman para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup podman              # Instala o Podman"
    log_output "  susa setup podman --upgrade    # Atualiza o Podman"
    log_output "  susa setup podman --uninstall  # Desinstala o Podman"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Após a instalação, reinicie o terminal ou execute:"
    log_output "    source ~/.bashrc   (para Bash)"
    log_output "    source ~/.zshrc    (para Zsh)"
    log_output ""
    log_output "${LIGHT_GREEN}Próximos passos:${NC}"
    log_output "  podman --version                   # Verifica a instalação"
    log_output "  podman run hello-world             # Teste com container simples"
    log_output "  podman images                      # Lista imagens disponíveis"
}

get_latest_version() {
    github_get_latest_version "containers/podman"
}

# Get installed Podman version
get_current_version() {
    if check_installation; then
        podman --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if Podman is installed
check_installation() {
    command -v podman &> /dev/null
}

# Install Podman on macOS using Homebrew
install_podman_macos() {
    log_info "Instalando Podman no macOS..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL $PODMAN_HOMEBREW_INSTALL_URL)\""
        return 1
    fi

    # Install or upgrade Podman
    if brew list podman &> /dev/null; then
        log_info "Atualizando Podman via Homebrew..."
        brew upgrade podman || true
    else
        log_info "Instalando Podman via Homebrew..."
        brew install podman
    fi

    # Install podman-compose if not present
    if ! brew list podman-compose &> /dev/null 2>&1; then
        log_info "Instalando podman-compose..."
        brew install podman-compose || log_debug "podman-compose não disponível via brew"
    fi

    # Initialize podman machine
    log_info "Inicializando máquina virtual do Podman..."
    podman machine init 2> /dev/null || log_debug "Máquina virtual já existe"
    podman machine start || log_debug "Máquina virtual já está rodando"

    return 0
}

# Install Podman on Linux using package manager
install_podman_linux() {
    log_info "Instalando Podman no Linux..."

    # Get latest version
    local podman_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$podman_version" ]; then
        return 1
    fi

    # Detect OS and architecture using github library
    local os_arch=$(github_detect_os_arch "standard")
    if [ $? -ne 0 ]; then
        return 1
    fi

    local arch="${os_arch#*:}"
    # Convert arch format for Podman (x64 -> amd64)
    case "$arch" in
        x64) arch="amd64" ;;
        arm64) arch="arm64" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    local install_dir="$LOCAL_BIN_DIR"
    mkdir -p "$install_dir"

    # Build download URL with correct filename for checksum verification
    local filename="podman-remote-static-linux_${arch}.tar.gz"
    local download_url="https://github.com/containers/podman/releases/download/${podman_version}/${filename}"
    local output_file="/tmp/${filename}"

    log_info "Baixando e verificando Podman ${podman_version}..."
    log_debug "URL: $download_url" >&2

    # Download and verify with checksum
    if ! github_download_and_verify "containers/podman" "$podman_version" "$download_url" "$output_file" "shasums" "sha256"; then
        log_error "Falha ao baixar ou verificar Podman" >&2
        return 1
    fi

    # Extract binary
    log_info "Extraindo Podman..."
    local temp_dir="/tmp/podman-extract-$$"
    mkdir -p "$temp_dir"

    if ! tar -xzf "$output_file" -C "$temp_dir" 2> /dev/null; then
        log_error "Falha ao extrair Podman"
        rm -rf "$temp_dir" "$output_file"
        return 1
    fi
    rm -f "$output_file"

    # List extracted files for debugging
    log_debug "Arquivos extraídos:"
    find "$temp_dir" -type f | while read file; do
        log_debug "  $(basename "$file")"
    done

    # Find and install binary (try multiple possible names)
    local podman_binary=$(find "$temp_dir" -type f \( -name "podman-remote-static" -o -name "podman-remote" -o -name "podman" \) | head -1)

    if [ -z "$podman_binary" ]; then
        # Try to find any executable file
        log_debug "Procurando por executável..."
        podman_binary=$(find "$temp_dir" -type f -executable | head -1)
    fi

    if [ -z "$podman_binary" ]; then
        log_error "Binário do Podman não encontrado no arquivo"
        log_debug "Conteúdo do diretório:"
        ls -la "$temp_dir"
        rm -rf "$temp_dir"
        return 1
    fi

    log_debug "Binário encontrado: $podman_binary"

    local podman_bin="$LOCAL_BIN_DIR/podman"
    mv "$podman_binary" "$podman_bin"
    chmod +x "$podman_bin"
    rm -rf "$temp_dir"

    log_debug "Binário instalado em $podman_bin"

    # Configure PATH if needed
    local shell_config=$(detect_shell_config)
    if ! grep -q ".local/bin" "$shell_config" 2> /dev/null; then
        echo "" >> "$shell_config"
        echo "# Local binaries PATH" >> "$shell_config"
        echo "export PATH=\"$LOCAL_BIN_DIR:\$PATH\"" >> "$shell_config"
        log_debug "PATH configurado em $shell_config"
    fi

    # Update current session PATH
    export PATH="$LOCAL_BIN_DIR:$PATH"

    # Install podman-compose
    log_info "Instalando podman-compose..."

    local compose_installed=false

    # Try to install via package manager first
    if command -v apt-get &> /dev/null; then
        if sudo apt-get install -y podman-compose > /dev/null 2>&1; then
            log_debug "podman-compose instalado via apt-get"
            compose_installed=true
        fi
    elif command -v dnf &> /dev/null; then
        if sudo dnf install -y podman-compose > /dev/null 2>&1; then
            log_debug "podman-compose instalado via dnf"
            compose_installed=true
        fi
    elif command -v yum &> /dev/null; then
        if sudo yum install -y podman-compose > /dev/null 2>&1; then
            log_debug "podman-compose instalado via yum"
            compose_installed=true
        fi
    fi

    # If package manager installation failed, try pip
    if [ "$compose_installed" = false ]; then
        log_debug "podman-compose não disponível via gerenciador de pacotes, tentando via pip..."

        # Ensure pip3 is installed
        ensure_pip3_installed || return 1

        pip3 install --user podman-compose > /dev/null 2>&1 || log_debug "Não foi possível instalar podman-compose"
    fi

    # Verify installation
    if ! command -v podman &> /dev/null; then
        log_error "Falha na instalação do Podman"
        return 1
    fi

    return 0
}

# Main installation function
install_podman() {
    if check_installation; then
        log_info "Podman $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do Podman..."

    # Detect OS
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            install_podman_macos
            ;;
        linux)
            install_podman_linux
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    local install_result=$?

    if [ $install_result -eq 0 ]; then
        # Verify installation
        if check_installation; then
            local installed_version=$(get_current_version)
            log_success "Podman $installed_version instalado com sucesso!"
            register_or_update_software_in_lock "podman" "$installed_version"
            echo ""
            echo "Próximos passos:"

            if [ "$os_name" = "darwin" ]; then
                log_output "  1. A máquina virtual do Podman foi iniciada"
                log_output "  2. Execute: ${LIGHT_CYAN}podman run hello-world${NC}"
            else
                log_output "  1. Reinicie o terminal ou execute: ${LIGHT_CYAN}source $(detect_shell_config)${NC}"
                log_output "  2. Execute: ${LIGHT_CYAN}podman --version${NC}"
            fi

            log_output "  2. Use ${LIGHT_CYAN}susa setup podman --help${NC} para mais informações"
        else
            log_error "Podman foi instalado mas não está disponível no PATH"
            return 1
        fi
    else
        return $install_result
    fi
}

# Update Podman
update_podman() {
    log_info "Atualizando Podman..."

    # Check if Podman is installed
    if ! check_installation; then
        log_error "Podman não está instalado. Use 'susa setup podman' para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Versão atual: $current_version"

    # Get latest version
    local podman_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$podman_version" ]; then
        return 1
    fi
    local target_version_clean="${podman_version#v}"

    if [ "$current_version" = "$target_version_clean" ]; then
        log_info "Você já possui a versão mais recente instalada ($current_version)"
        return 0
    fi

    log_info "Atualizando de $current_version para $target_version_clean..."

    # Detect OS and update
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            if ! command -v brew &> /dev/null; then
                log_error "Homebrew não está instalado"
                return 1
            fi

            log_info "Atualizando Podman via Homebrew..."
            brew upgrade podman || {
                log_error "Falha ao atualizar Podman"
                return 1
            }

            # Update podman-compose if installed
            if brew list podman-compose &> /dev/null 2>&1; then
                log_info "Atualizando podman-compose..."
                brew upgrade podman-compose || log_debug "podman-compose já está atualizado"
            fi
            ;;
        linux)
            # Remove old binary
            local podman_bin="$LOCAL_BIN_DIR/podman"
            if [ -f "$podman_bin" ]; then
                log_info "Removendo versão anterior..."
                rm -f "$podman_bin"
            fi

            # Install new version
            install_podman_linux
            return $?
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    # Verify update
    if check_installation; then
        local new_version=$(get_current_version)
        log_success "Podman atualizado com sucesso para versão $new_version!"
        register_or_update_software_in_lock "podman" "$new_version"
    else
        log_error "Falha na atualização do Podman"
        return 1
    fi
}

# Uninstall Podman
uninstall_podman() {
    log_info "Desinstalando Podman..."

    # Check if Podman is installed
    if ! check_installation; then
        log_warning "Podman não está instalado"
        return 0
    fi

    local version=$(get_current_version)
    log_debug "Versão a ser removida: $version"

    # Confirm uninstallation
    echo ""
    log_output "${YELLOW}Deseja realmente desinstalar o Podman $version? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sSyY]$ ]]; then
        log_info "Desinstalação cancelada"
        return 1
    fi

    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local shell_config=$(detect_shell_config)

    case "$os_name" in
        darwin)
            # Stop and remove podman machine
            if check_installation; then
                log_info "Parando máquina virtual do Podman..."
                podman machine stop 2> /dev/null || true
                podman machine rm -f 2> /dev/null || true
            fi

            # Uninstall via Homebrew
            if command -v brew &> /dev/null; then
                log_info "Removendo Podman via Homebrew..."
                brew uninstall podman 2> /dev/null || log_debug "Podman não instalado via Homebrew"
                brew uninstall podman-compose 2> /dev/null || log_debug "podman-compose não instalado"
            fi
            ;;
        linux)
            local podman_location=$(which podman 2> /dev/null)
            local removed_system=false

            # Check if installed via system package manager
            if [ -n "$podman_location" ]; then
                log_debug "Podman encontrado em: $podman_location"

                # Detect installation method
                if [[ "$podman_location" == "/usr/bin/podman" ]] || [[ "$podman_location" == "/usr/local/bin/podman" ]]; then
                    log_info "Detectado Podman instalado via gerenciador de pacotes do sistema"

                    # Try to remove via package manager
                    if command -v apt-get &> /dev/null; then
                        log_debug "Verificando instalação via apt..."
                        if dpkg -l podman 2> /dev/null | grep -q "^ii"; then
                            log_info "Removendo Podman via apt..."
                            log_debug "Executando: sudo apt-get remove -y podman"
                            local apt_output=$(sudo apt-get remove -y podman 2>&1)
                            local apt_exit=$?
                            echo "$apt_output" | while read -r line; do log_debug "apt: $line"; done
                            if [ $apt_exit -eq 0 ]; then
                                removed_system=true
                                log_debug "Podman removido via apt com sucesso"
                            else
                                log_warning "Falha ao remover Podman via apt (código $apt_exit)"
                            fi
                        else
                            log_debug "Podman não está instalado via apt"
                        fi
                    elif command -v dnf &> /dev/null; then
                        if rpm -qa | grep -q "^podman"; then
                            log_info "Removendo Podman via dnf..."
                            local dnf_output=$(sudo dnf remove -y podman 2>&1)
                            local dnf_exit=$?
                            echo "$dnf_output" | while read -r line; do log_debug "dnf: $line"; done
                            if [ $dnf_exit -eq 0 ]; then
                                removed_system=true
                                log_debug "Podman removido via dnf com sucesso"
                            else
                                log_warning "Falha ao remover Podman via dnf (código $dnf_exit)"
                            fi
                        fi
                    elif command -v yum &> /dev/null; then
                        if rpm -qa | grep -q "^podman"; then
                            log_info "Removendo Podman via yum..."
                            local yum_output=$(sudo yum remove -y podman 2>&1)
                            local yum_exit=$?
                            echo "$yum_output" | while read -r line; do log_debug "yum: $line"; done
                            if [ $yum_exit -eq 0 ]; then
                                removed_system=true
                                log_debug "Podman removido via yum com sucesso"
                            else
                                log_warning "Falha ao remover Podman via yum (código $yum_exit)"
                            fi
                        fi
                    elif command -v pacman &> /dev/null; then
                        if pacman -Q podman &> /dev/null; then
                            log_info "Removendo Podman via pacman..."
                            local pacman_output=$(sudo pacman -R --noconfirm podman 2>&1)
                            local pacman_exit=$?
                            echo "$pacman_output" | while read -r line; do log_debug "pacman: $line"; done
                            if [ $pacman_exit -eq 0 ]; then
                                removed_system=true
                                log_debug "Podman removido via pacman com sucesso"
                            else
                                log_warning "Falha ao remover Podman via pacman (código $pacman_exit)"
                            fi
                        fi
                    fi
                fi
            fi

            # Remove binary from local bin if exists
            local podman_bin="$LOCAL_BIN_DIR/podman"
            if [ -f "$podman_bin" ]; then
                rm -f "$podman_bin"
                log_debug "Binário local removido: $podman_bin"
            fi

            # Remove podman-compose
            log_info "Removendo podman-compose..."

            # Try to remove via package manager first
            if command -v apt-get &> /dev/null; then
                sudo apt-get remove -y podman-compose > /dev/null 2>&1 || log_debug "podman-compose não instalado via apt-get"
            elif command -v dnf &> /dev/null; then
                sudo dnf remove -y podman-compose > /dev/null 2>&1 || log_debug "podman-compose não instalado via dnf"
            elif command -v yum &> /dev/null; then
                sudo yum remove -y podman-compose > /dev/null 2>&1 || log_debug "podman-compose não instalado via yum"
            fi

            # Also try to remove from pip
            if command -v pip3 &> /dev/null; then
                pip3 uninstall -y podman-compose > /dev/null 2>&1 || log_debug "podman-compose não instalado via pip"
            fi
            ;;
    esac

    # Verify removal
    if ! check_installation; then
        log_success "Podman desinstalado com sucesso!"
        remove_software_in_lock "podman"

        echo ""
        log_info "Reinicie o terminal ou execute: source $shell_config"
    else
        log_warning "Podman removido, mas executável ainda encontrado no PATH"
        log_debug "Pode ser necessário remover manualmente de: $(which podman)"
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
                show_software_info
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
            install_podman
            ;;
        update)
            update_podman
            ;;
        uninstall)
            uninstall_podman
            ;;
        *)
            log_error "Ação desconhecida: $action"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
