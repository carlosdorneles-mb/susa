#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Setup command environment
# Bibliotecas essenciais já carregadas automaticamente

# ============================================================
# Help Function
# ============================================================

show_help() {
    show_description
    log_output ""
    show_usage "<cache-name> | --all"
    log_output ""
    log_output "${LIGHT_GREEN}Argumentos:${NC}"
    log_output "  <cache-name>      Nome do cache a limpar (ex: lock)"
    log_output "  --all             Limpa todos os caches"
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output ""
    log_output "${LIGHT_GREEN}Descrição:${NC}"
    log_output "  Remove um cache específico ou todos os caches da memória e disco."
    log_output ""
    log_output "  Os caches serão recriados automaticamente quando necessário."
    log_output ""
    log_output "  Use este comando quando:"
    log_output "  • Você deseja limpar espaço em memória"
    log_output "  • Um cache está corrompido ou causando problemas"
    log_output "  • Para forçar uma recriação completa"
    log_output ""
    log_output "${LIGHT_GREEN}Caches Disponíveis:${NC}"
    log_output "  lock              Cache do arquivo susa.lock (categorias, comandos, plugins)"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa self cache clear lock        # Limpa apenas o cache do lock"
    log_output "  susa self cache clear --all       # Limpa todos os caches"
}

# ============================================================
# Main
# ============================================================

main() {
    # Parse arguments
    if [ $# -eq 0 ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        show_help
        exit 0
    fi

    local cache_name="$1"

    # Clear all caches
    if [ "$cache_name" = "--all" ]; then
        log_info "Limpando todos os caches..."

        # Get all cache files
        local cache_dir
        if [[ "$(uname)" == "Darwin" ]]; then
            cache_dir="${TMPDIR:-$HOME/Library/Caches}/susa"
        else
            cache_dir="${XDG_RUNTIME_DIR:-/tmp}/susa-$USER"
        fi

        if [ -d "$cache_dir" ]; then
            local count=0
            for cache_file in "$cache_dir"/*.cache; do
                [ -f "$cache_file" ] || continue
                local name=$(basename "$cache_file" .cache)
                cache_named_clear "$name" 2> /dev/null || true
                count=$((count + 1))
            done

            if [ $count -gt 0 ]; then
                log_success "✓ $count cache(s) removido(s) com sucesso!"
            else
                log_warning "Nenhum cache encontrado"
            fi
        else
            log_warning "Diretório de cache não existe"
        fi
        exit 0
    fi

    # Clear specific cache
    log_info "Limpando cache '$cache_name'..."

    if cache_named_clear "$cache_name" 2> /dev/null; then
        log_success "✓ Cache '$cache_name' removido com sucesso!"
    else
        log_warning "Cache '$cache_name' não existe ou já foi removido"
    fi
}

main "$@"
