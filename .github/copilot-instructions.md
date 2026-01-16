# Copilot Instructions - SUSA CLI

Este documento contém diretrizes e conhecimento sobre o projeto SUSA CLI para auxiliar o GitHub Copilot.

## 📋 Índice

1. [Quick Reference](#-quick-reference) - Comandos e padrões mais usados
2. [Arquitetura do Projeto](#️-arquitetura-do-projeto) - Estrutura de diretórios
3. [Sistema de Categorias, Comandos e Plugins](#-sistema-de-categorias-comandos-e-plugins)
4. [Sistema de Cache](#-sistema-de-cache)
5. [Bibliotecas Core](#-bibliotecas-core---guia-de-uso)
6. [Padrões de Código](#-padrões-de-código)
7. [Fluxo de Dados](#-fluxo-de-dados)
8. [Padrões de Performance](#-padrões-de-performance)
9. [Testing Guidelines](#-testing-guidelines)
10. [Documentação de Comandos](#-documentação-de-comandos)
11. [Learning Resources](#-learning-resources)

---

## 🎯 Quick Reference

### Comandos Mais Usados

```bash
# Cache - SEMPRE use para múltiplas consultas
cache_load
is_installed_cached "docker"
get_installed_version_cached "docker"

# Registry - NUNCA use jq diretamente
registry_plugin_exists "$file" "nome"
registry_get_plugin_info "$file" "nome" "version"

# Instalações - Preferir funções cached
register_or_update_software_in_lock "docker" "24.0"
get_installed_from_cache
```

### Ordem de Source de Bibliotecas

```bash
# Sempre nesta ordem (dependências resolvidas):
source "$LIB_DIR/logger.sh"
source "$LIB_DIR/color.sh"
source "$LIB_DIR/internal/cache.sh"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/internal/registry.sh"
source "$LIB_DIR/github.sh"
```

### Padrões Críticos

| ✅ Fazer | ❌ Evitar |
|----------|-----------|
| `cache_load` antes de loop | `jq` direto no lock file |
| `is_installed_cached()` | `is_installed()` em loop |
| `registry_get_plugin_info()` | `jq` direto no registry |
| `cache_refresh()` após sync | Cache stale após modificações |

---

## 🏗️ Arquitetura do Projeto

### Estrutura de Diretórios

```
susa/
├── core/
│   ├── susa                    # Executável principal
│   ├── cli.json                # Metadados do CLI
│   └── lib/                    # Bibliotecas compartilhadas
│       ├── *.sh                # Bibliotecas públicas (color, logger, github, etc)
│       └── internal/           # Bibliotecas internas (cache, registry, installations)
├── commands/
│   ├── self/                   # Comandos de gerenciamento do CLI
│   ├── setup/                  # Comandos de instalação de software
│   └── [categoria]/            # Outras categorias de comandos
├── plugins/                    # Plugins instalados
│   └── registry.json           # Registro de plugins
├── config/
│   └── settings.conf           # Configurações globais
└── docs/                       # Documentação
```

## 🔧 Sistema de Categorias, Comandos e Plugins

### Categorias

Categorias organizam comandos em grupos lógicos. Cada categoria tem um arquivo `category.json`:

**Estrutura do category.json:**
```json
{
  "name": "Setup",
  "description": "Instalação e atualização de softwares e ferramentas",
  "entrypoint": "main.sh"  // Opcional - script executado pela categoria
}
```

**Tipos de categorias:**
1. **Top-level:** Diretamente em `commands/` (ex: `setup`, `self`)
2. **Subcategorias:** Aninhadas (ex: `self/plugin`, `self/cache`)

**Entrypoint (opcional):**
- Se categoria tem `entrypoint`, executa `main.sh` ao invés de listar comandos
- Exemplo: `susa setup --list` executa `commands/setup/main.sh --list`
- Script pode implementar `show_complement_help()` para adicionar info na listagem

### Comandos

Comandos são scripts executáveis dentro de categorias. Cada comando tem:
- **Diretório:** `commands/[categoria]/[comando]/`
- **Arquivo de config:** `command.json`
- **Script principal:** `main.sh`

**Estrutura do command.json:**
```json
{
  "name": "Docker",
  "description": "Instala Docker CLI e Engine (plataforma de containers)",
  "entrypoint": "main.sh",
  "sudo": true,              // Se requer privilégios root
  "group": "container",      // Agrupa comandos relacionados
  "os": ["linux", "mac"],    // Sistemas operacionais compatíveis
  "envs": {                  // Variáveis de ambiente específicas
    "DOCKER_DOWNLOAD_BASE_URL": "https://download.docker.com"
  }
}
```

**Campos importantes:**
- `name`: Nome exibido no help
- `description`: Descrição do comando
- `entrypoint`: Script a executar (sempre `main.sh`)
- `sudo`: Exibe indicador `[sudo]` no help
- `group`: Agrupa comandos na listagem (ex: "container", "runtime")
- `os`: Array com sistemas suportados (`linux`, `mac`, `windows`)
- `envs`: Variáveis de ambiente injetadas antes da execução

**Indicadores na listagem:**
- `✓` - Software já instalado (categoria setup)
- `[sudo]` - Requer privilégios de administrador
- `[plugin]` - Comando vem de plugin instalado
- `[dev]` - Plugin em modo desenvolvimento

**Descoberta de comandos:**
1. CLI lê `susa.lock` (gerado por `susa self lock`)
2. Busca em `commands/[categoria]/[comando]/command.json`
3. Busca em plugins instalados
4. Valida compatibilidade de OS

### Plugins

Plugins estendem o CLI com novos comandos e categorias. Há dois tipos:

#### 1. Plugins Remotos (GitHub)

**Instalação:**
```bash
susa self plugin add https://github.com/usuario/meu-plugin
```

**Localização:** `plugins/meu-plugin/`

**Processo:**
1. Clone do repositório
2. Validação do `plugin.json`
3. Registro em `plugins/registry.json`
4. Regeneração do `susa.lock`

#### 2. Plugins de Desenvolvimento (Local)

**Instalação:**
```bash
susa self plugin add /caminho/local/meu-plugin --dev
```

**Características:**
- Marcado com `"dev": true` no registry
- Usa caminho local no campo `source`
- Permite desenvolvimento iterativo sem commit
- Indicador `[dev]` na listagem de comandos

**Estrutura do plugin.json:**
```json
{
  "name": "meu-plugin",
  "version": "1.0.0",
  "description": "Descrição do plugin",
  "directory": "commands"  // Opcional - onde ficam as categorias
}
```

**Campos:**
- `name`: Identificador único do plugin (obrigatório)
- `version`: Versão semântica (obrigatório)
- `description`: Descrição curta (opcional)
- `directory`: Subdiretório com categorias (opcional, padrão: raiz do plugin)

**Estrutura de arquivos:**
```
meu-plugin/
├── plugin.json
└── commands/              # Se directory="commands"
    └── dev/               # Nova categoria
        ├── category.json
        └── test/          # Novo comando
            ├── command.json
            └── main.sh
```

**Registry (plugins/registry.json):**
```json
{
  "version": "1.0.0",
  "plugins": [
    {
      "name": "remote-plugin",
      "source": "https://github.com/user/plugin",
      "version": "1.0.0",
      "installedAt": "2026-01-16T10:00:00Z",
      "dev": false
    },
    {
      "name": "dev-plugin",
      "source": "/home/user/projects/dev-plugin",
      "version": "0.1.0",
      "installedAt": "2026-01-16T11:00:00Z",
      "dev": true
    }
  ]
}
```

### Fluxo de Execução

**1. Descoberta de comandos:**
```
susa [categoria] [comando] [args]
  ↓
1. Validar categoria existe
2. Buscar comando em commands/categoria/comando/
3. Buscar comando em plugins/*/commands/categoria/comando/
4. Buscar comando em dev plugins (via registry.json)
5. Validar OS compatível
6. Carregar command.json
  ↓
Executar main.sh com argumentos
```

**2. Geração do lock file:**
```
susa self lock
  ↓
1. Escanear commands/*/category.json
2. Escanear commands/*/*/command.json
3. Escanear plugins/*/plugin.json
4. Escanear plugins/*/commands/ (se directory definido)
5. Escanear dev plugins do registry
6. Gerar JSON consolidado em susa.lock
7. Atualizar cache
```

**3. Listagem com cache:**
```
susa setup
  ↓
1. cache_load (carrega susa.lock em memória)
2. cache_query '.categories[] | select(.name == "Setup")'
3. cache_get_category_commands "setup"
4. Filtrar por OS atual
5. Agrupar por 'group' field
6. Adicionar indicadores (✓, [sudo], [plugin], [dev])
7. Exibir formatado
```

### Bibliotecas de Suporte

**config.sh** - Leitura de metadados
```bash
get_category_info "$lock_file" "setup" "description"
get_command_info "$lock_file" "setup" "docker" "description"
is_command_compatible "$lock_file" "setup" "docker" "linux"
get_category_commands "setup" "linux"
requires_sudo "$lock_file" "setup" "docker"
```

**plugin.sh** - Gerenciamento de plugins
```bash
validate_plugin_config "/path/to/plugin"
read_plugin_config "/path/to/plugin"  # Retorna: name|version|description|directory
detect_plugin_version "/path/to/plugin"
get_plugin_name "/path/to/plugin"
```

**cli.sh** - Helpers para comandos
```bash
build_command_path        # Ex: "self plugin add"
get_command_config_file   # Retorna caminho do command.json
show_usage "[options]"    # Exibe: "susa self plugin add [options]"
show_description          # Lê description do command.json
```

## 🚀 Sistema de Cache

### Como Funciona

O SUSA implementa um sistema de cache em memória para otimizar leituras do arquivo `susa.lock`:

1. **Localização:** `${XDG_RUNTIME_DIR:-/tmp}/susa-$USER/lock.cache`
2. **Invalidação:** Automática quando `susa.lock` é modificado
3. **Carregamento:** Lazy loading na primeira consulta
4. **Formato:** JSON minificado em memória

### Bibliotecas e Cache

#### ✅ SEMPRE usar cache para:
- Listar comandos disponíveis
- Verificar existência de plugins
- Consultar metadados de categorias
- **Consultas múltiplas em loop**

#### ❌ NUNCA usar cache para:
- Escrever no lock file
- Dados após `sync_installations()` (usar `cache_refresh()`)
- Modificações em registry.json

### Funções de Cache (core/lib/internal/cache.sh)

```bash
# Carregar cache (chamada única no início)
cache_load

# Consultar dados do cache
cache_query '.installations[].name'

# Funções especializadas
cache_get_categories
cache_get_plugins
cache_get_category_commands "setup"

# Atualizar cache após modificações
cache_refresh

# Limpar cache
cache_clear
```

## 📚 Bibliotecas Core - Guia de Uso

### internal/installations.sh

**Funções Otimizadas (Preferir):**
```bash
# ✅ Usa cache - rápido para múltiplas consultas
cache_load
is_installed_cached "docker"
get_installed_version_cached "docker"
get_installed_from_cache  # Lista todos instalados

# ✅ Para escrita no lock
register_or_update_software_in_lock "docker" "24.0"
remove_software_in_lock "docker"
```

**Funções Legadas (Usar quando necessário):**
```bash
# ⚠️ Lê do disco a cada chamada - mais lento
is_installed "docker"              # Para casos isolados
get_installed_version "docker"     # Para casos isolados
```

**Quando usar cada uma:**
- **Uma verificação:** Use função sem cache
- **Loop ou múltiplas verificações:** Use `cache_load` + funções cached
- **Após sync:** Use `cache_refresh()` antes de consultar

### internal/registry.sh

**Funções Disponíveis:**
```bash
# Verificações
registry_plugin_exists "$file" "plugin-name"
registry_is_dev_plugin "$file" "plugin-name"

# Consultas
registry_get_plugin_info "$file" "plugin-name" "version"
registry_get_plugin_by_source "$file" "/path/to/plugin"
registry_count_plugins "$file"
registry_get_all_plugin_names "$file"

# Modificações
registry_add_plugin "$file" "name" "source" "version" "false"
registry_remove_plugin "$file" "name"
```

**❌ NUNCA faça:**
```bash
# Ruim - acesso direto ao registry
jq -r '.plugins[] | select(.name == "x")' "$registry_file"

# ✅ Bom - use funções da biblioteca
registry_get_plugin_info "$registry_file" "x" "version"
```

### github.sh

**Funções Disponíveis:**
```bash
# Obter versões
github_get_latest_version "owner/repo"
github_get_version_from_raw "owner/repo" "main" "version.json" "version"
github_get_latest_version_with_fallback "owner/repo" "main" "cli.json" "version"

# Downloads
github_download_release "$url" "$output" "description"
github_verify_checksum "$file" "$checksum" "sha256"

# Detecção de sistema
github_detect_os_arch "standard"  # Returns "linux:x64"
```

## 🎨 Padrões de Código

### Nomenclatura

```bash
# Funções públicas (sem underscore)
is_installed()
get_latest_version()
cache_load()

# Funções internas (com underscore)
_cache_init()
_query_installation_field()
_mark_installed_software_in_lock()

# Funções com cache (sufixo _cached)
is_installed_cached()
get_installed_version_cached()
```

### Estrutura de Comandos

```bash
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source libraries (ordem importa!)
source "$LIB_DIR/logger.sh"
source "$LIB_DIR/internal/installations.sh"  # Se usar instalações
source "$LIB_DIR/internal/registry.sh"       # Se usar plugins
source "$LIB_DIR/github.sh"                  # Se usar GitHub

# Help function
show_help() {
    show_description
    log_output ""
    show_usage "[options]"
    # ... resto da ajuda
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help) show_help; exit 0 ;;
            -v | --verbose) export DEBUG=1; shift ;;
            *) log_error "Opção inválida: $1"; exit 1 ;;
        esac
    done

    # Lógica principal aqui
}

# Execute main
main "$@"
```

### Tratamento de Erros

```bash
# ✅ Bom - verificar antes de usar
if [ ! -f "$file" ]; then
    log_error "Arquivo não encontrado: $file"
    return 1
fi

# ✅ Bom - usar set -e e || para tratamento
command_that_might_fail || {
    log_error "Falha ao executar comando"
    return 1
}

# ❌ Ruim - não verificar erros
result=$(command_that_might_fail)
```

### Logs e Output

```bash
# Debug (apenas se DEBUG=1)
log_debug "Informação de debug"

# Informacional
log_info "Processando..."

# Sucesso
log_success "✓ Operação concluída!"

# Warning
log_warning "⚠ Atenção!"

# Erro
log_error "✗ Erro crítico"

# Output sem timestamp
log_output "Resultado: valor"
```

## 🔄 Fluxo de Dados

### Lock File (susa.lock)

**Estrutura:**
```json
{
  "version": "1.0.0",
  "generatedAt": "2026-01-16T...",
  "categories": [...],
  "commands": [...],
  "plugins": [...],
  "installations": [
    {
      "name": "docker",
      "installed": true,
      "version": "24.0.5",
      "installedAt": "2026-01-14T..."
    }
  ]
}
```

**Modificação:**
1. Sempre use funções de `installations.sh` ou `lock.sh`
2. Após modificar, considere atualizar o cache
3. Nunca edite manualmente em produção

### Registry (plugins/registry.json)

**Estrutura:**
```json
{
  "version": "1.0.0",
  "plugins": [
    {
      "name": "my-plugin",
      "source": "https://github.com/...",
      "version": "1.0.0",
      "installedAt": "2026-01-14T...",
      "dev": false
    }
  ]
}
```

**Modificação:**
1. Use funções de `registry.sh`
2. Para dev plugins, marque `dev: true` e use caminho local em `source`

## 🔍 Dependency Chain

```
cli.sh
  ↓
installations.sh → cache.sh, json.sh
  ↓
registry.sh (standalone)
  ↓
plugin.sh → git.sh
  ↓
config.sh → registry.sh, json.sh, cache.sh, plugin.sh
```

**Ordem de carregamento segura:**
1. logger.sh, color.sh (sem dependências)
2. json.sh (sem dependências)
3. cache.sh (sem dependências)
4. git.sh (sem dependências)
5. registry.sh (sem dependências)
6. plugin.sh (depende de git.sh)
7. installations.sh (depende de json.sh, cache.sh)
8. config.sh (depende de registry, json, cache, plugin)

## 🎯 Padrões de Performance

### Anti-patterns (Evitar)

```bash
# ❌ Ruim - loop com leituras repetidas
for software in docker podman poetry; do
    if is_installed "$software"; then
        version=$(get_installed_version "$software")
        echo "$software: $version"
    fi
done

# ❌ Ruim - chamadas jq diretas
jq -r '.installations[].name' "$lock_file"

# ❌ Ruim - não usar cache disponível
local count=$(jq '.plugins | length' "$registry_file")
```

### Best Practices (Seguir)

```bash
# ✅ Bom - carregar cache uma vez
cache_load
for software in docker podman poetry; do
    if is_installed_cached "$software"; then
        version=$(get_installed_version_cached "$software")
        echo "$software: $version"
    fi
done

# ✅ Bom - usar funções de biblioteca
local installations=$(get_installed_from_cache)

# ✅ Bom - usar funções especializadas
local count=$(registry_count_plugins "$registry_file")
```

## 🧪 Testing Guidelines

### Manual Testing

```bash
# Testar com debug
DEBUG=1 susa setup docker --info

# Testar cache
susa self cache info

# Verificar lock
jq . ~/.susa/susa.lock

# Testar performance
time susa setup --list
```

### Common Issues

1. **Cache desatualizado:** Execute `cache_refresh()` após modificar lock
2. **Funções não encontradas:** Verifique se biblioteca foi carregada com `source`
3. **Permission denied:** Verifique permissões de `~/.susa` e `/tmp/susa-$USER`
4. **jq not found:** Instale jq (`apt install jq` ou `brew install jq`)

## 📝 Commit Messages

Siga o padrão Conventional Commits:

```
feat(setup): add postgres installation command
fix(cache): refresh cache after sync_installations
perf(installations): add cached versions of query functions
docs(readme): update installation instructions
refactor(registry): use helper functions instead of direct jq
```

## 🔐 Security Notes

- Nunca commitar credenciais ou tokens
- Validar entrada de usuário antes de usar em comandos
- Usar `chmod 700` para diretórios de cache
- Sanitizar caminhos com `readlink -f` antes de usar

## 📝 Documentação de Comandos

### Estrutura de Documentação

Cada comando deve ter documentação no diretório `docs/reference/commands/[categoria]/[comando].md`:

**Localização:**
```
docs/
└── reference/
    └── commands/
        ├── .pages           # Lista categorias
        ├── index.md         # Overview de comandos
        ├── setup/
        │   ├── .pages       # Lista comandos da categoria
        │   ├── index.md     # Overview da categoria
        │   └── docker.md    # Documentação do comando
        └── self/
            ├── .pages
            ├── index.md
            └── info.md
```

### Padrão de Documentação

**Princípio:** Seja **direto ao ponto**. O usuário deve entender exatamente como funciona com pouco texto.

**Estrutura recomendada:**

```markdown
# [Nome do Comando]

[Uma linha descrevendo o que faz - máximo 80 caracteres]

## O que faz?

[2-3 parágrafos concisos explicando a funcionalidade]

## Como usar

\```bash
susa [categoria] [comando] [opções]
\```

## Opções

| Opção | Descrição |
|-------|-----------|
| `-h, --help` | Mostra ajuda |
| `--flag` | Descrição breve |

## Exemplos

\```bash
# Exemplo 1 - caso mais comum
susa categoria comando

# Exemplo 2 - com opções
susa categoria comando --flag
\```

## Veja também

- [Comando relacionado](../outro-comando.md)
```

**Características importantes:**
- ✅ **Títulos curtos e diretos**
- ✅ **Exemplos práticos** (sempre inclua o caso de uso mais comum)
- ✅ **Tabelas para opções** (mais fácil de escanear)
- ✅ **Links para comandos relacionados**
- ❌ **Evite parágrafos longos** (máximo 3-4 linhas)
- ❌ **Não repita informações** que já estão no help do comando

### Registrando no .pages

Após criar a documentação, adicione ao arquivo `.pages` da categoria:

**Exemplo: `docs/reference/commands/setup/.pages`**
```yaml
title: Setup
nav:
  - Visão Geral: index.md
  - Docker: docker.md       # Adicione aqui
  - Podman: podman.md
  - Poetry: poetry.md
```

### Vinculando no index.md

Se for um comando importante, adicione referência no `docs/index.md`:

```markdown
## 📚 Documentação

- [Referência de Comandos](reference/commands/index.md)
  - [Setup](reference/commands/setup/index.md) - Instalação de software
  - [Self](reference/commands/self/index.md) - Gerenciamento do CLI
```

### Exemplos de Boas Documentações

- **Concisa:** [`docs/reference/commands/self/info.md`](docs/reference/commands/self/info.md) - 50 linhas, tudo que precisa
- **Completa mas direta:** [`docs/reference/commands/setup/docker.md`](docs/reference/commands/setup/docker.md) - Cobre tudo, mas em seções escaneáveis

### Checklist de Documentação

Ao criar documentação de um novo comando:

- [ ] Criar arquivo `.md` em `docs/reference/commands/[categoria]/`
- [ ] Título e descrição de uma linha
- [ ] Seção "O que faz?" (2-3 parágrafos máximo)
- [ ] Seção "Como usar" com sintaxe básica
- [ ] Tabela de opções (se houver)
- [ ] Seção "Exemplos" com casos práticos
- [ ] Links para comandos relacionados
- [ ] Adicionar ao `.pages` da categoria
- [ ] (Opcional) Vincular no `index.md` se for comando importante

## 🎓 Learning Resources

- **Documentação:** `docs/` directory
- **Exemplos:** `commands/setup/docker/main.sh` (bem documentado)
- **Testes:** Execute comandos com `--help` para ver opções
- **Cache:** Execute `susa self cache info` para entender o estado

---

**Última atualização:** 2026-01-16
**Versão do documento:** 1.0.0
