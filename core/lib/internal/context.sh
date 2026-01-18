#!/bin/bash
#
# context.sh - Sistema de contexto para execução de comandos
#
# Provê funções para gerenciar um contexto de execução que persiste
# durante a vida de um comando e é automaticamente limpo após.
#
# Utiliza o sistema de cache nomeado para performance otimizada.
#
# Dependências:
#   - core/lib/internal/cache.sh (obrigatório)
#   - core/lib/logger.sh (opcional - para logs)
#

set -euo pipefail
IFS=$'\n\t'

# Nome do cache usado para contexto
CONTEXT_CACHE_NAME="context"

# Helper para log compatível (funciona mesmo sem logger.sh)
_context_log_debug() {
    if command -v log_debug &> /dev/null; then
        log_debug "$@"
    fi
}

_context_log_error() {
    if command -v log_error &> /dev/null; then
        log_error "$@"
    else
        echo "ERROR: $*" >&2
    fi
}

# Inicializa o contexto (limpa se existir)
# Deve ser chamado no início da execução de cada comando
context_init() {
    cache_named_clear "$CONTEXT_CACHE_NAME"
    cache_named_load "$CONTEXT_CACHE_NAME"
    _context_log_debug "Contexto inicializado"
}

# Define um valor no contexto
# Uso: context_set "chave" "valor"
context_set() {
    local key="$1"
    local value="$2"

    if [ -z "$key" ]; then
        _context_log_error "context_set: chave não pode ser vazia"
        return 1
    fi

    cache_named_set "$CONTEXT_CACHE_NAME" "$key" "$value"
}

# Obtém um valor do contexto
# Uso: context_get "chave"
# Retorna: valor da chave ou string vazia se não existir
context_get() {
    local key="$1"

    if [ -z "$key" ]; then
        _context_log_error "context_get: chave não pode ser vazia"
        return 1
    fi

    cache_named_get "$CONTEXT_CACHE_NAME" "$key"
}

# Verifica se uma chave existe no contexto
# Uso: context_has "chave"
# Retorna: 0 se existe, 1 se não existe
context_has() {
    local key="$1"

    if [ -z "$key" ]; then
        _context_log_error "context_has: chave não pode ser vazia"
        return 1
    fi

    cache_named_has "$CONTEXT_CACHE_NAME" "$key"
}

# Obtém todo o contexto como JSON
# Uso: context_get_all
# Retorna: JSON com todo o contexto
context_get_all() {
    cache_named_get_all "$CONTEXT_CACHE_NAME"
}

# Remove uma chave do contexto
# Uso: context_remove "chave"
context_remove() {
    local key="$1"

    if [ -z "$key" ]; then
        _context_log_error "context_remove: chave não pode ser vazia"
        return 1
    fi

    cache_named_remove "$CONTEXT_CACHE_NAME" "$key"
}

# Salva o contexto em disco (opcional - útil para debug)
# Uso: context_save
context_save() {
    cache_named_save "$CONTEXT_CACHE_NAME"
    _context_log_debug "Contexto salvo em disco"
}

# Limpa todo o contexto
# Deve ser chamado no final da execução de cada comando
context_clear() {
    cache_named_clear "$CONTEXT_CACHE_NAME"
    _context_log_debug "Contexto limpo"
}

# Lista todas as chaves do contexto
# Uso: context_keys
# Retorna: Array de chaves (uma por linha)
context_keys() {
    cache_named_keys "$CONTEXT_CACHE_NAME"
}

# Conta quantas chaves existem no contexto
# Uso: context_count
# Retorna: Número de chaves
context_count() {
    cache_named_count "$CONTEXT_CACHE_NAME"
}
