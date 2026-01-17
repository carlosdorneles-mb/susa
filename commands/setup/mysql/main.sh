#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/os.sh"

# Contants
MYSQL_CLIENT_PKG_DEBIAN="mysql-client"
MYSQL_CLIENT_PKG_REDHAT="mysql"
MYSQL_CLIENT_PKG_ARCH="mysql-clients"
MYSQL_CLIENT_PKG_HOMEBREW="mysql-client"
MYSQL_UTILS=("mysql" "mysqldump" "mysqladmin" "mysqlimport")
MYSQL_HOMEBREW_PATH="/opt/homebrew/opt/mysql-client/bin"
MYSQL_PROMPT_MSG="Deseja realmente desinstalar o MySQL Client"
MYSQL_PROMPT_CACHE="mysql --version"
MYSQL_BIN_NAME="mysql"

SKIP_CONFIRM=false
# Help function
show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  MySQL Client é o utilitário de linha de comando para interagir com servidores MySQL."
    log_output "  Inclui o comando ${MYSQL_UTILS[0]}, ${MYSQL_UTILS[1]} e outros utilitários."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --info            Mostra informações sobre a instalação do MySQL Client"
    log_output "  --uninstall       Desinstala o MySQL Client do sistema"
    log_output "  -y, --yes         Pula confirmação (usar com --uninstall)"
    log_output "  -u, --upgrade     Atualiza o MySQL Client para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup mysql              # Instala o MySQL Client"
    log_output "  susa setup mysql --upgrade    # Atualiza o MySQL Client"
    log_output "  susa setup mysql --uninstall  # Desinstala o MySQL Client"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Conectar a um servidor MySQL:"
    log_output "    mysql -h hostname -u username -p database"
    log_output ""
    log_output "${LIGHT_GREEN}Utilitários incluídos:${NC}"
    log_output "  ${MYSQL_UTILS[0]}        Cliente interativo"
    log_output "  ${MYSQL_UTILS[1]}    Backup de banco de dados"
    log_output "  ${MYSQL_UTILS[2]}   Administração do servidor"
}

# Get latest version from MySQL official repository
get_latest_version() {
    log_debug "Detectando método de instalação para obter a última versão do MySQL Client..."
    local os_name pkg_manager version
    os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            # Homebrew
            if command -v brew &> /dev/null; then
                version=$(brew info --json=v2 mysql-client | grep -oP '"versions":\s*\{[^}]*"stable":\s*"\K[0-9]+(\.[0-9]+)+' | head -1)
                log_debug "Última versão via Homebrew: $version"
                if [ -n "$version" ]; then
                    echo "$version"
                    return 0
                fi
            fi
            ;;
        linux)
            # Detect distro
            local distro="$(get_distro_id)"
            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    # apt
                    version=$(apt-cache policy mysql-client | grep Candidate | awk '{print $2}' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
                    log_debug "Última versão via apt: $version"
                    if [ -n "$version" ]; then
                        echo "$version"
                        return 0
                    fi
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    # dnf/yum
                    pkg_manager=$(get_redhat_pkg_manager)
                    version=$($pkg_manager info mysql 2> /dev/null | grep -E '^Version' | awk '{print $2}' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
                    log_debug "Última versão via $pkg_manager: $version"
                    if [ -n "$version" ]; then
                        echo "$version"
                        return 0
                    fi
                    ;;
                arch | manjaro)
                    # pacman
                    version=$(pacman -Si mysql-clients 2> /dev/null | grep Version | awk '{print $3}' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
                    log_debug "Última versão via pacman: $version"
                    if [ -n "$version" ]; then
                        echo "$version"
                        return 0
                    fi
                    ;;
            esac
            ;;
    esac

    # Fallback: buscar do site oficial
    log_debug "Não foi possível detectar via gerenciador. Buscando do site oficial."
    local version_json
    version_json=$(curl -s https://dev.mysql.com/doc/relnotes/mysql/ | grep -oP 'MySQL Community Server \K[0-9]+(\.[0-9]+)+' | head -1 | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
    log_debug "Versão mais recente detectada (site): $version_json"
    if [ -n "$version_json" ]; then
        echo "$version_json"
        return 0
    fi

    log_debug "Não foi possível obter a versão mais recente. Retornando vazio."
    echo ""
    return 1
}

# Get installed MySQL client version
get_current_version() {
    if check_installation; then
        ${MYSQL_UTILS[0]} --version 2> /dev/null | grep -oP '\d+(\.\d+){1,2}' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if MySQL client is installed
check_installation() {
    command -v ${MYSQL_UTILS[0]} &> /dev/null
}

# Show additional MySQL-specific information
show_additional_info() {
    if ! check_installation; then
        return
    fi
    local util_lines=""
    for util in "${MYSQL_UTILS[@]}"; do
        if command -v "$util" &> /dev/null; then
            util_lines+="    • $util\n"
        fi
    done
    if [ -n "$util_lines" ]; then
        log_output "  ${CYAN}Utilitários:${NC}\n$util_lines"
    fi
}

# Install MySQL client on macOS
install_mysql_macos() {
    log_info "Instalando MySQL Client via Homebrew..."
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado. Instale primeiro com:"
        log_output "  /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi
    log_debug "Obtendo versão mais recente do MySQL Client para macOS..."
    local major_version=$(get_latest_version)
    log_debug "Versão mais recente para macOS: $major_version"
    if brew list $MYSQL_CLIENT_PKG_HOMEBREW &> /dev/null 2>&1; then
        log_info "Atualizando MySQL Client via Homebrew..."
        brew upgrade $MYSQL_CLIENT_PKG_HOMEBREW || true
    else
        log_info "Instalando $MYSQL_CLIENT_PKG_HOMEBREW via Homebrew..."
        brew install $MYSQL_CLIENT_PKG_HOMEBREW
    fi
    if ! command -v ${MYSQL_UTILS[0]} &> /dev/null; then
        log_info "Configurando binários no PATH..."
        brew link --force $MYSQL_CLIENT_PKG_HOMEBREW || {
            log_warning "Não foi possível criar links automaticamente"
            log_output "Adicione manualmente ao seu PATH:"
            log_output "  export PATH=\"$MYSQL_HOMEBREW_PATH:$PATH\""
        }
    fi
    return 0
}

# Install MySQL client on Debian/Ubuntu
install_mysql_debian() {
    log_info "Instalando MySQL Client no Debian/Ubuntu..."
    log_debug "Atualizando lista de pacotes (apt)..."
    sudo apt-get update -qq || {
        log_error "Falha ao atualizar lista de pacotes"
        return 1
    }
    log_debug "Instalando mysql-client via apt..."
    log_info "Instalando mysql-client..."
    sudo apt-get install -y $MYSQL_CLIENT_PKG_DEBIAN || {
        log_error "Falha ao instalar MySQL Client"
        return 1
    }
    log_debug "Instalação via apt finalizada."
    return 0
}

# Install MySQL client on RedHat/CentOS/Fedora
install_mysql_redhat() {
    log_info "Instalando MySQL Client no RedHat/CentOS/Fedora..."
    local pkg_manager=$(get_redhat_pkg_manager)
    log_debug "Instalando mysql via $pkg_manager..."
    log_info "Instalando mysql via $pkg_manager..."
    sudo $pkg_manager install -y $MYSQL_CLIENT_PKG_REDHAT || {
        log_error "Falha ao instalar MySQL Client"
        return 1
    }
    log_debug "Instalação via $pkg_manager finalizada."
    return 0
}

# Install MySQL client on Arch Linux
install_mysql_arch() {
    log_info "Instalando MySQL Client no Arch Linux..."
    log_debug "Instalando mysql-clients via pacman..."
    log_info "Instalando mysql-clients via pacman..."
    sudo pacman -S --noconfirm $MYSQL_CLIENT_PKG_ARCH || {
        log_error "Falha ao instalar MySQL Client"
        return 1
    }
    log_debug "Instalação via pacman finalizada."
    return 0
}

# Main installation function
install_mysql() {
    if check_installation; then
        log_info "MySQL Client $(get_current_version) já está instalado."
        log_info "Use 'susa setup $COMMAND_NAME --upgrade' para atualizar."
        exit 0
    fi
    log_info "Iniciando instalação do MySQL Client..."
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local install_result=1
    case "$os_name" in
        darwin)
            install_mysql_macos
            install_result=$?
            ;;
        linux)
            local distro="$(get_distro_id)"
            log_debug "Distribuição detectada: $distro"
            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    install_mysql_debian
                    install_result=$?
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    install_mysql_redhat
                    install_result=$?
                    ;;
                arch | manjaro)
                    install_mysql_arch
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
            log_success "MySQL Client $installed_version instalado com sucesso!"
            register_or_update_software_in_lock "$COMMAND_NAME" "$installed_version"
            echo ""
            log_output "Teste a instalação com:"
            log_output "  ${LIGHT_CYAN}$MYSQL_PROMPT_CACHE${NC}"
            log_output ""
            log_output "Para conectar a um servidor MySQL:"
            log_output "  ${LIGHT_CYAN}${MYSQL_UTILS[0]} -h hostname -u username -p database${NC}"
        else
            log_error "MySQL Client foi instalado mas não está disponível no PATH"
            if [ "$os_name" = "darwin" ]; then
                log_output ""
                log_output "No macOS, você pode precisar adicionar ao PATH:"
                log_output "  export PATH=\"$MYSQL_HOMEBREW_PATH:$PATH\""
                log_output ""
                log_output "Adicione esta linha ao seu ~/.zshrc ou ~/.bashrc"
            fi
            return 1
        fi
    else
        return $install_result
    fi
}

# Update MySQL client
update_mysql() {
    if ! check_installation; then
        log_error "MySQL Client não está instalado. Use 'susa setup $COMMAND_NAME' para instalar."
        return 1
    fi
    local current_version=$(get_current_version)
    log_debug "Versão atual detectada: $current_version"
    log_info "Atualizando MySQL Client (versão atual: $current_version)..."
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local update_result=1
    case "$os_name" in
        darwin)
            log_info "Atualizando via Homebrew..."
            brew upgrade $MYSQL_CLIENT_PKG_HOMEBREW || {
                log_info "MySQL Client já está na versão mais recente"
            }
            update_result=0
            ;;
        linux)
            local distro="$(get_distro_id)"
            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    log_info "Atualizando via apt..."
                    sudo apt-get update -qq
                    sudo apt-get install --only-upgrade -y $MYSQL_CLIENT_PKG_DEBIAN || {
                        log_info "MySQL Client já está na versão mais recente"
                    }
                    update_result=0
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    local pkg_manager=$(get_redhat_pkg_manager)
                    log_info "Atualizando via $pkg_manager..."
                    sudo $pkg_manager upgrade -y $MYSQL_CLIENT_PKG_REDHAT || {
                        log_info "MySQL Client já está na versão mais recente"
                    }
                    update_result=0
                    ;;
                arch | manjaro)
                    log_info "Atualizando via pacman..."
                    sudo pacman -Syu --noconfirm $MYSQL_CLIENT_PKG_ARCH || {
                        log_info "MySQL Client já está na versão mais recente"
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
            register_or_update_software_in_lock "$COMMAND_NAME" "$new_version"
            if [ "$new_version" != "$current_version" ]; then
                log_success "MySQL Client atualizado de $current_version para $new_version!"
            else
                log_info "MySQL Client já está na versão mais recente ($current_version)"
            fi
        else
            log_error "Falha na atualização do MySQL Client"
            return 1
        fi
    else
        return $update_result
    fi
}

# Uninstall MySQL client
uninstall_mysql() {
    if ! check_installation; then
        log_info "MySQL Client não está instalado"
        return 0
    fi
    local current_version=$(get_current_version)
    log_debug "Versão instalada detectada para remoção: $current_version"

    if [ "$SKIP_CONFIRM" = false ]; then
        log_output ""
        log_output "${YELLOW}$MYSQL_PROMPT_MSG $current_version? (s/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Desinstalação cancelada"
            return 0
        fi
    fi
    log_info "Desinstalando MySQL Client..."
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local uninstall_result=1
    case "$os_name" in
        darwin)
            log_info "Desinstalando via Homebrew..."
            brew uninstall $MYSQL_CLIENT_PKG_HOMEBREW || {
                log_error "Falha ao desinstalar via Homebrew"
                return 1
            }
            uninstall_result=0
            ;;
        linux)
            local distro="$(get_distro_id)"
            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    log_info "Desinstalando via apt..."
                    sudo apt-get remove -y $MYSQL_CLIENT_PKG_DEBIAN || {
                        log_error "Falha ao desinstalar MySQL Client"
                        return 1
                    }
                    sudo apt-get autoremove -y
                    uninstall_result=0
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    local pkg_manager=$(get_redhat_pkg_manager)
                    log_info "Desinstalando via $pkg_manager..."
                    sudo $pkg_manager remove -y $MYSQL_CLIENT_PKG_REDHAT || {
                        log_error "Falha ao desinstalar MySQL Client"
                        return 1
                    }
                    uninstall_result=0
                    ;;
                arch | manjaro)
                    log_info "Desinstalando via pacman..."
                    sudo pacman -R --noconfirm $MYSQL_CLIENT_PKG_ARCH || {
                        log_error "Falha ao desinstalar MySQL Client"
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
            remove_software_in_lock "$COMMAND_NAME"
            log_success "MySQL Client desinstalado com sucesso!"
        else
            log_error "Falha ao desinstalar MySQL Client completamente"
            return 1
        fi
    else
        return $uninstall_result
    fi
}

# Main function
main() {
    local action="install"
    # First parse for global flags
    for arg in "$@"; do
        case "$arg" in
            -v | --verbose)
                export DEBUG=true
                ;;
            -q | --quiet)
                export SILENT=true
                ;;
        esac
    done

    # Parse dos argumentos e ações
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                show_help
                exit 0
                ;;
            -v | --verbose)
                shift
                ;;
            -q | --quiet)
                shift
                ;;
            --info)
                show_software_info $MYSQL_BIN_NAME
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
            install_mysql
            ;;
        update)
            update_mysql
            ;;
        uninstall)
            uninstall_mysql
            ;;
        *)
            log_error "Ação desconhecida: $action"
            exit 1
            ;;
    esac
}

main "$@"
