# json.sh

Biblioteca interna de utilitários JSON usando jq para manipulação de arquivos e strings JSON.

> **⚠️ Biblioteca Interna:** Esta biblioteca está em `core/lib/internal/` e é usada internamente pelo sistema. Comandos de usuário devem usar [config.sh](config.md) para operações JSON de alto nível.

## Visão Geral

A biblioteca `json.sh` fornece funções de baixo nível para:

- 📖 Leitura de campos e valores JSON
- 🔍 Filtragem e consulta de arrays
- ✏️ Criação e modificação de objetos JSON
- ✅ Validação de JSON
- 🎨 Formatação (pretty print e compact)

## Dependências

- **jq**: Ferramenta de linha de comando para processar JSON (instalado automaticamente)

## Funções de Leitura

### `json_get_config_field()`

Obtém um campo de um arquivo JSON de configuração.

**Parâmetros:**

- `$1` - Caminho do arquivo JSON
- `$2` - Nome do campo

**Retorno:**

- Valor do campo
- Código 1 se arquivo não existir

**Uso:**

```bash
source "$LIB_DIR/internal/json.sh"

version=$(json_get_config_field "cli.json" "version")
echo "$version"  # 1.0.0
```

---

### `json_get_value()`

Obtém um valor de um arquivo JSON usando query jq.

**Parâmetros:**

- `$1` - Caminho do arquivo JSON
- `$2` - Query jq (ex: `.version`, `.plugins[0].name`)

**Retorno:**

- Valor da query
- Código 1 se arquivo não existir

**Uso:**

```bash
source "$LIB_DIR/internal/json.sh"

version=$(json_get_value "package.json" ".version")
plugin_name=$(json_get_value "registry.json" ".plugins[0].name")
```

---

### `json_get_value_from_string()`

Obtém um valor de uma string JSON usando query jq.

**Parâmetros:**

- `$1` - String JSON
- `$2` - Query jq

**Retorno:**

- Valor da query

**Uso:**

```bash
source "$LIB_DIR/internal/json.sh"

json='{"name":"test","version":"1.0.0"}'
name=$(json_get_value_from_string "$json" ".name")
echo "$name"  # test
```

---

### `json_get_array()`

Obtém elementos de um array JSON.

**Parâmetros:**

- `$1` - Caminho do arquivo JSON
- `$2` - Query jq para array (ex: `.items[]`, `.plugins[].name`)

**Retorno:**

- Elementos do array (um por linha)

**Uso:**

```bash
source "$LIB_DIR/internal/json.sh"

json_get_array "command.json" ".plugins[].name" | while read plugin; do
    echo "Plugin: $plugin"
done
```

---

## Funções de Filtragem

### `json_filter_array()`

Filtra elementos de um array usando condição.

**Parâmetros:**

- `$1` - Caminho do arquivo JSON
- `$2` - Caminho do array (ex: `.plugins`)
- `$3` - Filtro jq (ex: `select(.name == "test")`)

**Retorno:**

- Elementos filtrados (JSON, um por linha)

**Uso:**

```bash
source "$LIB_DIR/internal/json.sh"

# Buscar plugin específico
json_filter_array "registry.json" ".plugins" 'select(.name == "backup-tools")'
```

---

### `json_get_field_from_array()`

Obtém campo de um elemento filtrado de array.

**Parâmetros:**

- `$1` - Caminho do arquivo JSON
- `$2` - Caminho do array
- `$3` - Filtro jq
- `$4` - Campo a extrair (ex: `.version`)

**Retorno:**

- Valor do campo do primeiro elemento que corresponder ao filtro

**Uso:**

```bash
source "$LIB_DIR/internal/json.sh"

# Obter versão de plugin específico
version=$(json_get_field_from_array \
    "registry.json" \
    ".plugins" \
    'select(.name == "backup-tools")' \
    ".version")
echo "$version"  # 1.2.0
```

---

## Funções de Validação

### `json_is_valid()`

Verifica se um arquivo contém JSON válido.

**Parâmetros:**

- `$1` - Caminho do arquivo JSON

**Retorno:**

- `0` - JSON válido
- `1` - JSON inválido ou arquivo não existe

**Uso:**

```bash
source "$LIB_DIR/internal/json.sh"

if json_is_valid "command.json"; then
    echo "JSON válido"
else
    echo "JSON inválido ou arquivo não encontrado"
fi
```

---

## Funções de Criação

### `json_create_object()`

Cria um objeto JSON com pares chave-valor.

**Parâmetros:**

- Pares de `key value` (quantidade variável)

**Retorno:**

- String JSON do objeto criado

**Uso:**

```bash
source "$LIB_DIR/internal/json.sh"

json=$(json_create_object \
    "name" "my-plugin" \
    "version" "1.0.0" \
    "active" "true")
echo "$json"
# {"name":"my-plugin","version":"1.0.0","active":true}
```

**Nota:** A função detecta automaticamente números, booleanos (true/false) e null.

---

### `json_create_array()`

Cria um array JSON a partir de valores.

**Parâmetros:**

- Lista de valores (quantidade variável)

**Retorno:**

- String JSON do array criado

**Uso:**

```bash
source "$LIB_DIR/internal/json.sh"

json=$(json_create_array "linux" "mac" "windows")
echo "$json"
# ["linux","mac","windows"]
```

---

## Funções de Modificação

### `json_add_to_array()`

Adiciona um objeto a um array em um arquivo JSON.

**Parâmetros:**

- `$1` - Caminho do arquivo JSON
- `$2` - Caminho do array (ex: `.plugins`)
- `$3` - Objeto JSON a adicionar (string)

**Retorno:**

- Modifica o arquivo in-place

**Uso:**

```bash
source "$LIB_DIR/internal/json.sh"

new_plugin='{"name":"test-plugin","version":"1.0.0"}'
json_add_to_array "registry.json" ".plugins" "$new_plugin"
```

---

### `json_update_value()`

Atualiza um valor em um arquivo JSON.

**Parâmetros:**

- `$1` - Caminho do arquivo JSON
- `$2` - Caminho jq do campo (ex: `.version`)
- `$3` - Novo valor

**Retorno:**

- Modifica o arquivo in-place

**Uso:**

```bash
source "$LIB_DIR/internal/json.sh"

json_update_value "package.json" ".version" "2.0.0"
```

---

### `json_remove_from_array()`

Remove elementos de um array usando filtro.

**Parâmetros:**

- `$1` - Caminho do arquivo JSON
- `$2` - Caminho do array
- `$3` - Filtro jq para elementos a remover

**Retorno:**

- Modifica o arquivo in-place

**Uso:**

```bash
source "$LIB_DIR/internal/json.sh"

# Remover plugin pelo nome
json_remove_from_array \
    "registry.json" \
    ".plugins" \
    'select(.name == "old-plugin")'
```

---

### `json_merge()`

Mescla dois objetos JSON.

**Parâmetros:**

- `$1` - Primeiro objeto JSON (string)
- `$2` - Segundo objeto JSON (string)

**Retorno:**

- Objeto JSON mesclado (string)

**Nota:** O segundo objeto sobrescreve valores do primeiro em caso de conflito.

**Uso:**

```bash
source "$LIB_DIR/internal/json.sh"

json1='{"name":"test","version":"1.0"}'
json2='{"version":"2.0","author":"me"}'

merged=$(json_merge "$json1" "$json2")
echo "$merged"
# {"name":"test","version":"2.0","author":"me"}
```

---

## Funções Utilitárias

### `json_array_length()`

Retorna o tamanho de um array JSON.

**Parâmetros:**

- `$1` - Caminho do arquivo JSON
- `$2` - Caminho do array

**Retorno:**

- Número de elementos no array

**Uso:**

```bash
source "$LIB_DIR/internal/json.sh"

count=$(json_array_length "registry.json" ".plugins")
echo "Total de plugins: $count"
```

---

### `json_pretty_print()`

Formata JSON de forma legível (pretty print).

**Parâmetros:**

- `$1` - Caminho do arquivo JSON

**Retorno:**

- JSON formatado na saída padrão

**Uso:**

```bash
source "$LIB_DIR/internal/json.sh"

json_pretty_print "command.json"
```

---

### `json_compact_print()`

Formata JSON de forma compacta (minified).

**Parâmetros:**

- `$1` - Caminho do arquivo JSON

**Retorno:**

- JSON compacto na saída padrão

**Uso:**

```bash
source "$LIB_DIR/internal/json.sh"

json_compact_print "command.json"
```

---

## Exemplo Completo

```bash
#!/bin/bash
set -euo pipefail

source "$LIB_DIR/internal/json.sh"
source "$LIB_DIR/logger.sh"

# Verificar se arquivo é válido
if ! json_is_valid "registry.json"; then
    log_error "Arquivo registry.json inválido"
    exit 1
fi

# Ler informações
plugin_count=$(json_array_length "registry.json" ".plugins")
log_info "Total de plugins: $plugin_count"

# Listar plugins
log_info "Plugins instalados:"
json_get_array "registry.json" ".plugins[].name" | while read plugin; do
    version=$(json_get_field_from_array \
        "registry.json" \
        ".plugins" \
        "select(.name == \"$plugin\")" \
        ".version")
    echo "  • $plugin ($version)"
done

# Adicionar novo plugin
new_plugin=$(json_create_object \
    "name" "my-plugin" \
    "version" "1.0.0" \
    "source" "/path/to/plugin")

json_add_to_array "registry.json" ".plugins" "$new_plugin"
log_success "Plugin adicionado"

# Validar resultado
if json_is_valid "registry.json"; then
    log_success "Registry atualizado com sucesso"
    json_pretty_print "registry.json"
fi
```

## Uso em Bibliotecas Internas

Esta biblioteca é usada por:

- **[config.sh](config.md)** - Leitura de configurações e lock file
- **[registry.sh](registry.md)** - Gerenciamento do registry.json
- **[installations.sh](installations.md)** - Rastreamento de instalações

## Boas Práticas

1. **Use config.sh quando possível** - Para comandos de usuário, prefira as funções de alto nível em config.sh
2. **Valide JSON antes de processar** - Use `json_is_valid()` antes de operações complexas
3. **Use queries jq específicas** - Queries mais específicas são mais rápidas
4. **Cuidado com modificações in-place** - Funções de modificação alteram arquivos diretamente
5. **Teste queries jq separadamente** - Use `jq` diretamente no terminal para testar queries complexas

## Localização

- **Arquivo:** `core/lib/internal/json.sh`
- **Tipo:** Biblioteca interna
- **Dependências:** jq (instalado automaticamente)

## Veja Também

- [config.sh](config.md) - Parser de configurações (alto nível)
- [registry.sh](registry.md) - Gerenciamento de plugins
- [installations.sh](installations.md) - Rastreamento de instalações
- [susa self lock](../commands/self/lock.md) - Comando que gerencia o lock file
