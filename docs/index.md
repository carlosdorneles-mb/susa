# Susa CLI

Sistema modular de CLI em Shell Script para automação de tarefas e gerenciamento de software.

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Shell](https://img.shields.io/badge/shell-bash-orange)
![Platform](https://img.shields.io/badge/platform-linux%20%7C%20macos-lightgrey)

## ✨ Características

- 🔍 **Discovery Automático** - Comandos descobertos da estrutura de diretórios
- 📦 **Sistema de Plugins** - Extensão via repositórios Git externos
- 🎯 **Subcategorias Multi-nível** - Navegação hierárquica ilimitada
- 🖥️ **Multi-plataforma** - Suporte para Linux (Debian, Fedora) e macOS
- 📚 **12 Bibliotecas Úteis** - Logger, detecção de SO, gerenciamento de dependências
- 🎨 **Interface Rica** - Logs coloridos, agrupamento visual, help customizado
- ⚙️ **Parser YAML Robusto** - yq v4+ com instalação automática
- 🔐 **Gestão de Permissões** - Indicadores e verificação de sudo
- 🌐 **Instalação Remota** - Instale com um único comando curl

## 🚀 Instalação Rápida

### Instalação com um comando (Recomendado)

```bash
# macOS e Linux
curl -LsSf https://raw.githubusercontent.com/carlosdorneles-mb/susa/main/cli/install-remote.sh | sh
```

Este comando irá:

- ✅ Detectar seu sistema operacional automaticamente
- ✅ Instalar dependências necessárias (git, yq)
- ✅ Clonar o repositório
- ✅ Executar a instalação
- ✅ Configurar o PATH automaticamente

### Desinstalação

```bash
# Desinstalar remotamente
curl -LsSf https://raw.githubusercontent.com/carlosdorneles-mb/susa/main/cli/uninstall-remote.sh | sh
```

### Verificar Instalação

```bash
susa --version
susa --help
```

## 📖 Uso Básico

### Comandos Principais

```bash
# Listar categorias
susa

# Listar comandos de uma categoria
susa setup

# Executar comando
susa setup docker

# Navegar subcategorias (multi-nível)
susa setup python tools pip

# Help de comando específico
susa setup docker --help

# Versão do CLI
susa --version
susa self version
```

### Gerenciar Plugins

```bash
# Instalar plugin do GitHub
susa self plugin install user/repo
susa self plugin install https://github.com/user/repo.git

# Listar plugins instalados
susa self plugin list

# Atualizar plugin
susa self plugin update nome-plugin

# Remover plugin
susa self plugin remove nome-plugin
```

## 📖 Estrutura do Projeto

```text
cli/
├── cli                    # Script principal
├── cli.yaml              # Configuração global
├── install.sh            # Instalador
├── uninstall.sh          # Desinstalador
│
├── lib/                  # Bibliotecas
│   ├── yaml.sh          # Parser YAML (com yq)
│   ├── plugin.sh        # Sistema de plugins
│   ├── registry.sh      # Registro de plugins
│   ├── dependencies.sh  # Gerenciamento de dependências
│   └── ...
│
├── commands/            # Comandos built-in
│   ├── install/        # Instalação de software
│   └── self/           # Gerenciamento do CLI
│       ├── plugin/     # Comandos de plugin
│       └── version/    # Versão do CLI
│
├── plugins/            # Plugins externos
│   └── registry.yaml  # Registro de plugins
│
├── config/            # Configurações de usuário
│   └── settings.conf
│
└── docs/             # Documentação
```

## 📚 Documentação

- [Início Rápido](quick-start.md) - Instalação e primeiros passos
- [Subcategorias](guides/subcategories.md) - Sistema de navegação multinível
- [Adicionando Comandos](guides/adding-commands.md) - Como criar novos comandos
- [Sistema de Plugins](plugins/overview.md) - Estendendo o Susa CLI
- [Funcionalidades](guides/features.md) - Guia completo de features

## 🔧 Exemplo de Uso

### Navegação Multinível

```bash
# Categoria → Subcategoria → Comando
susa setup python pip
susa setup python tools venv

# Plugins também suportam subcategorias
susa deploy aws ec2
susa deploy staging
```

### Criando um Comando

```bash
# Estrutura mínima
commands/
  minha-categoria/
    config.yaml           # name, description
    meu-comando/
      config.yaml         # name, description, script
      main.sh            # Script executável
```

## 🔌 Plugins

Instale plugins externos para adicionar funcionalidades:

```bash
# Instalar plugin
susa self plugin install https://github.com/user/susa-plugin-name

# Listar plugins
susa self plugin list

# Atualizar plugin
susa self plugin update plugin-name

# Remover plugin
susa self plugin remove plugin-name
```

## 🤝 Contribuindo

Contribuições são bem-vindas! Veja o [guia de contribuição](about/contributing.md).

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](about/license.md) para mais detalhes.
