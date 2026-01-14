# cli.sh

Funções auxiliares específicas do CLI.

## Funções

### `setup_command_env()`

Configura o ambiente do comando determinando SCRIPT_DIR e CONFIG_FILE.

**Comportamento:**

- Define `SCRIPT_DIR` como o diretório do script que chamou a função
- Define `CONFIG_FILE` como `$SCRIPT_DIR/config.yaml`
- Exporta ambas as variáveis para uso em subprocessos

**Uso:**

```bash
#!/bin/bash
set -euo pipefail

setup_command_env

# Agora você tem acesso a:
echo "Script dir: $SCRIPT_DIR"
echo "Config file: $CONFIG_FILE"
```

### `build_command_path()`

Constrói o caminho do comando baseado no SCRIPT_DIR.

**Parâmetros:**

- `$1` - Diretório do script (opcional, usa SCRIPT_DIR se não fornecido)

**Retorno:** Caminho do comando sem barras (separado por espaços)

**Exemplo:**

```bash
# Se SCRIPT_DIR = /opt/susa/commands/self/plugin/add
path=$(build_command_path)
echo "$path"  # self plugin add
```

### `show_usage()`

Mostra mensagem de uso do comando com argumentos customizáveis.

**Parâmetros:**

- `$@` - Argumentos opcionais (padrão: "[opções]")

**Uso:**

```bash
show_usage
# Output: Uso: susa <comando> [opções]

show_usage "<arquivo> <destino>"
# Output: Uso: susa setup docker <arquivo> <destino>
```

### `show_description()`

Exibe a descrição do comando do arquivo config.yaml.

**Requisitos:**

- Variável `CONFIG_FILE` deve estar definida (use `setup_command_env`)
- O arquivo config.yaml deve ter um campo "description"

**Uso:**

```bash
setup_command_env
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
setup_command_env

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

1. Sempre chame `setup_command_env` após `set -euo pipefail`
2. Use `show_description` e `show_usage` na função de ajuda
3. Use `show_version` para comandos `--version`
