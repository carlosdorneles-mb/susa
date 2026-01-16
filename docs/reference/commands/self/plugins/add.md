# Self Plugin Add

Instala um plugin a partir de um repositório Git, adicionando novos comandos ao Susa CLI.

Suporta **GitHub**, **GitLab** e **Bitbucket**.

## Como usar

### Usando URL completa

```bash
# GitHub
susa self plugin add https://github.com/usuario/susa-plugin-name
susa self plugin add git@github.com:organizacao/plugin-privado.git

# GitLab
susa self plugin add https://gitlab.com/usuario/susa-plugin-name
susa self plugin add git@gitlab.com:organizacao/plugin-privado.git

# Bitbucket
susa self plugin add https://bitbucket.org/usuario/susa-plugin-name
susa self plugin add git@bitbucket.org:organizacao/plugin-privado.git
```

### Usando formato user/repo

```bash
# GitHub (padrão)
susa self plugin add usuario/susa-plugin-name

# GitLab
susa self plugin add usuario/susa-plugin-name --gitlab

# Bitbucket
susa self plugin add usuario/susa-plugin-name --bitbucket

# Privado com SSH
susa self plugin add organizacao/plugin-privado --gitlab --ssh
```

### Usando caminho local (Modo Desenvolvimento)

```bash
# Caminho absoluto
susa self plugin add /caminho/completo/para/meu-plugin

# Caminho relativo
susa self plugin add ./meu-plugin
susa self plugin add ../outro-plugin

# Diretório atual
susa self plugin add .

# Com ~ (home directory)
susa self plugin add ~/projetos/meu-plugin
```

### Detecção automática do diretório atual

Se você estiver dentro do diretório de um plugin e não passar nenhum argumento, o comando **automaticamente** detecta e adiciona o plugin do diretório atual:

```bash
# Dentro do diretório do plugin
cd ~/projetos/meu-plugin
susa self plugin add
# Equivalente a: susa self plugin add .

# Funciona com flags
susa self plugin add -v
susa self plugin add --verbose
```

Isso é especialmente útil durante o desenvolvimento de plugins.

## O que acontece?

### Instalação via Git (URL ou user/repo)

1. Verifica se o plugin já está instalado
2. Valida acesso ao repositório
3. Clona o repositório Git do plugin
4. Registra o plugin no sistema
5. Torna os comandos do plugin disponíveis imediatamente

### Instalação Local (Modo Desenvolvimento)

1. Verifica se o plugin já está instalado
2. Valida estrutura do plugin no caminho local
3. Registra o plugin como **desenvolvimento** (dev: true)
4. Armazena referência ao caminho local (não copia arquivos)
5. Torna os comandos do plugin disponíveis imediatamente
6. **Alterações no código refletem automaticamente** sem reinstalação!

## Opções

| Opção | O que faz |
| ------- | ----------- |
| `-v, --verbose` | Modo verbose (exibe logs de debug) |
| `-q, --quiet` | Modo silencioso (mínimo de output) |
| `--gitlab` | Usa GitLab (para formato user/repo) |
| `--bitbucket` | Usa Bitbucket (para formato user/repo) |
| `--ssh` | Força uso de SSH (recomendado para repos privados) |
| `-h, --help` | Mostra ajuda |

**Nota:** Por padrão, o formato `user/repo` usa GitHub. Use `--gitlab` ou `--bitbucket` para outros provedores.

## Requisitos

- Git instalado no sistema
- Conexão com a internet
- Plugin deve seguir a estrutura do Susa CLI

## Estrutura esperada do plugin

### Estrutura básica (sem campo directory)

```text
susa-plugin-name/
├── plugin.json          # Obrigatório
├── README.md
└── categoria/
    └── comando/
        ├── command.json
        └── main.sh
```

### Estrutura com campo directory

Se o plugin usa o campo `directory` no `plugin.json`, os comandos devem estar dentro do subdiretório especificado:

```text
susa-plugin-name/
├── plugin.json          # Com "directory": "src"
├── README.md
└── src/                 # Comandos aqui dentro
    └── categoria/
        └── comando/
            ├── command.json
            └── main.sh
```

O campo `directory` é útil para organizar melhor o plugin, separando comandos de outros arquivos (docs, testes, etc). O sistema detecta automaticamente e busca os comandos no local correto.

## Modo Desenvolvimento

### O que é?

O modo desenvolvimento permite testar e desenvolver plugins **sem publicar no Git**. O plugin aponta para o diretório local, e todas as alterações no código refletem imediatamente.

### Quando usar?

- Desenvolver novos plugins
- Testar alterações antes de publicar
- Depurar problemas em plugins
- Trabalhar em plugins privados localmente

### Como funciona?

```bash
# Navegar até o diretório do plugin
cd ~/projetos/meu-plugin

# Instalar em modo desenvolvimento
susa self plugin add .
```

### Características

✅ **Alterações instantâneas** - Sem necessidade de reinstalar
✅ **Não copia arquivos** - Aponta para o diretório original
✅ **Badge [DEV]** - Identificação visual na listagem
✅ **Versão "dev"** - Se não houver arquivo VERSION
🚫 **Não pode ser atualizado** - Alterações já são imediatas

### Diferenças entre Dev e Git

| Aspecto | Plugin Git | Plugin Dev |
| --------- | ------------ | ------------ |
| Origem | Repositório Git | Diretório local |
| Arquivos | Copiados para ~/.susa/plugins | Referência ao path |
| Alterações | Precisa `susa self plugin update` | Reflete automaticamente |
| Identificação | Nome do plugin | Badge [DEV] |
| Atualização | ✅ Pode atualizar | ❌ Não aplicável |
| Remoção | Remove diretório + registry | Remove apenas registry |

### Validação de Estrutura

Plugins locais são validados automaticamente. O sistema verifica:

1. **plugin.json** existe e é válido
2. Comandos estão no local correto (raiz ou dentro do `directory` configurado)
3. Estrutura de categorias e comandos está correta

**Estrutura sem campo directory:**

```text
meu-plugin/
├── plugin.json
└── categoria/
    └── comando/
        ├── category.json
        └── main.sh
```

**Estrutura com campo directory:**

```text
meu-plugin/
├── plugin.json       # "directory": "src"
└── src/
    └── categoria/
        └── comando/
            ├── category.json
            └── main.sh
```

Se a estrutura for inválida, o comando mostra o formato esperado com base na configuração do plugin.

## Exemplo de uso

### Plugin Git

```bash
# Instalar plugin de backup
susa self plugin add usuario/susa-backup-tools

# Após instalação, os comandos ficam disponíveis
susa backup criar
susa backup restaurar
```

### Plugin Local (Desenvolvimento)

```bash
# Criar estrutura do plugin
mkdir -p ~/dev/my-plugin/tools/hello
cat > ~/dev/my-plugin/tools/category.json << 'EOF'
name: "tools"
description: "Ferramentas úteis"
EOF

cat > ~/dev/my-plugin/tools/hello/command.json << 'EOF'
name: "hello"
description: "Diz olá"
entrypoint: "main.sh"
os: ["linux", "mac"]
EOF

echo '#!/bin/bash
echo "Hello from dev plugin!"' > ~/dev/my-plugin/tools/hello/main.sh
chmod +x ~/dev/my-plugin/tools/hello/main.sh

# Instalar em modo dev
cd ~/dev/my-plugin
susa self plugin add .

# Usar o comando
susa tools hello
# Saída: Hello from dev plugin!

# Editar o código
echo '#!/bin/bash
echo "Hello, World! Updated!"' > ~/dev/my-plugin/tools/hello/main.sh

# Testar novamente (sem reinstalar!)
susa tools hello
# Saída: Hello, World! Updated!
```

## Se o plugin já estiver instalado

### Plugin Git

O comando mostra informações do plugin existente e sugere ações:

```text
⚠ Plugin 'backup-tools' já está instalado

  Versão atual: 1.2.0
  Instalado em: 2026-01-10 14:30:00

Opções disponíveis:
  • Atualizar plugin:  susa self plugin update backup-tools
  • Remover plugin:    susa self plugin remove backup-tools
  • Listar plugins:    susa self plugin list
```

### Plugin Dev

Para plugins em modo desenvolvimento, não oferece opção de atualização:

```text
⚠ Plugin 'meu-plugin' já está instalado

Detalhes do plugin:
  Modo: desenvolvimento
  Local do plugin: /home/usuario/projetos/meu-plugin
  Versão atual: dev
  Instalado em: 2026-01-14 23:00:00

Opções disponíveis:
  • Remover plugin:   susa self plugin remove meu-plugin
  • Listar plugins:   susa self plugin list
```

## Repositórios Privados

### Provedores Suportados

O sistema detecta automaticamente SSH para:

- **GitHub** (github.com)
- **GitLab** (gitlab.com)
- **Bitbucket** (bitbucket.org)

Para cada provedor, o sistema verifica se você tem SSH configurado e usa automaticamente quando disponível.

### Autenticação SSH (Recomendada)

O sistema detecta automaticamente se você tem SSH configurado e usa quando disponível:

```bash
# 1. Configure sua chave SSH
ssh-keygen -t ed25519 -C "seu-email@example.com"
cat ~/.ssh/id_ed25519.pub

# 2. Adicione a chave no provedor:
#    • GitHub: Settings → SSH and GPG keys → New SSH key
#    • GitLab: Preferences → SSH Keys
#    • Bitbucket: Personal settings → SSH keys

# 3. Instale o plugin (detecta SSH automaticamente)
susa self plugin add organizacao/plugin-privado          # GitHub
susa self plugin add organizacao/plugin-privado --gitlab # GitLab
susa self plugin add organizacao/plugin-privado --bitbucket # Bitbucket
```

### Forçar SSH

Use `--ssh` para garantir uso de SSH:

```bash
susa self plugin add organizacao/plugin-privado --ssh
```

### Autenticação HTTPS

Configure credential helper para repositórios HTTPS:

```bash
git config --global credential.helper store
susa self plugin add https://github.com/org/plugin-privado.git
```

### Mensagens de Erro

Se não tiver acesso, o comando mostra ajuda:

```text
[ERROR] Não foi possível acessar o repositório

Possíveis causas:
  • Repositório não existe
  • Repositório é privado e você não tem acesso
  • Credenciais Git não configuradas

Para repositórios privados:
  • Use --ssh e configure chave SSH no GitHub/GitLab
  • Configure credential helper: git config --global credential.helper store
```

## Veja também

- [susa self plugin list](list.md) - Listar plugins instalados
- [susa self plugin update](update.md) - Atualizar um plugin
- [susa self plugin remove](remove.md) - Remover um plugin
- [Visão Geral de Plugins](../../../../plugins/overview.md) - Entenda o sistema de plugins
- [Arquitetura de Plugins](../../../../plugins/architecture.md) - Como funcionam os plugins
