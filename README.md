# Susa CLI

Framework modular em Shell Script para criar CLIs extensíveis com descoberta automática de comandos, sistema de plugins e suporte a autocompletar.

![Susa CLI](cli.png)

## ✨ Características

- 🔍 **Discovery Automático** - Comandos descobertos da estrutura de diretórios
- 📦 **Sistema de Plugins** - Extensível via repositórios Git
- 🎯 **Subcategorias Multi-nível** - Hierarquia ilimitada de comandos
- 🌍 **Variáveis de Ambiente** - Configurações isoladas por comando
- 🖥️ **Multi-plataforma** - Linux e macOS
- 📚 **Bibliotecas Reutilizáveis** - Logger, detecção de SO, parser YAML e mais
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
│   ├── cli.yaml           # Configuração global
│   └── lib/               # Bibliotecas compartilhadas
├── commands/              # Comandos nativos
│   ├── setup/            # Categoria de comandos
│   │   ├── config.yaml
│   │   └── docker/       # Comando individual
│   │       ├── config.yaml
│   │       └── main.sh
│   └── self/             # Comandos internos (plugin, completion)
├── plugins/              # Plugins externos (Git)
│   └── registry.yaml
└── docs/                 # Documentação MkDocs
```

## 🚀 Começar Rápido

### Criar Novo Comando

**1. Estrutura básica:**

```bash
mkdir -p commands/setup/myapp
```

**2. Configurar comando com envs:**

```yaml
# commands/setup/myapp/config.yaml
name: "My App"
description: "Instala My App"
entrypoint: "main.sh"
sudo: false
os: ["linux", "mac"]
envs:
  MYAPP_VERSION: "1.0.0"
  MYAPP_INSTALL_DIR: "$HOME/.myapp"
  MYAPP_DOWNLOAD_URL: "https://example.com/myapp"
  MYAPP_TIMEOUT: "300"
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

## 📚 Documentação

- **[Documentação Completa](https://duducp.github.io/susa/)** - Guias e referências

## 🤝 Contribuindo

Contribuições são bem-vindas! Veja [CONTRIBUTING.md](docs/about/contributing.md).

## 📄 Licença

MIT License - veja [LICENSE](docs/about/license.md).

---

**Feito com ❤️ por [Carlos Dorneles](https://github.com/duducp)**
