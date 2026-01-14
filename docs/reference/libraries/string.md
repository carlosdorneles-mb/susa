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

Remove espaços do início e fim da string.

```bash
result=$(strip_whitespace "  hello world  ")
echo "$result"  # hello world
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

# Strings
user_input="  Ubuntu  "
normalized=$(strip_whitespace "$user_input")
normalized=$(to_lowercase "$normalized")

echo "Sistema: $normalized"  # Sistema: ubuntu

# Arrays
os_list=("linux,mac" "windows")
parse_comma_separated os_list

for os in "${os_list[@]}"; do
    echo "- $os"
done
# Output:
# - linux
# - mac
# - windows
```

## Boas Práticas

1. Use para normalizar entrada de usuário
2. Combine com validação de entrada
3. Útil para processar campos de config.yaml
