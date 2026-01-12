#!/bin/bash
set -euo pipefail

# ============================================================
# Remote Uninstaller for Susa CLI
# ============================================================

# Settings
CLI_NAME="${CLI_NAME:-susa}"
INSTALL_DIR="${CLI_INSTALL_DIR:-$HOME/.local/susa}"
BIN_DIR="$HOME/.local/bin"

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

# Detect operating system
detect_os() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "macOS"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# Banner
show_banner() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║         Desinstalador Remoto do Susa CLI              ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
}

# Main uninstall function
uninstall_susa() {
    local os_type=$(detect_os)
    log_info "Sistema detectado: $os_type"
    echo ""

    # Run the local uninstall script
    if [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/uninstall.sh" ]; then
        log_info "Executando script de desinstalação local..."
        bash "$INSTALL_DIR/uninstall.sh"
        echo ""
    else
        log_error "Susa CLI não está instalado ou diretório não encontrado: $INSTALL_DIR"
        exit 1
    fi

    # Remove o diretório de instalação
    if [ -d "$INSTALL_DIR" ]; then
        log_info "Removendo diretório de instalação: $INSTALL_DIR..."
        rm -rf "$INSTALL_DIR"
        log_success "Diretório removido"
    fi

    echo ""
    log_success "Desinstalação completa!"
    echo ""
}

# Main execution
main() {
    show_banner

    # Confirmation
    echo -ne "${YELLOW}Deseja realmente desinstalar o Susa CLI? [s/N]:${NC} "
    read -r confirm
    echo ""

    if [[ "$confirm" =~ ^[sS]$ ]]; then
        uninstall_susa
    else
        log_info "Desinstalação cancelada."
        exit 0
    fi
}

# Checks if it is being executed via pipe
if [ -t 0 ]; then
    # Interactive terminal
    main
else
    # Via pipe (curl | sh), uninstalls directly
    show_banner
    log_warning "Executando desinstalação automática (não interativa)..."
    echo ""
    uninstall_susa
fi
