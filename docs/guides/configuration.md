# 🛠️ Configuração do CLI

Este guia explica como configurar e personalizar o comportamento global do CLI.

> **📖 Para configuração de comandos individuais** (config.yaml de comandos), veja [Como Adicionar Novos Comandos](adding-commands.md#3-configurar-o-comando).

---

## 📁 Arquivos de Configuração

O CLI usa diversos níveis de configuração:

### 1. `cli.yaml` - Configuração Global

Arquivo principal localizado na raiz do Susa CLI que define metadados gerais.

**Localização:** `/caminho/para/susa/cli.yaml`

**Conteúdo:**

```yaml
name: "Susa CLI"
description: "Gerenciador de Shell Scripts para automação"
version: "1.0.0"
commands_dir: "commands"
plugins_dir: "plugins"
```

**Campos:**

| Campo | Tipo | Descrição | Padrão |
| ----- | ---- | --------- | ------ |
| `name` | string | Nome amigável exibido no help e versão | - |
| `description` | string | Descrição exibida no help principal | - |
| `version` | string | Versão semântica (major.minor.patch) | - |
| `commands_dir` | string | Diretório onde ficam os comandos | `commands` |
| `plugins_dir` | string | Diretório onde ficam os plugins | `plugins` |

**Quando Modificar:**

- Alterar nome ou versão do CLI
- Mudar descrição principal
- Reorganizar estrutura de diretórios

---

### 2. `config/settings.conf` - Configurações Opcionais

Arquivo de configuração adicional para settings customizados.

**Localização:** `/caminho/para/cli/config/settings.conf`

**Uso Atual:** Este arquivo existe mas não é usado pelos scripts principais do CLI. Pode ser usado por comandos personalizados.

**Como Usar em Comandos:**

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Carregar configurações customizadas
if [ -f "$CLI_DIR/config/settings.conf" ]; then
    source "$CLI_DIR/config/settings.conf"
fi

# Usar variáveis definidas no settings.conf
echo "API_ENDPOINT: ${API_ENDPOINT:-https://api.default.com}"
```

**Exemplo de Conteúdo:**

```bash
# config/settings.conf

# API Configuration
API_ENDPOINT="https://api.example.com"
API_TOKEN="your-token-here"

# Default Settings
DEFAULT_REGION="us-east-1"
DEBUG_MODE="false"

# Paths
BACKUP_DIR="/var/backups"
```

---

### 3. Configuração de Categorias e Comandos

> **📖 Documentação completa:** Para detalhes sobre `config.yaml` de categorias, subcategorias e comandos, consulte:
> - **[Como Adicionar Novos Comandos](adding-commands.md)** - Estrutura básica e campos do config.yaml
> - **[Sistema de Subcategorias](subcategories.md)** - Hierarquias e organização multinível

**Resumo:**

| Tipo | Arquivo | Campos Principais | Referência |
|------|---------|-------------------|------------|
| Categoria | `commands/<categoria>/config.yaml` | `name`, `description` | [Ver guia](adding-commands.md#2-configurar-a-categoria) |
| Comando | `commands/<categoria>/<comando>/config.yaml` | `name`, `description`, `script`, `sudo`, `os`, `group` (opcional) | [Ver guia](adding-commands.md#3-configurar-o-comando) |
| Subcategoria | `commands/<categoria>/<sub>/config.yaml` | `name`, `description` (sem `script`) | [Ver guia](subcategories.md#todos-usam-configyaml) |

**Indicadores Visuais:**

- Comandos com `sudo: true` exibem **`[sudo]`** na listagem
- Comandos de plugins exibem **`[plugin]`** na listagem
- Ambos podem aparecer juntos: `comando [plugin] [sudo]`

> Veja mais sobre indicadores em [Filtros de Sistema Operacional e Sudo](subcategories.md#⚙️-filtros-de-sistema-operacional-e-sudo) e [Plugins](../plugins/overview.md#indicador-visual).

---

## 🎛️ Variáveis de Ambiente

O CLI respeita algumas variáveis de ambiente para customização.

### `DEBUG`

Ativa modo debug com logs adicionais.

**Valores aceitos:** `true`, `1`, `on`

**Exemplo:**

```bash
DEBUG=true susa setup docker
```

**Saída:**

```text
[DEBUG] 2026-01-12 14:30:45 - Carregando config de: /opt/cli/cli.yaml
[DEBUG] 2026-01-12 14:30:45 - Categoria detectada: install
[DEBUG] 2026-01-12 14:30:45 - Comando detectado: docker
[INFO] 2026-01-12 14:30:45 - Instalando Docker Engine...
```

**Uso em Scripts:**

```bash
#!/bin/bash
source "$CLI_DIR/lib/logger.sh"

log_debug "Valor da variável X: $X"  # Só aparece com DEBUG=true
```

---

### `CLI_DIR`

Diretório raiz do CLI (normalmente detectado automaticamente).

**Uso:** Raramente precisa ser definido manualmente.

**Exemplo:**

```bash
CLI_DIR=/opt/mycli ./susa setup docker
```

---

### `GLOBAL_CONFIG_FILE`

Caminho para o arquivo cli.yaml (normalmente detectado automaticamente).

**Uso:** Útil para testar com configurações alternativas.

**Exemplo:**

```bash
GLOBAL_CONFIG_FILE=/tmp/test-cli.yaml ./susa --version
```

---

## 🔧 Personalizações Comuns

### Alterar Nome do CLI

Edite `cli.yaml`:

```yaml
name: "MeuApp CLI"     # Era: Susa CLI
description: "Meu gerenciador customizado"
```

Renomeie o executável:

```bash
mv susa meuapp
```

Reinstale:

```bash
./install.sh
```

Agora use:

```bash
meuapp setup asdf
meuapp self version
```

---

### Adicionar Diretório de Configuração Customizado

Se quiser um diretório separado para configs de produção:

```bash
mkdir -p config/production
```

Crie arquivos de ambiente:

```bash
# config/production/database.conf
DB_HOST="prod-db.example.com"
DB_PORT="5432"
DB_NAME="production"

# config/production/api.conf
API_URL="https://api.production.com"
API_TIMEOUT="30"
```

Use em comandos:

```bash
#!/bin/bash
CLI_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Carrega configuração de produção
if [ -f "$CLI_DIR/config/production/database.conf" ]; then
    source "$CLI_DIR/config/production/database.conf"
fi

echo "Conectando a: $DB_HOST:$DB_PORT/$DB_NAME"
```

---

### Configurar Aliases

Adicione aliases ao shell para comandos frequentes:

```bash
# ~/.zshrc ou ~/.bashrc

# Aliases do CLI
alias clic='susa setup'
alias cliu='cli update'
alias clid='susa deploy'
alias clip='susa self plugin'
```

Uso:

```bash
clic asdf         # Equivale a: susa setup asdf
cliu              # Equivale a: susa self update
clip list         # Equivale a: susa self plugin list
```

---

### Configurar PATH

Se o Susa CLI foi instalado em `/opt/susa`, adicione ao PATH:

```bash
# Adicione ao ~/.zshrc ou ~/.bashrc
export PATH="$PATH:/opt/susa"
```

Ou durante instalação, o `install.sh` já faz isso automaticamente:

```bash
./install.sh
# Adiciona symlink em /usr/local/bin/susa automaticamente
```

---

## 🗂️ Estrutura de Configuração Completa

```text
susa/
├── cli.yaml                     # ✅ Config global (obrigatório)
├── config/
│   └── settings.conf           # ⚠️ Opcional (não usado por padrão)
├── commands/
│   ├── setup/
│   │   ├── config.yaml         # ⚠️ Opcional (metadados da categoria)
│   │   └── asdf/
│   │       ├── config.yaml     # ✅ Obrigatório (config do comando)
│   │       └── main.sh         # ✅ Obrigatório (script)
│   └── self/
│       ├── config.yaml
│       └── plugin/
│           ├── config.yaml
│           └── add/
│               ├── config.yaml # ✅ Obrigatório
│               └── main.sh     # ✅ Obrigatório
└── plugins/
    ├── registry.yaml            # 🔧 Gerado automaticamente
    └── hello-world/             # Exemplo de plugin
        └── text/
            ├── config.yaml
            └── hello-world/
                ├── config.yaml  # ✅ Obrigatório (plugin)
                └── main.sh      # ✅ Obrigatório (plugin)
```

**Legenda:**

- ✅ Obrigatório
- ⚠️ Opcional
- 🔧 Gerado automaticamente

---

## 📝 Boas Práticas de Configuração

### 1. Use Configurações Descentralizadas

❌ **Evite:**

```yaml
# Um YAML centralizado gigante
categories:
  install:
    commands:
      - name: "Docker"
        description: "Docker description"
        # ... 50 linhas ...
      - name: "NodeJS"
        # ... 50 linhas ...
      # ... 500 comandos ...
```

✅ **Prefira:**

```text
commands/
├── install/
│   ├── docker/
│   │   └── config.yaml    # Apenas config do docker
│   └── nodejs/
│       └── config.yaml    # Apenas config do nodejs
```

---

### 2. Separe Secrets de Configuração

❌ **Evite:**

```yaml
# config.yaml
api_token: "sk-1234567890abcdef"  # ❌ Nunca commite secrets!
```

✅ **Prefira:**

```bash
# config/settings.conf (não commitado)
API_TOKEN="sk-1234567890abcdef"

# .gitignore
config/settings.conf
config/production/*.conf
config/*.secret
```

---

### 3. Use Variáveis de Ambiente para Overrides

```bash
#!/bin/bash

# Valores padrão
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
API_TIMEOUT="${API_TIMEOUT:-30}"

# Permite override via env vars:
# DB_HOST=prod-db.com susa deploy app
```

---

### 4. Documente Configurações Customizadas

Se adicionar configurações em `config/settings.conf`, documente:

```bash
# config/settings.conf

# ============================================================
# Configurações da API
# ============================================================
# API_ENDPOINT: URL base da API (padrão: https://api.example.com)
# API_TOKEN: Token de autenticação (obtenha em: https://dashboard.example.com)
# API_TIMEOUT: Timeout em segundos (padrão: 30)

API_ENDPOINT="https://api.example.com"
API_TOKEN=""  # CONFIGURE AQUI
API_TIMEOUT="30"

# ============================================================
# Configurações de Backup
# ============================================================
# BACKUP_DIR: Diretório para armazenar backups
# BACKUP_RETENTION_DAYS: Dias para manter backups antigos

BACKUP_DIR="/var/backups/mycli"
BACKUP_RETENTION_DAYS="30"
```

---

### 5. Valide Configurações Obrigatórias

Em comandos que dependem de config:

```bash
#!/bin/bash
CLI_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Carrega configuração
if [ -f "$CLI_DIR/config/settings.conf" ]; then
    source "$CLI_DIR/config/settings.conf"
fi

# Valida campos obrigatórios
if [ -z "$API_TOKEN" ]; then
    log_error "API_TOKEN não configurado em config/settings.conf"
    log_info "Configure em: $CLI_DIR/config/settings.conf"
    exit 1
fi

# Prossegue com execução
log_info "Conectando a API..."
```

---

## 🔍 Troubleshooting de Configuração

> **📖 Para troubleshooting de comandos específicos**, veja a seção [Troubleshooting](subcategories.md#troubleshooting) no guia de subcategorias.

### Problema: CLI não encontra cli.yaml

**Verificar:**

```bash
# Verificar se arquivo existe no local correto
ls -la ./cli.yaml
ls -la /opt/susa/cli.yaml

# Testar com caminho absoluto
GLOBAL_CONFIG_FILE=/caminho/completo/cli.yaml susa --version
```

---

### Problema: Configuração não está sendo carregada (settings.conf)

**Debug:**

```bash
# Ativar modo debug
DEBUG=true susa setup docker

# Verificar se arquivo existe
ls -la /caminho/para/cli/cli.yaml

# Verificar permissões
stat /caminho/para/cli/cli.yaml

# Validar sintaxe YAML
yq eval . /caminho/para/cli/cli.yaml
```

---

### Problema: Variável de ambiente não funciona

**Verificar:**

```bash
# Verificar se variável está definida
echo $DEBUG
echo $CLI_DIR

# Exportar variável
export DEBUG=true
susa setup docker

# Ou inline
DEBUG=true susa setup docker
```

---

## 📚 Recursos Adicionais

- **[Como Adicionar Novos Comandos](adding-commands.md)** - Configuração de comandos e categorias
- **[Sistema de Subcategorias](subcategories.md)** - Organização hierárquica
- **[Funcionalidades](features.md)** - Visão geral do sistema
- **[Referência de Bibliotecas](../reference/libraries/index.md)** - API das libs
- **[Sistema de Plugins](../plugins/overview.md)** - Extensão via Git

---

## 🎯 Resumo

**Configurações principais:**

1. **`cli.yaml`** - Metadados globais (obrigatório)
2. **`<comando>/config.yaml`** - Config de cada comando (obrigatório)
3. **`config/settings.conf`** - Configurações customizadas (opcional)
4. **Variáveis de ambiente** - `DEBUG`, `CLI_DIR`, etc. (opcional)

**Hierarquia de precedência:**

```text
Variáveis de Ambiente
    ↓
config/settings.conf
    ↓
<comando>/config.yaml
    ↓
cli.yaml (defaults)
```

**Para começar:** Apenas `cli.yaml` e `<comando>/config.yaml` são necessários!
