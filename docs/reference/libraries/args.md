# args.sh

Biblioteca para parsing consistente de argumentos de linha de comando.

## Descrição

A biblioteca `args.sh` centraliza a lógica de parsing de argumentos, eliminando código duplicado e garantindo comportamento consistente em todos os comandos. Fornece funções para validação, extração e tratamento de argumentos obrigatórios e opcionais.

## Funções

### `parse_help_arg()`

Processa argumento `--help/-h` e exibe ajuda se solicitado.

**Parâmetros:**

- `$@` - Todos os argumentos da linha de comando

**Retorno:**

- `0` - Help foi exibido e script encerrado
- `1` - Nenhum argumento de help encontrado

**Uso:**

```bash
parse_help_arg "$@"
```

**Exemplo:**

```bash
#!/bin/bash
source "$LIB_DIR/internal/args.sh"

# Parse help primeiro
parse_help_arg "$@"

# Se chegou aqui, não é --help, continue o parsing...
```

---

### `require_arguments()`

Valida se pelo menos um argumento foi fornecido. Se não houver argumentos, exibe ajuda e encerra.

**Parâmetros:**

- `$@` - Todos os argumentos da linha de comando

**Comportamento:**

- Se `$# -eq 0`: Exibe `show_help` e encerra com `exit 1`
- Se `$# -gt 0`: Retorna normalmente

**Uso:**

```bash
require_arguments "$@"
```

**Exemplo:**

```bash
#!/bin/bash
source "$LIB_DIR/internal/args.sh"

# Garante que há pelo menos um argumento
require_arguments "$@"

# Continue o parsing sabendo que há argumentos...
```

---

### `parse_simple_help_only()`

Parse completo para comandos que aceitam **apenas** `--help/-h` (nenhum outro argumento).

**Parâmetros:**

- `$@` - Todos os argumentos da linha de comando

**Comportamento:**

- Se `--help` ou `-h`: Exibe ajuda e encerra
- Se qualquer outro argumento: Exibe erro e encerra
- Se sem argumentos: Retorna normalmente

**Uso:**

```bash
parse_simple_help_only "$@"
```

**Exemplo:**

```bash
#!/bin/bash
source "$LIB_DIR/internal/args.sh"

show_help() {
    echo "Este comando não aceita argumentos"
}

# Parse automático de --help e rejeita outros argumentos
parse_simple_help_only "$@"

# Se chegou aqui, não há argumentos. Execute a função principal
main
```

**Comandos que usam:**

- `susa self info`
- `susa self update`
- `susa self plugin list`

---

### `extract_first_positional()`

Extrai o primeiro argumento posicional, ignorando flags.

**Parâmetros:**

- `$@` - Todos os argumentos da linha de comando

**Retorno:**

- Imprime o primeiro argumento posicional via `echo`
- Código de saída `0` se encontrado, `1` caso contrário

**Uso:**

```bash
PLUGIN_NAME=$(extract_first_positional "$@")
```

**Exemplo:**

```bash
#!/bin/bash
source "$LIB_DIR/internal/args.sh"

# Em: susa plugin remove --verbose myplugin
PLUGIN_NAME=$(extract_first_positional "$@")
# PLUGIN_NAME = "myplugin"
```

---

### `validate_required_arg()`

Valida se um argumento obrigatório foi fornecido. Exibe erro e encerra se estiver vazio.

**Parâmetros:**

- `$1` - Valor do argumento a validar
- `$2` - Descrição legível do argumento (para mensagem de erro)
- `$3` - (Opcional) Formato para exibir no `show_usage`

**Comportamento:**

- Se argumento vazio: Exibe erro com `log_error`, mostra uso e encerra com `exit 1`
- Se argumento presente: Retorna normalmente

**Uso:**

```bash
validate_required_arg "$PLUGIN_NAME" "Nome do plugin" "<plugin-name>"
```

**Exemplo:**

```bash
#!/bin/bash
source "$LIB_DIR/internal/args.sh"

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            PLUGIN_ARG="$1"
            shift
            ;;
    esac
done

# Valida argumento obrigatório
validate_required_arg "${PLUGIN_ARG:-}" "Nome do plugin" "<plugin-name>"

# Se chegou aqui, PLUGIN_ARG está preenchido
main "$PLUGIN_ARG"
```

---

## Padrões de Uso

### Comando Sem Argumentos (apenas --help)

```bash
#!/bin/bash
set -euo pipefail

source "$LIB_DIR/internal/args.sh"

show_help() {
    echo "Uso: susa comando"
    echo "Este comando não aceita argumentos"
}

# Parse automático
parse_simple_help_only "$@"

# Execute função principal
main
```

**Exemplos:** `susa self info`, `susa self update`

---

### Comando com 1 Argumento Obrigatório

```bash
#!/bin/bash
set -euo pipefail

source "$LIB_DIR/internal/args.sh"

show_help() {
    echo "Uso: susa comando <argumento>"
}

# Garante pelo menos 1 argumento
require_arguments "$@"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            ARG="$1"
            shift
            break
            ;;
    esac
done

# Valida argumento obrigatório
validate_required_arg "${ARG:-}" "Argumento" "<argumento>"

# Execute com argumento validado
main "$ARG"
```

**Exemplos:** `susa self plugin remove <plugin-name>`

---

### Comando com Argumento e Flags Opcionais

```bash
#!/bin/bash
set -euo pipefail

source "$LIB_DIR/internal/args.sh"

VERBOSE="false"
ARG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        --verbose)
            VERBOSE="true"
            shift
            ;;
        *)
            ARG="$1"
            shift
            ;;
    esac
done

# Valida argumento obrigatório
validate_required_arg "$ARG" "URL do plugin" "<git-url|user/repo> [opções]"

# Execute
main "$ARG" "$VERBOSE"
```

**Exemplos:** `susa self plugin add <url> --ssh`

---

## Benefícios

### ✅ Consistência

Todos os comandos tratam argumentos da mesma forma:

- Help sempre funciona com `-h` ou `--help`
- Mensagens de erro padronizadas
- Validação uniforme

### ✅ Menos Código

Elimina ~10-20 linhas de parsing repetido por comando.

**Antes:**

```bash
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Opção desconhecida: $1"
            show_usage
            exit 1
            ;;
    esac
    shift
done
```

**Depois:**

```bash
parse_simple_help_only "$@"
```

### ✅ Manutenibilidade

Correções e melhorias em um único lugar beneficiam todos os comandos.

---

## Funções Relacionadas

Estas funções **devem existir** no comando que usar `args.sh`:

- `show_help()` - Exibe ajuda do comando
- `show_usage()` - Exibe formato de uso (geralmente fornecido por `cli.sh`)
- `log_error()` - Registra erro (fornecido por `logger.sh`)

---

## Localização

```text
core/lib/internal/args.sh
```

**Importar:**

```bash
source "$LIB_DIR/internal/args.sh"
```
