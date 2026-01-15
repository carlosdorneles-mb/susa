# string.sh

Funções auxiliares para manipulação de strings e arrays.

## Funções de String

### `to_uppercase()`

Converte string para maiúsculas.

```bash
result=$(to_uppercase "hello world")
echo "$result"  # HELLO WORLD
```

### `to_lowercase()`

Converte string para minúsculas.

```bash
result=$(to_lowercase "HELLO WORLD")
echo "$result"  # hello world
```

### `strip_whitespace()`

Remove espaços em branco do início e fim da string.

```bash
result=$(strip_whitespace "  hello world  ")
echo "$result"  # hello world
```

### `string_to_upper()`

Alias para `to_uppercase()`. Converte string para maiúsculas.

```bash
result=$(string_to_upper "hello world")
echo "$result"  # HELLO WORLD
```

### `string_to_lower()`

Alias para `to_lowercase()`. Converte string para minúsculas.

```bash
result=$(string_to_lower "HELLO WORLD")
echo "$result"  # hello world
```

### `string_trim()`

Alias para `strip_whitespace()`. Remove espaços do início e fim da string.

```bash
result=$(string_trim "  hello world  ")
echo "$result"  # hello world
```

### `string_contains()`

Verifica se uma string contém uma substring.

**Parâmetros:**

- `$1` - String completa
- `$2` - Substring a procurar

**Retorno:**

- `0` (true) - String contém a substring
- `1` (false) - String não contém a substring

**Uso:**

```bash
if string_contains "hello world" "world"; then
    echo "Contém 'world'"
fi

# Validar entrada
user_input="ubuntu-22.04"
if string_contains "$user_input" "ubuntu"; then
    echo "Sistema Ubuntu detectado"
fi
```

### `string_starts_with()`

Verifica se uma string começa com um prefixo específico.

**Parâmetros:**

- `$1` - String completa
- `$2` - Prefixo a verificar

**Retorno:**

- `0` (true) - String começa com o prefixo
- `1` (false) - String não começa com o prefixo

**Uso:**

```bash
if string_starts_with "hello world" "hello"; then
    echo "Começa com 'hello'"
fi
```

### `validate_name()`

Valida se um nome segue as convenções de nomenclatura do Susa CLI.

**Convenções:**

- Apenas letras minúsculas (a-z)
- Números (0-9)
- Hífens (-) para separar palavras
- Não pode começar ou terminar com hífen
- Não pode ter hífens consecutivos

**Parâmetros:**

- `$1` - Nome a validar

**Retorno:**

- `0` (true) - Nome é válido
- `1` (false) - Nome é inválido

**Uso:**

```bash
# Validar nome de comando
if validate_name "my-command"; then
    echo "Nome válido"
else
    echo "Nome inválido"
fi

# Validar input do usuário
read -p "Nome do comando: " cmd_name
if ! validate_name "$cmd_name"; then
    log_error "Nome inválido. Use apenas letras minúsculas, números e hífens."
    exit 1
fi

# Exemplos de validação
validate_name "docker"           # ✅ Válido
validate_name "mysql-client"     # ✅ Válido
validate_name "python3"          # ✅ Válido
validate_name "Docker"           # ❌ Inválido (maiúsculas)
validate_name "my_command"       # ❌ Inválido (underscore)
validate_name "my command"       # ❌ Inválido (espaço)
validate_name "-docker"          # ❌ Inválido (começa com hífen)
```

### `sanitize_name()`

Sanitiza um nome para seguir as convenções de nomenclatura do Susa CLI.

**Transformações aplicadas:**

- Converte para lowercase
- Substitui espaços e underscores por hífens
- Remove caracteres especiais
- Remove hífens consecutivos
- Remove hífens no início e fim

**Parâmetros:**

- `$1` - Nome a sanitizar

**Retorno:**

- String sanitizada

**Uso:**

```bash
# Sanitizar nome de comando
raw_name="My Command_Name"
clean_name=$(sanitize_name "$raw_name")
echo "$clean_name"  # my-command-name

# Sanitizar input do usuário
read -p "Nome do comando: " user_input
command_name=$(sanitize_name "$user_input")
log_info "Nome sanitizado: $command_name"

# Exemplos de sanitização
sanitize_name "Docker"           # docker
sanitize_name "My Command"       # my-command
sanitize_name "my_command"       # my-command
sanitize_name "MySQL__Client"    # mysql-client
sanitize_name "--start--"        # start
sanitize_name "Hello World!"     # hello-world
```

**Nota:** Esta função é usada internamente pelo comando `susa self lock` para processar nomes durante a geração do cache.

### `strtobool()`

Converte string para valor booleano.

**Parâmetros:**

- `$1` - String a converter

**Retorno:**
- `1` (false) - String não começa com o prefixo

**Uso:**

```bash
if string_starts_with "hello world" "hello"; then
    echo "Começa com 'hello'"
fi
```

## Funções de Conversão

### `strtobool()`

Converte string para boolean (retorno de função shell).

**Parâmetros:**

- `$1` - String a converter

**Valores aceitos:**

- **True:** "true", "1", "on", "yes" (case-insensitive)
- **False:** "false", "0", "off", "no" (case-insensitive)

**Retorno:**

- `0` - True
- `1` - False

**Uso:**

```bash
if strtobool "yes"; then
    echo "Valor é verdadeiro"
fi

if strtobool "${ENABLE_FEATURE:-false}"; then
    log_info "Feature habilitada"
fi

# Checagem de variáveis de ambiente
if strtobool "${DEBUG:-false}"; then
    log_debug "Modo debug ativo"
fi
```

- `1` (false) - String não começa com o prefixo

**Uso:**

```bash
if string_starts_with "https://example.com" "https://"; then
    echo "URL usa HTTPS"
fi

# Validar formato de branch
branch="feature/nova-funcionalidade"
if string_starts_with "$branch" "feature/"; then
    echo "Branch de feature detectada"
fi
```

## Funções de Array

### `parse_comma_separated()`

Divide elementos do array separados por vírgula em elementos individuais.

```bash
arr=("a,b,c" "d")
parse_comma_separated arr
# arr agora é: ("a" "b" "c" "d")

echo "${arr[@]}"  # a b c d
```

### `join_to_comma_separated()`

Junta todos os elementos do array em uma única string separada por vírgulas.

```bash
arr=("a" "b" "c")
join_to_comma_separated arr
# arr agora é: ("a,b,c")

echo "${arr[@]}"  # a,b,c
```

## Exemplo Completo

```bash
#!/bin/bash
source "$LIB_DIR/string.sh"

# Normalizar entrada de usuário
user_input="  Ubuntu  "
normalized=$(string_trim "$user_input")
normalized=$(string_to_lower "$normalized")

echo "Sistema: $normalized"  # Sistema: ubuntu

# Verificar conteúdo
if string_contains "$normalized" "ubuntu"; then
    echo "Sistema Ubuntu detectado"
fi

# Verificar prefixo de URL
url="https://github.com/user/repo"
if string_starts_with "$url" "https://"; then
    echo "URL segura (HTTPS)"
fi

# Processar arrays
os_list=("linux,mac" "windows")
parse_comma_separated os_list

echo "Sistemas suportados:"
for os in "${os_list[@]}"; do
    echo "- $os"
done
# Output:
# Sistemas suportados:
# - linux
# - mac
# - windows

# Converter para maiúsculas
env="production"
env_upper=$(string_to_upper "$env")
echo "Ambiente: $env_upper"  # Ambiente: PRODUCTION
```

## Boas Práticas

1. Use `string_trim()` para normalizar entrada de usuário
2. Use `string_contains()` e `string_starts_with()` para validação
3. Combine com validação de entrada antes de processar
4. Útil para processar campos de config.json
