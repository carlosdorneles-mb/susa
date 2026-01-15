# Arquitetura de Plugins

## 📋 Visão Geral

O CLI agora suporta uma arquitetura descentralizada com suporte a plugins externos. Cada comando tem sua própria configuração local, facilitando a modularidade e extensibilidade.

## 🏗️ Estrutura

```text
cli/
├── core/                    # Core do CLI
│   ├── susa                # Entrypoint principal
│   ├── cli.yaml            # Config global (nome, versão, categorias)
│   └── lib/                # Bibliotecas
│
├── commands/                # Comandos built-in
│   ├── install/
│   │   ├── asdf/
│   │   │   ├── config.yaml  # Config do comando
│   │   │   └── main.sh      # Script
│   │   └── docker/
│   │       ├── config.yaml
│   │       └── main.sh
│   └── daily/
│       └── backup/
│           ├── config.yaml
│           └── main.sh
└── plugins/                 # Plugins externos
    ├── registry.yaml        # Registro de plugins
    └── backup-tools/        # Exemplo de plugin
        └── daily/
            └── backup-s3/
                ├── config.yaml
                └── main.sh
```

## 📝 Formato do config.yaml

Cada comando deve ter um arquivo `config.yaml` no seu diretório:

```yaml
name: "Backup S3"           # Nome para exibição
description: "Descrição"    # Descrição curta
entrypoint: "main.sh"       # Entrypoint principal
sudo: false                 # Requer sudo?
os: ["linux", "mac"]        # Sistemas compatíveis
group: "Backups"            # (Opcional) Grupo para organização
envs:                       # (Opcional) Variáveis de ambiente
  BACKUP_BUCKET: "my-bucket-name"
  BACKUP_TIMEOUT: "300"
  BACKUP_DIR: "$HOME/.backups"
```

### Variáveis de Ambiente (envs)

Plugins suportam **variáveis de ambiente isoladas** da mesma forma que comandos built-in.

**Definição no config.yaml:**

```yaml
envs:
  # URLs e endpoints
  DEPLOY_API_URL: "https://api.example.com"

  # Timeouts (sempre como string)
  DEPLOY_TIMEOUT: "60"
  DEPLOY_RETRY: "3"

  # Paths com expansão de variáveis
  DEPLOY_CONFIG_DIR: "$HOME/.config/deploy"
  DEPLOY_LOG_FILE: "$PWD/logs/deploy.log"

  # Tokens e credenciais
  DEPLOY_API_TOKEN: "secret-token"
```

**Uso no main.sh:**

```bash
#!/bin/bash

# Sempre use fallback
api_url="${DEPLOY_API_URL:-https://default.com}"
timeout="${DEPLOY_TIMEOUT:-30}"
config_dir="${DEPLOY_CONFIG_DIR:-$HOME/.config/deploy}"

curl --max-time "$timeout" "$api_url"
```

**Características:**

- ✅ Carregamento automático pelo framework
- ✅ Expansão de variáveis (`$HOME`, `$USER`, `$PWD`)
- ✅ Isolamento total entre comandos
- ✅ Override via variáveis de sistema: `DEPLOY_TIMEOUT=120 susa deploy staging`
- ✅ Mesma precedência: Sistema > Config > Padrão no script

**Documentação completa:** [Guia de Variáveis de Ambiente](../guides/envs.md)

## 🔌 Como Criar um Plugin

### 1. Estrutura Básica

Crie um diretório dentro de `plugins/`:

```bash
mkdir -p plugins/meu-plugin/categoria/comando
```

### 2. Crie o config.yaml

```yaml
name: "Meu Comando"
description: "Descrição do comando"
entrypoint: "main.sh"
sudo: false
os: ["linux"]
envs:
  MY_API_URL: "https://api.example.com"
  MY_TIMEOUT: "30"
```

### 3. Crie o Script

```bash
#!/bin/bash

# Variáveis disponíveis automaticamente
api_url="${MY_API_URL:-https://default.com}"
timeout="${MY_TIMEOUT:-30}"

echo "Conectando em $api_url (timeout: ${timeout}s)"
curl --max-time "$timeout" "$api_url"
```

### 4. Torne Executável

```bash
chmod +x plugins/meu-plugin/categoria/comando/main.sh
```

## ✅ Vantagens

1. **Modularidade**: Cada comando é auto-contido
2. **Plugins Externos**: Fácil adicionar comandos sem modificar o core
3. **Isolamento**: Plugins não quebram outros comandos
4. **Distribuição**: Comandos podem ser compartilhados como repositórios Git
5. **Versionamento**: Cada plugin pode ter sua versão

## 🚀 Comandos de Gerenciamento

### Listar Plugins

```bash
susa self plugin list
```

Mostra todos os plugins instalados com:

- Origem (URL Git)
- Versão
- Número de comandos
- Categorias
- Data de instalação

### Instalar Plugin

```bash
# De URL completa
susa self plugin add https://github.com/user/cli-plugin-name

# Atalho GitHub
susa self plugin add user/cli-plugin-name
```

Durante a instalação:

- Clona o repositório
- Detecta versão (de version.txt)
- Registra no registry.yaml

### Remover Plugin

```bash
susa self plugin remove plugin-name
```

Remove completamente:

- Diretório do plugin
- Entrada no registry.yaml

### Atualizar Plugin

```bash
susa self plugin update plugin-name
```

Atualiza o plugin para a versão mais recente:

- Obtém URL de origem do registry
- Faz backup temporário do plugin atual
- Clona versão mais recente do repositório
- Atualiza informações no registry (versão, data)
- Remove backup se sucesso, restaura se falha

**Requisitos:**

- Plugin deve ter sido instalado via `susa self plugin add`
- Origem deve ser um repositório Git válido
- Plugins locais não podem ser atualizados

### Executar Plugin (Dev Mode)

```bash
cd ~/meu-plugin
susa self plugin run meu-plugin deploy staging
```

Executa plugin sem instalação permanente:

- **Modo automático**: Plugin é adicionado, executado e removido automaticamente
- **Modo manual**: Use `--prepare` para adicionar, execute múltiplos comandos, use `--cleanup` para remover
- **Subcategorias**: Use barra `/` para indicar hierarquia (ex: `deploy/aws`)
- **Separador `--`**: Separa opções do run de argumentos do plugin

Veja [Self Plugin Run](../reference/commands/self/plugins/run.md) para mais detalhes.

## 📦 Distribuindo Plugins

Plugins podem ser distribuídos como repositórios Git:

```bash
# Estrutura do repositório
my-cli-plugin/
├── README.md
└── daily/
    └── meu-comando/
        ├── config.yaml
        └── main.sh
```

Usuários podem clonar e copiar para `plugins/`:

```bash
git clone https://github.com/user/my-cli-plugin
cp -r my-cli-plugin plugins/
```

## 🔍 Discovery de Comandos

O sistema descobre comandos automaticamente:

1. Busca em `commands/categoria/` (built-in)
2. Busca em `plugins/*/categoria/` (externos)
3. Filtra por compatibilidade de SO
4. Aplica permissões (sudo)

## 📋 Registry (plugins/registry.yaml)

O registry mantém controle de todos os plugins:

```yaml
version: "1.0.0"

plugins:
  - name: "backup-tools"
    source: "https://github.com/user/backup-tools.git"
    version: "1.2.0"
    installed_at: "2026-01-11T22:30:00Z"
    commands: 4
    categories: backup, restore
    dev: false
```

**Campos:**

- `name`: Nome do plugin
- `source`: URL do repositório Git
- `version`: Versão instalada
- `installed_at`: Data/hora da instalação
- `commands`: Quantidade de comandos disponíveis (calculado automaticamente)
- `categories`: Lista de categorias de comandos (calculado automaticamente)
- `dev`: Flag indicando se é plugin em desenvolvimento

**Funcionalidades:**

- **Tracking**: Origem, versão, data de instalação
- **Histórico**: Mantém registro de todos os plugins
- **Metadados**: Comandos e categorias para listagem rápida
- **Dev Mode**: Campo `dev: true` para plugins em desenvolvimento
- **Performance**: Evita varredura de diretórios ao listar plugins

## 📄 Lock File (susa.lock)

O arquivo `susa.lock` contém cache de todos os comandos, incluindo campo `source` para resolução de paths:

```yaml
commands:
  - category: "deploy"
    name: "staging"
    description: "Deploy para staging"
    plugin:
      name: "backup-tools"
      source: "/home/user/.config/susa/plugins/backup-tools"
```

**Campo `source` no plugin:**

- **Plugins instalados**: Aponta para `$CLI_DIR/plugins/nome-plugin`
- **Plugins dev**: Aponta para diretório atual do plugin
- **Uso**: Sistema usa `source` para construir path completo do script

## ⚡ Performance

- **Lazy Loading**: Configs são lidas apenas quando necessário
- **Filesystem-based**: Não precisa parsear YAML central
- **Cache**: Possível implementar cache em `/tmp` futuramente
