# Arquitetura de Plugins

## 📋 Visão Geral

O CLI agora suporta uma arquitetura descentralizada com suporte a plugins externos. Cada comando tem sua própria configuração local, facilitando a modularidade e extensibilidade.

## 🏗️ Estrutura

```text
cli/
├── core/                    # Core do CLI
│   ├── susa                # Entrypoint principal
│   ├── cli.json            # Config global (nome, versão, categorias)
│   └── lib/                # Bibliotecas
│
├── commands/                # Comandos built-in
│   ├── install/
│   │   ├── asdf/
│   │   │   ├── command.json  # Config do comando
│   │   │   └── main.sh      # Script
│   │   └── docker/
│   │       ├── command.json
│   │       └── main.sh
│   └── daily/
│       └── backup/
│           ├── command.json
│           └── main.sh
└── plugins/                 # Plugins externos
    ├── registry.json        # Registro de plugins
    └── backup-tools/        # Exemplo de plugin
        ├── plugin.json      # ⚠️ Config do plugin (OBRIGATÓRIO)
        └── daily/
            └── backup-s3/
                ├── command.json
                └── main.sh
```

## 📝 Formato do command.json

Cada comando deve ter um arquivo `command.json` no seu diretório:

```json
{
  "name": "Backup S3",
  "description": "Descrição",
  "entrypoint": "main.sh",
  "sudo": false,
  "os": ["linux", "mac"],
  "group": "Backups",
  "envs": {
    "BACKUP_BUCKET": "my-bucket-name",
    "BACKUP_TIMEOUT": "300",
    "BACKUP_DIR": "$HOME/.backups"
  }
}
```

### Variáveis de Ambiente (envs)

Plugins suportam **variáveis de ambiente isoladas** da mesma forma que comandos built-in.

**Definição no command.json:**

```json
{
  "envs": {
    "DEPLOY_API_URL": "https://api.example.com",
    "DEPLOY_TIMEOUT": "60",
    "DEPLOY_RETRY": "3",
    "DEPLOY_CONFIG_DIR": "$HOME/.config/deploy",
    "DEPLOY_LOG_FILE": "$PWD/logs/deploy.log",
    "DEPLOY_API_TOKEN": "secret-token"
  }
}
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

## � Formato do plugin.json

⚠️ **OBRIGATÓRIO**: Todo plugin deve ter um arquivo `plugin.json` na raiz do diretório do plugin.

```json
{
  "name": "backup-tools",
  "version": "1.2.0",
  "description": "Ferramentas de backup e restore",
  "directory": "src"
}
```

### Campos

**Obrigatórios:**

- `name`: Nome do plugin (usado para identificação)
- `version`: Versão no formato semver (ex: 1.0.0, 2.1.3)

**Opcionais:**

- `description`: Descrição do que o plugin faz
- `directory`: Subdiretório onde os comandos estão localizados (útil para organização)

### Validação

O sistema valida o `plugin.json` durante a instalação:

- ✅ Arquivo deve existir na raiz do plugin
- ✅ JSON deve ser válido (sem erros de sintaxe)
- ✅ Campo `name` é obrigatório e não pode estar vazio
- ✅ Campo `version` é obrigatório e não pode estar vazio
- ⚠️ Plugins sem `plugin.json` válido serão **rejeitados**

### Campo directory

O campo `directory` permite organizar seus comandos em um subdiretório específico do plugin.

**Para que serve:**
Separar os comandos do plugin de outros arquivos (README, testes, docs), mantendo uma estrutura organizada.

**Onde usar:**
Configure este campo no `plugin.json` quando seus comandos não estão na raiz do repositório:

```json
{
  "name": "meu-plugin",
  "version": "1.0.0",
  "directory": "src"
}
```

**Como funciona:**
Quando o Susa executa um comando do plugin, ele busca automaticamente no diretório especificado. Por exemplo, com `"directory": "src"`, o comando `demo hello` será buscado em:

```text
meu-plugin/
├── plugin.json          # directory: "src"
├── README.md
└── src/                 # Comandos aqui dentro
    └── demo/
        └── hello/
            ├── command.json
            └── main.sh
```

O sistema automaticamente resolve o caminho correto usando as informações do `susa.lock`.

## 🔌 Como Criar um Plugin

### 1. Crie o plugin.json (OBRIGATÓRIO)

Na raiz do seu plugin, crie o arquivo `plugin.json`:

```json
{
  "name": "meu-plugin",
  "version": "1.0.0",
  "description": "Descrição do meu plugin",
  "directory": "src"
}
```

### 2. Estrutura Básica

Crie um diretório dentro de `plugins/`:

```bash
mkdir -p plugins/meu-plugin/src/categoria/comando
```

### 3. Crie o command.json do Comando

```json
{
  "name": "Meu Comando",
  "description": "Descrição do comando",
  "entrypoint": "main.sh",
  "sudo": false,
  "os": ["linux"],
  "envs": {
    "MY_API_URL": "https://api.example.com",
    "MY_TIMEOUT": "30"
  }
}
```

### 4. Crie o Script

```bash
#!/bin/bash

# Variáveis disponíveis automaticamente
api_url="${MY_API_URL:-https://default.com}"
timeout="${MY_TIMEOUT:-30}"

echo "Conectando em $api_url (timeout: ${timeout}s)"
curl --max-time "$timeout" "$api_url"
```

### 5. Torne Executável

```bash
chmod +x plugins/meu-plugin/src/categoria/comando/main.sh
```

## ✅ Vantagens

1. **Modularidade**: Cada comando é auto-contido
2. **Plugins Externos**: Fácil adicionar comandos sem modificar o core
3. **Isolamento**: Plugins não quebram outros comandos
4. **Distribuição**: Comandos podem ser compartilhados como repositórios Git
5. **Versionamento**: Cada plugin tem sua própria versão via plugin.json
6. **Validação**: Plugin.json obrigatório garante qualidade e compatibilidade
7. **Metadados**: Descrição e informações organizadas em um único arquivo

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

# Modo desenvolvimento (local)
susa self plugin add /caminho/para/meu-plugin
susa self plugin add .
```

Durante a instalação:

- Clona o repositório (ou referencia caminho local)
- **Valida plugin.json** (obrigatório)
- Lê metadados do plugin (nome, versão, descrição)
- Conta comandos e categorias
- Registra no registry.json
- ⚠️ **Rejeita plugins sem plugin.json válido**

### Remover Plugin

```bash
susa self plugin remove plugin-name
```

Remove completamente:

- Diretório do plugin
- Entrada no registry.json

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

## 📦 Distribuindo Plugins

Plugins podem ser distribuídos como repositórios Git:

```bash
# Estrutura do repositório
my-cli-plugin/
├── plugin.json
├── README.md
└── daily/
    └── meu-comando/
        ├── category.json
        └── main.sh
```

**plugin.json obrigatório:**

```json
{
  "name": "my-cli-plugin",
  "version": "1.0.0",
  "description": "Meu plugin CLI"
}
```

Usuários podem instalar diretamente:

```bash
# Via GitHub
susa self plugin add user/my-cli-plugin

# Via URL completa
susa self plugin add https://github.com/user/my-cli-plugin.git
```

⚠️ **Importante**: Plugins sem `plugin.json` válido serão rejeitados durante a instalação.

## 🔍 Discovery de Comandos

O sistema descobre comandos automaticamente:

1. Busca em `commands/categoria/` (built-in)
2. Busca em `plugins/*/categoria/` (externos)
3. Filtra por compatibilidade de SO
4. Aplica permissões (sudo)

## 📋 Registry (plugins/registry.json)

O registry mantém controle de todos os plugins:

```json
{
  "version": "1.0.0",
  "plugins": [
    {
      "name": "backup-tools",
      "source": "https://github.com/user/backup-tools.git",
      "version": "1.2.0",
      "description": "Ferramentas de backup e restore",
      "installedAt": "2026-01-11T22:30:00Z",
      "commands": 4,
      "categories": "backup, restore",
      "dev": false
    }
  ]
}
```

**Campos:**

- `name`: Nome do plugin (do plugin.json)
- `source`: URL do repositório Git ou caminho local (modo dev)
- `version`: Versão instalada (do plugin.json)
- `description`: Descrição do plugin (do plugin.json, opcional)
- `installedAt`: Data/hora da instalação
- `commands`: Quantidade de comandos disponíveis (calculado automaticamente)
- `categories`: Lista de categorias de comandos (calculado automaticamente)
- `dev`: Flag indicando se é plugin em desenvolvimento local

**Funcionalidades:**

- **Tracking**: Origem, versão, data de instalação
- **Histórico**: Mantém registro de todos os plugins
- **Metadados**: Comandos e categorias para listagem rápida
- **Dev Mode**: Campo `dev: true` para plugins em desenvolvimento
- **Performance**: Evita varredura de diretórios ao listar plugins

## 📄 Lock File (susa.lock)

O arquivo `susa.lock` contém cache de todos os comandos, incluindo campo `source` para resolução de paths:

```json
{
  "commands": [
    {
      "category": "deploy",
      "name": "staging",
      "description": "Deploy para staging",
      "plugin": {
        "name": "backup-tools",
        "source": "/home/user/.config/susa/plugins/backup-tools"
      }
    }
  ]
}
```

**Campo `source` no plugin:**

- **Plugins instalados**: Aponta para `$CLI_DIR/plugins/nome-plugin`
- **Plugins dev**: Aponta para diretório atual do plugin
- **Uso**: Sistema usa `source` para construir path completo do script

## ⚡ Performance

- **Lazy Loading**: Configs são lidas apenas quando necessário
- **Filesystem-based**: Não precisa parsear JSON central
- **Cache**: Possível implementar cache em `/tmp` futuramente
