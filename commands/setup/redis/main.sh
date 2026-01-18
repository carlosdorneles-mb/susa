#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/os.sh"

# Contants
REDIS_CLI_BIN_NAME="redis-cli"
REDIS_PKG_MACOS="redis"
REDIS_PKG_DEBIAN="redis-tools"
REDIS_PKG_REDHAT="redis"
REDIS_PKG_ARCH="redis"
SKIP_CONFIRM=false

# Help function
show_help() {
    log_output "${LIGHT_GREEN}Redis CLI - Cliente de linha de comando para Redis${NC}"
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --info            Mostra informações sobre a instalação do Redis CLI"
    log_output "  --uninstall       Desinstala o Redis CLI do sistema"
    log_output "  -y, --yes         Pula confirmação (usar com --uninstall)"
    log_output "  -u, --upgrade     Atualiza o Redis CLI para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup redis              # Instala o Redis CLI"
    log_output "  susa setup redis --upgrade    # Atualiza o Redis CLI"
    log_output "  susa setup redis --uninstall  # Remove o Redis CLI"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Conectar a um servidor Redis:"
    log_output "    $REDIS_CLI_BIN_NAME -h hostname -p port"
}

# Get latest stable version from GitHub
get_latest_version() {
    github_get_latest_version "redis/redis"
}

# Get installed redis-cli version
get_current_version() {
    if check_installation; then
        $REDIS_CLI_BIN_NAME --version 2> /dev/null | grep -oP 'v?\d+\.\d+\.\d+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if redis-cli is installed
check_installation() {
    command -v $REDIS_CLI_BIN_NAME &> /dev/null
}

# Install redis-cli on macOS
install_redis_macos() {
    log_info "Instalando Redis CLI via Homebrew..."
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado. Instale primeiro."
        return 1
    fi
    brew install $REDIS_PKG_MACOS || {
        log_error "Falha ao instalar Redis CLI via Homebrew"
        return 1
    }
    return 0
}

# Install redis-cli on Debian/Ubuntu
install_redis_debian() {
    log_info "Instalando Redis CLI no Debian/Ubuntu..."
    sudo apt-get update -qq || {
        log_error "Falha ao atualizar lista de pacotes"
        return 1
    }
    sudo apt-get install -y $REDIS_PKG_DEBIAN || {
        log_error "Falha ao instalar Redis CLI"
        return 1
    }
    return 0
}

# Install redis-cli on RedHat/CentOS/Fedora
install_redis_redhat() {
    log_info "Instalando Redis CLI no RedHat/CentOS/Fedora..."
    local pkg_manager=$(get_redhat_pkg_manager)
    sudo $pkg_manager install -y $REDIS_PKG_REDHAT || {
        log_error "Falha ao instalar Redis CLI"
        return 1
    }
    return 0
}

# Install redis-cli on Arch Linux
install_redis_arch() {
    log_info "Instalando Redis CLI no Arch Linux..."
    sudo pacman -S --noconfirm $REDIS_PKG_ARCH || {
        log_error "Falha ao instalar Redis CLI"
        return 1
    }
    return 0
}

# Main installation function
install_redis() {
    if check_installation; then
        log_info "Redis CLI $(get_current_version) já está instalado. Use --upgrade para atualizar."
        exit 0
    fi
    log_info "Iniciando instalação do Redis CLI..."
    log_debug "Sistema operacional: $OS_TYPE"
    local install_result=1
    case "$OS_TYPE" in
        macos)
            log_debug "Executando: brew install redis"
            install_redis_macos
            install_result=$?
            ;;
        debian)
            log_debug "Executando: sudo apt-get install -y redis-tools"
            install_redis_debian
            install_result=$?
            ;;
        fedora)
            log_debug "Executando: sudo dnf/yum install -y redis"
            install_redis_redhat
            install_result=$?
            ;;
        *)
            # Check for Arch-based distros
            if is_arch; then
                log_debug "Distribuição detectada: Arch-based"
                log_debug "Executando: sudo pacman -S --noconfirm redis"
                install_redis_arch
                install_result=$?
            else
                log_error "Distribuição Linux não suportada: $(get_distro_id)"
                log_output "Instale manualmente usando o gerenciador de pacotes da sua distribuição"
                return 1
            fi
            ;;
    esac
    if [ $install_result -eq 0 ]; then
        if check_installation; then
            local installed_version=$(get_current_version)
            log_debug "Versão detectada após instalação: $installed_version"
            log_success "Redis CLI $installed_version instalado com sucesso!"
            register_or_update_software_in_lock "$COMMAND_NAME" "$installed_version"
            echo ""
            log_output "Teste a instalação com:"
            log_output "  ${LIGHT_CYAN}$REDIS_CLI_BIN_NAME --version${NC}"
            log_output "Para conectar a um servidor Redis:"
            log_output "  ${LIGHT_CYAN}$REDIS_CLI_BIN_NAME -h hostname -p port${NC}"
        else
            log_error "Redis CLI foi instalado mas não está disponível no PATH"
            return 1
        fi
    else
        log_debug "Falha na instalação, código de saída: $install_result"
        return $install_result
    fi
}

# Update redis-cli
update_redis() {
    if ! check_installation; then
        log_error "Redis CLI não está instalado. Use 'susa setup $COMMAND_NAME' para instalar."
        return 1
    fi
    local current_version=$(get_current_version)
    log_info "Atualizando Redis CLI (versão atual: $current_version)..."
    log_debug "Sistema operacional: $OS_TYPE"
    local update_result=1
    case "$OS_TYPE" in
        macos)
            log_debug "Executando: brew upgrade $REDIS_PKG_MACOS"
            brew upgrade $REDIS_PKG_MACOS || {
                log_info "Redis CLI já está na versão mais recente"
            }
            update_result=0
            ;;
        debian)
            log_debug "Executando: sudo apt-get install --only-upgrade -y $REDIS_PKG_DEBIAN"
            sudo apt-get update -qq
            sudo apt-get install --only-upgrade -y $REDIS_PKG_DEBIAN || {
                log_info "Redis CLI já está na versão mais recente"
            }
            update_result=0
            ;;
        fedora)
            local pkg_manager=$(get_redhat_pkg_manager)
            log_debug "Executando: sudo $pkg_manager upgrade -y $REDIS_PKG_REDHAT"
            sudo $pkg_manager upgrade -y $REDIS_PKG_REDHAT || {
                log_info "Redis CLI já está na versão mais recente"
            }
            update_result=0
            ;;
        *)
            # Check for Arch-based distros
            if is_arch; then
                log_debug "Distribuição detectada: Arch-based"
                log_debug "Executando: sudo pacman -Syu --noconfirm $REDIS_PKG_ARCH"
                sudo pacman -Syu --noconfirm $REDIS_PKG_ARCH || {
                    log_info "Redis CLI já está na versão mais recente"
                }
                update_result=0
            else
                log_error "Distribuição Linux não suportada: $(get_distro_id)"
                return 1
            fi
            ;;
    esac
    if [ $update_result -eq 0 ]; then
        if check_installation; then
            local new_version=$(get_current_version)
            log_debug "Versão detectada após atualização: $new_version"
            register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"
            if [ "$new_version" != "$current_version" ]; then
                log_success "Redis CLI atualizado de $current_version para $new_version!"
            else
                log_info "Redis CLI já está na versão mais recente ($current_version)"
            fi
        else
            log_error "Falha na atualização do Redis CLI"
            return 1
        fi
    else
        log_debug "Falha na atualização, código de saída: $update_result"
        return $update_result
    fi
}

# Uninstall redis-cli
uninstall_redis() {
    if ! check_installation; then
        log_info "Redis CLI não está instalado"
        return 0
    fi
    local current_version=$(get_current_version)

    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}Deseja realmente desinstalar o Redis CLI $current_version? (s/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi
    log_info "Desinstalando Redis CLI..."
    log_debug "Sistema operacional: $OS_TYPE"
    local uninstall_result=1
    case "$OS_TYPE" in
        macos)
            log_debug "Executando: brew uninstall redis"
            brew uninstall redis || {
                log_error "Falha ao desinstalar via Homebrew"
                return 1
            }
            uninstall_result=0
            ;;
        debian)
            log_debug "Executando: sudo apt-get remove -y redis-tools"
            sudo apt-get remove -y redis-tools || {
                log_error "Falha ao desinstalar Redis CLI"
                return 1
            }
            sudo apt-get autoremove -y
            uninstall_result=0
            ;;
        fedora)
            local pkg_manager=$(get_redhat_pkg_manager)
            log_debug "Executando: sudo $pkg_manager remove -y redis"
            sudo $pkg_manager remove -y redis || {
                log_error "Falha ao desinstalar Redis CLI"
                return 1
            }
            uninstall_result=0
            ;;
        *)
            # Check for Arch-based distros
            if is_arch; then
                log_debug "Distribuição detectada: Arch-based"
                log_debug "Executando: sudo pacman -R --noconfirm redis"
                sudo pacman -R --noconfirm redis || {
                    log_error "Falha ao desinstalar Redis CLI"
                    return 1
                }
                uninstall_result=0
            else
                log_error "Distribuição Linux não suportada: $(get_distro_id)"
                return 1
            fi
            ;;
    esac
    if [ $uninstall_result -eq 0 ]; then
        if ! check_installation; then
            log_debug "Removido do sistema, atualizando lock."
            remove_software_in_lock "$COMMAND_NAME"
            log_success "Redis CLI desinstalado com sucesso!"
        else
            log_error "Falha ao desinstalar Redis CLI completamente"
            return 1
        fi
    else
        log_debug "Falha na remoção, código de saída: $uninstall_result"
        return $uninstall_result
    fi
}

# Main function
main() {
    local action="install"
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
                show_software_info "$REDIS_CLI_BIN_NAME"
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
                show_help
                exit 1
                ;;
        esac
    done
    case "$action" in
        install)
            install_redis
            ;;
        update)
            update_redis
            ;;
        uninstall)
            uninstall_redis
            ;;
        *)
            log_error "Ação desconhecida: $action"
            exit 1
            ;;
    esac
}

main "$@"
