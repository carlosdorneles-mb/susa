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
    log_output "  Google Cloud SDK (gcloud) é um conjunto de ferramentas de linha"
    log_output "  de comando para gerenciar recursos e aplicações hospedadas no"
    log_output "  Google Cloud Platform. Inclui gcloud, gsutil e bq."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --info            Mostra informações sobre a instalação do gcloud"
    log_output "  --uninstall       Desinstala o Google Cloud SDK do sistema"
    log_output "  -u, --upgrade     Atualiza o gcloud para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup gcloud              # Instala o Google Cloud SDK"
    log_output "  susa setup gcloud --upgrade    # Atualiza o gcloud"
    log_output "  susa setup gcloud --uninstall  # Desinstala o gcloud"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Após a instalação, reinicie o terminal ou execute:"
    log_output "    source ~/.bashrc   (para Bash)"
    log_output "    source ~/.zshrc    (para Zsh)"
    log_output ""
    log_output "  Autentique-se com:"
    log_output "    gcloud init"
    log_output "    gcloud auth login"
    log_output ""
    log_output "${LIGHT_GREEN}Próximos passos:${NC}"
    log_output "  gcloud --version               # Verifica a instalação"
    log_output "  gcloud init                    # Inicializa configuração"
    log_output "  gcloud projects list           # Lista projetos GCP"
}

# Get latest version from Google Cloud SDK
get_latest_version() {
    local version=$(curl -s https://dl.google.com/dl/cloudsdk/channels/rapid/components-2.json | grep -oP '"version": "\K[^"]+' | head -1)

    if [ -z "$version" ]; then
        log_debug "Não foi possível obter a versão mais recente"
        echo "desconhecida"
        return 1
    fi

    echo "$version"
}

# Get installed gcloud version
get_current_version() {
    if check_installation; then
        gcloud version --format="value(.)" 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if gcloud is installed
check_installation() {
    command -v gcloud &> /dev/null
}

# Show additional gcloud-specific information
# Called by show_software_info()
show_additional_info() {
    if ! check_installation; then
        return
    fi

    # Show configured account
    local account=$(gcloud config get-value account 2> /dev/null || echo "não configurado")
    log_output "  ${CYAN}Conta:${NC} $account"

    # Show configured project
    local project=$(gcloud config get-value project 2> /dev/null || echo "não configurado")
    log_output "  ${CYAN}Projeto:${NC} $project"

    # Show configured region (try region first, then zone)
    local region=$(gcloud config get-value compute/region 2> /dev/null)
    if [ -z "$region" ]; then
        local zone=$(gcloud config get-value compute/zone 2> /dev/null)
        if [ -n "$zone" ]; then
            region="$zone (zona)"
        else
            region="não configurado"
        fi
    fi
    log_output "  ${CYAN}Região:${NC} $region"

    # Show available components
    log_output "  ${CYAN}Componentes:${NC} $(gcloud components list --filter="state.name=Installed" --format="value(id)" 2> /dev/null | wc -l | xargs) instalados"
}

# Detect OS and architecture
detect_os_and_arch() {
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)

    case "$os_name" in
        linux) os_name="linux" ;;
        darwin) os_name="darwin" ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    case "$arch" in
        x86_64 | amd64) arch="x86_64" ;;
        aarch64 | arm64) arch="arm" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    echo "${os_name}:${arch}"
}

# Get download filename for current system
get_download_filename() {
    local os_arch="$1"
    local os="${os_arch%%:*}"
    local arch="${os_arch##*:}"

    # Google Cloud SDK archive naming convention
    case "$os:$arch" in
        linux:x86_64)
            echo "google-cloud-cli-linux-x86_64.tar.gz"
            ;;
        linux:arm)
            echo "google-cloud-cli-linux-arm.tar.gz"
            ;;
        darwin:x86_64)
            echo "google-cloud-cli-darwin-x86_64.tar.gz"
            ;;
        darwin:arm)
            echo "google-cloud-cli-darwin-arm.tar.gz"
            ;;
        *)
            log_error "Combinação de OS/arquitetura não suportada: $os:$arch"
            return 1
            ;;
    esac
}

# Install Google Cloud SDK on macOS using Homebrew
install_gcloud_macos_brew() {
    log_info "Instalando Google Cloud SDK via Homebrew..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_warning "Homebrew não está instalado. Instalando via tarball..."
        return 1
    fi

    # Install or upgrade gcloud
    if brew list google-cloud-sdk &> /dev/null 2>&1; then
        log_info "Atualizando Google Cloud SDK via Homebrew..."
        brew upgrade google-cloud-sdk || true
    else
        log_info "Instalando Google Cloud SDK via Homebrew..."
        brew install google-cloud-sdk
    fi

    return 0
}

# Install Google Cloud SDK from tarball (Linux and macOS fallback)
install_gcloud_tarball() {
    local os_arch="$1"

    log_info "Instalando Google Cloud SDK via tarball..."

    # Get download filename
    local filename=$(get_download_filename "$os_arch")
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Build download URL
    local download_url="${GCLOUD_SDK_BASE_URL}/${filename}"
    local output_file="/tmp/${filename}"

    log_info "Baixando Google Cloud SDK..."
    log_debug "URL: $download_url"

    # Download with retry
    if ! curl -fsSL --retry 3 --retry-delay 2 -o "$output_file" "$download_url"; then
        log_error "Falha ao baixar Google Cloud SDK"
        rm -f "$output_file"
        return 1
    fi

    # Extract to installation directory
    local install_dir="$HOME/.local/share/google-cloud-sdk"

    # Remove old installation if exists
    if [ -d "$install_dir" ]; then
        log_debug "Removendo instalação antiga..."
        rm -rf "$install_dir"
    fi

    mkdir -p "$(dirname "$install_dir")"

    log_info "Extraindo Google Cloud SDK..."
    if ! tar -xzf "$output_file" -C "$(dirname "$install_dir")" 2> /dev/null; then
        log_error "Falha ao extrair Google Cloud SDK"
        rm -f "$output_file"
        return 1
    fi
    rm -f "$output_file"

    # Run install script
    log_info "Configurando Google Cloud SDK..."
    local install_script="$install_dir/install.sh"

    if [ -f "$install_script" ]; then
        # Run installer non-interactively
        bash "$install_script" \
            --usage-reporting=false \
            --command-completion=true \
            --path-update=true \
            --quiet \
            2> /dev/null || log_debug "Instalador executado com avisos"
    else
        log_error "Script de instalação não encontrado"
        return 1
    fi

    # Configure PATH for current session
    export PATH="$install_dir/bin:$PATH"

    # Add to shell configuration
    local shell_config=$(detect_shell_config)
    local gcloud_path_line="export PATH=\"\$HOME/.local/share/google-cloud-sdk/bin:\$PATH\""

    if ! grep -q "google-cloud-sdk/bin" "$shell_config" 2> /dev/null; then
        echo "" >> "$shell_config"
        echo "# Google Cloud SDK" >> "$shell_config"
        echo "$gcloud_path_line" >> "$shell_config"
        log_debug "PATH configurado em $shell_config"
    fi

    return 0
}

# Main installation function
install_gcloud() {
    if check_installation; then
        log_info "Google Cloud SDK $(get_current_version) já está instalado."
        log_info "Use 'susa setup gcloud --upgrade' para atualizar."
        exit 0
    fi

    log_info "Iniciando instalação do Google Cloud SDK..."

    # Detect OS and architecture
    local os_arch=$(detect_os_and_arch)
    if [ $? -ne 0 ]; then
        return 1
    fi

    local os_name="${os_arch%%:*}"

    # Try Homebrew on macOS first
    if [ "$os_name" = "darwin" ]; then
        if install_gcloud_macos_brew; then
            local install_result=0
        else
            install_gcloud_tarball "$os_arch"
            local install_result=$?
        fi
    else
        # Linux: use tarball installation
        install_gcloud_tarball "$os_arch"
        local install_result=$?
    fi

    if [ $install_result -eq 0 ]; then
        # Verify installation
        # Need to reload PATH for current session
        export PATH="$HOME/.local/share/google-cloud-sdk/bin:$PATH"

        if check_installation; then
            local installed_version=$(get_current_version)
            log_success "Google Cloud SDK $installed_version instalado com sucesso!"
            register_or_update_software_in_lock "gcloud" "$installed_version"
            echo ""
            echo "Próximos passos:"
            log_output "  1. Reinicie o terminal ou execute: ${LIGHT_CYAN}source $(detect_shell_config)${NC}"
            log_output "  2. Autentique-se: ${LIGHT_CYAN}gcloud init${NC}"
            log_output "  3. Execute: ${LIGHT_CYAN}gcloud --version${NC}"
            log_output "  4. Use ${LIGHT_CYAN}susa setup gcloud --help${NC} para mais informações"
        else
            log_error "Google Cloud SDK foi instalado mas não está disponível no PATH"
            log_output "Tente reiniciar o terminal"
            return 1
        fi
    else
        return $install_result
    fi
}

# Update Google Cloud SDK
update_gcloud() {
    # Check if gcloud is installed
    if ! check_installation; then
        log_error "Google Cloud SDK não está instalado. Use 'susa setup gcloud' para instalar."
        return 1
    fi

    local current_version=$(get_current_version)
    log_info "Atualizando Google Cloud SDK (versão atual: $current_version)..."

    # Detect OS
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            # Check if installed via Homebrew
            if brew list google-cloud-sdk &> /dev/null 2>&1; then
                log_info "Atualizando via Homebrew..."
                brew upgrade google-cloud-sdk || {
                    log_warning "Homebrew não atualizou. Tentando gcloud components update..."
                    gcloud components update --quiet 2> /dev/null || true
                }
            else
                log_info "Atualizando componentes do gcloud..."
                gcloud components update --quiet || {
                    log_error "Falha ao atualizar Google Cloud SDK"
                    return 1
                }
            fi
            ;;
        linux)
            log_info "Atualizando componentes do gcloud..."
            gcloud components update --quiet || {
                log_error "Falha ao atualizar Google Cloud SDK"
                return 1
            }
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    # Verify update
    if check_installation; then
        local new_version=$(get_current_version)

        # Update version in lock file
        register_or_update_software_in_lock "gcloud" "$new_version"

        if [ "$new_version" != "$current_version" ]; then
            log_success "Google Cloud SDK atualizado de $current_version para $new_version!"
        else
            log_info "Google Cloud SDK já está na versão mais recente ($current_version)"
        fi
    else
        log_error "Falha na atualização do Google Cloud SDK"
        return 1
    fi
}

# Uninstall Google Cloud SDK
uninstall_gcloud() {
    # Check if gcloud is installed
    if ! check_installation; then
        log_info "Google Cloud SDK não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)

    log_output ""
    log_output "${YELLOW}Deseja realmente desinstalar o Google Cloud SDK $current_version? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sSyY]$ ]]; then
        log_info "Desinstalação cancelada"
        return 0
    fi

    log_info "Desinstalando Google Cloud SDK..."

    # Detect OS
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            # Check if installed via Homebrew
            if brew list google-cloud-sdk &> /dev/null 2>&1; then
                log_info "Desinstalando via Homebrew..."
                brew uninstall google-cloud-sdk || {
                    log_error "Falha ao desinstalar via Homebrew"
                    return 1
                }
            else
                # Remove tarball installation
                local install_dir="$HOME/.local/share/google-cloud-sdk"
                if [ -d "$install_dir" ]; then
                    rm -rf "$install_dir"
                    log_debug "Removido diretório $install_dir"
                fi
            fi
            ;;
        linux)
            # Remove tarball installation
            local install_dir="$HOME/.local/share/google-cloud-sdk"
            if [ -d "$install_dir" ]; then
                rm -rf "$install_dir"
                log_debug "Removido diretório $install_dir"
            fi
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    # Remove from shell configuration
    local shell_config=$(detect_shell_config)
    if [ -f "$shell_config" ]; then
        # Remove Google Cloud SDK PATH lines
        sed -i.bak '/# Google Cloud SDK/d' "$shell_config" 2> /dev/null ||
            sed -i '' '/# Google Cloud SDK/d' "$shell_config" 2> /dev/null

        sed -i.bak '/google-cloud-sdk\/bin/d' "$shell_config" 2> /dev/null ||
            sed -i '' '/google-cloud-sdk\/bin/d' "$shell_config" 2> /dev/null

        rm -f "${shell_config}.bak"
        log_debug "Removido PATH do $shell_config"
    fi

    # Verify uninstallation
    if ! check_installation; then
        # Mark as uninstalled in lock file
        remove_software_in_lock "gcloud"

        log_success "Google Cloud SDK desinstalado com sucesso!"
        log_output ""
        log_output "Reinicie o terminal para aplicar as mudanças no PATH"
    else
        log_error "Falha ao desinstalar Google Cloud SDK completamente"
        log_output "Você pode precisar remover manualmente:"
        log_output "  - Diretório: $HOME/.local/share/google-cloud-sdk"
        log_output "  - Entradas no PATH em: $shell_config"
        return 1
    fi

    log_output ""
    log_output "${YELLOW}Deseja remover também as configurações e credenciais? (s/N)${NC}"
    read -r response

    if [[ "$response" =~ ^[sSyY]$ ]]; then
        log_debug "Removendo configurações do gcloud..."
        rm -rf "$HOME/.config/gcloud" 2> /dev/null || true
        rm -rf "$HOME/.gsutil" 2> /dev/null || true
        log_success "Configurações removidas"
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
                shift
                ;;
            -q | --quiet)
                export SILENT=true
                shift
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
            install_gcloud
            ;;
        update)
            update_gcloud
            ;;
        uninstall)
            uninstall_gcloud
            ;;
        *)
            log_error "Ação desconhecida: $action"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
