# Susa CLI

Framework modular em Shell Script para criar CLIs extensíveis com descoberta automática de comandos, sistema de plugins e suporte a autocompletar.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Características

- 🔍 **Discovery Automático** - Comandos descobertos da estrutura de diretórios
- 📦 **Sistema de Plugins** - Extensível via repositórios Git
- 🎯 **Subcategorias Multi-nível** - Hierarquia ilimitada de comandos
- 🖥️ **Multi-plataforma** - Linux e macOS
- 📚 **Bibliotecas Reutilizáveis** - Logger, detecção de SO, parser YAML e mais
- ⚡ **Autocompletar** - Tab completion para bash e zsh

## 🚀 Instalação

```bash
curl -LsSf https://raw.githubusercontent.com/carlosdorneles-mb/susa/main/install-remote.sh | sh
```

### Desinstalação

```bash
# Desinstalar remotamente
curl -LsSf https://raw.githubusercontent.com/carlosdorneles-mb/susa/main/uninstall-remote.sh | sh
```

## 📖 Uso Básico

```bash
susa                    # Listar categorias
susa setup              # Listar comandos da categoria
susa setup docker       # Executar comando
susa setup --help       # Ajuda
susa --version          # Versão
```

## 📁 Estrutura Básica

```text
susa/
├── susa                    # Executável principal
├── cli.yaml                # Configuração global
├── commands/               # Comandos nativos
│   ├── setup/             # Categoria de comandos
│   │   ├── config.yaml
│   │   └── docker/        # Comando individual
│   │       ├── config.yaml
│   │       └── main.sh
│   └── self/              # Comandos internos (plugin, completion)
├── plugins/               # Plugins externos (Git)
│   └── registry.yaml
├── lib/                   # Bibliotecas compartilhadas
└── docs/                  # Documentação MkDocs
```

## 🚀 Começar Rápido

### Criar Novo Comando

```bash
# 1. Estrutura
mkdir -p commands/setup/meuapp

# 2. Configuração (commands/setup/meuapp/config.yaml)
cat > commands/setup/meuapp/config.yaml << EOF
name: "Meu App"
description: "Instala Meu App"
script: "main.sh"
EOF

# 3. Script (commands/setup/meuapp/main.sh)
cat > commands/setup/meuapp/main.sh << 'EOF'
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/../../.." && pwd)/lib/logger.sh"

log_info "Instalando Meu App..."
# Sua lógica aqui
log_success "Pronto!"
EOF

chmod +x commands/setup/meuapp/main.sh

# 4. Usar
susa setup meuapp
```

### Instalar Plugins

```bash
susa self plugin install user/repo
susa self plugin list
```

### Ativar Autocompletar

```bash
susa self completion --install
```

## 📚 Documentação Completa

- **[Documentação Completa](https://carlosdorneles-mb.github.io/susa/)** - Guias e referências
- **[Quick Start](docs/quick-start.md)** - Primeiros passos
- **[Guia de Funcionalidades](docs/guides/features.md)** - Recursos detalhados
- **[Adicionar Comandos](docs/guides/adding-commands.md)** - Tutorial passo-a-passo
- **[Referência de Bibliotecas](docs/reference/libraries.md)** - API completa
- **[Sistema de Plugins](docs/plugins/overview.md)** - Extensibilidade

## 🤝 Contribuindo

Contribuições são bem-vindas! Veja [CONTRIBUTING.md](docs/about/contributing.md).

## 📄 Licença

MIT License - veja [LICENSE](docs/about/license.md).

---

**Feito com ❤️ por [Carlos Dorneles](https://github.com/carlosdorneles-mb)**
