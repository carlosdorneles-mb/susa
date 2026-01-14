# registry.sh

Gerenciamento do arquivo `registry.yaml` de plugins.

## Funções

### `registry_add_plugin()`

Adiciona um plugin ao registry.

**Parâmetros:**

- `$1` - Caminho do arquivo registry.yaml
- `$2` - Nome do plugin
- `$3` - URL do repositório
- `$4` - Versão (opcional, padrão: "1.0.0")

**Retorno:**

- `0` - Plugin adicionado
- `1` - Plugin já existe

```bash
registry_file="/opt/susa/plugins/registry.yaml"

registry_add_plugin "$registry_file" "myplugin" "https://github.com/user/plugin.git" "1.2.0"
```

### `registry_remove_plugin()`

Remove um plugin do registry.

```bash
registry_remove_plugin "$registry_file" "myplugin"
```

### `registry_list_plugins()`

Lista todos os plugins do registry em formato delimitado por `|`.

**Retorno:** Linhas no formato: `nome|source|version|installed_at`

```bash
registry_list_plugins "$registry_file" | while IFS='|' read -r name source version installed; do
    echo "Plugin: $name"
    echo "  Source: $source"
    echo "  Version: $version"
    echo "  Installed: $installed"
done
```

### `registry_get_plugin_info()`

Obtém informação específica de um plugin.

**Parâmetros:**

- `$1` - Caminho do arquivo registry.yaml
- `$2` - Nome do plugin
- `$3` - Campo (source, version, installed_at)

```bash
source=$(registry_get_plugin_info "$registry_file" "myplugin" "source")
version=$(registry_get_plugin_info "$registry_file" "myplugin" "version")

echo "Plugin myplugin: $version ($source)"
```

## Exemplo Completo

```bash
#!/bin/bash
source "$LIB_DIR/registry.sh"

registry_file="$CLI_DIR/plugins/registry.yaml"

# Adiciona plugin
registry_add_plugin "$registry_file" "awesome" "https://github.com/user/awesome.git" "2.0.0"

# Lista todos
echo "Plugins instalados:"
registry_list_plugins "$registry_file" | while IFS='|' read -r name source version installed; do
    echo "- $name v$version (instalado em: $installed)"
done

# Obtém info específica
version=$(registry_get_plugin_info "$registry_file" "awesome" "version")
echo "Versão do awesome: $version"

# Remove plugin
registry_remove_plugin "$registry_file" "awesome"
```

## Boas Práticas

1. Sempre verifique se registry existe antes de usar
2. Use em conjunto com plugin.sh
3. Mantenha registry sincronizado com diretório plugins/
