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
    log_output "  Docker é a plataforma líder em containers para desenvolvimento,"
    log_output "  empacotamento e execução de aplicações. Esta instalação inclui"
    log_output "  apenas o Docker CLI e Engine, sem o Docker Desktop."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --info            Mostra informações sobre a instalação do Docker"
    log_output "  --uninstall       Desinstala o Docker do sistema"
    log_output "  -u, --upgrade     Atualiza o Docker para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup docker              # Instala o Docker"
    log_output "  susa setup docker --upgrade    # Atualiza o Docker"
    log_output "  susa setup docker --uninstall  # Desinstala o Docker"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Após a instalação, faça logout e login novamente para que"
    log_output "  as permissões do grupo docker sejam aplicadas, ou execute:"
    log_output "    newgrp docker"
}

get_latest_version() {
    # Get latest version from GitHub releases (format: docker-v29.1.4)
    local version_tag
    version_tag=$(github_get_latest_version "moby/moby")

    if [ $? -eq 0 ] && [ -n "$version_tag" ]; then
        # Remove "docker-v" prefix to get just the version number
        local version="${version_tag#docker-v}"
        echo "$version"
        return 0
    fi

    log_error "Não foi possível obter a versão mais recente do Docker"
    log_error "Verifique sua conexão com a internet e tente novamente"
    return 1
}

# Get installed Docker version
get_current_version() {
    if check_installation; then
        docker --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if Docker is installed
check_installation() {
    command -v docker &> /dev/null
}

# Show additional Docker-specific information
# It's called by show_software_info() in the base script
show_additional_info() {
    # Check if Docker daemon is running
    if docker info &> /dev/null; then
        log_output "  ${CYAN}Daemon:${NC} ${GREEN}Executando${NC}"
    else
        log_output "  ${CYAN}Daemon:${NC} ${RED}Parado${NC}"
    fi

    # Show Docker Compose version if available
    if check_installation; then
        local compose_version=$(docker compose version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [ -n "$compose_version" ]; then
            log_output "  ${CYAN}Docker Compose:${NC} $compose_version"
        fi
    fi
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
        x86_64) arch="x86_64" ;;
        aarch64 | arm64) arch="aarch64" ;;
        armv7l) arch="armhf" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    echo "${os_name}:${arch}"
}

# Configure user to run Docker without sudo
configure_docker_group() {
    # Check if docker group exists
    if ! getent group docker &> /dev/null; then
        if ! sudo groupadd docker 2> /dev/null; then
            log_error "Falha ao criar grupo docker"
            return 1
        fi
    fi

    # Add current user to docker group
    local current_user=$(whoami)
    if ! groups "$current_user" | grep -q docker; then
        log_debug "Adicionando usuário $current_user ao grupo docker..."
        if ! sudo usermod -aG docker "$current_user" 2> /dev/null; then
            log_error "Falha ao adicionar usuário ao grupo docker"
            return 1
        fi
    else
        log_debug "Usuário já está no grupo docker"
    fi

    return 0
}

# Install Docker on macOS using Homebrew
install_docker_macos() {
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL $DOCKER_HOMEBREW_INSTALL_URL)\""
        return 1
    fi

    # Install or upgrade Docker
    if brew list docker &> /dev/null; then
        brew upgrade docker || true
    else
        brew install docker
    fi

    # Install docker-compose if not present
    if ! brew list docker-compose &> /dev/null 2>&1; then
        brew install docker-compose || log_debug "docker-compose não disponível via brew"
    fi

    return 0
}

# Install Docker on Linux
install_docker_linux() {
    # Detect Linux distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        local distro=$ID
        log_debug "Distribuição detectada: $distro"
    else
        log_error "Não foi possível detectar a distribuição Linux"
        return 1
    fi

    case "$distro" in
        ubuntu | debian | pop | linuxmint)
            install_docker_debian
            ;;
        fedora | rhel | centos | rocky | almalinux)
            install_docker_rhel
            ;;
        arch | manjaro)
            install_docker_arch
            ;;
        *)
            log_error "Distribuição não suportada: $distro"
            log_info "Visite https://docs.docker.com/engine/install/ para instruções manuais"
            return 1
            ;;
    esac

    local install_result=$?
    if [ $install_result -ne 0 ]; then
        return $install_result
    fi

    # Start and enable Docker service
    sudo systemctl enable docker > /dev/null 2>&1 || log_debug "Não foi possível habilitar serviço"
    sudo systemctl start docker > /dev/null 2>&1 || log_debug "Não foi possível iniciar serviço"

    # Configure user permissions
    configure_docker_group

    return 0
}

# Install Docker on Debian/Ubuntu based systems
install_docker_debian() {
    # Remove old versions
    sudo apt-get remove -y docker docker-engine docker.io containerd runc > /dev/null 2>&1 || true

    # Update package index
    sudo apt-get update > /dev/null 2>&1

    # Install dependencies
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release > /dev/null 2>&1

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    local distro
    distro=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    curl -fsSL "$DOCKER_DOWNLOAD_BASE_URL/linux/${distro}/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg > /dev/null 2>&1
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] $DOCKER_DOWNLOAD_BASE_URL/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') \
      $(lsb_release -cs) stable" |
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update package index again
    sudo apt-get update > /dev/null 2>&1

    # Install Docker Engine
    sudo apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin > /dev/null 2>&1

    return $?
}

# Install Docker on RHEL/Fedora based systems
install_docker_rhel() {
    # Remove old versions
    sudo dnf remove -y docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-engine > /dev/null 2>&1 || true

    # Install dependencies
    sudo dnf install -y dnf-plugins-core > /dev/null 2>&1

    # Add Docker repository
    sudo dnf config-manager --add-repo $DOCKER_DOWNLOAD_BASE_URL/linux/fedora/docker-ce.repo > /dev/null 2>&1

    # Install Docker Engine
    sudo dnf install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin > /dev/null 2>&1

    return $?
}

# Install Docker on Arch based systems
install_docker_arch() {
    # Install Docker
    sudo pacman -S --noconfirm docker docker-compose > /dev/null 2>&1

    return $?
}

# Main installation function
install_docker() {
    if check_installation; then
        log_info "Docker $(get_current_version) já está instalado."
        exit 0
    fi

    log_info "Iniciando instalação do Docker..."

    # Detect OS
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            install_docker_macos
            ;;
        linux)
            install_docker_linux
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

            # Mark as installed in lock file
            register_or_update_software_in_lock "docker" "$installed_version"

            log_success "Docker $installed_version instalado com sucesso!"
        else
            log_error "Docker foi instalado mas não está disponível no PATH"
            return 1
        fi
    else
        return $install_result
    fi
}

# Update Docker
update_docker() {
    # Check if Docker is installed
    if ! check_installation; then
        log_error "Docker não está instalado. Use 'susa setup docker' para instalar."
        return 1
    fi

    local current_version=$(get_current_version)

    # Get latest version
    local docker_version=$(get_latest_version)
    if [ $? -ne 0 ] || [ -z "$docker_version" ]; then
        return 1
    fi

    if [ "$current_version" = "$docker_version" ]; then
        log_info "Você já possui a versão mais recente instalada ($current_version)"
        return 0
    fi

    log_info "Atualizando Docker..."

    # Detect OS and update
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            if ! command -v brew &> /dev/null; then
                log_error "Homebrew não está instalado"
                return 1
            fi

            brew upgrade docker || {
                log_error "Falha ao atualizar Docker"
                return 1
            }

            # Update docker-compose if installed
            if brew list docker-compose &> /dev/null 2>&1; then
                brew upgrade docker-compose || log_debug "docker-compose já está atualizado"
            fi
            ;;
        linux)
            # Detect Linux distribution
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                local distro=$ID
                log_debug "Distribuição detectada: $distro"
            else
                log_error "Não foi possível detectar a distribuição Linux"
                return 1
            fi

            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    sudo apt-get update > /dev/null 2>&1
                    sudo apt-get install --only-upgrade -y \
                        docker-ce \
                        docker-ce-cli \
                        containerd.io \
                        docker-buildx-plugin \
                        docker-compose-plugin > /dev/null 2>&1
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    sudo dnf upgrade -y \
                        docker-ce \
                        docker-ce-cli \
                        containerd.io \
                        docker-buildx-plugin \
                        docker-compose-plugin > /dev/null 2>&1
                    ;;
                arch | manjaro)
                    sudo pacman -Syu --noconfirm docker docker-compose > /dev/null 2>&1
                    ;;
                *)
                    log_error "Distribuição não suportada: $distro"
                    return 1
                    ;;
            esac
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
        register_or_update_software_in_lock "docker" "$new_version"

        log_success "Docker atualizado com sucesso para versão $new_version!"
    else
        log_error "Falha na atualização do Docker"
        return 1
    fi
}

# Uninstall Docker
uninstall_docker() {
    # Check if Docker is installed
    if ! check_installation; then
        log_info "Docker não está instalado"
        return 0
    fi

    local current_version=$(get_current_version)

    log_output ""
    log_output "${YELLOW}Deseja realmente desinstalar o Docker $current_version? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sSyY]$ ]]; then
        log_info "Desinstalação cancelada"
        return 0
    fi

    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            # Uninstall via Homebrew
            if command -v brew &> /dev/null; then
                brew uninstall docker 2> /dev/null || log_debug "Docker não instalado via Homebrew"
                brew uninstall docker-compose 2> /dev/null || log_debug "docker-compose não instalado"
            fi
            ;;
        linux)
            # Detect Linux distribution
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                local distro=$ID
                log_debug "Distribuição detectada: $distro"
            else
                log_error "Não foi possível detectar a distribuição Linux"
                return 1
            fi

            # Stop Docker service
            sudo systemctl stop docker > /dev/null 2>&1 || log_debug "Serviço já parado"
            sudo systemctl disable docker > /dev/null 2>&1 || log_debug "Serviço não estava habilitado"

            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    sudo apt-get purge -y \
                        docker-ce \
                        docker-ce-cli \
                        containerd.io \
                        docker-buildx-plugin \
                        docker-compose-plugin > /dev/null 2>&1
                    sudo apt-get autoremove -y > /dev/null 2>&1
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    sudo dnf remove -y \
                        docker-ce \
                        docker-ce-cli \
                        containerd.io \
                        docker-buildx-plugin \
                        docker-compose-plugin > /dev/null 2>&1
                    ;;
                arch | manjaro)
                    sudo pacman -Rns --noconfirm docker docker-compose > /dev/null 2>&1
                    ;;
            esac

            # Remove user from docker group
            local current_user=$(whoami)
            if groups "$current_user" | grep -q docker; then
                sudo gpasswd -d "$current_user" docker > /dev/null 2>&1 || log_debug "Não foi possível remover do grupo"
            fi
            ;;
    esac

    # Verify uninstallation
    if ! check_installation; then
        # Mark as uninstalled in lock file
        remove_software_in_lock "docker"

        log_success "Docker desinstalado com sucesso!"
    else
        log_error "Falha ao desinstalar Docker completamente"
        return 1
    fi

    log_output ""
    log_output "${YELLOW}Deseja remover também as imagens, containers e volumes do Docker? (s/N)${NC}"
    read -r response

    if [[ "$response" =~ ^[sSyY]$ ]]; then
        log_debug "Removendo dados do Docker..."
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
            install_docker
            ;;
        update)
            update_docker
            ;;
        uninstall)
            uninstall_docker
            ;;
        *)
            log_error "Ação desconhecida: $action"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
