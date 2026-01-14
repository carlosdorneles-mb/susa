# 🛠️ Configuração do CLI

Este guia explica como configurar e personalizar o comportamento global do CLI.

> **📖 Para configuração de comandos individuais** (config.yaml de comandos), veja [Como Adicionar Novos Comandos](adding-commands.md#3-configurar-o-comando).

---

## 📁 Arquivos de Configuração

O CLI usa diversos níveis de configuração:

### 1. `cli.yaml` - Configuração Global

Arquivo principal localizado na raiz do Susa CLI que define metadados gerais.

**Localização:** `/caminho/para/susa/core/cli.yaml`

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

**Uso:** Variáveis globais compartilhadas entre todos os comandos. Carregado automaticamente pelo framework.

**Carregamento Automático:**

O arquivo é carregado na linha 46 do `core/susa`:

```bash
[ -f "$CLI_DIR/config/settings.conf" ] && source "$CLI_DIR/config/settings.conf"
```

**Como Usar em Comandos:**

```bash
#!/bin/bash

# Variáveis do settings.conf já estão disponíveis automaticamente
echo "API_ENDPOINT: ${API_ENDPOINT:-https://api.default.com}"
echo "DEBUG_MODE: ${DEBUG_MODE:-false}"
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
LOG_DIR="/var/log/susa"
```

---

## ⚡ Ordem de Carregamento

Quando você executa `susa categoria comando`, o framework carrega as configurações nesta ordem:

```text
┌─────────────────────────────────────────────────────────────┐
│ 1. Variáveis de Ambiente do Sistema                         │
│    └─ Já existentes na sessão (export VAR=value)           │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Definição de Caminhos                                    │
│    ├─ CORE_DIR, CLI_DIR, LIB_DIR                           │
│    ├─ PLUGINS_DIR, GLOBAL_CONFIG_FILE                      │
│    └─ Exportados para child processes                       │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Bibliotecas do Core                                      │
│    ├─ color.sh, logger.sh, string.sh                       │
│    ├─ os.sh, sudo.sh                                        │
│    ├─ yaml.sh, cli.sh, shell.sh                            │
│    └─ dependencies.sh                                        │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Configurações Globais (se existir)                       │
│    └─ config/settings.conf                                  │
│       • Variáveis compartilhadas entre comandos             │
│       • Sobrescreve defaults, mas não sobrescreve sistema   │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Validação do CLI                                         │
│    └─ core/cli.yaml                                         │
│       • Verifica se arquivo existe                          │
│       • Obtém metadados (nome, versão, descrição)          │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. Cache/Lock File (se existir)                             │
│    └─ susa.lock                                             │
│       • Usado para descoberta rápida de comandos            │
│       • Inclui comandos de plugins                          │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. Configuração do Comando                                  │
│    └─ categoria/comando/config.yaml                         │
│       • Valida comando existe e é compatível com OS         │
│       • Lê metadados (nome, entrypoint, sudo, os)          │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 8. Variáveis de Ambiente do Comando                         │
│    └─ load_command_envs() lê config.yaml → envs:           │
│       • Exporta variáveis específicas do comando            │
│       • NÃO sobrescreve variáveis já definidas no sistema   │
│       • Expande $HOME, $USER, etc.                          │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 9. Script do Comando                                        │
│    └─ categoria/comando/main.sh                             │
│       • Executa com todas as configurações carregadas       │
│       • Tem acesso a todas as variáveis                     │
└─────────────────────────────────────────────────────────────┘
```

**Referência no código (core/susa):**

```bash
# Linhas 15-28: Definição de caminhos
CORE_DIR="$(cd -P "$(dirname "$CURRENT_SCRIPT")" && pwd)"
CLI_DIR="$(cd -P "$CORE_DIR/.." && pwd)"
# ... exports

# Linhas 33-44: Carrega bibliotecas
source "$LIB_DIR/color.sh"
source "$LIB_DIR/logger.sh"
# ... outras bibliotecas

# Linha 46: Carrega settings.conf (se existir)
[ -f "$CLI_DIR/config/settings.conf" ] && source "$CLI_DIR/config/settings.conf"

# Linhas 48-51: Valida cli.yaml
if [ ! -f "$GLOBAL_CONFIG_FILE" ]; then
    echo "Erro: Arquivo de configuração '$GLOBAL_CONFIG_FILE' não encontrado"
    exit 1
fi

# Linha 396: Carrega envs do comando (antes de executar)
load_command_envs "$config_file"

# Linha 398: Executa o script
source "$script_path" "$@"
```

### Precedência de Variáveis

Quando uma mesma variável é definida em múltiplos lugares:

```text
1. Variáveis de Sistema (maior precedência)
   └─ export VAR=value
   └─ VAR=value susa comando

2. Envs do Comando
   └─ config.yaml → envs:

3. Variáveis Globais
   └─ config/settings.conf

4. Valores Padrão no Script (menor precedência)
   └─ ${VAR:-default}
```

**Exemplo prático:**

```yaml
# config/settings.conf
TIMEOUT="20"

# commands/setup/docker/config.yaml
envs:
  TIMEOUT: "60"

# commands/setup/docker/main.sh
timeout="${TIMEOUT:-10}"
```

**Resultados:**

```bash
./susa setup docker                    # → 60 (do comando)
TIMEOUT=90 ./susa setup docker        # → 90 (do sistema, override)
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

- Comandos instalados exibem **`✓`** em verde (apenas categoria `setup`)
- Comandos com `sudo: true` exibem **`[sudo]`** na listagem
- Comandos de plugins exibem **`[plugin]`** na listagem
- Todos podem aparecer juntos: `comando ✓ [plugin] [sudo]`

**Exemplo:**

```text
Comandos:
  asdf            Instala ASDF ✓
  docker          Instala Docker ✓ [sudo]
  postgres        Instala PostgreSQL [sudo]
  deploy-prod     Deploy produção [plugin] [sudo]
```

> Veja mais sobre indicadores em [Filtros de Sistema Operacional e Sudo](subcategories.md#filtros-de-sistema-operacional-e-sudo) e [Plugins](../plugins/overview.md#indicador-visual).

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
source "$LIB_DIR/logger.sh"

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

## 🌍 Variáveis de Ambiente por Comando

O Susa CLI permite definir variáveis de ambiente específicas para cada comando através da seção `envs` no `config.yaml`.

### Como Funciona

Cada comando pode ter suas próprias variáveis de ambiente que são automaticamente carregadas e exportadas **apenas durante a execução daquele comando**. Isso garante isolamento e evita conflitos entre comandos.

### Definindo Variáveis no config.yaml

No arquivo `config.yaml` do seu comando, adicione a seção `envs`:

```yaml
name: "ASDF"
description: "Instala ASDF (gerenciador de versões polyglot)"
entrypoint: "main.sh"
sudo: false
os: ["linux", "mac"]
envs:
  # URLs do repositório
  ASDF_GITHUB_API_URL: "https://api.github.com/repos/asdf-vm/asdf/releases/latest"
  ASDF_GITHUB_REPO_URL: "https://github.com/asdf-vm/asdf.git"
  ASDF_RELEASES_BASE_URL: "https://github.com/asdf-vm/asdf/releases/download"

  # Timeouts (em segundos)
  ASDF_API_MAX_TIME: "10"
  ASDF_API_CONNECT_TIMEOUT: "5"
  ASDF_GIT_TIMEOUT: "5"

  # Configurações de download
  ASDF_DOWNLOAD_CONNECT_TIMEOUT: "30"
  ASDF_DOWNLOAD_MAX_TIME: "300"
  ASDF_DOWNLOAD_RETRY: "3"
  ASDF_DOWNLOAD_RETRY_DELAY: "2"

  # Diretórios (suporta expansão de variáveis)
  ASDF_INSTALL_DIR: "$HOME/.asdf"
  ASDF_LOCAL_BIN_DIR: "$HOME/.local/bin"
```

### Usando no Script

No `main.sh` do comando, use as variáveis com valores padrão de fallback:

```bash
#!/bin/bash
set -euo pipefail


# Usar variáveis com fallback para compatibilidade
get_latest_version() {
    local api_url="${ASDF_GITHUB_API_URL:-https://api.github.com/repos/asdf-vm/asdf/releases/latest}"
    local max_time="${ASDF_API_MAX_TIME:-10}"
    local connect_timeout="${ASDF_API_CONNECT_TIMEOUT:-5}"

    curl -s --max-time "$max_time" --connect-timeout "$connect_timeout" "$api_url"
}

install_asdf() {
    local install_dir="${ASDF_INSTALL_DIR:-$HOME/.asdf}"
    local download_timeout="${ASDF_DOWNLOAD_MAX_TIME:-300}"

    echo "Instalando em: $install_dir"
    curl -L --max-time "$download_timeout" "$download_url" -o /tmp/asdf.tar.gz
}
```

### Características das Envs por Comando

#### ✅ Expansão de Variáveis

Variáveis como `$HOME`, `$USER`, etc., são automaticamente expandidas:

```yaml
envs:
  MY_CONFIG_DIR: "$HOME/.config/myapp"  # Expande para /home/user/.config/myapp
  BACKUP_PATH: "$HOME/backups/$USER"     # Expande para /home/user/backups/user
```

#### 🔒 Isolamento Total

As variáveis são **isoladas por comando**. Não há vazamento entre comandos:

```bash
# Comando 1
$ susa setup asdf
  → ASDF_INSTALL_DIR disponível
  → FIM (variável descartada)

# Comando 2
$ susa setup docker
  → ASDF_INSTALL_DIR NÃO está disponível
  → DOCKER_* envs estão disponíveis
```

#### 🎯 Escopo de Execução

```text
Usuario executa comando
        ↓
[core/susa] execute_command()
        ↓
Valida e localiza config.yaml
        ↓
[yaml.sh] load_command_envs(config.yaml)
        ↓
Exporta todas as envs (com expansão)
        ↓
Executa main.sh
        ↓
Script usa ${VAR:-default}
        ↓
Fim da execução (envs descartadas)
```

### Vantagens

✅ **Configurações Centralizadas**: Todos os parâmetros em um único lugar
✅ **Fácil Customização**: Basta editar o YAML, sem tocar no código
✅ **Valores de Fallback**: Scripts continuam funcionando sem as envs
✅ **Expansão Automática**: Variáveis como `$HOME` são expandidas
✅ **Isolamento**: Comandos não interferem uns nos outros
✅ **Sem Código Extra**: Framework cuida do carregamento automaticamente

### Boas Práticas

**1. Use Prefixos Únicos**

```yaml
envs:
  ASDF_INSTALL_DIR: "..."      # ✅ Prefixo único
  INSTALL_DIR: "..."           # ❌ Muito genérico
```

**2. Sempre Forneça Fallbacks**

```bash
# ✅ Bom: funciona com ou sem env
local dir="${ASDF_INSTALL_DIR:-$HOME/.asdf}"

# ❌ Ruim: quebra sem a env
local dir="$ASDF_INSTALL_DIR"
```

**3. Documente as Variáveis**

```yaml
envs:
  # Timeout máximo para API do GitHub (em segundos)
  # Padrão: 10
  ASDF_API_MAX_TIME: "10"

  # Diretório de instalação do ASDF
  # Padrão: $HOME/.asdf
  ASDF_INSTALL_DIR: "$HOME/.asdf"
```

**4. Use Tipos Apropriados**

```yaml
envs:
  # Números devem ser strings no YAML
  TIMEOUT: "30"              # ✅ String
  RETRY_COUNT: "3"           # ✅ String

  # Booleanos também
  ENABLE_CACHE: "true"       # ✅ String

  # URLs e paths
  API_URL: "https://..."     # ✅ String
  INSTALL_DIR: "$HOME/..."   # ✅ String
```

### Exemplo Completo

**config.yaml:**

```yaml
name: "Docker"
description: "Instala Docker Engine"
entrypoint: "main.sh"
sudo: true
os: ["linux", "mac"]
envs:
  # URLs
  DOCKER_REPO_URL: "https://download.docker.com"
  DOCKER_GPG_KEY_URL: "https://download.docker.com/linux/ubuntu/gpg"

  # Configurações
  DOCKER_DATA_ROOT: "/var/lib/docker"
  DOCKER_LOG_LEVEL: "info"
  DOCKER_MAX_CONCURRENT_DOWNLOADS: "3"

  # Timeouts
  DOCKER_DOWNLOAD_TIMEOUT: "300"
  DOCKER_STARTUP_TIMEOUT: "60"
```

**main.sh:**

```bash
#!/bin/bash
set -euo pipefail

source "$LIB_DIR/logger.sh"

download_docker() {
    local repo_url="${DOCKER_REPO_URL:-https://download.docker.com}"
    local timeout="${DOCKER_DOWNLOAD_TIMEOUT:-300}"

    log_info "Baixando Docker de: $repo_url"
    curl -L --max-time "$timeout" "$repo_url/install.sh" | sudo bash
}

configure_docker() {
    local data_root="${DOCKER_DATA_ROOT:-/var/lib/docker}"
    local log_level="${DOCKER_LOG_LEVEL:-info}"

    cat > /etc/docker/daemon.json <<EOF
{
  "data-root": "$data_root",
  "log-level": "$log_level"
}
EOF
}

main() {
    download_docker
    configure_docker
    log_success "Docker instalado com sucesso!"
}

main "$@"
```

---

## 🌐 Variáveis de Ambiente Globais

Para configurações que devem estar disponíveis em **todos os comandos**, use `config/settings.conf`.

### Configuração Global

**Localização:** `config/settings.conf`

```bash
# config/settings.conf

# Configurações globais da API
API_ENDPOINT="https://api.example.com"
API_TOKEN="your-token-here"

# Configurações de rede
HTTP_TIMEOUT="30"
HTTP_RETRY="3"

# Diretórios globais
BACKUP_DIR="/var/backups"
LOG_DIR="/var/log/susa"

# Debug
DEBUG_MODE="false"
```

### Carregamento Automático

O arquivo `config/settings.conf` é carregado **automaticamente** no início da execução do CLI (se existir):

```bash
# core/susa (linha 46)
[ -f "$CLI_DIR/config/settings.conf" ] && source "$CLI_DIR/config/settings.conf"
```

### Usando em Comandos

As variáveis globais estão automaticamente disponíveis:

```bash
#!/bin/bash
set -euo pipefail


# Variáveis do settings.conf já estão disponíveis
echo "API Endpoint: ${API_ENDPOINT:-não configurado}"
echo "HTTP Timeout: ${HTTP_TIMEOUT:-30}"
echo "Backup Dir: ${BACKUP_DIR:-/var/backups}"

# Fazer requisição usando config global
curl --max-time "${HTTP_TIMEOUT:-30}" \
     --retry "${HTTP_RETRY:-3}" \
     -H "Authorization: Bearer ${API_TOKEN}" \
     "${API_ENDPOINT}/status"
```

### Precedência de Variáveis

Quando a mesma variável existe em múltiplos lugares:

```text
1. Variáveis de Ambiente do Sistema (maior precedência)
2. Variáveis do Comando (config.yaml envs:)
3. Variáveis Globais (config/settings.conf)
4. Valores Padrão no Script (fallback)
```

**Exemplo:**

```bash
# settings.conf
TIMEOUT="30"

# comando/config.yaml
envs:
  TIMEOUT: "60"

# No script
timeout="${TIMEOUT:-10}"  # Usará 60 (do comando)

# Mas se executar com:
TIMEOUT=90 susa comando   # Usará 90 (do sistema)
```

### Quando Usar Cada Tipo

| Tipo | Quando Usar | Exemplo |
|------|-------------|---------|
| **Envs por Comando** | Configurações específicas do comando | URLs específicas, diretórios de instalação, timeouts customizados |
| **Envs Globais** | Configurações compartilhadas entre comandos | Credenciais de API, configurações de rede, paths globais |
| **Variáveis de Sistema** | Override temporário durante execução | `DEBUG=true susa comando`, `TIMEOUT=90 susa comando` |
| **Valores Padrão** | Fallback quando nada está configurado | `${VAR:-valor_padrao}` |

### Exemplo Prático Completo

**config/settings.conf (global):**

```bash
# Configurações de rede globais
HTTP_TIMEOUT="30"
HTTP_RETRY="3"
API_BASE_URL="https://api.example.com"
```

**commands/deploy/app/config.yaml:**

```yaml
name: "Deploy App"
description: "Deploy da aplicação"
entrypoint: "main.sh"
sudo: false
os: ["linux"]
envs:
  # Específicas deste comando
  DEPLOY_TARGET_DIR: "/var/www/app"
  DEPLOY_BACKUP_ENABLED: "true"
  DEPLOY_ROLLBACK_ENABLED: "true"
```

**commands/deploy/app/main.sh:**

```bash
#!/bin/bash
set -euo pipefail


deploy_app() {
    # Usa configuração global
    local api_url="${API_BASE_URL:-https://api.example.com}"
    local timeout="${HTTP_TIMEOUT:-30}"

    # Usa configuração do comando
    local target_dir="${DEPLOY_TARGET_DIR:-/var/www/app}"
    local backup="${DEPLOY_BACKUP_ENABLED:-true}"

    log_info "Fazendo deploy para: $target_dir"
    log_info "API URL: $api_url"

    if [ "$backup" = "true" ]; then
        log_info "Criando backup..."
        cp -r "$target_dir" "${target_dir}.backup.$(date +%s)"
    fi

    # Deploy via API
    curl --max-time "$timeout" \
         --retry "${HTTP_RETRY:-3}" \
         -X POST "$api_url/deploy" \
         -d '{"target": "'"$target_dir"'"}'
}

deploy_app "$@"
```

**Execução:**

```bash
# Usa todas as configs definidas
$ susa deploy app

# Override de config global
$ HTTP_TIMEOUT=60 susa deploy app

# Override de config do comando
$ DEPLOY_TARGET_DIR=/tmp/app susa deploy app

# Override de múltiplas
$ API_BASE_URL=https://staging.api.com DEPLOY_BACKUP_ENABLED=false susa deploy app
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
├── core/
│   ├── cli.yaml                 # ✅ Config global (obrigatório)
│   ├── susa                    # Entrypoint principal
│   └── lib/                    # Bibliotecas
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
2. **`<comando>/config.yaml`** - Config de cada comando com envs (obrigatório)
3. **`config/settings.conf`** - Variáveis globais compartilhadas (opcional)
4. **Variáveis de ambiente do sistema** - Override temporário (opcional)

**Tipos de Variáveis de Ambiente:**

| Tipo | Arquivo | Escopo | Uso |
|------|---------|--------|-----|
| **Por Comando** | `config.yaml` (seção `envs:`) | Apenas durante execução do comando | URLs, timeouts, paths específicos |
| **Globais** | `config/settings.conf` | Todos os comandos | Credenciais, configs de rede |
| **Sistema** | Linha de comando | Override temporário | `DEBUG=true susa comando` |

**Hierarquia de precedência (maior → menor):**

```text
1. Variáveis de Ambiente do Sistema (export VAR=value ou VAR=value comando)
    ↓
2. Envs do Comando (config.yaml → envs:)
    ↓
3. Variáveis Globais (config/settings.conf)
    ↓
4. Valores Padrão no Script (${VAR:-default})
```

**Características das Envs por Comando:**

✅ Carregamento automático antes da execução
✅ Expansão de variáveis (`$HOME`, `$USER`)
✅ Isolamento total entre comandos
✅ Suporte a fallback (`${VAR:-default}`)
✅ Sem código adicional necessário

**Para começar:**

- **Básico:** Apenas `cli.yaml` e `<comando>/config.yaml` são necessários
- **Com envs por comando:** Adicione seção `envs:` no `config.yaml` do comando
- **Com envs globais:** Crie `config/settings.conf` com variáveis compartilhadas

**Exemplo mínimo com envs:**

```yaml
# commands/setup/docker/config.yaml
name: "Docker"
description: "Instala Docker"
entrypoint: "main.sh"
sudo: true
os: ["linux"]
envs:
  DOCKER_REPO_URL: "https://download.docker.com"
  DOCKER_TIMEOUT: "300"
```

```bash
# commands/setup/docker/main.sh
#!/bin/bash

repo="${DOCKER_REPO_URL:-https://download.docker.com}"
timeout="${DOCKER_TIMEOUT:-300}"

curl --max-time "$timeout" "$repo/install.sh" | sudo bash
```
