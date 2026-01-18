#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Setup command environment
# Bibliotecas essenciais já carregadas automaticamente
source "$LIB_DIR/table.sh"

# ============================================================
# Help Function
# ============================================================

show_help() {
    show_description
    log_output ""
    show_usage --no-options
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output ""
    log_output "${LIGHT_GREEN}Descrição:${NC}"
    log_output "  Lista todos os caches atualmente disponíveis no sistema,"
    log_output "  mostrando informações detalhadas de cada um:"
    log_output "  • Nome do cache"
    log_output "  • Tamanho do arquivo"
    log_output "  • Número de chaves armazenadas"
    log_output "  • Data da última modificação"
    log_output "  • Localização do arquivo"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplo:${NC}"
    log_output "  susa self cache list"
}

# ============================================================
# Main
# ============================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Opção inválida: $1"
                log_output ""
                log_output "Use ${LIGHT_CYAN}susa self cache list --help${NC} para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    log_info "Listando caches disponíveis..."
    echo ""

    local cache_dir
    if [[ "$(uname)" == "Darwin" ]]; then
        cache_dir="${TMPDIR:-$HOME/Library/Caches}/susa"
    else
        cache_dir="${XDG_RUNTIME_DIR:-/tmp}/susa-$USER"
    fi

    # Check if cache directory exists
    if [ ! -d "$cache_dir" ]; then
        log_warning "Nenhum cache encontrado"
        log_output ""
        log_output "O diretório de cache será criado automaticamente quando você"
        log_output "executar comandos que utilizam cache."
        exit 0
    fi

    # List all caches
    local found=0
    local total_size=0

    log_output "${BOLD}Caches Disponíveis:${NC}"
    echo ""

    # Initialize table
    table_init
    table_add_header "Nome" "Tamanho" "Chaves" "Modificado" "Localização"

    # Build table data
    for cache_file in "$cache_dir"/*.cache; do
        [ -f "$cache_file" ] || continue

        local name=$(basename "$cache_file" .cache)
        local size_bytes

        # Get file size in bytes (cross-platform)
        if [[ "$(uname)" == "Darwin" ]]; then
            size_bytes=$(stat -f %z "$cache_file" 2> /dev/null || echo "0")
        else
            size_bytes=$(stat -c %s "$cache_file" 2> /dev/null || echo "0")
        fi

        local size_human

        # Format size
        if ((size_bytes < 1024)); then
            size_human="${size_bytes}B"
        elif ((size_bytes < 1048576)); then
            size_human="$((size_bytes / 1024))KB"
        else
            size_human="$((size_bytes / 1048576))MB"
        fi

        # Get key count
        local key_count=$(cache_named_count "$name" 2> /dev/null || echo "0")

        # Get modification date
        local cache_date
        if [[ "$(uname)" == "Darwin" ]]; then
            cache_date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$cache_file" 2> /dev/null || echo "N/A")
        else
            cache_date=$(stat -c "%y" "$cache_file" 2> /dev/null | cut -d'.' -f1 || echo "N/A")
        fi

        # Add row to table
        table_add_row "${CYAN}${name}${NC}" "$size_human" "$key_count" "$cache_date" "${GRAY}${cache_file}${NC}"

        found=$((found + 1))
        total_size=$((total_size + size_bytes))
    done

    if [ $found -eq 0 ]; then
        log_warning "Nenhum cache encontrado"
        exit 0
    fi

    # Render table
    table_render

    # Show summary
    echo ""

    local total_human
    if ((total_size < 1024)); then
        total_human="${total_size}B"
    elif ((total_size < 1048576)); then
        total_human="$((total_size / 1024))KB"
    else
        total_human="$((total_size / 1048576))MB"
    fi

    log_output "${BOLD}Total:${NC} $found cache(s) • $total_human"
}

main "$@"
