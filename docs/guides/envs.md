# Variáveis de Ambiente

Referência rápida sobre o sistema de variáveis de ambiente do Susa CLI.

> **📖 Para documentação completa**, veja [Guia de Configuração](configuration.md#variaveis-de-ambiente-por-comando).

## 📋 Tipos de Variáveis

### 1. Variáveis por Comando (Isoladas)

Definidas no `command.json` do comando, disponíveis apenas durante sua execução.

**Funciona em:**

- ✅ Comandos built-in (em `commands/`)
- ✅ Comandos de plugins (em `plugins/`)

**Definição:**

```json
// commands/setup/docker/command.json (built-in)
// ou
// plugins/meu-plugin/deploy/staging/command.json (plugin)
{
  "name": "Docker",
  "description": "Instala Docker",
  "entrypoint": "main.sh",
  "sudo": true,
  "os": ["linux"],
  "envs": {
    "DOCKER_REPO_URL": "https://download.docker.com",
    "DOCKER_TIMEOUT": "300",
    "DOCKER_INSTALL_DIR": "$HOME/.docker"
  }
}
```

**Uso no script:**

```bash
#!/bin/bash

# Variáveis automaticamente disponíveis
repo="${DOCKER_REPO_URL:-https://default.com}"
timeout="${DOCKER_TIMEOUT:-300}"
install_dir="${DOCKER_INSTALL_DIR:-$HOME/.docker}"
```

**Características:**

- ✅ Carregamento automático
- ✅ Expansão de variáveis (`$HOME`, `$USER`)
- ✅ Isolamento total (não vazam entre comandos)
- ✅ Sobrescrita por variáveis de sistema
- ✅ Funciona em comandos built-in e plugins

### 1.1 Variáveis de Arquivos .env

Além de definir variáveis diretamente no `command.json`, você pode carregá-las de arquivos `.env`.

**Definição:**

```json
// commands/deploy/app/command.json
{
  "name": "Deploy App",
  "description": "Deploy da aplicação",
  "entrypoint": "main.sh",
  "sudo": false,
  "os": ["linux"],
  "env_files": [
    ".env",
    ".env.local",
    ".env.production"
  ],
  "envs": {
    "DEPLOY_TIMEOUT": "300",
    "DEPLOY_TARGET": "production"
  }
}
```

**Exemplo de arquivo .env:**

```bash
# .env
DATABASE_URL="postgresql://localhost/mydb"
API_KEY="your-api-key-here"
DEBUG_MODE="false"

# Suporta expansão de variáveis
CONFIG_DIR="$HOME/.config/app"
LOG_FILE="$PWD/logs/app.log"

# Comentários são ignorados
# Linhas vazias também são ignoradas

# Valores entre aspas
APP_NAME="My Application"
VERSION='1.0.0'
```

**Características dos arquivos .env:**

- ✅ Caminhos relativos ao diretório do `command.json`
- ✅ Caminhos absolutos também suportados
- ✅ Múltiplos arquivos .env podem ser especificados
- ✅ Carregados na ordem definida em `env_files`
- ✅ Suporta comentários (`#`) e linhas vazias
- ✅ Suporta aspas simples e duplas
- ✅ Expansão de variáveis (`$HOME`, `$USER`, etc.)
- ✅ Arquivos inexistentes são ignorados silenciosamente

### 2. Variáveis Globais (Compartilhadas)

Definidas em `config/settings.conf`, disponíveis para todos os comandos.

**Definição:**

```bash
# config/settings.conf
API_ENDPOINT="https://api.example.com"
API_TOKEN="secret-token"
HTTP_TIMEOUT="30"
DEBUG_MODE="false"
```

**Uso:**

```bash
#!/bin/bash

# Disponíveis em todos os comandos
echo "API: ${API_ENDPOINT}"
echo "Timeout: ${HTTP_TIMEOUT}"
```

### 3. Variáveis de Sistema (Override)

Definidas na linha de comando, sobrescrevem todas as outras.

```bash
# Override temporário
DOCKER_TIMEOUT=600 susa setup docker

# Export permanente (sessão)
export DEBUG=true
susa setup docker
```

## 🎯 Precedência

Ordem de precedência (maior → menor):

```text
1. Variáveis de Sistema    → export VAR=value ou VAR=value comando
2. Envs do Comando         → command.json → envs:
3. Variáveis Globais       → config/settings.conf
4. Arquivos .env           → command.json → env_files: (na ordem especificada)
5. Valores Padrão          → ${VAR:-default}
```

**Exemplo prático:**

```json
// command.json
{
  "env_files": [".env", ".env.local"],
  "envs": {
    "TIMEOUT": "60"
  }
}
```

```bash
# .env
TIMEOUT="40"
API_URL="https://api.example.com"
```

```bash
# .env.local
TIMEOUT="50"
```

```bash
# config/settings.conf
TIMEOUT="30"
```

```bash
# No script
timeout="${TIMEOUT:-10}"
api_url="${API_URL:-https://default.com}"

# Resultados:
./susa comando                    # → TIMEOUT=60 (do command.json envs)
                                  # → API_URL=https://api.example.com (do .env)
TIMEOUT=90 ./susa comando        # → TIMEOUT=90 (do sistema - maior prioridade)
```

**Ordem de carregamento detalhada:**

1. Sistema verifica variáveis de ambiente do sistema primeiro
2. Carrega `config/settings.conf` (variáveis globais)
3. Carrega arquivos .env na ordem especificada em `env_files`
4. Carrega variáveis da seção `envs` do `command.json`
5. Variáveis já definidas não são sobrescritas (princípio da precedência)

## 📝 Sintaxe JSON

### Tipos de Valores

```json
{
  "envs": {
    "VAR_STRING": "valor",
    "VAR_NUMBER": "42",
    "VAR_BOOL": "true",
    "VAR_URL": "https://example.com/path",
    "VAR_PATH": "$HOME/.config/app",
    "VAR_COMPLEX": "$HOME/backups/$USER"
  }
}
```

### Expansão de Variáveis

Variáveis suportadas para expansão:

- `$HOME` - Diretório home do usuário
- `$USER` - Nome do usuário
- `$PWD` - Diretório atual
- `$HOSTNAME` - Nome do host
- Qualquer variável de ambiente existente

**Exemplo:**

```json
{
  "envs": {
    "CONFIG_DIR": "$HOME/.config/myapp",
    "BACKUP_DIR": "$HOME/backups/$USER",
    "LOG_FILE": "$PWD/logs/app.log"
  }
}
```

## 🛠️ Uso no Script

### Padrão Recomendado

Sempre use valores de fallback com a sintaxe `${VAR:-default}`:

```bash
#!/bin/bash
set -euo pipefail


# ✅ Bom: funciona com ou sem env
local timeout="${TIMEOUT:-30}"
local url="${API_URL:-https://default.com}"
local dir="${INSTALL_DIR:-$HOME/.app}"

# ❌ Ruim: quebra se env não existir
local timeout="$TIMEOUT"
```

**Como funciona `${VAR:-default}`:**

- Se `VAR` estiver definida e não vazia → usa o valor de `VAR`
- Se `VAR` não estiver definida ou estiver vazia → usa `default`

**Exemplos:**

```bash
# Variável definida no command.json
TIMEOUT="60"
timeout="${TIMEOUT:-30}"        # → 60 (usa o valor da env)

# Variável não definida
# TIMEOUT não existe
timeout="${TIMEOUT:-30}"        # → 30 (usa o valor padrão)

# Override via sistema
TIMEOUT=90 susa comando
timeout="${TIMEOUT:-30}"        # → 90 (usa o valor do sistema)
```

**Sintaxes alternativas:**

```bash
# ${VAR:-default} - Mais comum, usa default se VAR vazia ou indefinida
url="${API_URL:-https://default.com}"

# ${VAR-default} - Usa default apenas se VAR indefinida (não se vazia)
url="${API_URL-https://default.com}"

# ${VAR:=default} - Define VAR como default se vazia ou indefinida
: "${TIMEOUT:=30}"              # TIMEOUT agora tem valor 30 se estava vazia

# Recomendamos usar ${VAR:-default} por ser mais seguro
```

### Validação de Variáveis

```bash
# Verificar se variável obrigatória existe
if [ -z "${API_TOKEN:-}" ]; then
    log_error "API_TOKEN não configurado"
    exit 1
fi

# Usar variável
curl -H "Authorization: Bearer $API_TOKEN" "$API_URL"
```

### Documentação Inline

```bash
# URLs e endpoints
local api_url="${API_URL:-https://api.example.com}"  # URL da API principal
local timeout="${API_TIMEOUT:-30}"                    # Timeout em segundos (padrão: 30)

# Diretórios
local install_dir="${INSTALL_DIR:-$HOME/.app}"        # Diretório de instalação
local backup_dir="${BACKUP_DIR:-/var/backups}"        # Diretório de backup
```

## 📊 Comparação

| Característica | Envs por Comando | Envs Globais | Variáveis de Sistema |
| -------------- | ---------------- | ------------ | -------------------- |
| **Escopo** | Apenas o comando | Todos os comandos | Override temporário |
| **Arquivo** | `command.json` | `config/settings.conf` | Linha de comando |
| **Isolamento** | ✅ Total | ❌ Compartilhado | ✅ Por execução |
| **Expansão** | ✅ Automática | ❌ Manual | ❌ Manual |
| **Precedência** | Média | Baixa | Alta |
| **Uso** | Configs específicas | Configs globais | Testing/Debug |

## ✅ Boas Práticas

### 1. Prefixos Únicos

```json
// ✅ Bom: prefixo único por comando
{
  "envs": {
    "DOCKER_REPO_URL": "...",
    "DOCKER_TIMEOUT": "..."
  }
}

// ❌ Ruim: muito genérico
{
  "envs": {
    "REPO_URL": "...",
    "TIMEOUT": "..."
  }
}
```

### 2. Documentação

```json
{
  "envs": {
    "DOCKER_REPO_URL": "https://download.docker.com",
    "DOCKER_DOWNLOAD_TIMEOUT": "300",
    "DOCKER_DATA_ROOT": "/var/lib/docker"
  }
}
```

### 3. Valores Padrão Sensatos

Configure valores padrão no `command.json` e **sempre** forneça fallback no script:

```json
// command.json
{
  "envs": {
    "HTTP_TIMEOUT": "30",
    "DOWNLOAD_TIMEOUT": "300",
    "HTTP_RETRY": "3",
    "INSTALL_DIR": "$HOME/.app"
  }
}
```

```bash
# main.sh - Sempre com fallback
timeout="${HTTP_TIMEOUT:-30}"
download_timeout="${DOWNLOAD_TIMEOUT:-300}"
retry="${HTTP_RETRY:-3}"
install_dir="${INSTALL_DIR:-$HOME/.app}"
```

**Por que usar fallback no script?**

- ✅ Script funciona mesmo se `command.json` não tiver `envs`
- ✅ Valores padrão visíveis no código
- ✅ Facilita manutenção e testes
- ✅ Documentação inline dos valores esperados

### 4. Tipos Consistentes

```json
{
  "envs": {
    "PORT": "8080",
    "MAX_CONNECTIONS": "100",
    "ENABLE_CACHE": "true",
    "DEBUG_MODE": "false"
  }
}
```

## 🔍 Debugging

### Ver Variáveis Carregadas

```bash
# No script, adicione temporariamente:
echo "=== Variáveis Carregadas ==="
echo "DOCKER_REPO_URL: ${DOCKER_REPO_URL:-não definida}"
echo "DOCKER_TIMEOUT: ${DOCKER_TIMEOUT:-não definida}"
echo "============================="
```

### Testar com Diferentes Valores

```bash
# Usar valor padrão
$ susa setup docker

# Override via sistema
$ DOCKER_TIMEOUT=600 susa setup docker

# Debug completo
$ DEBUG=true DOCKER_TIMEOUT=600 susa setup docker
```

### Verificar Expansão

```bash
# No script:
local dir="${INSTALL_DIR:-$HOME/.app}"
log_debug "Diretório expandido: $dir"

# Executar com debug:
$ DEBUG=true susa setup myapp
[DEBUG] Diretório expandido: /home/user/.app
```

## 📚 Recursos Adicionais

- **[Guia de Configuração](configuration.md)** - Documentação completa
- **[Como Adicionar Comandos](adding-commands.md)** - Criar comandos com envs
- **[Arquitetura de Plugins](../plugins/architecture.md)** - Usar envs em plugins
- **[Exemplos Práticos](adding-commands.md#exemplo-com-variaveis-de-ambiente)** - Código completo

## 🔌 Envs em Plugins

Plugins suportam variáveis de ambiente da **mesma forma** que comandos built-in, incluindo suporte a arquivos .env.

**Exemplo de plugin com envs e arquivos .env:**

```json
// plugins/deploy-tools/deploy/staging/command.json
{
  "name": "Deploy Staging",
  "description": "Deploy para ambiente de staging",
  "entrypoint": "main.sh",
  "env_files": [
    ".env",
    ".env.staging"
  ],
  "envs": {
    "STAGING_API_URL": "https://api.staging.example.com",
    "STAGING_TIMEOUT": "60",
    "STAGING_SSH_KEY": "$HOME/.ssh/staging_key"
  }
}
```

```bash
# plugins/deploy-tools/deploy/staging/.env
DATABASE_URL="postgresql://staging-db.example.com/mydb"
REDIS_URL="redis://staging-redis.example.com:6379"
AWS_REGION="us-east-1"
```

```bash
# plugins/deploy-tools/deploy/staging/.env.staging
DEPLOY_TARGET="/var/www/staging"
BACKUP_ENABLED="true"
```

```bash
# plugins/deploy-tools/deploy/staging/main.sh
#!/bin/bash

api_url="${STAGING_API_URL:-https://default-staging.com}"
timeout="${STAGING_TIMEOUT:-30}"
database_url="${DATABASE_URL:-}"
deploy_target="${DEPLOY_TARGET:-/tmp/staging}"

log_info "Deploying to: $api_url"
log_info "Database: $database_url"
log_info "Target: $deploy_target"
```

## 📝 Exemplos Completos com Arquivos .env

### Exemplo 1: Aplicação com Múltiplos Ambientes

**Estrutura:**

```text
commands/
  deploy/
    category.json
    app/
      command.json
      main.sh
      .env
      .env.development
      .env.staging
      .env.production
```

**command.json:**

```json
{
  "name": "Deploy App",
  "description": "Deploy da aplicação",
  "entrypoint": "main.sh",
  "sudo": false,
  "os": ["linux", "mac"],
  "env_files": [
    ".env",
    ".env.${DEPLOY_ENV:-development}"
  ],
  "envs": {
    "DEPLOY_TIMEOUT": "300",
    "DEPLOY_MAX_RETRIES": "3"
  }
}
```

**.env (base):**

```bash
# Configurações comuns a todos os ambientes
APP_NAME="My Application"
LOG_LEVEL="info"
MAX_CONNECTIONS="100"
```

**.env.development:**

```bash
# Desenvolvimento
API_URL="http://localhost:3000"
DATABASE_URL="postgresql://localhost/myapp_dev"
DEBUG_MODE="true"
```

**.env.staging:**

```bash
# Staging
API_URL="https://api.staging.example.com"
DATABASE_URL="postgresql://staging-db.example.com/myapp"
DEBUG_MODE="false"
```

**.env.production:**

```bash
# Produção
API_URL="https://api.example.com"
DATABASE_URL="postgresql://prod-db.example.com/myapp"
DEBUG_MODE="false"
ENABLE_MONITORING="true"
```

**Uso:**

```bash
# Deploy desenvolvimento (usa .env.development)
$ susa deploy app

# Deploy staging
$ DEPLOY_ENV=staging susa deploy app

# Deploy produção
$ DEPLOY_ENV=production susa deploy app
```

### Exemplo 2: Separação de Secrets

**Estrutura:**

```text
commands/
  api/
    category.json
    main.sh
    .env
    .env.secrets  # Não commitado (no .gitignore)
```

**command.json:**

```json
{
  "name": "API Client",
  "description": "Cliente da API",
  "entrypoint": "main.sh",
  "env_files": [
    ".env",
    ".env.secrets"
  ]
}
```

**.env:**

```bash
# Configurações públicas (commitado)
API_BASE_URL="https://api.example.com"
API_VERSION="v1"
TIMEOUT="30"
RETRY_COUNT="3"
```

**.env.secrets:**

```bash
# Secrets (NÃO commitado - adicionar ao .gitignore)
API_KEY="sk-1234567890abcdef"
API_SECRET="secret-value-here"
DATABASE_PASSWORD="super-secret-password"
```

**.gitignore:**

```text
.env.secrets
.env.local
.env.*.local
```

**Segurança:**

```bash
# Template para novos desenvolvedores
# .env.secrets.example (commitado)
API_KEY="your-api-key-here"
API_SECRET="your-api-secret-here"
DATABASE_PASSWORD="your-database-password"
```

### Exemplo 3: Configuração por Projeto

**Estrutura:**

```text
commands/
  setup/
    project/
      command.json
      main.sh
```

**command.json:**

```json
{
  "name": "Setup Project",
  "description": "Configura projeto",
  "entrypoint": "main.sh",
  "env_files": [
    "$PWD/.env",
    "$PWD/.env.local"
  ]
}
```

**Uso:**

```bash
# No diretório do projeto
$ cd ~/projects/myapp
$ cat .env
DATABASE_URL="postgresql://localhost/myapp"
API_PORT="3000"

$ susa setup project
# → Carrega .env do projeto atual
```

**Exemplo de plugin com envs:**

```json
// plugins/deploy-tools/deploy/staging/command.json
{
  "name": "Deploy Staging",
  "description": "Deploy para ambiente de staging",
  "entrypoint": "main.sh",
  "envs": {
    "STAGING_API_URL": "https://api.staging.example.com",
    "STAGING_TIMEOUT": "60",
    "STAGING_SSH_KEY": "$HOME/.ssh/staging_key"
  }
}
```

```bash
# plugins/deploy-tools/deploy/staging/main.sh
#!/bin/bash

api_url="${STAGING_API_URL:-https://default-staging.com}"
timeout="${STAGING_TIMEOUT:-30}"
ssh_key="${STAGING_SSH_KEY:-$HOME/.ssh/id_rsa}"

echo "Deploying to $api_url"
ssh -i "$ssh_key" deploy@staging.example.com "./deploy.sh"
```

**Execução:**

```bash
# Usar valores do command.json
$ susa deploy staging

# Override temporário
$ STAGING_TIMEOUT=120 susa deploy staging
```

**Características:**

- ✅ Isolamento entre plugins
- ✅ Mesma precedência (Sistema > Config > Padrão)
- ✅ Carregamento automático pelo framework
- ✅ Não requer código adicional

Veja [Arquitetura de Plugins](../plugins/architecture.md#variaveis-de-ambiente-envs) para mais detalhes.

## 🎯 Exemplo Mínimo

**command.json:**

```json
{
  "name": "My Command",
  "description": "Meu comando",
  "entrypoint": "main.sh",
  "sudo": false,
  "os": ["linux"],
  "envs": {
    "MY_URL": "https://example.com",
    "MY_TIMEOUT": "30"
  }
}
```

**main.sh:**

```bash
#!/bin/bash
set -euo pipefail


url="${MY_URL:-https://default.com}"
timeout="${MY_TIMEOUT:-30}"

curl --max-time "$timeout" "$url"
```

**Execução:**

```bash
# Usar valores do command.json
$ susa my command

# Override temporário
$ MY_TIMEOUT=60 susa my command
```
