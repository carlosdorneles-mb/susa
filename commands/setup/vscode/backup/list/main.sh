#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# List available VSCode backups
# Bibliotecas essenciais já carregadas automaticamente

# Default backup directory
DEFAULT_BACKUP_DIR="$HOME/.susa/backups/vscode"
BACKUP_DIR="${VSCODE_BACKUP_DIR:-$DEFAULT_BACKUP_DIR}"

# Show help
show_help() {
    show_description
    log_output ""
    show_usage "[opções]"
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --dir <dir>       Diretório de backups (padrão: ~/.susa/backups/vscode)"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplo:${NC}"
    log_output "  susa setup vscode backup list"
}

# List available backups
list_backups() {
    log_info "Listando backups disponíveis..."
    log_output ""

    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2> /dev/null)" ]; then
        log_output "Nenhum backup encontrado."
        log_output ""
        log_output "${LIGHT_GREEN}Para criar um backup:${NC}"
        log_output "  susa setup vscode backup create"
        return 0
    fi

    log_output "${LIGHT_GREEN}Backups disponíveis:${NC}"
    log_output ""

    local count=0
    for backup in "$BACKUP_DIR"/*.tar.gz; do
        if [ -f "$backup" ]; then
            count=$((count + 1))
            local backup_name=$(basename "$backup" .tar.gz)
            local backup_size=$(du -h "$backup" | cut -f1)
            local backup_date=$(date -r "$backup" "+%Y-%m-%d %H:%M:%S" 2> /dev/null || stat -c %y "$backup" 2> /dev/null | cut -d' ' -f1-2)

            log_output "  ${LIGHT_CYAN}$count.${NC} $backup_name"
            log_output "     ${GRAY}Tamanho: $backup_size | Criado: $backup_date${NC}"
            log_output ""
        fi
    done

    if [ $count -eq 0 ]; then
        log_output "Nenhum backup encontrado."
    else
        log_output "${LIGHT_GREEN}Total:${NC} $count backup(s)"
        log_output "${LIGHT_GREEN}Diretório:${NC} $BACKUP_DIR"
        log_output ""
        log_output "${LIGHT_GREEN}Para restaurar um backup:${NC}"
        log_output "  susa setup vscode backup restore <nome-do-backup>"
    fi
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                show_help
                exit 0
                ;;
            --dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_usage "[opções]"
                exit 1
                ;;
        esac
    done

    # List backups
    list_backups
}

# Execute main
main "$@"
