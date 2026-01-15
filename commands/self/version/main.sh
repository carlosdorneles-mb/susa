#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h | --help)
            show_version
            exit 0
            ;;
        -n | --number)
            show_number_version
            exit 0
            ;;
        -v | --verbose)
            export DEBUG=1
            log_debug "Modo verbose ativado"
            shift
            ;;
        *)
            log_error "Argumento inválido: $1"
            log_output ""
            show_version
            exit 1
            ;;
    esac
done

# Default: show full version
log_debug "Exibindo versão do Susa CLI"
show_version
