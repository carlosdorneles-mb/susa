#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

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

# Banner
show_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                        ║${NC}"
    echo -e "${CYAN}║      Susa CLI Remote Uninstaller       ║${NC}"
    echo -e "${CYAN}║                                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
}

# Main uninstall function
uninstall_susa() {
    local uninstalled=false
    local os_type=$(detect_os)

    log_info "Sistema detectado: $os_type"

    # Remove completion files first
    log_info "Removendo autocompletar..."
    local completion_removed=false
    if [ -f "$HOME/.local/share/bash-completion/completions/$CLI_NAME" ]; then
        rm -f "$HOME/.local/share/bash-completion/completions/$CLI_NAME"
        completion_removed=true
    fi
    if [ -f "$HOME/.local/share/zsh/site-functions/_$CLI_NAME" ]; then
        rm -f "$HOME/.local/share/zsh/site-functions/_$CLI_NAME"
        completion_removed=true
    fi
    if [ "$completion_removed" = true ]; then
        log_success "Autocompletar removido"
    else
        echo "  Autocompletar não encontrado"
    fi

    # Remove binary symlink
    log_info "Removendo executável..."
    if [ -L "$BIN_DIR/$CLI_NAME" ] || [ -f "$BIN_DIR/$CLI_NAME" ]; then
        rm -f "$BIN_DIR/$CLI_NAME"
        log_success "Executável removido"
        uninstalled=true
    else
        echo "  Executável não encontrado em $BIN_DIR"
    fi

    # Remove installation directory
    log_info "Removendo diretório de instalação..."
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        log_success "Diretório removido: $INSTALL_DIR"
        uninstalled=true
    else
        echo "  Diretório não encontrado: $INSTALL_DIR"
    fi

    echo ""
    if [ "$uninstalled" = false ]; then
        log_warning "Susa CLI não foi encontrado"
        log_info "Verifique manualmente em: $INSTALL_DIR e $BIN_DIR/$CLI_NAME"
        exit 1
    fi

    log_success "Susa CLI desinstalado com sucesso! ✓"
    log_info "Nota: Reinicie o terminal para aplicar todas as mudanças"
}

# Main execution
main() {
    show_banner

    # Confirmation
    echo -ne "${YELLOW}Deseja realmente desinstalar o Susa CLI? (s/N):${NC} "
    read -r confirm
    echo ""

    case "$confirm" in
        [sS])
            uninstall_susa
            ;;
        *)
            log_info "Desinstalação cancelada."
            exit 0
            ;;
    esac
}

# Checks if it is being executed via pipe
if [ -t 0 ]; then
    # Interactive terminal
    main
else
    # Via pipe (curl | sh), uninstalls directly
    show_banner
    log_warning "Executando desinstalação automática (não interativa)..."
    uninstall_susa
fi
