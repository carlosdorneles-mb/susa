#!/bin/bash

# =========================
# Remote Installer for CLI
# =========================

# Exit on error
set -e

# Settings
REPO_URL="${CLI_REPO_URL:-https://github.com/duducp/susa.git}"
REPO_BRANCH="${CLI_REPO_BRANCH:-main}"
INSTALL_DIR="${CLI_INSTALL_DIR:-$HOME/.local/susa}"
TEMP_DIR=$(mktemp -d)

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log functions
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

# Cleanup
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# Detect operating system
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

# Verify that the command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Ensure git is installed
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

# Main installation
main() {
    show_banner

    local os_type=$(detect_os)
    log_info "Sistema detectado: $os_type"

    if [ "$os_type" = "unknown" ]; then
        log_error "Sistema operacional não suportado"
        exit 1
    fi

    # Check/install git
    log_info "Verificando dependências..."
    if ! ensure_git; then
        exit 1
    fi

    # Clones repository
    log_info "Baixando Susa CLI do repositório..."
    cd "$TEMP_DIR"

    if ! git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" cli; then
        log_error "Falha ao clonar repositório: $REPO_URL"
        log_info "Verifique se o repositório existe e está acessível"
        exit 1
    fi

    cd cli

    # Check if install.sh exists
    if [ ! -f "install.sh" ]; then
        log_error "Script de instalação não encontrado no repositório"
        exit 1
    fi

    # Check for existing installation
    if [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/susa" ]; then
        log_warning "Susa CLI já está instalado em: $INSTALL_DIR"
        log_info "A instalação atual será substituída."
        echo ""
        # Remove old installation to avoid permission conflicts
        rm -rf "$INSTALL_DIR"
    fi

    # Copy to permanent location (excluding .git)
    log_info "Instalando em $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"

    # Copy all files except .git directory
    find . -mindepth 1 -maxdepth 1 ! -name '.git' -exec cp -r {} "$INSTALL_DIR/" \;

    # Run installation from permanent location
    cd "$INSTALL_DIR"
    chmod +x install.sh

    log_info "Executando instalação..."

    if bash install.sh; then
        log_success "Susa CLI instalado com sucesso! 🎉"
        echo ""
        log_info "Documentação: https://duducp.github.io/susa"
    else
        log_error "Falha durante a instalação"
        exit 1
    fi
}

# Run installation
main "$@"
