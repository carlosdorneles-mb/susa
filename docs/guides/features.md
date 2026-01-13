# 🎯 Funcionalidades do Susa CLI

> Guia completo das funcionalidades do Susa CLI

## 📋 Índice

- [Visão Geral](#visao-geral)
- [Conceitos Chave](#conceitos-chave)
- [Descoberta Automática](#descoberta-automatica)
- [Categorias e Subcategorias](#categorias-e-subcategorias)
- [Filtragem por SO](#filtragem-por-so)
- [Sistema de Plugins](#sistema-de-plugins)
- [Bibliotecas](#bibliotecas-disponiveis)
- [Referência Rápida](#referencia-rapida)

---

## 🎯 Visão Geral

O **Susa CLI** é um framework modular e extensível para criar ferramentas de linha de comando em Bash. O Susa usa **descoberta automática** e **configurações descentralizadas**.

### ✨ Características Principais

| Funcionalidade | Descrição |
|----------------|------------|
| 🔍 **Descoberta Automática** | Comandos descobertos da estrutura de diretórios |
| 📄 **Config Descentralizada** | Cada comando tem seu próprio `config.yaml` |
| 🌍 **Multi-plataforma** | Suporte para Linux e macOS |
| 📂 **Subcategorias** | Hierarquia de comandos ilimitada |
| 🔌 **Plugins** | Extensão via Git sem modificar código |
| 📦 **Bibliotecas** | Logger, OS detection, YAML parser, etc |
| 📖 **Help Customizado** | Documentação por comando |

### 🚀 Caso de Uso Ideal

- ✅ **DevOps**: Automatizar instalações e configurações
- ✅ **Administração**: Gerenciar servidores e ambientes
- ✅ **Desenvolvimento**: Scripts de setup e deploy
- ✅ **Equipes**: Padronizar workflows

---

## 💡 Conceitos Chave

### 🎯 Descoberta Automática

O CLI **descobre comandos automaticamente** da estrutura de diretórios:

```bash
# Criar nova pasta = novo comando disponível
mkdir -p commands/setup/docker
cat > commands/setup/docker/config.yaml << EOF
name: "Docker"
description: "Instala Docker Engine"
script: "main.sh"
EOF

# Comando já está disponível!
susa setup docker
```

### 📄 Configuração Descentralizada

Cada comando tem seu próprio `config.yaml`:

```yaml
name: "Docker"          # Nome amigável
description: "Instala Docker Engine"
script: "main.sh"       # Script a executar
sudo: false             # Requer privilégios?
os: ["linux", "mac"]    # SOs compatíveis
```

### 📂 Hierarquia de Comandos

```text
commands/
  setup/                 # Categoria
  ├── asdf/              # Comando
  │   ├── config.yaml
  │   └── main.sh
  └── python/            # Subcategoria
      ├── config.yaml
      └── pip/           # Comando
          ├── config.yaml
          └── main.sh
```

---

## 🔍 Descoberta Automática

### Como Funciona

O sistema varre diretórios em 3 etapas:

#### 1. Scanner de Diretórios

Procura em:

- 📁 `commands/` - Comandos nativos
- 📁 `plugins/*/` - Comandos de plugins

#### 2. Detecção de Tipo

| Condição | Tipo | Resultado |
|----------|------|-----------|
| Tem `config.yaml` + campo `script` + arquivo existe | **Comando** | Executável |
| Tem `config.yaml` sem script | **Categoria** | Navegável |
| Sem `config.yaml` | **Ignorado** | - |

#### 3. Disponibilização Imediata

Comandos ficam disponíveis automaticamente:

```bash
mkdir -p commands/deploy/production
cat > commands/deploy/production/config.yaml << EOF
name: "Production"
description: "Deploy para produção"
script: "main.sh"
EOF

echo '#!/bin/bash\necho "Deploying..."' > commands/deploy/production/main.sh
chmod +x commands/deploy/production/main.sh

# Já funciona!
susa deploy production
```

### Vantagens

- ✅ Sem YAML centralizado
- ✅ Cada comando é independente
- ✅ Fácil adicionar/remover (apenas pasta)
- ✅ Plugins não modificam arquivos centrais

---

## 📂 Categorias e Subcategorias

### Navegação Hierárquica

```bash
# Ver categorias
susa
# Output: self, setup

# Ver comandos da categoria
susa setup
# Output: asdf, ...

# Navegar subcategoria
susa setup python
# Output: pip, venv, ...

# Executar comando
susa setup python pip
```

### Estrutura Exemplo

```text
commands/
├── setup/               # Categoria
│   ├── config.yaml
│   ├── asdf/            # Comando
│   │   ├── config.yaml
│   │   └── main.sh
│   └── python/          # Subcategoria
│       ├── config.yaml
│       └── pip/         # Comando
│           ├── config.yaml
│           └── main.sh
└── self/                # Categoria
    ├── config.yaml
    ├── version/         # Comando
    │   ├── config.yaml
    │   └── main.sh
    └── plugin/          # Subcategoria
        ├── config.yaml
        ├── add/         # Comando
        │   ├── config.yaml
        │   └── main.sh
        └── list/        # Comando
            ├── config.yaml
            └── main.sh
```

### Boas Práticas

- Mantenha 2-3 níveis de profundidade
- Use nomes descritivos e curtos
- Agrupe comandos relacionados
- Cada nível pode ter `config.yaml` com metadados

Para mais detalhes, veja [Guia de Subcategorias](subcategories.md).

---

## 🌍 Filtragem por SO

### Como Funciona

O campo `os` no `config.yaml` filtra comandos automaticamente:

```yaml
# Apenas Linux
os: ["linux"]

# Apenas macOS
os: ["mac"]

# Ambos
os: ["linux", "mac"]

# Omitir = todos os SOs
```

### Exemplos

```yaml
# commands/setup/apt/config.yaml
name: "APT Tools"
description: "Ferramentas APT (Ubuntu/Debian)"
script: "main.sh"
os: ["linux"]  # Só aparece no Linux
```

```yaml
# commands/setup/brew/config.yaml
name: "Homebrew"
description: "Gerenciador de pacotes"
script: "main.sh"
os: ["mac"]  # Só aparece no macOS
```

### Detecção de SO

O CLI detecta automaticamente:

- `linux` - Detecta distribuições Linux
- `mac` - Detecta macOS

### Validação

Antes de executar

1. Se o comando é compatível com o SO atual
2. Se tem permissões necessárias (sudo)
3. Se dependências existem

---

## 🔌 Sistema de Plugins

Plugins estendem o CLI via repositórios Git.

### Instalação

```bash
# Usando URL completa
susa self plugin add https://github.com/usuario/plugin

# Usando formato user/repo
susa self plugin add usuario/plugin
```

### Estrutura de Plugin

```text
meu-plugin/
├── categoria1/
│   ├── config.yaml
│   └── comando1/
│       ├── config.yaml
│       └── main.sh
└── categoria2/
    ├── config.yaml
    └── comando2/
        ├── config.yaml
        └── main.sh
```

### Gerenciamento

```bash
# Listar plugins
susa self plugin list

# Atualizar plugin
susa self plugin update nome-plugin

# Remover plugin
susa self plugin remove nome-plugin
```

### Vantagens

- ✅ Não modifica código principal
- ✅ Comandos disponíveis imediatamente
- ✅ Atualizações independentes
- ✅ Fácil compartilhamento

Para mais detalhes, veja:

- [Visão Geral de Plugins](../plugins/overview.md)
- [Arquitetura de Plugins](../plugins/architecture.md)

---

## 📦 Bibliotecas Disponíveis

O Susa CLI oferece bibliotecas úteis em `lib/`:

### Logger (`lib/logger.sh`)

```bash
log_info "Informação"
log_success "Sucesso"
log_warning "Aviso"
log_error "Erro"
log_debug "Debug (só com DEBUG=true)"
```

### Colors (`lib/color.sh`)

```bash
echo -e "${LIGHT_GREEN}Verde${NC}"
echo -e "${LIGHT_CYAN}Ciano${NC}"
echo -e "${RED}Vermelho${NC}"
echo -e "${BOLD}Negrito${NC}"
```

### Shell (`lib/shell.sh`)

```bash
detect_shell_type        # Detecta bash, zsh, fish
get_completion_status    # Status do autocompletar
```

### OS (`lib/os.sh`)

```bash
detect_os                # Detecta Linux, macOS
get_os_release_info      # Info da distribuição
```

Para documentação completa, veja [Referência de Bibliotecas](../reference/libraries/index.md).

---

## 🎯 Referência Rápida

### Estrutura de Arquivos

```yaml
# cli.yaml (raiz)
name: "Susa CLI"
description: "Gerenciador de Shell Scripts"
version: "1.0.0"
commands_dir: "commands"
plugins_dir: "plugins"
```

```yaml
# commands/categoria/config.yaml
name: "Setup"
description: "Instalar e configurar ferramentas"
```

```yaml
# commands/categoria/comando/config.yaml
name: "ASDF"
description: "Instala ASDF Version Manager"
script: "main.sh"
sudo: false
os: ["linux", "mac"]
```

### Template de Comando

```bash
#!/bin/bash
set -euo pipefail

setup_command_env

show_help() {
    show_description
    echo ""
    show_usage
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  -h, --help    Mostra ajuda"
}

install() {
    log_info "Instalando..."
    # Código aqui
    log_success "Instalado!"
}

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Opção desconhecida: $1"
            exit 1
            ;;
    esac
done

install
```

### Comandos Úteis

```bash
# Listar categorias
susa

# Listar comandos
susa setup

# Executar comando
susa setup asdf

# Ver ajuda
susa setup asdf --help

# Debug
DEBUG=true susa setup asdf

# Plugins
susa self plugin list
susa self plugin add user/plugin
susa self plugin update plugin
susa self plugin remove plugin

# Informações
susa self version
susa self info
susa self update
```

---

## 📚 Próximos Passos

- [Adicionar Comandos](adding-commands.md) - Como criar comandos
- [Configuração](configuration.md) - Personalizar o CLI
- [Shell Completion](shell-completion.md) - Autocompletar
- [Subcategorias](subcategories.md) - Hierarquia de comandos
- [Sistema de Plugins](../plugins/overview.md) - Criar plugins
