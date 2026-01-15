# Como Adicionar Novos Comandos

Este guia mostra como adicionar novos comandos ao Susa CLI de forma dinâmica.

> **💡 Dica:** Para criar estruturas hierárquicas com subcategorias e múltiplos níveis, veja [Sistema de Categorias e Subcategorias Aninhadas](subcategories.md).

## 📋 Estrutura de um Comando

Cada comando deve seguir esta estrutura hierárquica:

```text
commands/
  <categoria>/
    config.yaml           # Configuração da categoria
    <comando>/
      config.yaml         # Configuração do comando
      main.sh             # Entrypoint principal executável
```

**Exemplo real:**

```text
commands/
  setup/
    config.yaml
    asdf/
      config.yaml
      main.sh
    docker/
      config.yaml
      main.sh
```

> **💡 Nota:** Categorias podem conter comandos diretos OU subcategorias. Para criar hierarquias com subcategorias aninhadas, veja [Sistema de Subcategorias](subcategories.md).

## ➕ Passos para Adicionar um Comando

### 1. Criar a Estrutura de Diretórios

```bash
# Criar categoria (se não existir)
mkdir -p commands/<categoria>/<comando>
```

**Exemplo:**

```bash
mkdir -p commands/setup/vscode
```

### 2. Configurar a Categoria

Crie ou edite `commands/<categoria>/config.yaml`:

```yaml
name: "Setup"
description: "Instalar e configurar ferramentas"
```

### 3. Configurar o Comando

Crie `commands/<categoria>/<comando>/config.yaml`:

```yaml
name: "Nome Amigável"
description: "Descrição clara e objetiva do comando"
entrypoint: "main.sh"
sudo: false
os: ["linux", "mac"]
```

**Exemplo completo:**

```yaml
name: "VS Code"
description: "Instala Visual Studio Code"
entrypoint: "main.sh"
sudo: false
os: ["linux", "mac"]
```

**Campos disponíveis:**

- `name`: Nome amigável exibido ao usuário
- `description`: Descrição breve do comando
- `entrypoint`: Nome do arquivo executável (geralmente `main.sh`)
- `sudo`: Se requer privilégios de administrador (`true`/`false`). Quando `true`, o comando exibe o indicador `[sudo]` na listagem
- `os`: Sistemas suportados (`["linux"]`, `["mac"]`, `["linux", "mac"]`)
- `envs`: **(Opcional)** Variáveis de ambiente específicas do comando (ver abaixo)

#### Variáveis de Ambiente (Envs)

Você pode definir variáveis de ambiente específicas para cada comando usando a seção `envs`:

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

  # Timeouts (em segundos)
  DOCKER_DOWNLOAD_TIMEOUT: "300"
  DOCKER_STARTUP_TIMEOUT: "60"

  # Diretórios (suporta expansão de $HOME, $USER, etc)
  DOCKER_CONFIG_DIR: "$HOME/.docker"
```

**Características:**

✅ **Carregamento automático**: As variáveis são exportadas antes da execução do script
✅ **Expansão de variáveis**: `$HOME`, `$USER` e outras variáveis são automaticamente expandidas
✅ **Isolamento**: Cada comando tem suas próprias variáveis (não vazam entre comandos)
✅ **Configuração centralizada**: Todos os parâmetros em um único arquivo YAML

**Uso no script:**

```bash
#!/bin/bash
set -euo pipefail


install_docker() {
    # Use as variáveis com valores de fallback
    local repo_url="${DOCKER_REPO_URL:-https://download.docker.com}"
    local timeout="${DOCKER_DOWNLOAD_TIMEOUT:-300}"
    local config_dir="${DOCKER_CONFIG_DIR:-$HOME/.docker}"

    log_info "Baixando de: $repo_url"
    curl --max-time "$timeout" "$repo_url/install.sh" | sudo bash

    mkdir -p "$config_dir"
}
```

**Vantagens:**

- ✅ Fácil customização sem alterar código
- ✅ Valores padrão garantem compatibilidade
- ✅ Melhor manutenibilidade
- ✅ Documentação inline das configurações

> **📖 Para mais detalhes sobre variáveis de ambiente**, veja [Guia de Variáveis de Ambiente](envs.md).

**Campos disponíveis (antigo):**

- `name`: Nome amigável exibido ao usuário
- `description`: Descrição breve do comando
- `script`: Nome do arquivo executável (geralmente `main.sh`)
- `sudo`: Se requer privilégios de administrador (`true`/`false`). Quando `true`, o comando exibe o indicador `[sudo]` na listagem
- `os`: Sistemas suportados (`["linux"]`, `["mac"]`, `["linux", "mac"]`)

### 4. Criar o Script Principal

Crie `commands/<categoria>/<comando>/main.sh`:

```bash
#!/bin/bash
set -euo pipefail


# Help function
show_help() {
    show_description
    echo ""
    show_usage
    echo ""
    echo -e "${LIGHT_GREEN}O que é:${NC}"
    echo "  Descrição detalhada da ferramenta ou funcionalidade"
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  -h, --help        Mostra esta mensagem de ajuda"
    echo "  --uninstall       Remove a instalação"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo "  susa <categoria> <comando>              # Instala"
    echo "  susa <categoria> <comando> --uninstall  # Remove"
    echo ""
}

# Main installation function
install() {
    log_info "Instalando..."

    # Seu código de instalação aqui

    log_success "Instalado com sucesso!"
}

# Uninstall function
uninstall() {
    log_info "Removendo..."

    # Seu código de remoção aqui

    log_success "Removido com sucesso!"
}

# Parse arguments
UNINSTALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        --uninstall|-u)
            UNINSTALL=true
            shift
            ;;
        *)
            log_error "Opção desconhecida: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Execute main logic
if [ "$UNINSTALL" = true ]; then
    uninstall
else
    install
fi
```

### 5. Tornar o Script Executável

```bash
chmod +x commands/<categoria>/<comando>/main.sh
```

### 6. Testar o Comando

```bash
# Listar comandos da categoria
susa <categoria>

# Executar o comando
susa <categoria> <comando>

# Exibir ajuda
susa <categoria> <comando> --help
```

**Exemplo:**

```bash
susa setup              # Lista todos os comandos de setup
susa setup vscode       # Instala o VS Code
susa setup vscode -h    # Mostra ajuda do comando
```

## 📚 Bibliotecas Disponíveis

Para detalhes completos de todas as bibliotecas, veja [Referência de Bibliotecas](../reference/libraries/index.md).

## 🎯 Boas Práticas

1. **Use as funções auxiliares do CLI**:
2. **Funções de log**: Use `log_*` em vez de `echo` para mensagens
3. **Função de ajuda**: Sempre implemente `show_help()` com `show_description` e `show_usage`
4. **Tratamento de erros**: Use `set -euo pipefail` no início
5. **Parse de argumentos**: Use `while` + `case` para processar opções
6. **Validação**: Verifique se dependências estão instaladas antes de usar
7. **Cores com reset**: Sempre termine mensagens coloridas com `${NC}`
8. **Variáveis de ambiente**:
   - Use seção `envs` no `config.yaml` para URLs, timeouts e configurações
   - Sempre forneça valores de fallback: `${VAR:-default}`
   - Use prefixos únicos para evitar conflitos: `COMANDO_VAR` em vez de `VAR`
   - Documente as variáveis com comentários no YAML
9. **Configurações**: Prefira `envs` no `config.yaml` em vez de hardcoded no script

## 🔍 Descoberta Automática

O Susa CLI descobre comandos **automaticamente**:

- Não há registro central de comandos
- O CLI varre o diretório `commands/` em tempo de execução
- Cada `config.yaml` é lido dinamicamente
- Plugins funcionam da mesma forma em `plugins/`

> **💡 Para entender como o sistema diferencia comandos e subcategorias**, veja [Diferença entre Comandos e Subcategorias](subcategories.md#diferenca-entre-comandos-e-subcategorias).

## 🧪 Testando Localmente

```bash
# Testar descoberta de comandos
susa

# Testar categoria específica
susa setup

# Executar comando
susa setup vscode

# Testar com debug
DEBUG=true susa setup vscode

# Ver ajuda
susa setup vscode --help
```

## 📖 Exemplo Completo

### Exemplo Básico (sem envs)

Veja o comando [setup asdf](../reference/commands/setup/asdf.md) como referência completa de implementação.

### Exemplo com Variáveis de Ambiente

**Estrutura:**

```text
commands/
  deploy/
    config.yaml
    app/
      config.yaml    # Com seção envs
      main.sh        # Usa as envs
```

**commands/deploy/config.yaml:**

```yaml
name: "Deploy"
description: "Comandos de deploy"
```

**commands/deploy/app/config.yaml:**

```yaml
name: "Deploy App"
description: "Deploy da aplicação para produção"
entrypoint: "main.sh"
sudo: false
os: ["linux", "mac"]
envs:
  # URLs e Endpoints
  DEPLOY_API_URL: "https://api.example.com"
  DEPLOY_WEBHOOK_URL: "https://hooks.slack.com/services/XXX"

  # Configurações de Deploy
  DEPLOY_TARGET_DIR: "/var/www/app"
  DEPLOY_BACKUP_DIR: "$HOME/backups"
  DEPLOY_MAX_RETRIES: "3"
  DEPLOY_TIMEOUT: "300"

  # Features
  DEPLOY_BACKUP_ENABLED: "true"
  DEPLOY_ROLLBACK_ENABLED: "true"
  DEPLOY_NOTIFICATIONS_ENABLED: "true"
```

**commands/deploy/app/main.sh:**

```bash
#!/bin/bash
set -euo pipefail

source "$LIB_DIR/logger.sh"

# Help function
show_help() {
    show_description
    echo ""
    show_usage "<ambiente>"
    echo ""
    echo -e "${LIGHT_GREEN}Argumentos:${NC}"
    echo "  <ambiente>        staging ou production"
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  -h, --help        Mostra esta mensagem"
    echo "  --skip-backup     Não cria backup antes do deploy"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo "  susa deploy app staging       # Deploy para staging"
    echo "  susa deploy app production    # Deploy para production"
    echo ""
}

# Send notification
send_notification() {
    local message="$1"
    local webhook="${DEPLOY_WEBHOOK_URL:-}"
    local enabled="${DEPLOY_NOTIFICATIONS_ENABLED:-false}"

    if [ "$enabled" = "true" ] && [ -n "$webhook" ]; then
        curl -X POST "$webhook" \
             -H "Content-Type: application/json" \
             -d "{\"text\":\"$message\"}" \
             2>/dev/null || true
    fi
}

# Create backup
create_backup() {
    local target_dir="${DEPLOY_TARGET_DIR:-/var/www/app}"
    local backup_dir="${DEPLOY_BACKUP_DIR:-$HOME/backups}"
    local enabled="${DEPLOY_BACKUP_ENABLED:-true}"

    if [ "$enabled" != "true" ]; then
        log_info "Backup desabilitado"
        return 0
    fi

    log_info "Criando backup..."

    mkdir -p "$backup_dir"
    local backup_file="$backup_dir/app-$(date +%Y%m%d-%H%M%S).tar.gz"

    tar -czf "$backup_file" -C "$(dirname "$target_dir")" "$(basename "$target_dir")"

    log_success "Backup criado: $backup_file"
}

# Deploy application
deploy() {
    local env="$1"
    local skip_backup="${2:-false}"

    local api_url="${DEPLOY_API_URL:-https://api.example.com}"
    local target_dir="${DEPLOY_TARGET_DIR:-/var/www/app}"
    local timeout="${DEPLOY_TIMEOUT:-300}"
    local max_retries="${DEPLOY_MAX_RETRIES:-3}"

    log_info "Iniciando deploy para: $env"
    send_notification "🚀 Deploy para $env iniciado"

    # Backup
    if [ "$skip_backup" != "true" ]; then
        create_backup
    fi

    # Deploy via API
    log_info "Fazendo deploy via API..."

    local retry=0
    while [ $retry -lt $max_retries ]; do
        if curl --max-time "$timeout" \
                --fail \
                -X POST "$api_url/deploy" \
                -H "Content-Type: application/json" \
                -d "{\"env\":\"$env\",\"target\":\"$target_dir\"}"; then
            log_success "Deploy concluído com sucesso!"
            send_notification "✅ Deploy para $env concluído com sucesso"
            return 0
        fi

        retry=$((retry + 1))
        log_warning "Tentativa $retry de $max_retries falhou"
        sleep 5
    done

    log_error "Deploy falhou após $max_retries tentativas"
    send_notification "❌ Deploy para $env falhou"

    # Rollback if enabled
    if [ "${DEPLOY_ROLLBACK_ENABLED:-true}" = "true" ]; then
        log_info "Executando rollback automático..."
        rollback
    fi

    exit 1
}

# Rollback to previous version
rollback() {
    local backup_dir="${DEPLOY_BACKUP_DIR:-$HOME/backups}"
    local target_dir="${DEPLOY_TARGET_DIR:-/var/www/app}"

    log_info "Procurando backup mais recente..."

    local latest_backup=$(ls -t "$backup_dir"/app-*.tar.gz 2>/dev/null | head -1)

    if [ -z "$latest_backup" ]; then
        log_error "Nenhum backup encontrado"
        return 1
    fi

    log_info "Restaurando: $latest_backup"

    rm -rf "$target_dir"
    mkdir -p "$(dirname "$target_dir")"
    tar -xzf "$latest_backup" -C "$(dirname "$target_dir")"

    log_success "Rollback concluído"
    send_notification "🔄 Rollback executado com sucesso"
}

# Parse arguments
ENVIRONMENT=""
SKIP_BACKUP=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        staging|production)
            ENVIRONMENT="$1"
            shift
            ;;
        *)
            log_error "Argumento inválido: $1"
            show_usage "<ambiente>"
            exit 1
            ;;
    esac
done

# Validate environment
if [ -z "$ENVIRONMENT" ]; then
    log_error "Ambiente não especificado"
    show_usage "<ambiente>"
    exit 1
fi

# Execute deploy
deploy "$ENVIRONMENT" "$SKIP_BACKUP"
```

**Uso:**

```bash
# Deploy básico
$ susa deploy app staging

# Deploy sem backup
$ susa deploy app production --skip-backup

# Customizar configurações via env vars
$ DEPLOY_TIMEOUT=600 DEPLOY_MAX_RETRIES=5 susa deploy app production

# Ver ajuda
$ susa deploy app --help
```

**Customização sem editar código:**

```yaml
# Apenas edite config.yaml para customizar
envs:
  DEPLOY_API_URL: "https://api.staging.com"  # Mudar URL
  DEPLOY_TIMEOUT: "600"                       # Aumentar timeout
  DEPLOY_NOTIFICATIONS_ENABLED: "false"      # Desabilitar notificações
```

## 🔗 Guias Relacionados

- **[Sistema de Categorias e Subcategorias Aninhadas](subcategories.md)** - Para criar estruturas hierárquicas com múltiplos níveis
- **[Referência de Bibliotecas](../reference/libraries/index.md)** - Bibliotecas disponíveis para usar em seus scripts
