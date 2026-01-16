# Susa CLI

Framework modular em Shell Script para criar CLIs extensíveis com descoberta automática de comandos, sistema de plugins e suporte a autocompletar.

![Susa CLI](cli.png)

## ✨ Características

- 🔍 **Discovery Automático** - Comandos descobertos da estrutura de diretórios
- 📦 **Sistema de Plugins** - Extensível via repositórios Git
- 🎯 **Subcategorias Multi-nível** - Hierarquia ilimitada de comandos
- 🌍 **Variáveis de Ambiente** - Configurações isoladas por comando
- 🖥️ **Multi-plataforma** - Linux e macOS
- 📚 **Bibliotecas Reutilizáveis** - Logger, detecção de SO, parser JSON e mais
- ⚡ **Autocompletar** - Tab completion para bash e zsh

## 🚀 Instalação

### Instalação Rápida (recomendado)

```bash
curl -LsSf https://raw.githubusercontent.com/duducp/susa/main/install-remote.sh | bash
```

### Instalação Manual (para desenvolvimento)

```bash
git clone https://github.com/duducp/susa.git
cd susa
make cli-install
```

### Desinstalação

```bash
make cli-uninstall
```

## 📖 Uso Básico

```bash
susa                    # Listar categorias
susa self               # Listar comandos da categoria
susa --version          # Versão
```

## 📁 Estrutura Básica

```text
susa/
├── core/                   # Core do CLI
│   ├── susa               # Executável principal
│   ├── cli.json           # Configuração global
│   └── lib/               # Bibliotecas compartilhadas
├── commands/              # Comandos nativos
│   ├── setup/            # Categoria de comandos
│   │   ├── category.json
│   │   └── docker/       # Comando individual
│   │       ├── command.json
│   │       └── main.sh
│   └── self/             # Comandos internos (plugin, completion)
├── plugins/              # Plugins externos (Git)
│   └── registry.json
└── docs/                 # Documentação MkDocs
```

## 🚀 Começar Rápido

### Criar Novo Comando

**1. Estrutura básica:**

```bash
mkdir -p commands/setup/myapp
```

**2. Configurar comando com envs:**

```json
// commands/setup/myapp/command.json
{
  "name": "My App",
  "description": "Instala My App",
  "entrypoint": "main.sh",
  "sudo": false,
  "os": ["linux", "mac"],
  "envs": {
    "MYAPP_VERSION": "1.0.0",
    "MYAPP_INSTALL_DIR": "$HOME/.myapp",
    "MYAPP_DOWNLOAD_URL": "https://example.com/myapp",
    "MYAPP_TIMEOUT": "300"
  }
}
```

**3. Criar script usando as envs:**

```bash
# commands/setup/myapp/main.sh
#!/bin/bash
set -euo pipefail

install() {
    local version="${MYAPP_VERSION:-1.0.0}"
    local install_dir="${MYAPP_INSTALL_DIR:-$HOME/.myapp}"
    local url="${MYAPP_DOWNLOAD_URL:-https://example.com/myapp}"

    log_info "Instalando My App $version em $install_dir"
    curl --max-time "${MYAPP_TIMEOUT:-300}" "$url" -o /tmp/myapp.tar.gz
    tar -xzf /tmp/myapp.tar.gz -C "$install_dir"
    log_success "Instalado com sucesso!"
}

install "$@"
```

**4. Executar:**

```bash
susa setup myapp
```

Para mais detalhes, consulte a [documentação oficial](https://duducp.github.io/susa/guides/adding-commands/).

### Instalar Plugins

Consulte a [documentação oficial](https://duducp.github.io/susa/plugins/overview/).

### Otimizar Performance

O CLI utiliza um arquivo de cache (`susa.lock`) para acelerar a inicialização:

```bash
susa self lock
```

Este arquivo é **gerado automaticamente** na primeira execução e atualizado ao instalar/remover plugins.

Execute manualmente apenas se adicionar comandos diretamente no diretório `commands/`.

### Ativar Autocompletar

```bash
susa self completion --install
```

## ✅ Quality Assurance

O projeto usa **ShellCheck** para análise estática e **shfmt** para formatação de código:

```bash
# Verificar qualidade do código
make shellcheck

# Verificar formatação
make shfmt

# Formatar automaticamente
make format

# Executar todas as verificações
make lint

# Executar todos os testes
make test
```

**Ferramentas:**

- 🔍 **ShellCheck**: Análise estática de código shell
- 📝 **shfmt**: Formatação automática de scripts

[![CI Status](https://github.com/duducp/susa/actions/workflows/ci.yml/badge.svg)](https://github.com/duducp/susa/actions/workflows/ci.yml)

## 📚 Documentação

A documentação completa está disponível em [duducp.github.io/susa](https://duducp.github.io/susa/).

Para rodar a documentação localmente:

```bash
# Instalar dependências (apenas primeira vez)
make install-dev

# Iniciar servidor de documentação
make doc
```

Acesse em: http://127.0.0.1:8000

## 💻 Desenvolvimento

### Configurar Ambiente de Desenvolvimento

Para desenvolver com suporte de IDE completo (autocomplete, linting em tempo real, etc.):

```bash
# Instalar ferramentas de desenvolvimento e dependências para documentação
make install-dev

# Configurar VS Code
make setup-vscode
```

Após executar `setup-vscode`, reabra o VS Code e instale as extensões recomendadas quando solicitado.

### Git Hooks

O projeto utiliza **pre-commit** do Python para executar verificações automaticamente antes de cada commit.

Os hooks irão executar:

- ✅ ShellCheck (verificação de qualidade do código)
- ✅ shfmt (verificação de formatação)
- ✅ Verificações gerais (espaços em branco, fim de arquivo, etc.)
- ❌ Bloquear commit se houver erros

Para executar manualmente todos os hooks:

```bash
# Executar em todos os arquivos
pre-commit run --all-files

# Executar em arquivos staged
pre-commit run
```

Para corrigir problemas de formatação automaticamente: `make format`

**Ferramentas Instaladas:**

- 🔧 **bash-language-server**: Language Server Protocol para Bash
- 🔍 **ShellCheck**: Análise estática de código shell
- 📝 **shfmt**: Formatação automática de scripts

**Extensões VS Code Recomendadas:**

- **Bash IDE** (mads-hartmann.bash-ide-vscode): LSP para Bash com recursos avançados
- **Shell Format** (foxundermoon.shell-format): Formatação automática
- **ShellCheck** (timonwong.shellcheck): Linting em tempo real

**Recursos IDE:**

- Autocomplete inteligente de comandos e variáveis
- Verificação de erros em tempo real
- Formatação automática ao salvar
- Navegação por definições (Ctrl+Click)
- Documentação ao passar o mouse
- Destaque de sintaxe aprimorado

## 🤝 Contribuindo

Contribuições são bem-vindas! Veja [CONTRIBUTING.md](docs/about/contributing.md).

Antes de enviar seu PR:

1. Execute `make shellcheck` para verificar a qualidade do código
2. Certifique-se de que todos os testes passam no CI

## 📄 Licença

MIT License - veja [LICENSE](docs/about/license.md).

---

**Feito com ❤️ por [Carlos Dorneles](https://github.com/duducp)**
