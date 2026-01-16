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

Obtém o caminho do arquivo command.json do comando sendo executado.

**Comportamento:**

- Detecta automaticamente o script main.sh na pilha de chamadas
- Retorna o caminho para command.json do mesmo diretório

**Retorno:** Caminho absoluto para command.json ou category.json

**Exemplo:**

```bash
# Se executando commands/setup/docker/main.sh
config=$(get_command_config_file)
echo "$config"  # /path/to/commands/setup/docker/command.json
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

Exibe a descrição do comando do arquivo command.json.

**Comportamento:**

- Detecta automaticamente o command.json do comando
- Lê e exibe o campo "description"

**Requisitos:**

- O arquivo command.json deve ter um campo "description"

**Uso:**

```bash
show_description
# Output: Instala Docker no sistema
```

**Nota:** Para funções de versão (`show_version()` e `show_number_version()`), veja a documentação de [config.sh](config.md).

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
    show_version  # Função em config.sh
    exit 0
fi
```

## Boas Práticas

1. Use `show_description` e `show_usage` na função de ajuda
2. Para versão, use funções de `config.sh`
3. Use `build_command_path()` é chamado automaticamente por `show_usage()`
