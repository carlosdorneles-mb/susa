#!/bin/bash
set -euo pipefail

# ============================================================
# Remote Installer for Susa CLI
# ============================================================
# Instala o Susa CLI diretamente do GitHub
# Uso: curl -LsSf https://raw.githubusercontent.com/USER/REPO/main/install-remote.sh | sh

# Configurações
REPO_URL="${CLI_REPO_URL:-https://github.com/carlosdorneles-mb/susa.git}"
REPO_BRANCH="${CLI_REPO_BRANCH:-main}"
INSTALL_DIR="${CLI_INSTALL_DIR:-$HOME/.local/susa}"
TEMP_DIR=$(mktemp -d)

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funções de log
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Cleanup ao sair
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# Detecta sistema operacional
detect_os() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian)
                echo "debian"
                ;;
            fedora|rhel|centos|rocky|almalinux)
                echo "fedora"
                ;;
            *)
                echo "linux"
                ;;
        esac
    else
        echo "unknown"
    fi
}

# Verifica se comando existe
command_exists() {
    command -v "$1" &>/dev/null
}

# Garante que git está instalado
ensure_git() {
    if command_exists git; then
        return 0
    fi

    log_warning "Git não encontrado. Tentando instalar..."
    
    local os_type=$(detect_os)
    
    case "$os_type" in
        debian)
            if command_exists sudo; then
                sudo apt-get update && sudo apt-get install -y git
            else
                apt-get update && apt-get install -y git
            fi
            ;;
        fedora)
            if command_exists sudo; then
                sudo dnf install -y git || sudo yum install -y git
            else
                dnf install -y git || yum install -y git
            fi
            ;;
        macos)
            if command_exists brew; then
                brew install git
            else
                log_error "Homebrew não encontrado. Instale git manualmente: https://git-scm.com"
                return 1
            fi
            ;;
        *)
            log_error "Sistema operacional não suportado para instalação automática de git"
            log_error "Por favor, instale git manualmente: https://git-scm.com"
            return 1
            ;;
    esac
    
    if ! command_exists git; then
        log_error "Falha ao instalar git"
        return 1
    fi
    
    log_success "Git instalado com sucesso"
    return 0
}

# Banner
show_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                        ║${NC}"
    echo -e "${CYAN}║      Susa CLI Remote Installer         ║${NC}"
    echo -e "${CYAN}║                                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
}

# Instalação principal
main() {
    show_banner
    
    local os_type=$(detect_os)
    log_info "Sistema detectado: $os_type"
    
    if [ "$os_type" = "unknown" ]; then
        log_error "Sistema operacional não suportado"
        exit 1
    fi
    
    # Verifica/instala git
    log_info "Verificando dependências..."
    if ! ensure_git; then
        exit 1
    fi
    
    # Clona repositório
    log_info "Baixando Susa CLI do repositório..."
    cd "$TEMP_DIR"
    
    if ! git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" cli; then
        log_error "Falha ao clonar repositório: $REPO_URL"
        log_info "Verifique se o repositório existe e está acessível"
        exit 1
    fi
    
    cd cli/cli  # Navega para o diretório do Susa CLI dentro do repo
    
    # Verifica se install.sh existe
    if [ ! -f "install.sh" ]; then
        log_error "Script de instalação não encontrado no repositório"
        exit 1
    fi
    
    # Torna install.sh executável
    chmod +x install.sh
    
    # Executa instalação
    log_info "Executando instalação..."
    echo ""
    
    if bash install.sh; then
        echo ""
        log_success "Susa CLI instalado com sucesso! 🎉"
        echo ""
        log_info "Para começar a usar, execute:"
        echo -e "  ${GREEN}susa --version${NC}"
        echo -e "  ${GREEN}susa --help${NC}"
        echo ""
        log_info "Documentação: https://github.com/carlosdorneles-mb/susa"
        echo ""
    else
        log_error "Falha durante a instalação"
        exit 1
    fi
}

# Executa instalação
main "$@"
