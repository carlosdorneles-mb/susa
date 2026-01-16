# Installations Library

Biblioteca para rastreamento de instalações de software no arquivo `susa.lock`.

## Localização

```text
core/lib/internal/installations.sh
```

## Descrição

A biblioteca `installations.sh` fornece funções para rastrear instalações de software gerenciadas pelo Susa CLI. Mantém um registro de:

- Software instalado via comandos `susa setup`
- Versões instaladas
- Timestamps de instalação/atualização
- Estado de instalação (instalado/desinstalado)

Todas as informações são armazenadas na seção `installations` do arquivo `susa.lock`.

**Integração Visual**: O CLI automaticamente exibe um **`✓`** verde ao lado de comandos `setup` que estão instalados, proporcionando feedback visual instantâneo do estado das instalações.

**Exemplo:**

```text
Comandos:
  asdf            Instala ASDF ✓
  docker          Instala Docker ✓ [sudo]
  postgres        Instala PostgreSQL [sudo]
```

## Funções Disponíveis

### Rastreamento de Instalações

#### `_mark_installed_software_in_lock()`

Marca um software como instalado no lock file.

**Parâmetros:**

- `$1` - Nome do software (ex: "docker", "podman")
- `$2` - Versão instalada (opcional, padrão: "unknown")

**Retorno:**

- `0` - Sucesso
- `1` - Lock file não encontrado

**Comportamento:**

- Cria a seção `installations` se não existir
- Atualiza entrada existente ou cria nova
- Registra timestamp de instalação

**Exemplo:**

```bash
source "$LIB_DIR/internal/installations.sh"

# Após instalar Docker
_mark_installed_software_in_lock "docker" "24.0.5"

# Sem versão específica
_mark_installed_software_in_lock "podman"
```

#### `remove_software_in_lock()`

Marca um software como desinstalado no lock file.

**Parâmetros:**

- `$1` - Nome do software

**Retorno:**

- `0` - Sucesso

**Comportamento:**

- Define `installed: false`
- Remove a versão (`version: null`)
- Remove o timestamp de instalação
- Mantém o registro no lock para histórico

**Exemplo:**

```bash
# Após desinstalar Docker
remove_software_in_lock "docker"
```

#### `update_version()`

Atualiza a versão de um software já instalado.

**Parâmetros:**

- `$1` - Nome do software
- `$2` - Nova versão

**Retorno:**

- `0` - Sucesso
- `1` - Software não encontrado no lock

**Comportamento:**

- Atualiza apenas a versão
- Registra timestamp de atualização

**Exemplo:**

```bash
# Após atualizar Docker de 24.0.5 para 24.0.6
update_version "docker" "24.0.6"
```

### Consultas

#### `is_installed()`

Verifica se um software está marcado como instalado.

**Parâmetros:**

- `$1` - Nome do software

**Retorno:**

- `0` - Software está instalado
- `1` - Software não está instalado ou não encontrado

**Exemplo:**

```bash
if is_installed "docker"; then
    echo "Docker está instalado"
else
    echo "Docker não está instalado"
fi
```

#### `get_installed_version()`

Obtém a versão instalada de um software.

**Parâmetros:**

- `$1` - Nome do software

**Retorno:**

- Imprime a versão e retorna `0` se encontrada
- Retorna `1` se não encontrada

**Exemplo:**

```bash
version=$(get_installed_version "docker")
if [ $? -eq 0 ]; then
    echo "Docker versão: $version"
fi
```

#### `get_installation_info()`

Obtém informações completas sobre uma instalação.

**Parâmetros:**

- `$1` - Nome do software

**Retorno:**

- Imprime informações JSON completas
- Retorna `1` se não encontrada

**Exemplo:**

```bash
get_installation_info "docker"
# Saída:
# {
#   "name": "docker",
#   "installed": true,
#   "version": "24.0.5",
#   "installedAt": "2026-01-14T15:27:36Z"
# }
```

#### `list_installed()`

Lista todos os softwares marcados como instalados.

**Retorno:**

- Imprime lista de nomes (um por linha)
- Retorna `1` se lock file não existir

**Exemplo:**

```bash
echo "Softwares instalados:"
list_installed | while read software; do
    version=$(get_installed_version "$software")
    echo "  - $software ($version)"
done
```

### Detecção e Sincronização

#### `check_software_installed()`

Verifica se um software está realmente instalado no sistema (sem prompts).

**Parâmetros:**

- `$1` - Nome do software

**Retorno:**

- `0` - Software está instalado no sistema
- `1` - Software não está instalado

**Comportamento:**

- Verifica binários no PATH
- Verifica diretórios específicos (ex: `~/.asdf`, `/Applications/iTerm.app`)
- Não exibe mensagens ou prompts

**Softwares Suportados:**

- docker, podman, mise, asdf
- poetry, uv, tilix, iterm
- toolbox/jetbrains-toolbox

**Exemplo:**

```bash
if check_software_installed "docker"; then
    echo "Docker encontrado no sistema"
fi
```

#### `get_current_software_version()`

Obtém a versão de um software instalado no sistema (sem prompts).

**Parâmetros:**

- `$1` - Nome do software

**Retorno:**

- Imprime a versão detectada
- Imprime "unknown" se não puder detectar

**Exemplo:**

```bash
version=$(get_current_software_version "docker")
echo "Docker versão: $version"
```

#### `get_available_setup_commands()`

Lista todos os comandos setup disponíveis.

**Retorno:**

- Imprime lista de comandos (um por linha)

**Exemplo:**

```bash
get_available_setup_commands
# Saída:
# asdf
# docker
# iterm
# mise
# podman
# poetry
# ...
```

#### `sync_installations()`

Sincroniza instalações entre o sistema e o lock file.

**Comportamento:**

1. **Adiciona novas instalações (Sistema → Lock)**
   - Detecta software instalado no sistema
   - Adiciona ao lock se não estiver registrado
   - Obtém e registra a versão

2. **Remove instalações desinstaladas (Lock → Sistema)**
   - Verifica software no lock marcado como instalado
   - Detecta se foi desinstalado do sistema
   - Marca como `installed: false` no lock

**Saída:**

```bash
$ sync_installations
[INFO] Sincronizando instalações...
[SUCCESS] Sincronizado: docker (29.1.4)
[SUCCESS] Sincronizado: podman (5.7.1)
[WARNING] Removido do lock: fake-app (não está mais instalado)

[SUCCESS] 2 software(s) adicionado(s) ao lock file.
[SUCCESS] 1 software(s) removido(s) do lock file.
```

**Exemplo de Integração:**

```bash
#!/bin/bash
source "$LIB_DIR/internal/installations.sh"

# Após gerar lock file
generate_lock_file

# Sincronizar instalações
sync_installations
```

## Uso em Comandos Setup

Os comandos `susa setup` devem usar estas funções para rastrear instalações:

```bash
#!/bin/bash
source "$LIB_DIR/internal/installations.sh"

install_docker() {
    # ... lógica de instalação ...

    # Verificar instalação
    if command -v docker &>/dev/null; then
        local version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        log_success "Docker $version instalado com sucesso!"

        # Registrar no lock file
        _mark_installed_software_in_lock "docker" "$version"
    fi
}

update_docker() {
    # ... lógica de atualização ...

    if command -v docker &>/dev/null; then
        local new_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

        # Atualizar versão no lock file
        update_version "docker" "$new_version"
    fi
}

uninstall_docker() {
    # ... lógica de desinstalação ...

    # Marcar como desinstalado
    remove_software_in_lock "docker"
}
```

## Integração com `susa self lock`

O comando `susa self lock --sync` utiliza estas funções para sincronização:

```bash
main() {
    local should_sync=false

    # Parse argumentos
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --sync)
                should_sync=true
                shift
                ;;
        esac
    done

    # Gerar lock file
    generate_lock_file

    # Sincronizar se solicitado
    if [ "$should_sync" = true ]; then
        sync_installations
    fi
}
```

## Estrutura no Lock File

```json
{
  "installations": [
    {
      "name": "docker",
      "installed": true,
      "version": "29.1.4",
      "installedAt": "2026-01-14T15:27:36Z"
    },
    {
      "name": "mise",
      "installed": true,
      "version": "2026.1.1",
      "installedAt": "2026-01-14T15:27:36Z",
      "updatedAt": "2026-01-14T16:00:00Z"
    },
    {
      "name": "fake-app",
      "installed": false,
      "version": null
    }
  ]
}
```

## Dependências

Esta biblioteca requer:

- `jq` - Parser JSON (instalado via `ensure_jq_installed`)
- `$LIB_DIR/dependencies.sh` - Para verificar dependências
- `$LIB_DIR/logger.sh` - Para mensagens (usado em sync_installations)
- Variável `$CLI_DIR` - Diretório raiz do CLI

## Notas Importantes

1. **Lock File Obrigatório**: Todas as funções assumem que `susa.lock` existe
2. **Timestamps UTC**: Usa formato ISO 8601 com timezone UTC
3. **Preservação em Regeneração**: O `generate_lock_file` preserva a seção `installations`
4. **Sem Prompts**: Funções de detecção não exibem prompts ao usuário
5. **Idempotência**: Pode ser chamado múltiplas vezes sem efeitos colaterais

## Casos de Uso

### Verificar Status Antes de Instalar

```bash
if is_installed "docker"; then
    current_version=$(get_installed_version "docker")
    echo "Docker $current_version já está instalado"
    exit 0
fi

# Prosseguir com instalação
install_docker
```

### Auditoria de Instalações

```bash
echo "=== Softwares Gerenciados pelo Susa ==="
list_installed | while read software; do
    version=$(get_installed_version "$software")

    # Verificar se ainda está no sistema
    if check_software_installed "$software"; then
        echo "✓ $software ($version) - OK"
    else
        echo "✗ $software ($version) - DESINSTALADO"
    fi
done
```

### Detecção de Drift

```bash
# Comparar lock com sistema
list_installed | while read software; do
    lock_version=$(get_installed_version "$software")
    system_version=$(get_current_software_version "$software")

    if [ "$lock_version" != "$system_version" ]; then
        echo "DRIFT: $software"
        echo "  Lock:   $lock_version"
        echo "  System: $system_version"
    fi
done
```

## Ver Também

- [susa self lock](../commands/self/lock.md) - Comando que usa esta biblioteca
- [Logger Library](logger.md) - Para mensagens consistentes
- [Config Library](config.md) - Para manipulação de JSON
- [Dependencies Library](dependencies.md) - Para verificar dependências
