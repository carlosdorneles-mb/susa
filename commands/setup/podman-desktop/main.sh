#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/github.sh"

# Constants
REPO="containers/podman-desktop"
APP_NAME="Podman Desktop"
BIN_LINUX="/usr/local/bin/podman-desktop"
APP_MACOS="/Applications/Podman Desktop.app"
DMG_MACOS="/tmp/Podman-Desktop.dmg"
VOLUME_MACOS="/Volumes/Podman Desktop"
URL_LINUX="https://github.com/$REPO/releases/download/v"
URL_MACOS="https://github.com/$REPO/releases/download/v"

# Functions
get_latest_version() {
    github_get_latest_version "$REPO"
}

install_podman_desktop() {
    local version=$(get_latest_version)
    log_info "Instalando $APP_NAME versão $version..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        local url="${URL_LINUX}${version}/Podman-Desktop-${version}-linux-x86_64.AppImage"
        curl -L "$url" -o "$BIN_LINUX"
        chmod +x "$BIN_LINUX"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        local url="${URL_MACOS}${version}/Podman-Desktop-${version}-mac.dmg"
        curl -L "$url" -o "$DMG_MACOS"
        hdiutil attach "$DMG_MACOS"
        cp -R "$VOLUME_MACOS/Podman Desktop.app" "$APP_MACOS"
        hdiutil detach "$VOLUME_MACOS"
    else
        log_error "Sistema operacional não suportado: $OSTYPE"
        exit 1
    fi

    log_success "$APP_NAME versão $version instalada com sucesso."
}

remove_podman_desktop() {
    log_info "Removendo $APP_NAME..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        rm -f "$BIN_LINUX"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        rm -rf "$APP_MACOS"
    else
        log_error "Sistema operacional não suportado: $OSTYPE"
        exit 1
    fi

    log_success "$APP_NAME removido com sucesso."
}

update_podman_desktop() {
    log_info "Atualizando $APP_NAME..."
    remove_podman_desktop
    install_podman_desktop
}

# Main
main() {
    local action="${1:-}"
    case "$action" in
        install) install_podman_desktop ;;
        remove) remove_podman_desktop ;;
        update) update_podman_desktop ;;
        *) log_error "Ação inválida. Use 'install', 'remove' ou 'update'." ;;
    esac
}

main "$@"
