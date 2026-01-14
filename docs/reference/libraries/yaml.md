# yaml.sh

Parser YAML usando yq para configurações.

## Configuração Inicial

Antes de usar, defina:

```bash
GLOBAL_CONFIG_FILE="/path/to/cli.yaml"
CLI_DIR="/path/to/susa"
```

## Funções - Config Global

### `get_yaml_field()`

Obtém campos do arquivo cli.yaml.

**Parâmetros:**

- `$1` - Caminho do arquivo yaml
- `$2` - Campo (name, description, version, commands_dir, plugins_dir)

**Uso:**

```bash
name=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "name")
version=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "version")
```

### `discover_categories()`

Descobre categorias da estrutura de diretórios (commands/ e plugins/).

```bash
categories=$(discover_categories)
for cat in $categories; do
    echo "Categoria: $cat"
done
```

### `get_category_info()`

Obtém informações de uma categoria do config.yaml dela.

**Parâmetros:**

- `$1` - Caminho do arquivo yaml global
- `$2` - Nome da categoria
- `$3` - Campo (name, description)

```bash
desc=$(get_category_info "$GLOBAL_CONFIG_FILE" "setup" "description")
echo "Categoria setup: $desc"
```

## Funções - Discovery de Comandos

### `is_command_dir()`

Verifica se um diretório é um comando (tem config.yaml com campo script).

**Retorno:**

- `0` - É um comando
- `1` - Não é comando (é subcategoria)

```bash
if is_command_dir "/opt/susa/commands/setup/asdf"; then
    echo "É um comando"
else
    echo "É uma subcategoria"
fi
```

### `discover_items_in_category()`

Descobre comandos e subcategorias em uma categoria.

**Parâmetros:**

- `$1` - Diretório base (commands/ ou plugins/nome)
- `$2` - Caminho da categoria (ex: "setup" ou "setup/python")
- `$3` - Tipo: "commands", "subcategories", ou "all" (padrão: "all")

**Retorno:** Linhas no formato `command:nome` ou `subcategory:nome`

```bash
# Todos os itens
discover_items_in_category "$CLI_DIR/commands" "setup" "all"

# Apenas comandos
discover_items_in_category "$CLI_DIR/commands" "setup" "commands" | sed 's/^command://'
```

### `get_category_commands()`

Obtém comandos de uma categoria.

```bash
commands=$(get_category_commands "setup")
for cmd in $commands; do
    echo "Comando: $cmd"
done
```

## Funções - Config de Comandos

### `get_command_config_field()`

Lê um campo do config.yaml de um comando.

**Parâmetros:**

- `$1` - Caminho do arquivo config.yaml
- `$2` - Campo (category, id, name, description, script, sudo, os)

```bash
name=$(get_command_config_field "/opt/susa/commands/setup/asdf/config.yaml" "name")
```

### `find_command_config()`

Encontra o arquivo config.yaml de um comando.

```bash
config=$(find_command_config "setup" "asdf")
echo "$config"  # /opt/susa/commands/setup/asdf/config.yaml
```

### `get_command_info()`

Obtém informação de um comando específico.

**Parâmetros:**

- `$1` - Arquivo yaml global
- `$2` - Categoria
- `$3` - ID do comando
- `$4` - Campo (name, description, script, sudo, os)

```bash
script=$(get_command_info "$GLOBAL_CONFIG_FILE" "setup" "asdf" "script")
needs_sudo=$(get_command_info "$GLOBAL_CONFIG_FILE" "setup" "asdf" "sudo")
```

### `is_command_compatible()`

Verifica se comando é compatível com o SO atual.

```bash
current_os=$(get_simple_os)

if is_command_compatible "$GLOBAL_CONFIG_FILE" "setup" "asdf" "$current_os"; then
    echo "Comando compatível"
fi
```

### `requires_sudo()`

Verifica se comando requer sudo.

```bash
if requires_sudo "$GLOBAL_CONFIG_FILE" "setup" "asdf"; then
    log_warning "Este comando requer sudo"
fi
```

## Exemplo Completo

```bash
#!/bin/bash
source "$LIB_DIR/internal/yaml.sh"
source "$LIB_DIR/os.sh"

# Configuração
GLOBAL_CONFIG_FILE="$CORE_DIR/cli.yaml"

# Obtém info global
cli_name=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "name")
cli_version=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "version")

echo "$cli_name v$cli_version"

# Lista categorias e comandos
categories=$(discover_categories)
current_os=$(get_simple_os)

for category in $categories; do
    cat_desc=$(get_category_info "$GLOBAL_CONFIG_FILE" "$category" "description")
    echo "Categoria: $cat_desc"

    commands=$(get_category_commands "$category")
    for cmd in $commands; do
        if is_command_compatible "$GLOBAL_CONFIG_FILE" "$category" "$cmd" "$current_os"; then
            cmd_name=$(get_command_info "$GLOBAL_CONFIG_FILE" "$category" "$cmd" "name")
            echo "  - $cmd_name"
        fi
    done
done
```

## Funções - Variáveis de Ambiente

### `load_command_envs()`

> **✨ Novo na versão 1.0+**

Carrega e exporta variáveis de ambiente definidas na seção `envs` do config.yaml de um comando.

**Parâmetros:**

- `$1` - Caminho do arquivo config.yaml do comando

**Comportamento:**

- Lê a seção `envs:` do config.yaml
- Exporta cada variável como variável de ambiente
- Expande variáveis como `$HOME`, `$USER`, etc.
- Ignora se a seção `envs` não existir
- Chamado automaticamente pelo framework antes de executar o comando

**Uso:**

```bash
# Carregamento automático (framework faz isso)
load_command_envs "$CONFIG_FILE"

# No script do comando, as variáveis já estão disponíveis
local timeout="${MY_TIMEOUT:-30}"
local url="${MY_API_URL:-https://default.com}"
```

**Exemplo de config.yaml:**

```yaml
name: "My Command"
description: "Meu comando"
entrypoint: "main.sh"
sudo: false
os: ["linux"]
envs:
  MY_API_URL: "https://api.example.com"
  MY_TIMEOUT: "30"
  MY_INSTALL_DIR: "$HOME/.myapp"
  MY_MAX_RETRIES: "3"
```

**Exemplo de uso no script:**

```bash
#!/bin/bash
set -euo pipefail


# Variáveis do config.yaml já estão exportadas
install_app() {
    local api_url="${MY_API_URL:-https://api.example.com}"
    local timeout="${MY_TIMEOUT:-30}"
    local install_dir="${MY_INSTALL_DIR:-$HOME/.myapp}"

    log_info "Instalando em: $install_dir"
    curl --max-time "$timeout" "$api_url/download" -o /tmp/app.tar.gz
    tar -xzf /tmp/app.tar.gz -C "$install_dir"
}

install_app "$@"
```

**Características:**

- ✅ Expansão automática de variáveis (`$HOME` → `/home/user`)
- ✅ Isolamento entre comandos (não vazam)
- ✅ Respeita variáveis de sistema (precedência: Sistema > Config)
- ✅ Suporta qualquer variável de ambiente válida
- ✅ Funciona em comandos built-in e plugins

**Precedência:**

1. **Variáveis de Sistema** (mais alta) - `export VAR=value` ou `VAR=value comando`
2. **Variáveis do Config** - `config.yaml` → `envs:`
3. **Valores Padrão** (mais baixa) - `${VAR:-default}` no script

**Exemplo de precedência:**

```bash
# config.yaml tem TIMEOUT: "30"
# Script usa: timeout="${TIMEOUT:-10}"

./core/susa comando                  # → 30 (do config)
TIMEOUT=60 ./core/susa comando       # → 60 (do sistema, override)
```

**Notas:**

- Não é necessário chamar manualmente; o framework faz isso automaticamente
- Use sempre valores de fallback no script: `${VAR:-default}`
- Variáveis são isoladas; cada comando tem seu próprio ambiente
- Override via sistema sempre tem prioridade

> **📖 Para mais detalhes**, veja [Guia de Variáveis de Ambiente](../../guides/envs.md).

## Boas Práticas

1. Sempre defina `GLOBAL_CONFIG_FILE` e `CLI_DIR` no início
2. Use `is_command_compatible()` antes de executar comandos
3. Cache resultados de funções pesadas em loops
