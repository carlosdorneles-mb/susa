# lock.sh

Wrapper para acesso otimizado ao cache do arquivo `susa.lock`.

> **ℹ️ Biblioteca Interna:** Esta biblioteca está em `core/lib/internal/` e fornece acesso simplificado ao cache do lock file. Para cache genérico, veja [cache.sh](cache.md).

## Visão Geral

A biblioteca `lock.sh` fornece funções específicas para trabalhar com o arquivo `susa.lock`:

- 📦 **Auto-carregamento**: Carrega e valida cache automaticamente
- 🔍 **Queries otimizadas**: Funções helpers para dados comuns
- 🚀 **Performance**: ~1-3ms por operação (via cache em memória)
- ✅ **Validação**: Detecta automaticamente mudanças no lock file

Internamente, usa o sistema de cache nomeado (`cache_named_*`) com o nome `"lock"`.

## Configuração

### Variáveis Disponíveis

```bash
LOCK_FILE="${CLI_DIR:-$HOME/.susa}/susa.lock"
LOCK_CACHE_NAME="lock"
```

## Carregamento

### `cache_load()`

Carrega o cache do lock file. Auto-detecta mudanças e recarrega se necessário.

**Uso:**

```bash
source "$LIB_DIR/internal/lock.sh"

cache_load  # Carrega susa.lock em memória
```

**Características:**

- ✅ Primeira chamada: carrega do disco
- ✅ Chamadas subsequentes: usa cache em memória
- ✅ Auto-atualização: detecta mudanças no lock file

**Equivalente interno:**

```bash
cache_named_load "$LOCK_CACHE_NAME" "$LOCK_FILE"
```

## Consultas Genéricas

### `cache_query(jq_query)`

Executa query jq diretamente no cache do lock file.

**Parâmetros:**

- `$1` - Query jq

**Uso:**

```bash
# Listar todas as categorias
cache_query '.categories[].name'

# Obter versão do docker instalado
cache_query '.installations[] | select(.name == "docker") | .version'

# Verificar se há plugins
cache_query '.plugins | length'
```

**Retorno:** Resultado da query jq (uma ou mais linhas)

## Consultas de Categorias

### `cache_get_categories()`

Lista todas as categorias disponíveis.

**Uso:**

```bash
categories=$(cache_get_categories)
for cat in $categories; do
    echo "Categoria: $cat"
done
```

**Exemplo de saída:**

```
self
self/cache
self/plugin
setup
setup/vscode
```

### `cache_get_category_info(category, field)`

Obtém informação específica de uma categoria.

**Parâmetros:**

- `$1` - Nome da categoria (ex: "setup")
- `$2` - Campo (name, description, entrypoint)

**Uso:**

```bash
desc=$(cache_get_category_info "setup" "description")
echo "$desc"
# Saída: Instalação e atualização de softwares e ferramentas

entrypoint=$(cache_get_category_info "setup" "entrypoint")
if [ -n "$entrypoint" ]; then
    echo "Categoria tem entrypoint: $entrypoint"
fi
```

### `cache_get_category_commands(category)`

Lista comandos de uma categoria.

**Parâmetros:**

- `$1` - Nome da categoria

**Uso:**

```bash
commands=$(cache_get_category_commands "setup")
for cmd in $commands; do
    echo "Comando: $cmd"
done
```

**Exemplo de saída:**

```text
docker
podman
poetry
asdf
mise
```

## Consultas de Comandos

### `cache_get_command_info(category, command, field)`

Obtém informação específica de um comando.

**Parâmetros:**

- `$1` - Categoria (ex: "setup")
- `$2` - Comando (ex: "docker")
- `$3` - Campo (name, description, sudo, group, os)

**Uso:**

```bash
# Descrição do comando
desc=$(cache_get_command_info "setup" "docker" "description")
echo "$desc"
# Saída: Instala Docker CLI e Engine (plataforma de containers)

# Verificar se requer sudo
sudo=$(cache_get_command_info "setup" "docker" "sudo")
if [ "$sudo" = "true" ]; then
    echo "⚠️ Este comando requer privilégios sudo"
fi

# Obter grupo do comando
group=$(cache_get_command_info "setup" "docker" "group")
echo "Grupo: $group"
# Saída: Grupo: container

# Sistemas operacionais suportados
os_list=$(cache_get_command_info "setup" "docker" "os")
echo "Suporta: $os_list"
# Saída: Suporta: linux mac
```

**Campos disponíveis:**

| Campo | Descrição |
|-------|-----------|
| `name` | Nome exibido do comando |
| `description` | Descrição curta |
| `sudo` | `true` se requer privilégios root |
| `group` | Grupo de agrupamento (container, runtime, etc) |
| `os` | Array de sistemas suportados |
| `entrypoint` | Script de entrada (geralmente `main.sh`) |

## Consultas de Plugins

### `cache_get_plugin_info(plugin_name, field)`

Obtém informações de um plugin instalado.

**Parâmetros:**

- `$1` - Nome do plugin
- `$2` - Campo (name, version, source, installedAt, dev)

**Uso:**

```bash
version=$(cache_get_plugin_info "hello-world" "version")
echo "Versão: $version"

source=$(cache_get_plugin_info "hello-world" "source")
echo "Fonte: $source"

is_dev=$(cache_get_plugin_info "hello-world" "dev")
if [ "$is_dev" = "true" ]; then
    echo "[dev] Plugin em desenvolvimento"
fi
```

### `cache_get_plugins()`

Lista todos os plugins instalados.

**Uso:**

```bash
plugins=$(cache_get_plugins)
for plugin in $plugins; do
    echo "Plugin: $plugin"
done
```

**Exemplo de saída:**

```text
hello-world
dev-tools
my-commands
```

## Gerenciamento do Cache

### `cache_refresh()`

Força atualização do cache, recarregando do disco.

**Uso:**

```bash
# Após modificar susa.lock manualmente
echo "Atualizando lock file..."
jq '.installations += [{"name": "custom", "version": "1.0"}]' susa.lock > susa.lock.tmp
mv susa.lock.tmp susa.lock

# Atualizar cache
cache_refresh
```

**Quando usar:**

- ✅ Após modificar `susa.lock` manualmente
- ✅ Depois de `sync_installations()`
- ✅ Quando suspeitar que cache está desatualizado

### `cache_clear()`

Remove o cache do disco e da memória.

**Uso:**

```bash
cache_clear
```

O cache será recriado automaticamente na próxima chamada a `cache_load()`.

### `cache_exists()`

Verifica se o arquivo de cache existe.

**Retorno:**

- `0` - Cache existe
- `1` - Cache não existe

**Uso:**

```bash
if cache_exists; then
    echo "Cache disponível"
else
    echo "Cache não existe, será criado"
fi
```

### `cache_info()`

Exibe informações detalhadas sobre o cache (timestamp, tamanho, validade).

**Uso:**

```bash
cache_info
```

**Exemplo de saída:**

```text
[INFO] 2026-01-18 10:00:00 - Informações do Cache:

Informações do Cache
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Localização:
  Diretório: /run/user/1000/susa-user
  Arquivo:   /run/user/1000/susa-user/lock.cache
  Lock:      /home/user/.susa/susa.lock

Status do Cache:
  Existe:      ✓ Sim
  Tamanho:     12K
  Modificado:  2026-01-18 09:50:00.123456789 -0300

Status do Lock File:
  Existe:      ✓ Sim
  Modificado:  2026-01-18 09:45:00.987654321 -0300

Validação:
  Status:      ✓ Válido
  Descrição:   Cache está atualizado e pronto para uso
```

## Padrões de Uso

### Básico - Listar Comandos

```bash
#!/bin/bash
source "$LIB_DIR/internal/lock.sh"

# Carregar cache
cache_load

# Listar comandos da categoria setup
echo "Comandos disponíveis:"
for cmd in $(cache_get_category_commands "setup"); do
    desc=$(cache_get_command_info "setup" "$cmd" "description")
    echo "  $cmd - $desc"
done
```

### Avançado - Verificar Compatibilidade

```bash
#!/bin/bash
source "$LIB_DIR/internal/lock.sh"
source "$LIB_DIR/os.sh"

cache_load

check_command_compatibility() {
    local category="$1"
    local command="$2"

    # Obter sistemas suportados
    local supported_os=$(cache_query ".commands[] |
        select(.category == \"$category\" and .name == \"$command\") |
        .os[]" 2>/dev/null)

    # Verificar se OS atual está na lista
    if echo "$supported_os" | grep -q "^$OS_TYPE$"; then
        return 0  # Compatível
    else
        return 1  # Incompatível
    fi
}

# Uso
if check_command_compatibility "setup" "docker"; then
    echo "✓ Docker compatível com $OS_TYPE"
else
    echo "✗ Docker não suportado em $OS_TYPE"
fi
```

### Otimização - Múltiplas Consultas

```bash
#!/bin/bash
source "$LIB_DIR/internal/lock.sh"

# ✅ BOM: Carregar cache uma vez
cache_load

# Depois fazer múltiplas consultas (todas em memória)
for category in $(cache_get_categories); do
    desc=$(cache_get_category_info "$category" "description")
    commands=$(cache_get_category_commands "$category")
    echo "$category: $desc ($commands)"
done
```

## Comparação com Cache Genérico

| lock.sh | cache.sh (genérico) |
|---------|---------------------|
| `cache_load()` | `cache_named_load("lock", "$LOCK_FILE")` |
| `cache_query(query)` | `cache_named_query("lock", query)` |
| `cache_refresh()` | `cache_named_load("lock", "$LOCK_FILE")` |
| `cache_clear()` | `cache_named_clear("lock")` |

**lock.sh** é apenas um wrapper conveniente sobre **cache.sh** para o arquivo `susa.lock`.

## Dependências

```text
lock.sh
├── json.sh (para parsing JSON)
└── cache.sh (sistema de cache nomeado)
    └── logger.sh (opcional, para debug)
```

## Comandos Relacionados

- `susa self cache list` - Lista todos os caches disponíveis
- `susa self cache list --detailed` - Exibe informações detalhadas dos caches
- `susa self cache clear lock` - Remove o cache do lock
- `susa self lock` - Gerencia o arquivo susa.lock (atualiza cache automaticamente)

## Veja também

- [cache.sh](cache.md) - Sistema genérico de caches nomeados
- [config.sh](config.md) - Parser de configurações
- [installations.sh](installations.md) - Gerenciamento de instalações

## Performance

### Comparação de Operações

```bash
# Com cache (em memória)
cache_load                           # ~3ms (primeira vez)
cache_get_categories                 # ~1ms
cache_get_command_info "setup" "docker" "description"  # ~1ms

# Sem cache (leitura de disco + jq)
jq -r '.categories[].name' susa.lock           # ~100ms
jq -r '.commands[] | select(...)' susa.lock    # ~150ms
```

**Ganho:** ~100-150x mais rápido com cache! 🚀

## Troubleshooting

### Cache desatualizado

**Sintoma:** Dados antigos após modificar susa.lock

**Solução:**

```bash
cache_refresh  # Força recarga do disco
```

### Cache não carrega

**Sintoma:** `cache_load` falha ou retorna vazio

**Possíveis causas:**

1. Lock file não existe → Execute `susa self lock`
2. Lock file corrompido → Valide JSON com `jq . susa.lock`
3. Permissões incorretas → Verifique permissões de `$XDG_RUNTIME_DIR`

### Performance ainda lenta

**Sintoma:** Operações demoram muito

**Verificar:**

```bash
# Certifique-se de carregar cache apenas uma vez
cache_load  # Chame apenas no início

# Use funções de cache, não jq direto
cache_get_categories  # ✓ Rápido
jq -r '.categories[].name' susa.lock  # ✗ Lento
```
