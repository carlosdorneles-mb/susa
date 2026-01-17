#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/color.sh"

# Help function
show_help() {
    log_output "${LIGHT_GREEN}Redis CLI - Cliente de linha de comando para Redis${NC}"
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --info            Mostra informações sobre a instalação do Redis CLI"
    log_output "  --uninstall       Desinstala o Redis CLI do sistema"
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
    log_output "    redis-cli -h hostname -p port"
}

# Get latest stable version from GitHub
get_latest_version() {
    github_get_latest_version "redis/redis"
}

# Get installed redis-cli version
get_current_version() {
    if check_installation; then
        redis-cli --version 2> /dev/null | grep -oP 'v?\d+\.\d+\.\d+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if redis-cli is installed
check_installation() {
    command -v redis-cli &> /dev/null
}

# Install redis-cli on macOS
install_redis_macos() {
    log_info "Instalando Redis CLI via Homebrew..."
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado. Instale primeiro."
        return 1
    fi
    brew install redis || {
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
    sudo apt-get install -y redis-tools || {
        log_error "Falha ao instalar Redis CLI"
        return 1
    }
    return 0
}

# Install redis-cli on RedHat/CentOS/Fedora
install_redis_redhat() {
    log_info "Instalando Redis CLI no RedHat/CentOS/Fedora..."
    local pkg_manager="dnf"
    if ! command -v dnf &> /dev/null; then
        pkg_manager="yum"
    fi
    sudo $pkg_manager install -y redis || {
        log_error "Falha ao instalar Redis CLI"
        return 1
    }
    return 0
}

# Install redis-cli on Arch Linux
install_redis_arch() {
    log_info "Instalando Redis CLI no Arch Linux..."
    sudo pacman -S --noconfirm redis || {
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
    log_debug "Detectando sistema operacional..."
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local install_result=1
    case "$os_name" in
        darwin)
            log_debug "Executando: brew install redis"
            install_redis_macos
            install_result=$?
            ;;
        linux)
            local distro=$(detect_linux_distro)
            log_debug "Distribuição detectada: $distro"
            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    log_debug "Executando: sudo apt-get install -y redis-tools"
                    install_redis_debian
                    install_result=$?
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    log_debug "Executando: sudo $pkg_manager install -y redis"
                    install_redis_redhat
                    install_result=$?
                    ;;
                arch | manjaro)
                    log_debug "Executando: sudo pacman -S --noconfirm redis"
                    install_redis_arch
                    install_result=$?
                    ;;
                *)
                    log_error "Distribuição Linux não suportada: $distro"
                    log_output "Instale manualmente usando o gerenciador de pacotes da sua distribuição"
                    return 1
                    ;;
            esac
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac
    if [ $install_result -eq 0 ]; then
        if check_installation; then
            local installed_version=$(get_current_version)
            log_debug "Versão detectada após instalação: $installed_version"
            log_success "Redis CLI $installed_version instalado com sucesso!"
            register_or_update_software_in_lock "redis" "$installed_version"
            echo ""
            log_output "Teste a instalação com:"
            log_output "  ${LIGHT_CYAN}redis-cli --version${NC}"
            log_output "Para conectar a um servidor Redis:"
            log_output "  ${LIGHT_CYAN}redis-cli -h hostname -p port${NC}"
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
        log_error "Redis CLI não está instalado. Use 'susa setup redis' para instalar."
        return 1
    fi
    local current_version=$(get_current_version)
    log_info "Atualizando Redis CLI (versão atual: $current_version)..."
    log_debug "Detectando sistema operacional para atualização..."
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local update_result=1
    case "$os_name" in
        darwin)
            log_debug "Executando: brew upgrade redis"
            brew upgrade redis || {
                log_info "Redis CLI já está na versão mais recente"
            }
            update_result=0
            ;;
        linux)
            local distro=$(detect_linux_distro)
            log_debug "Distribuição detectada: $distro"
            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    log_debug "Executando: sudo apt-get install --only-upgrade -y redis-tools"
                    sudo apt-get update -qq
                    sudo apt-get install --only-upgrade -y redis-tools || {
                        log_info "Redis CLI já está na versão mais recente"
                    }
                    update_result=0
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    local pkg_manager="dnf"
                    if ! command -v dnf &> /dev/null; then
                        pkg_manager="yum"
                    fi
                    log_debug "Executando: sudo $pkg_manager upgrade -y redis"
                    sudo $pkg_manager upgrade -y redis || {
                        log_info "Redis CLI já está na versão mais recente"
                    }
                    update_result=0
                    ;;
                arch | manjaro)
                    log_debug "Executando: sudo pacman -Syu --noconfirm redis"
                    sudo pacman -Syu --noconfirm redis || {
                        log_info "Redis CLI já está na versão mais recente"
                    }
                    update_result=0
                    ;;
                *)
                    log_error "Distribuição Linux não suportada: $distro"
                    return 1
                    ;;
            esac
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac
    if [ $update_result -eq 0 ]; then
        if check_installation; then
            local new_version=$(get_current_version)
            log_debug "Versão detectada após atualização: $new_version"
            register_or_update_software_in_lock "redis" "$new_version"
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
    log_output ""
    log_output "${YELLOW}Deseja realmente desinstalar o Redis CLI $current_version? (s/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[sSyY]$ ]]; then
        log_info "Desinstalação cancelada"
        return 0
    fi
    log_info "Desinstalando Redis CLI..."
    log_debug "Detectando sistema operacional para remoção..."
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local uninstall_result=1
    case "$os_name" in
        darwin)
            log_debug "Executando: brew uninstall redis"
            brew uninstall redis || {
                log_error "Falha ao desinstalar via Homebrew"
                return 1
            }
            uninstall_result=0
            ;;
        linux)
            local distro=$(detect_linux_distro)
            log_debug "Distribuição detectada: $distro"
            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    log_debug "Executando: sudo apt-get remove -y redis-tools"
                    sudo apt-get remove -y redis-tools || {
                        log_error "Falha ao desinstalar Redis CLI"
                        return 1
                    }
                    sudo apt-get autoremove -y
                    uninstall_result=0
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    local pkg_manager="dnf"
                    if ! command -v dnf &> /dev/null; then
                        pkg_manager="yum"
                    fi
                    log_debug "Executando: sudo $pkg_manager remove -y redis"
                    sudo $pkg_manager remove -y redis || {
                        log_error "Falha ao desinstalar Redis CLI"
                        return 1
                    }
                    uninstall_result=0
                    ;;
                arch | manjaro)
                    log_debug "Executando: sudo pacman -R --noconfirm redis"
                    sudo pacman -R --noconfirm redis || {
                        log_error "Falha ao desinstalar Redis CLI"
                        return 1
                    }
                    uninstall_result=0
                    ;;
                *)
                    log_error "Distribuição Linux não suportada: $distro"
                    return 1
                    ;;
            esac
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac
    if [ $uninstall_result -eq 0 ]; then
        if ! check_installation; then
            log_debug "Removido do sistema, atualizando lock."
            remove_software_in_lock "redis"
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
                show_software_info "redis-cli"
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
