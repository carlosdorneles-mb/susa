#!/bin/bash

# --- Sudo Helper Functions --- #

check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        log_warning "Este comando requer privilégios de superusuário (sudo)."
        return 1
    fi
    return 0
}

required_sudo() {
    if ! check_sudo; then
        sudo -v || { log_error "Falha ao obter privilégios de sudo"; exit 1; }
    fi
}