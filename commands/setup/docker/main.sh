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
    log_output "  Docker é a plataforma líder em containers para desenvolvimento,"
    log_output "  empacotamento e execução de aplicações. Esta instalação inclui"
    log_output "  apenas o Docker CLI e Engine, sem o Docker Desktop."
    echo ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o Docker do sistema"
    log_output "  --update          Atualiza o Docker para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    echo ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup docker              # Instala o Docker"
    log_output "  susa setup docker --update     # Atualiza o Docker"
    log_output "  susa setup docker --uninstall  # Desinstala o Docker"
    echo ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Após a instalação, faça logout e login novamente para que"
    log_output "  as permissões do grupo docker sejam aplicadas, ou execute:"
    echo "    newgrp docker"
    echo ""
    log_output "${LIGHT_GREEN}Próximos passos:${NC}"
    log_output "  docker --version               # Verifica a instalação"
    log_output "  docker run hello-world         # Teste com container simples"
    log_output "  docker images                  # Lista imagens disponíveis"
    log_output "  docker ps                      # Lista containers em execução"
}

get_latest_docker_version() {
    # Try to get the latest version via GitHub API (format: docker-v29.1.4)
    local latest_version=$(curl -s --max-time 10 --connect-timeout 5 https://api.github.com/repos/moby/moby/releases/latest 2> /dev/null | grep '"tag_name":' | sed -E 's/.*"docker-v([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via API do GitHub: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    # If it fails, try via git ls-remote with semantic version sorting
    log_debug "API do GitHub falhou, tentando via git ls-remote..." >&2
    latest_version=$(timeout ${DOCKER_GIT_TIMEOUT:-5} git ls-remote --tags --refs ${DOCKER_GITHUB_REPO_URL:-https://github.com/moby/moby.git} 2> /dev/null |
        grep 'docker-v' |
        grep -v '\-rc' |
        grep -oE 'docker-v[0-9]+\.[0-9]+\.[0-9]+$' |
        sed 's/docker-v//' |
        sort -V |
        tail -1)

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via git ls-remote: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    # If both methods fail, notify user
    log_error "Não foi possível obter a versão mais recente do Docker" >&2
    log_error "Verifique sua conexão com a internet e tente novamente" >&2
    return 1
}

# Get installed Docker version
get_docker_version() {
    if command -v docker &> /dev/null; then
        docker --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Check if Docker is already installed
check_existing_installation() {
    log_debug "Verificando instalação existente do Docker..."

    if ! command -v docker &> /dev/null; then
        log_debug "Docker não está instalado"
        return 0
    fi

    local current_version=$(get_docker_version)
    log_info "Docker $current_version já está instalado."

    # Mark as installed in lock file
    mark_installed "docker" "$current_version"

    # Check for updates
    log_debug "Obtendo última versão..."
    local latest_version=$(get_latest_docker_version)
    if [ $? -eq 0 ] && [ -n "$latest_version" ]; then
        if [ "$current_version" != "$latest_version" ]; then
            echo ""
            log_output "${YELLOW}Nova versão disponível ($latest_version).${NC}"
            log_output "Para atualizar, execute: ${LIGHT_CYAN}susa setup docker --update${NC}"
        fi
    else
        log_warning "Não foi possível verificar atualizações"
    fi

    return 1
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

    log_output "${os_name}:${arch}"
}

# Configure user to run Docker without sudo
configure_docker_group() {
    log_info "Configurando permissões do Docker..."

    # Check if docker group exists
    if ! getent group docker &> /dev/null; then
        log_debug "Criando grupo docker..."
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
        log_info "Usuário adicionado ao grupo docker. Faça logout/login ou execute: newgrp docker"
    else
        log_debug "Usuário já está no grupo docker"
    fi

    return 0
}

# Install Docker on macOS using Homebrew
install_docker_macos() {
    log_info "Instalando Docker no macOS..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew não está instalado. Instale-o primeiro:"
        log_output "  /bin/bash -c \"\$(curl -fsSL ${DOCKER_HOMEBREW_INSTALL_URL:-https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh})\""
        return 1
    fi

    # Install or upgrade Docker
    if brew list docker &> /dev/null; then
        log_info "Atualizando Docker via Homebrew..."
        brew upgrade docker || true
    else
        log_info "Instalando Docker via Homebrew..."
        brew install docker
    fi

    # Install docker-compose if not present
    if ! brew list docker-compose &> /dev/null 2>&1; then
        log_info "Instalando docker-compose..."
        brew install docker-compose || log_debug "docker-compose não disponível via brew"
    fi

    log_info "Nota: No macOS, você precisará do Docker Desktop ou colima para executar containers."
    log_info "Para usar sem Docker Desktop, instale colima: brew install colima"
    log_info "Inicie colima com: colima start"

    return 0
}

# Install Docker on Linux
install_docker_linux() {
    log_info "Instalando Docker no Linux..."

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
    log_info "Habilitando e iniciando serviço Docker..."
    sudo systemctl enable docker > /dev/null 2>&1 || log_debug "Não foi possível habilitar serviço"
    sudo systemctl start docker > /dev/null 2>&1 || log_debug "Não foi possível iniciar serviço"

    # Configure user permissions
    configure_docker_group

    return 0
}

# Install Docker on Debian/Ubuntu based systems
install_docker_debian() {
    log_debug "Instalando Docker em sistema baseado em Debian/Ubuntu..."

    # Remove old versions
    log_info "Removendo versões antigas do Docker..."
    sudo apt-get remove -y docker docker-engine docker.io containerd runc > /dev/null 2>&1 || true

    # Update package index
    log_info "Atualizando índice de pacotes..."
    sudo apt-get update > /dev/null 2>&1

    # Install dependencies
    log_info "Instalando dependências..."
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release > /dev/null 2>&1

    # Add Docker's official GPG key
    log_info "Adicionando chave GPG do Docker..."
    sudo install -m 0755 -d /etc/apt/keyrings
    local distro
    distro=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    curl -fsSL "${DOCKER_DOWNLOAD_BASE_URL:-https://download.docker.com}/linux/${distro}/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg > /dev/null 2>&1
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up repository
    log_info "Configurando repositório do Docker..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] ${DOCKER_DOWNLOAD_BASE_URL:-https://download.docker.com}/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') \
      $(lsb_release -cs) stable" |
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update package index again
    sudo apt-get update > /dev/null 2>&1

    # Install Docker Engine
    log_info "Instalando Docker Engine, CLI e plugins..."
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
    log_debug "Instalando Docker em sistema baseado em RHEL/Fedora..."

    # Remove old versions
    log_info "Removendo versões antigas do Docker..."
    sudo dnf remove -y docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-engine > /dev/null 2>&1 || true

    # Install dependencies
    log_info "Instalando dependências..."
    sudo dnf install -y dnf-plugins-core > /dev/null 2>&1

    # Add Docker repository
    log_info "Adicionando repositório do Docker..."
    sudo dnf config-manager --add-repo ${DOCKER_DOWNLOAD_BASE_URL:-https://download.docker.com}/linux/fedora/docker-ce.repo > /dev/null 2>&1

    # Install Docker Engine
    log_info "Instalando Docker Engine, CLI e plugins..."
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
    log_debug "Instalando Docker em sistema baseado em Arch..."

    # Install Docker
    log_info "Instalando Docker via pacman..."
    sudo pacman -S --noconfirm docker docker-compose > /dev/null 2>&1

    return $?
}

# Main installation function
install_docker() {
    if ! check_existing_installation; then
        exit 0
    fi

    log_info "Iniciando instalação do Docker..."

    # Detect OS
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    log_debug "SO: $os_name"

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
        if command -v docker &> /dev/null; then
            local installed_version=$(get_docker_version)

            # Mark as installed in lock file
            mark_installed "docker" "$installed_version"

            log_success "Docker $installed_version instalado com sucesso!"
            log_debug "Executável: $(which docker)"
            echo ""
            echo "Próximos passos:"

            if [ "$os_name" = "darwin" ]; then
                log_output "  1. Instale colima: ${LIGHT_CYAN}brew install colima${NC}"
                log_output "  2. Inicie colima: ${LIGHT_CYAN}colima start${NC}"
                log_output "  3. Execute: ${LIGHT_CYAN}docker run hello-world${NC}"
            else
                log_output "  1. Faça logout e login novamente, ou execute: ${LIGHT_CYAN}newgrp docker${NC}"
                log_output "  2. Execute: ${LIGHT_CYAN}docker run hello-world${NC}"
                log_output "  3. Use ${LIGHT_CYAN}susa setup docker --help${NC} para mais informações"
            fi
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
    log_info "Atualizando Docker..."

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker não está instalado. Use 'susa setup docker' para instalar."
        return 1
    fi

    local current_version=$(get_docker_version)
    log_info "Versão atual: $current_version"
    log_debug "Executável: $(which docker)"

    # Get latest version
    log_debug "Obtendo última versão..."
    local docker_version=$(get_latest_docker_version)
    if [ $? -ne 0 ] || [ -z "$docker_version" ]; then
        return 1
    fi

    if [ "$current_version" = "$docker_version" ]; then
        log_info "Você já possui a versão mais recente instalada ($current_version)"
        return 0
    fi

    log_info "Atualizando de $current_version para $docker_version..."

    # Detect OS and update
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            if ! command -v brew &> /dev/null; then
                log_error "Homebrew não está instalado"
                return 1
            fi

            log_info "Atualizando Docker via Homebrew..."
            brew upgrade docker || {
                log_error "Falha ao atualizar Docker"
                return 1
            }

            # Update docker-compose if installed
            if brew list docker-compose &> /dev/null 2>&1; then
                log_info "Atualizando docker-compose..."
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
                    log_info "Atualizando Docker via apt..."
                    sudo apt-get update > /dev/null 2>&1
                    sudo apt-get install --only-upgrade -y \
                        docker-ce \
                        docker-ce-cli \
                        containerd.io \
                        docker-buildx-plugin \
                        docker-compose-plugin > /dev/null 2>&1
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    log_info "Atualizando Docker via dnf..."
                    sudo dnf upgrade -y \
                        docker-ce \
                        docker-ce-cli \
                        containerd.io \
                        docker-buildx-plugin \
                        docker-compose-plugin > /dev/null 2>&1
                    ;;
                arch | manjaro)
                    log_info "Atualizando Docker via pacman..."
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
    if command -v docker &> /dev/null; then
        local new_version=$(get_docker_version)

        # Update version in lock file
        update_version "docker" "$new_version"

        log_success "Docker atualizado com sucesso para versão $new_version!"
        log_debug "Executável: $(which docker)"
    else
        log_error "Falha na atualização do Docker"
        return 1
    fi
}

# Uninstall Docker
uninstall_docker() {
    log_info "Desinstalando Docker..."

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_info "Docker não está instalado"
        return 0
    fi

    local current_version=$(get_docker_version)
    log_debug "Versão a ser removida: $current_version"
    log_debug "Executável: $(which docker)"

    echo ""
    log_output "${YELLOW}Deseja realmente desinstalar o Docker $current_version? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sS]$ ]]; then
        log_info "Desinstalação cancelada"
        return 0
    fi

    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            # Uninstall via Homebrew
            if command -v brew &> /dev/null; then
                log_info "Removendo Docker via Homebrew..."
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
            log_info "Parando serviço Docker..."
            sudo systemctl stop docker > /dev/null 2>&1 || log_debug "Serviço já parado"
            sudo systemctl disable docker > /dev/null 2>&1 || log_debug "Serviço não estava habilitado"

            case "$distro" in
                ubuntu | debian | pop | linuxmint)
                    log_info "Removendo Docker via apt..."
                    sudo apt-get purge -y \
                        docker-ce \
                        docker-ce-cli \
                        containerd.io \
                        docker-buildx-plugin \
                        docker-compose-plugin > /dev/null 2>&1
                    sudo apt-get autoremove -y > /dev/null 2>&1
                    ;;
                fedora | rhel | centos | rocky | almalinux)
                    log_info "Removendo Docker via dnf..."
                    sudo dnf remove -y \
                        docker-ce \
                        docker-ce-cli \
                        containerd.io \
                        docker-buildx-plugin \
                        docker-compose-plugin > /dev/null 2>&1
                    ;;
                arch | manjaro)
                    log_info "Removendo Docker via pacman..."
                    sudo pacman -Rns --noconfirm docker docker-compose > /dev/null 2>&1
                    ;;
            esac

            # Remove user from docker group
            local current_user=$(whoami)
            if groups "$current_user" | grep -q docker; then
                log_debug "Removendo usuário do grupo docker..."
                sudo gpasswd -d "$current_user" docker > /dev/null 2>&1 || log_debug "Não foi possível remover do grupo"
            fi
            ;;
    esac

    # Verify uninstallation
    if ! command -v docker &> /dev/null; then
        # Mark as uninstalled in lock file
        mark_uninstalled "docker"

        log_success "Docker desinstalado com sucesso!"
        log_debug "Executável removido"
    else
        log_error "Falha ao desinstalar Docker completamente"
        return 1
    fi

    echo ""
    log_output "${YELLOW}Deseja remover também as imagens, containers e volumes do Docker? (s/N)${NC}"
    read -r response

    if [[ "$response" =~ ^[sS]$ ]]; then
        log_info "Removendo dados do Docker..."
        sudo rm -rf /var/lib/docker > /dev/null 2>&1 || log_debug "Diretório não encontrado"
        sudo rm -rf /var/lib/containerd > /dev/null 2>&1 || log_debug "Diretório não encontrado"
        log_info "Dados removidos"
    fi

    log_info "Reinicie o terminal para aplicar as mudanças"
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
