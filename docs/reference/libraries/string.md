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
4. Útil para processar campos de config.yaml
