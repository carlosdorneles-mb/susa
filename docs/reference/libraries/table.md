# table.sh

Sistema genérico de renderização de tabelas usando `column` para alinhamento automático.

## Descrição

A biblioteca `table.sh` fornece funções para criar e exibir tabelas formatadas de forma consistente em todo o CLI. Usa o comando `column` para alinhamento automático das colunas.

## Carregamento

```bash
source "$LIB_DIR/table.sh"
```

## API

### `table_init([--no-number])`

Inicializa uma nova tabela, limpando qualquer dado anterior.

**Opções:**

- `--no-number` - Desabilita numeração automática de linhas (habilitada por padrão)

**Comportamento padrão:**

Por padrão, a biblioteca adiciona automaticamente uma coluna `#` como primeira coluna e numera as linhas sequencialmente (1, 2, 3...). Você não precisa passar manualmente o número da linha.

**Exemplo:**

```bash
table_init              # Com numeração automática (padrão)
table_init --no-number  # Sem numeração automática
```

### `table_set_indent(indentação)`

Define a indentação da tabela (padrão: 2 espaços).

**Argumentos:**

- `indentação` - String de indentação (ex: "  ", "    ")

**Exemplo:**

```bash
table_set_indent "    "  # 4 espaços
```

### `table_add_header(col1, col2, ...)`

Adiciona uma linha de cabeçalho com formatação em negrito/cinza.

**Argumentos:**

- `col1, col2, ...` - Valores das colunas do cabeçalho

**Comportamento com numeração automática:**

Se a numeração automática estiver habilitada (padrão), a coluna `#` é adicionada automaticamente. Você não precisa incluí-la manualmente nos argumentos.

**Exemplo:**

```bash
# Com numeração automática (padrão)
table_init
table_add_header "Nome" "Idade" "Cidade"
# Resultado: #  Nome  Idade  Cidade

# Sem numeração automática
table_init --no-number
table_add_header "Nome" "Idade" "Cidade"
# Resultado: Nome  Idade  Cidade
```

### `table_add_row(val1, val2, ...)`

Adiciona uma linha de dados à tabela.

**Argumentos:**

- `val1, val2, ...` - Valores das colunas

**Comportamento com numeração automática:**

Se a numeração automática estiver habilitada (padrão), o número da linha é adicionado automaticamente como primeira coluna. Você não precisa passar o número manualmente.

**Exemplo:**

```bash
# Com numeração automática (padrão)
table_init
table_add_header "Nome" "Status"
table_add_row "João" "${GREEN}✓${NC}"
table_add_row "Maria" "${GREEN}✓${NC}"
# Resultado:
#   #  Nome   Status
#   1  João   ✓
#   2  Maria  ✓

# Sem numeração automática
table_init --no-number
table_add_header "Nome" "Status"
table_add_row "João" "${GREEN}✓${NC}"
table_add_row "Maria" "${GREEN}✓${NC}"
# Resultado:
#   Nome   Status
#   João   ✓
#   Maria  ✓
```

### `table_render([--no-clear])`

Renderiza a tabela usando `column` para alinhamento.

**Opções:**

- `--no-clear` - Não limpa a tabela após renderizar (padrão: limpa)

**Exemplo:**

```bash
table_render
# ou
table_render --no-clear
```

### `table_get_data()`

Retorna o conteúdo atual da tabela (útil para debugging).

**Exemplo:**

```bash
local data=$(table_get_data)
echo "Dados da tabela: $data"
```

### `table_count_rows()`

Retorna o número de linhas na tabela.

**Exemplo:**

```bash
local count=$(table_count_rows)
echo "Total de linhas: $count"
```

## Exemplo Completo

### Exemplo Básico

```bash
#!/bin/bash
source "$LIB_DIR/table.sh"

# Criar tabela (com numeração automática por padrão)
table_init
table_add_header "Nome" "Tamanho" "Status"

# Adicionar dados (números adicionados automaticamente)
table_add_row "${CYAN}lock${NC}" "8KB" "${GREEN}✓${NC}"
table_add_row "${CYAN}context${NC}" "2KB" "${GREEN}✓${NC}"
table_add_row "${CYAN}temp${NC}" "512B" "${YELLOW}⚠${NC}"

# Renderizar
table_render

# Output:
#   #  Nome     Tamanho  Status
#   1  lock     8KB      ✓
#   2  context  2KB      ✓
#   3  temp     512B     ⚠
```

### Exemplo Sem Numeração

```bash
#!/bin/bash
source "$LIB_DIR/table.sh"

# Criar tabela sem numeração automática
table_init --no-number
table_add_header "Nome" "Tamanho" "Status"

# Adicionar dados
table_add_row "${CYAN}lock${NC}" "8KB" "${GREEN}✓${NC}"
table_add_row "${CYAN}context${NC}" "2KB" "${GREEN}✓${NC}"

# Renderizar
table_render

# Output:
#   Nome     Tamanho  Status
#   lock     8KB      ✓
#   context  2KB      ✓
```

### Exemplo com Numeração Automática

```bash
#!/bin/bash
source "$LIB_DIR/table.sh"

# Lista de items
local items=(
    "lock:8KB:active"
    "context:2KB:active"
    "temp:512B:warning"
)

# Criar tabela (numeração automática habilitada por padrão)
table_init
table_add_header "Nome" "Tamanho" "Status"

# Adicionar dados (sem passar números manualmente)
for item in "${items[@]}"; do
    IFS=':' read -r name size status <<< "$item"

    # Escolher cor do status
    local status_color="${GREEN}"
    local status_icon="✓"
    if [[ "$status" == "warning" ]]; then
        status_color="${YELLOW}"
        status_icon="⚠"
    fi

    # Não é necessário passar o número - é adicionado automaticamente
    table_add_row "${CYAN}${name}${NC}" "$size" "${status_color}${status_icon}${NC}"
done

# Renderizar
table_render

# Resumo
local total=${#items[@]}
echo ""
log_output "${BOLD}Total:${NC} $total item(s)"

# Output:
#   #  Nome     Tamanho  Status
#   1  lock     8KB      ✓
#   2  context  2KB      ✓
#   3  temp     512B     ⚠
#
#   Total: 3 item(s)
```

## Uso em Plugins

Plugins podem usar a biblioteca da mesma forma:

```bash
#!/bin/bash
# No plugin
source "$LIB_DIR/table.sh"

table_init
table_add_header "ID" "Name" "Version"

for app in "${apps[@]}"; do
    table_add_row "$id" "$name" "$version"
done

table_render
```

## Características

✅ **Alinhamento automático** - `column` ajusta colunas ao conteúdo
✅ **Suporte a cores** - Códigos ANSI são preservados
✅ **Cross-platform** - Funciona em Linux e macOS
✅ **API simples** - Funções intuitivas
✅ **Reutilizável** - Disponível para comandos e plugins
✅ **Consistente** - Mesma formatação em todo o CLI

## Notas

- O separador de colunas é `\t` (tab)
- Indentação padrão é 2 espaços
- A tabela é limpa automaticamente após `table_render()`
- Cores são carregadas de `color.sh` se disponível

## Veja Também

- [color.sh](color.md) - Sistema de cores
- [logger.sh](logger.md) - Sistema de logs
