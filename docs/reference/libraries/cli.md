# cli.sh

Funções auxiliares específicas do CLI.

## Funções

### `build_command_path()`

Constrói o caminho do comando baseado no script que está sendo executado.

**Comportamento:**

- Detecta automaticamente o script main.sh na pilha de chamadas
- Extrai o caminho relativo do comando
- Funciona com comandos built-in e plugins

**Retorno:** Caminho do comando sem barras (separado por espaços)

**Exemplo:**

```bash
# Se executando /opt/susa/commands/self/plugin/add/main.sh
path=$(build_command_path)
echo "$path"  # self plugin add
```

**Uso interno:** Chamada automaticamente por `show_usage()`

### `get_command_config_file()`

Obtém o caminho do arquivo config.yaml do comando sendo executado.

**Comportamento:**

- Detecta automaticamente o script main.sh na pilha de chamadas
- Retorna o caminho para config.yaml do mesmo diretório

**Retorno:** Caminho absoluto para config.yaml

**Exemplo:**

```bash
# Se executando commands/setup/docker/main.sh
config=$(get_command_config_file)
echo "$config"  # /path/to/commands/setup/docker/config.yaml
```

**Uso interno:** Chamada automaticamente por `show_description()`

### `show_usage()`

Mostra mensagem de uso do comando com argumentos customizáveis.

**Parâmetros:**

- `$@` - Argumentos opcionais (padrão: "[opções]")
- `--no-options` - Remove a exibição de "[opções]"

**Uso:**

```bash
show_usage
# Output: Uso: susa setup docker [opções]

show_usage "<arquivo> <destino>"
# Output: Uso: susa setup docker <arquivo> <destino>

show_usage --no-options
# Output: Uso: susa self info
```

### `show_description()`

Exibe a descrição do comando do arquivo config.yaml.

**Comportamento:**

- Detecta automaticamente o config.yaml do comando
- Lê e exibe o campo "description"

**Requisitos:**

- O arquivo config.yaml deve ter um campo "description"

**Uso:**

```bash
show_description
# Output: Instala Docker no sistema
```

### `show_version()`

Mostra nome e versão do CLI formatados.

```bash
show_version
# Output: Susa CLI v1.0.0
```

### `show_number_version()`

Mostra apenas o número da versão do CLI.

```bash
version=$(show_number_version)
echo "$version"  # 1.0.0
```

## Exemplo Completo

```bash
#!/bin/bash
set -euo pipefail

source "$LIB_DIR/cli.sh"

# Setup do ambiente

if [ $# -eq 0 ]; then
    show_description
    echo ""
    show_usage
    exit 0
fi

# Mostra versão se solicitado
if [ "$1" = "--version" ]; then
    show_version
    exit 0
fi
```

## Boas Práticas

1. Use `show_description` e `show_usage` na função de ajuda
2. Use `show_version` para comandos `--version`
