# Sistema de Cache do SUSA CLI

## Visão Geral

O SUSA CLI implementa um sistema unificado de **caches nomeados** para máxima performance. Todos os caches usam a mesma arquitetura baseada em arrays associativos do Bash 4+, mantendo dados em memória para acesso ultrarrápido.

## Arquitetura

### Cache Nomeado Unificado

Todos os caches (incluindo o cache do `susa.lock`) usam o mesmo sistema:

- **Em memória**: Arrays associativos (`declare -A`)
- **Zero I/O durante uso**: Operações apenas em memória (~1-3ms)
- **Isolamento**: Cada cache tem namespace próprio
- **Persistência opcional**: Salva em disco apenas quando necessário

### Caches Disponíveis

```text
${XDG_RUNTIME_DIR:-/tmp}/susa-$USER/
  ├── lock.cache      # Cache do susa.lock (atualizado automaticamente)
  ├── context.cache   # Contexto de execução de comandos
  └── *.cache         # Outros caches nomeados conforme necessário
```

## Benefícios

✅ **Performance extrema** - Operações em ~1-3ms vs ~100-500ms de I/O
✅ **Arquitetura limpa** - Um único sistema para todos os caches
✅ **Zero configuração** - Funciona automaticamente
✅ **Isolamento** - Cada cache independente
✅ **Validação automática** - Cache do lock detecta mudanças

## Comandos de Gerenciamento

### `susa self cache`

Gerencia o sistema de cache do CLI.

#### Subcomandos

**`list [--detailed]`** - Lista todos os caches

```bash
# Listagem resumida (padrão)
susa self cache list

# Listagem detalhada
susa self cache list --detailed
```

Exibe:
- Nome de cada cache
- Tamanho do arquivo
- Número de chaves armazenadas
- Data de modificação (modo detalhado)
- Localização (modo detalhado)

**`clear <nome> | --all`** - Remove cache(s)

```bash
# Remove cache específico
susa self cache clear lock

# Remove todos os caches
susa self cache clear --all
```

O cache será recriado automaticamente quando necessário.

> **Nota:** O cache do lock é atualizado automaticamente por `susa self lock`.
> Não há necessidade de comandos manuais de refresh.

## API - Cache Nomeado (Core)

Sistema genérico para criar caches personalizados.

### Gerenciamento

#### `cache_named_load(name)`

Carrega um cache nomeado em memória.

```bash
cache_named_load "mydata"
```

#### `cache_named_save(name)`

Salva cache em disco (opcional - para persistência).

```bash
cache_named_save "mydata"
```

#### `cache_named_clear(name)`

Limpa cache (memória e disco).

```bash
cache_named_clear "mydata"
```

### Consultas

#### `cache_named_query(name, jq_query)`

Executa query jq no cache.

```bash
cache_named_query "lock" '.categories[].name'
```

#### `cache_named_get_all(name)`

Retorna todo o conteúdo do cache como JSON.

```bash
cache_named_get_all "lock" | jq .
```

### Operações Chave-Valor

#### `cache_named_set(name, key, value)`

Define um valor no cache.

```bash
cache_named_set "mydata" "username" "john"
cache_named_set "mydata" "role" "admin"
```

#### `cache_named_get(name, key)`

Obtém um valor do cache.

```bash
local username=$(cache_named_get "mydata" "username")
```

#### `cache_named_has(name, key)`

Verifica se chave existe.

```bash
if cache_named_has "mydata" "username"; then
    echo "Usuário definido"
fi
```

#### `cache_named_remove(name, key)`

Remove uma chave do cache.

```bash
cache_named_remove "mydata" "temp_key"
```

### Utilitários

#### `cache_named_keys(name)`

Lista todas as chaves (uma por linha).

```bash
cache_named_keys "mydata"
```

#### `cache_named_count(name)`

Retorna número de chaves.

```bash
local count=$(cache_named_count "mydata")
echo "Total: $count itens"
```

## API - Cache do Lock File

> **📖 Documentação Completa:** Para funções de acesso ao `susa.lock`, veja [lock.sh](lock.md).

Funções como `cache_load()`, `cache_query()`, `cache_get_*` não estão mais em `cache.sh`. Elas foram movidas para `lock.sh` para manter esta biblioteca genérica.

**Migração rápida:**

```bash
# Antes (cache.sh tinha tudo)
source "$LIB_DIR/internal/cache.sh"
cache_load
cache_query '.categories[].name'

# Agora (lock.sh para funções de lock)
source "$LIB_DIR/internal/lock.sh"  # Já carrega cache.sh automaticamente
cache_load
cache_query '.categories[].name'
```

**Funções disponíveis em lock.sh:**

- `cache_load()` - Carrega cache do lock file
- `cache_query(query)` - Consulta com jq
- `cache_get_categories()` - Lista categorias
- `cache_get_category_info(cat, field)` - Info de categoria
- `cache_get_category_commands(cat)` - Comandos de categoria
- `cache_get_command_info(cat, cmd, field)` - Info de comando
- `cache_get_plugin_info(plugin, field)` - Info de plugin
- `cache_get_plugins()` - Lista plugins
- `cache_refresh()` - Força atualização
- `cache_clear()` - Limpa cache
- `cache_exists()` - Verifica existência
- `cache_info()` - Exibe informações

Veja [documentação completa de lock.sh](lock.md) para detalhes e exemplos.

## Exemplos Práticos

### Exemplo 1: Cache Personalizado

```bash
#!/bin/bash
source "$LIB_DIR/internal/cache.sh"

# Carregar cache
cache_named_load "myapp"

# Armazenar configurações
cache_named_set "myapp" "api_url" "https://api.example.com"
cache_named_set "myapp" "timeout" "30"
cache_named_set "myapp" "retries" "3"

# Ler configurações
api_url=$(cache_named_get "myapp" "api_url")
timeout=$(cache_named_get "myapp" "timeout")

echo "Conectando a $api_url (timeout: ${timeout}s)"

# Limpar ao final
cache_named_clear "myapp"
```

### Exemplo 2: Usando Cache do Lock

```bash
#!/bin/bash
source "$LIB_DIR/internal/lock.sh"  # lock.sh já carrega cache.sh

# Carregar cache do lock
cache_load

# Listar categorias
echo "Categorias disponíveis:"
cache_get_categories | while read -r cat; do
    desc=$(cache_get_category_info "$cat" "description")
    echo "  - $cat: $desc"
done

# Listar comandos de uma categoria
echo ""
echo "Comandos em 'setup':"
cache_get_category_commands "setup" | while read -r cmd; do
    desc=$(cache_get_command_info "setup" "$cmd" "description")
    echo "  - $cmd: $desc"
done
```

### Exemplo 3: Query Complexa no Lock

```bash
#!/bin/bash
source "$LIB_DIR/internal/lock.sh"

cache_load

# Buscar comandos que requerem sudo
cache_query '.commands[] | select(.sudo == true) | .name' | \
while read -r cmd; do
    echo "Comando com sudo: $cmd"
done

# Contar total de comandos
total=$(cache_query '.commands | length')
echo "Total de comandos: $total"
```

## Performance

### Comparação de Abordagens

| Operação | Arquivo (I/O) | Cache Nomeado | Ganho |
|----------|---------------|---------------|-------|
| Leitura simples | ~100ms | ~1ms | ~100x |
| 10 consultas | ~1000ms | ~10ms | ~100x |
| 100 operações | ~10s | ~100ms | ~100x |

### Medições Reais

```bash
# Teste de performance
time (
    cache_named_load "test"
    for i in {1..100}; do
        cache_named_set "test" "key$i" "value$i"
        cache_named_get "test" "key$i" >/dev/null
    done
    cache_named_clear "test"
)
# Resultado: ~300-600ms para 200 operações
# ~1.5-3ms por operação
```

## Casos de Uso

### ✅ Use Cache Nomeado Para

- Contexto de execução de comandos
- Estado temporário entre funções
- Configurações em memória durante execução
- Dados efêmeros (não persistir após comando)
- Cache de validações e pré-requisitos

### ❌ Não Use Cache Nomeado Para

- Dados que precisam persistir entre execuções → Use `susa.lock`
- Configurações de usuário → Use `settings.conf`
- Instalações de software → Use sistema de `installations`
- Grandes volumes de dados → Use arquivos dedicados

## Troubleshooting

### Cache do lock desatualizado

```bash
# Limpar cache específico
susa self cache clear lock

# Regenerar lock e cache
susa self lock
```

### Verificar estado dos caches

```bash
# Listagem resumida
susa self cache list

# Informações detalhadas
susa self cache list --detailed
```

### Cache nomeado não salva

Caches nomeados **não salvam automaticamente**. Para persistir:

```bash
cache_named_save "nome_do_cache"
```

Para apenas memória (mais comum), não salve.

### Bash 4+ não disponível

Caches nomeados requerem Bash 4+:

```bash
$ bash --version
GNU bash, version 5.x.x
```

macOS: `brew install bash`

### Erro de permissão no cache dir

```bash
chmod 700 "${XDG_RUNTIME_DIR:-/tmp}/susa-$USER"
```

## Boas Práticas

### ✅ Padrão Recomendado

```bash
#!/bin/bash
source "$LIB_DIR/internal/cache.sh"

main() {
    # Carregar no início
    cache_named_load "mycommand"

    # Usar durante execução
    cache_named_set "mycommand" "status" "processing"

    # Lógica...

    # SEMPRE limpar no final
    cache_named_clear "mycommand"
}

main "$@"
```

### ❌ Anti-patterns

```bash
# Ruim - não limpar cache
cache_named_load "data"
cache_named_set "data" "key" "value"
# Faltou: cache_named_clear "data"

# Ruim - armazenar dados sensíveis por muito tempo
cache_named_set "auth" "password" "secret123"
# Limpe imediatamente após usar!

# Ruim - usar I/O quando cache está disponível
jq -r '.categories[]' "$LOCK_FILE"  # ❌
cache_get_categories  # ✅
```

## Estrutura Interna

### Implementação

```bash
# Arrays associativos para caches
declare -A _SUSA_NAMED_CACHES
declare -A _SUSA_NAMED_CACHES_LOADED

# Cache do lock usa sistema nomeado
LOCK_CACHE_NAME="lock"

# Funções antigas delegam para cache nomeado
cache_load() {
    cache_named_load "$LOCK_CACHE_NAME"
}

cache_query() {
    cache_named_query "$LOCK_CACHE_NAME" "$1"
}
```

### Localização dos Arquivos

- **Implementação**: `core/lib/internal/cache.sh`
- **Caches em disco**: `${XDG_RUNTIME_DIR:-/tmp}/susa-$USER/*.cache`
- **Lock file**: `$CLI_DIR/susa.lock`

## Segurança

- ✅ Diretório de cache com permissão `700` (apenas o usuário)
- ✅ Arquivos de cache com permissão `600`
- ✅ Cada usuário tem cache isolado
- ✅ Dados apenas em memória durante execução
- ✅ Limpeza automática de caches temporários

## Veja Também

- [lock.sh](lock.md) - Wrapper para acesso ao cache do lock file
- [context.sh](context.md) - Sistema de contexto que usa cache nomeado
- [installations.sh](installations.md) - Sistema de rastreamento de instalações
