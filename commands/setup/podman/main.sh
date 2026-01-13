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
    echo "  Podman é um motor de container open-source para desenvolvimento,"
    echo "  gerenciamento e execução de containers OCI. É uma alternativa"
    echo "  daemon-less e rootless ao Docker."
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  -h, --help        Mostra esta mensagem de ajuda"
    echo "  -u, --uninstall   Desinstala o Podman do sistema"
    echo "  --update          Atualiza o Podman para a versão mais recente"
    echo "  -v, --verbose     Habilita saída detalhada para depuração"
    echo "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo "  susa setup podman              # Instala o Podman"
    echo "  susa setup podman --update     # Atualiza o Podman"
    echo "  susa setup podman --uninstall  # Desinstala o Podman"
    echo ""
    echo -e "${LIGHT_GREEN}Pós-instalação:${NC}"
    echo "  Após a instalação, reinicie o terminal ou execute:"
    echo "    source ~/.bashrc   (para Bash)"
    echo "    source ~/.zshrc    (para Zsh)"
    echo ""
    echo -e "${LIGHT_GREEN}Próximos passos:${NC}"
    echo "  podman --version                   # Verifica a instalação"
    echo "  podman run hello-world             # Teste com container simples"
    echo "  podman images                      # Lista imagens disponíveis"
}

get_latest_podman_version() {
    local fallback_version="v5.7.1"

    # Try to get the latest version via GitHub API
    local latest_version=$(curl -s --max-time 10 --connect-timeout 5 https://api.github.com/repos/containers/podman/releases/latest 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via API do GitHub: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    # If it fails, try via git ls-remote
    log_debug "API do GitHub falhou, tentando via git ls-remote..." >&2
    latest_version=$(timeout 5 git ls-remote --tags --refs https://github.com/containers/podman.git 2>/dev/null | tail -1 | sed 's/.*\///')

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via git ls-remote: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    # If it still fails, use fallback version
    log_debug "Usando versão fallback: $fallback_version" >&2
    echo "$fallback_version"
}

# Check if Podman is already installed and ask about update
check_existing_installation() {
    local target_version="$1"

    if ! command -v podman &>/dev/null; then
        return 0  # Not installed, you can continue
    fi

    local current_version=$(podman --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida")
    log_debug "Podman já está instalado (versão atual: $current_version)"

    # Remove 'v' prefix for comparison
    local target_version_clean="${target_version#v}"

    if [ "$current_version" = "$target_version_clean" ]; then
        log_info "Você já possui a versão mais recente instalada ($current_version)"
        return 2  # Já atualizado
    fi

    echo ""
    echo -e "${YELLOW}Podman $current_version está instalado. Atualizar para $target_version_clean? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sS]$ ]]; then
        log_info "Instalação cancelada"
        return 1  # Canceled
    fi

    log_info "Atualizando de $current_version para $target_version_clean..."
    return 0  # You can continue
}

# Install Podman on macOS using Homebrew
install_podman_macos() {
    log_info "Instalando Podman no macOS..."

    # Check if Homebrew is installed
    if ! command -v brew &>/dev/null; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    # Install or upgrade Podman
    if brew list podman &>/dev/null; then
        log_info "Atualizando Podman via Homebrew..."
        brew upgrade podman || true
    else
        log_info "Instalando Podman via Homebrew..."
        brew install podman
    fi

    # Install podman-compose if not present
    if ! brew list podman-compose &>/dev/null 2>&1; then
        log_info "Instalando podman-compose..."
        brew install podman-compose || log_debug "podman-compose não disponível via brew"
    fi

    # Initialize podman machine
    log_info "Inicializando máquina virtual do Podman..."
    podman machine init 2>/dev/null || log_debug "Máquina virtual já existe"
    podman machine start || log_debug "Máquina virtual já está rodando"

    return 0
}

# Install Podman on Linux using package manager
install_podman_linux() {
    log_info "Instalando Podman no Linux..."

    # Get latest version
    log_debug "Obtendo última versão..."
    local podman_version=$(get_latest_podman_version)

    # Detect architecture
    local arch=$(uname -m)
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"

    # Build download URL
    local download_url="https://github.com/containers/podman/releases/download/${podman_version}/podman-remote-static-linux_${arch}.tar.gz"
    local output_file="/tmp/podman-remote.tar.gz"

    log_info "Baixando Podman ${podman_version}..."
    log_debug "URL: $download_url"

    if ! curl -L --progress-bar \
        --connect-timeout 30 \
        --max-time 300 \
        --retry 3 \
        --retry-delay 2 \
        "$download_url" -o "$output_file"; then
        log_error "Falha ao baixar Podman"
        rm -f "$output_file"
        return 1
    fi

    # Extract binary
    log_info "Extraindo Podman..."
    local temp_dir="/tmp/podman-extract-$$"
    mkdir -p "$temp_dir"

    if ! tar -xzf "$output_file" -C "$temp_dir" 2>/dev/null; then
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

    mv "$podman_binary" "$install_dir/podman"
    chmod +x "$install_dir/podman"
    rm -rf "$temp_dir"

    log_debug "Binário instalado em $install_dir/podman"

    # Configure PATH if needed
    local shell_config=$(detect_shell_config)
    if ! grep -q ".local/bin" "$shell_config" 2>/dev/null; then
        echo "" >> "$shell_config"
        echo "# Local binaries PATH" >> "$shell_config"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$shell_config"
        log_debug "PATH configurado em $shell_config"
    fi

    # Update current session PATH
    export PATH="$HOME/.local/bin:$PATH"

    # Install podman-compose
    log_info "Instalando podman-compose..."

    local compose_installed=false

    # Try to install via package manager first
    if command -v apt-get &>/dev/null; then
        if sudo apt-get install -y podman-compose >/dev/null 2>&1; then
            log_debug "podman-compose instalado via apt-get"
            compose_installed=true
        fi
    elif command -v dnf &>/dev/null; then
        if sudo dnf install -y podman-compose >/dev/null 2>&1; then
            log_debug "podman-compose instalado via dnf"
            compose_installed=true
        fi
    elif command -v yum &>/dev/null; then
        if sudo yum install -y podman-compose >/dev/null 2>&1; then
            log_debug "podman-compose instalado via yum"
            compose_installed=true
        fi
    fi

    # If package manager installation failed, try pip
    if [ "$compose_installed" = false ]; then
        log_debug "podman-compose não disponível via gerenciador de pacotes, tentando via pip..."

        # Ensure pip3 is installed
        ensure_pip3_installed || return 1

        pip3 install --user podman-compose >/dev/null 2>&1 || log_debug "Não foi possível instalar podman-compose"
    fi

    # Verify installation
    if ! command -v podman &>/dev/null; then
        log_error "Falha na instalação do Podman"
        return 1
    fi

    return 0
}

# Main installation function
install_podman() {
    # Check if Podman is already installed
    if command -v podman &>/dev/null; then
        local current_version=$(podman --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida")
        log_info "Podman $current_version já está instalado."

        log_debug "Obtendo última versão..."
        local podman_version=$(get_latest_podman_version)
        local target_version_clean="${podman_version#v}"

        if [ "$current_version" != "$target_version_clean" ]; then
            echo ""
            echo -e "${YELLOW}Uma versão mais recente está disponível ($target_version_clean).${NC}"
            echo -e "Para atualizar, execute: ${LIGHT_CYAN}susa setup podman --update${NC}"
        fi

        return 0
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
        if command -v podman &>/dev/null; then
            local installed_version=$(podman --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
            log_success "Podman $installed_version instalado com sucesso!"
            echo ""
            echo "Próximos passos:"

            if [ "$os_name" = "darwin" ]; then
                echo -e "  1. A máquina virtual do Podman foi iniciada"
                echo -e "  2. Execute: ${LIGHT_CYAN}podman run hello-world${NC}"
            else
                echo -e "  1. Reinicie o terminal ou execute: ${LIGHT_CYAN}source $(detect_shell_config)${NC}"
                echo -e "  2. Execute: ${LIGHT_CYAN}podman --version${NC}"
            fi

            echo -e "  2. Use ${LIGHT_CYAN}susa setup podman --help${NC} para mais informações"
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
    if ! command -v podman &>/dev/null; then
        log_error "Podman não está instalado. Use 'susa setup podman' para instalar."
        return 1
    fi

    local current_version=$(podman --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida")
    log_info "Versão atual: $current_version"

    # Get latest version
    log_debug "Obtendo última versão..."
    local podman_version=$(get_latest_podman_version)
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
            if ! command -v brew &>/dev/null; then
                log_error "Homebrew não está instalado"
                return 1
            fi

            log_info "Atualizando Podman via Homebrew..."
            brew upgrade podman || {
                log_error "Falha ao atualizar Podman"
                return 1
            }

            # Update podman-compose if installed
            if brew list podman-compose &>/dev/null 2>&1; then
                log_info "Atualizando podman-compose..."
                brew upgrade podman-compose || log_debug "podman-compose já está atualizado"
            fi
            ;;
        linux)
            # Remove old binary
            if [ -f "$HOME/.local/bin/podman" ]; then
                log_info "Removendo versão anterior..."
                rm -f "$HOME/.local/bin/podman"
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
    if command -v podman &>/dev/null; then
        local new_version=$(podman --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        log_success "Podman atualizado com sucesso para versão $new_version!"
    else
        log_error "Falha na atualização do Podman"
        return 1
    fi
}

# Uninstall Podman
uninstall_podman() {
    log_info "Desinstalando Podman..."

    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            # Stop and remove podman machine
            if command -v podman &>/dev/null; then
                log_info "Parando máquina virtual do Podman..."
                podman machine stop 2>/dev/null || true
                podman machine rm -f 2>/dev/null || true
            fi

            # Uninstall via Homebrew
            if command -v brew &>/dev/null; then
                log_info "Removendo Podman via Homebrew..."
                brew uninstall podman 2>/dev/null || log_debug "Podman não instalado via Homebrew"
                brew uninstall podman-compose 2>/dev/null || log_debug "podman-compose não instalado"
            fi
            ;;
        linux)
            # Remove binary
            if [ -f "$HOME/.local/bin/podman" ]; then
                rm -f "$HOME/.local/bin/podman"
                log_debug "Binário removido: $HOME/.local/bin/podman"
            else
                log_debug "Podman não está instalado em $HOME/.local/bin"
            fi

            # Remove podman-compose
            log_info "Removendo podman-compose..."

            # Try to remove via package manager first
            if command -v apt-get &>/dev/null; then
                sudo apt-get remove -y podman-compose >/dev/null 2>&1 || log_debug "podman-compose não instalado via apt-get"
            elif command -v dnf &>/dev/null; then
                sudo dnf remove -y podman-compose >/dev/null 2>&1 || log_debug "podman-compose não instalado via dnf"
            elif command -v yum &>/dev/null; then
                sudo yum remove -y podman-compose >/dev/null 2>&1 || log_debug "podman-compose não instalado via yum"
            fi

            # Also try to remove from pip
            if command -v pip3 &>/dev/null; then
                pip3 uninstall -y podman-compose >/dev/null 2>&1 || log_debug "podman-compose não instalado via pip"
            fi
            ;;
    esac

    log_success "Podman desinstalado com sucesso!"
}

# Main function
main() {
    local action="${1:-install}"

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
