# Documentação de Funcionalidades do CLI

## Índice

- [Visão Geral](#visão-geral)
- [Arquitetura de Configuração](#arquitetura-de-configuração)
- [Sistema de Discovery](#sistema-de-discovery)
- [Sistema de Categorias e Subcategorias](#sistema-de-categorias-e-subcategorias)
- [Sistema de Grupos](#sistema-de-grupos)
- [Filtragem por Sistema Operacional](#filtragem-por-sistema-operacional)
- [Gerenciamento de Sudo](#gerenciamento-de-sudo)
- [Help Customizado para Comandos](#help-customizado-para-comandos)
- [Sistema de Plugins](#sistema-de-plugins)
- [Bibliotecas Disponíveis](#bibliotecas-disponíveis)
- [Como Adicionar Novos Comandos](#como-adicionar-novos-comandos)

---

## Visão Geral

Este CLI é um framework modular de linha de comando baseado em **discovery automático de estrutura de diretórios** e **configurações YAML descentralizadas**. O sistema descobre comandos e categorias automaticamente da estrutura `commands/` e `plugins/`, com cada comando tendo seu próprio arquivo `config.yaml`.

### Características Principais

- **Discovery Automático**: Comandos descobertos da estrutura de diretórios
- **Configuração Descentralizada**: Cada comando/categoria tem seu próprio `config.yaml`
- **Multi-plataforma**: Suporte para Linux e macOS com filtragem automática
- **Subcategorias Multi-nível**: Navegação hierárquica ilimitada (`install/python/tools`)
- **Sistema de Plugins**: Extensão via repositórios Git externos
- **Parser YAML com yq**: Dependência gerenciada automaticamente
- **Agrupamento de Comandos**: Organize comandos relacionados em grupos visuais
- **Indicadores Visuais**: Marcadores para comandos que requerem sudo
- **Help Personalizado**: Cada comando pode ter sua própria documentação
- **Validação de Compatibilidade**: Verifica SO e permissões antes da execução

---

## Arquitetura de Configuração

O sistema usa **configurações YAML descentralizadas** com discovery automático.

### Arquivo Global: `cli.yaml`

Configuração principal do CLI (apenas metadados):

```yaml
command: "cli"                        # Nome do executável
name: "MyCLI"                         # Nome exibido
description: "Meu CLI personalizado"  # Descrição na ajuda
version: "2.0.0"                      # Versão do Susa CLI
commands_dir: "commands"              # Diretório de comandos
plugins_dir: "plugins"                # Diretório de plugins
```

**Campos:**

| Campo | Descrição |
| ----- | --------- |
| `command` | Nome do comando usado para invocar o CLI |
| `name` | Nome amigável exibido na versão e ajuda |
| `description` | Descrição exibida no help principal |
| `version` | Versão semântica do CLI |
| `commands_dir` | Diretório onde estão os comandos (padrão: `commands`) |
| `plugins_dir` | Diretório onde estão os plugins (padrão: `plugins`) |

### Arquivos de Categoria: `<categoria>/config.yaml`

Cada categoria/subcategoria pode ter metadados:

```yaml
name: "Install"
description: "Instalação de ferramentas e dependências"
```

### Arquivos de Comando: `<comando>/config.yaml`

Cada comando **obrigatoriamente** tem seu `config.yaml`:

```yaml
name: "Docker"                    # Nome exibido
description: "Instala Docker Engine" # Descrição curta
script: "main.sh"                 # Script a executar
sudo: true                        # Requer sudo? (opcional)
os: ["linux"]                     # SOs compatíveis (opcional)
group: "development"              # Grupo visual (opcional)
```

**Campos de Comando:**

| Campo | Tipo | Obrigatório | Descrição |
| ----- | ---- | ----------- | --------- |
| `name` | string | ✅ | Nome amigável do comando |
| `description` | string | ✅ | Descrição exibida na listagem |
| `script` | string | ✅ | Nome do arquivo script (geralmente `main.sh`) |
| `sudo` | boolean | ❌ | Se `true`, indica que o comando requer privilégios de superusuário |
| `os` | array | ❌ | Lista de SOs compatíveis: `["linux"]`, `["mac"]` ou `["linux", "mac"]` |
| `group` | string | ❌ | Nome do grupo para agrupamento visual na listagem |

---

## Sistema de Discovery

O CLI **descobre comandos e categorias automaticamente** da estrutura de diretórios.

### Como Funciona

1. **Scanner de Diretórios**: Varre `commands/` e `plugins/*/`
2. **Detecção de Tipo**:
   - **Comando**: Diretório com `config.yaml` + campo `script` + arquivo existe
   - **Subcategoria**: Diretório sem script executável
3. **Hierarquia**: Suporta níveis ilimitados de subcategorias

### Estrutura de Diretórios

```text
commands/
├── install/             # Categoria
│   ├── config.yaml      # Metadados da categoria
│   ├── docker/          # Comando
│   │   ├── config.yaml  # Config do comando
│   │   └── main.sh      # Script executável
│   └── python/          # Subcategoria
│       ├── config.yaml  # Metadados da subcategoria
│       ├── basic/       # Comando
│       │   ├── config.yaml
│       │   └── main.sh
│       └── tools/       # Sub-subcategoria
│           └── pip/     # Comando
│               ├── config.yaml
│               └── main.sh
└── self/                # Categoria
    ├── version/         # Comando
    │   ├── config.yaml
    │   └── main.sh
    └── plugin/          # Subcategoria
        ├── install/     # Comando
        │   ├── config.yaml
        │   └── main.sh
        └── list/        # Comando
            ├── config.yaml
            └── main.sh
```

### Lógica de Detecção

O arquivo `lib/yaml.sh` usa a função `is_command_dir()`:

```bash
# Verifica se um diretório é um comando
is_command_dir() {
    local item_dir="$1"
    
    # Deve ter config.yaml
    [ ! -f "$item_dir/config.yaml" ] && return 1
    
    # Lê o campo script usando yq
    local script_name=$(yq eval '.script' "$item_dir/config.yaml" 2>/dev/null)
    
    # Se tem campo script E o arquivo existe, é um comando
    if [ -n "$script_name" ] && [ "$script_name" != "null" ] && [ -f "$item_dir/$script_name" ]; then
        return 0
    fi
    
    return 1
}
```

**Vantagens:**
- ✅ Sem YAML centralizado gigante
- ✅ Cada comando é independente
- ✅ Fácil adicionar/remover comandos (apenas adiciona/remove pasta)
- ✅ Plugins não precisam modificar arquivos centrais

---

## Sistema de Categorias e Subcategorias

O CLI suporta **navegação hierárquica ilimitada** de categorias.

### Navegação

```bash
cli                           # Lista categorias de nível 1
susa setup                   # Lista comandos e subcategorias de setup
susa setup python            # Lista comandos e sub-subcategorias de python
susa setup python tools      # Lista comandos de tools
susa setup python tools pip  # Executa comando pip
```

### Exemplo de Hierarquia

```text
setup/                     # Nível 1
├── docker                   # Comando
├── nodejs                   # Comando
└── python/                  # Nível 2
    ├── basic                # Comando
    ├── venv                 # Comando
    └── tools/               # Nível 3
        ├── pip              # Comando
        └── poetry           # Comando
```

**Comandos:**
```bash
susa setup docker               # ✅ Funciona
susa setup python basic         # ✅ Funciona
susa setup python tools pip     # ✅ Funciona
```

### Boas Práticas para Subcategorias

- Use subcategorias para agrupar comandos relacionados
- Mantenha hierarquia simples (2-3 níveis ideal)
- Cada subcategoria pode ter `config.yaml` com `name` e `description`
- Comandos e subcategorias podem coexistir no mesmo nível

### Detalhes Técnicos

Para mais informações sobre subcategorias, veja [Guia de Subcategorias](subcategories.md).

---

## Sistema de Grupos

Grupos permitem agrupar visualmente comandos relacionados dentro de uma mesma categoria.

### Como Funciona

Quando comandos têm o campo `group` definido, eles aparecem agrupados na listagem:

```text
Commands:
  docker          Instala Docker Engine [sudo]
  
development
  nodejs          Instala Node.js via NVM
  python          Instala Python via deadsnakes PPA [sudo]
```

### Regras de Agrupamento

1. **Comandos sem grupo** aparecem primeiro
2. **Comandos com grupo** aparecem depois, organizados por grupo
3. **Ordem**: Comandos aparecem na ordem descoberta
4. **Compatibilidade**: Apenas comandos compatíveis com o SO atual são exibidos

### Exemplo de Configuração

```yaml
# commands/install/docker/config.yaml
name: "Docker"
description: "Instala Docker Engine"
script: "main.sh"
# Sem grupo - aparece primeiro

# commands/install/nodejs/config.yaml
name: "Node.js"
description: "Instala Node.js via NVM"
script: "main.sh"
group: "development"

# commands/install/python/config.yaml
name: "Python"
description: "Instala Python via deadsnakes PPA"
script: "main.sh"
group: "development"
sudo: true
```

### Casos de Uso

- **Linguagens de programação**: `group: "languages"`
- **Ferramentas de desenvolvimento**: `group: "devtools"`
- **Servidores**: `group: "servers"`
- **Bancos de dados**: `group: "databases"`

---

## Filtragem por Sistema Operacional

O CLI filtra automaticamente comandos baseado no sistema operacional do usuário.

### Valores Suportados

| Valor | Descrição | Detecta |
| ----- | --------- | ------- |
| `linux` | Sistemas Linux (Ubuntu, Debian, Fedora, etc) | Qualquer distro Linux |
| `mac` | macOS | Darwin/macOS |
| Omitido | Compatível com todos os SOs | - |

### Comportamento

1. **Listagem**: Comandos incompatíveis não aparecem na listagem
2. **Execução**: Tentativa de executar comando incompatível retorna erro
3. **Multi-plataforma**: Use `os: ["linux", "mac"]` para ambos

### Exemplos

```yaml
# Apenas Linux - commands/update/system/config.yaml
name: "APT Update"
script: "main.sh"
os: ["linux"]
  
# Apenas macOS - commands/update/brew/config.yaml
name: "Brew Update"
script: "main.sh"
os: ["mac"]
  
# Ambos - commands/install/nodejs/config.yaml
name: "Node.js"
script: "main.sh"
os: ["linux", "mac"]
  
# Todos (campo omitido) - commands/daily/backup/config.yaml
name: "Backup"
script: "main.sh"
```

### Detecção de SO

O CLI detecta automaticamente usando `lib/os.sh`:

- **Linux**: Ubuntu, Debian, Fedora, RHEL, CentOS, Rocky, AlmaLinux
- **macOS**: Darwin (macOS)
- **Desconhecido**: Marca como `unknown` e oculta comandos com restrição de OS

Função disponível: `get_simple_os` retorna `"linux"` ou `"mac"`.

---

## Gerenciamento de Sudo

O CLI gerencia privilégios de superusuário de forma inteligente.

### Campo `sudo`

```yaml
name: "Docker"
description: "Instala Docker Engine"
script: "main.sh"
sudo: true     # Indica que requer sudo
```

### Comportamento

1. **Indicador Visual**: Comandos com `sudo: true` exibem marcador `[sudo]` em amarelo
2. **Aviso**: Antes da execução, exibe: `[WARNING] Este comando requer privilégios de superusuário (sudo)`
3. **Validação**: Verifica se o usuário está executando como root ou tem permissão sudo
4. **Não Bloqueante**: O aviso é informativo, não impede a execução

### Exemplo de Saída

```bash
$ susa setup

Commands:
  docker          Instala Docker Engine [sudo]
  nodejs          Instala Node.js via NVM
  python          Instala Python via PPA [sudo]
```

### Boas Práticas

- Defina `sudo: true` para comandos que:
  - Instalam pacotes do sistema
  - Modificam arquivos de sistema
  - Alteram configurações globais
  - Gerenciam serviços do sistema

- Use `sudo: false` ou omita para comandos que:
  - Instalam em diretório do usuário
  - Fazem backup de arquivos
  - Consultam informações
  - Scripts que gerenciam seu próprio sudo

---

## Help Customizado para Comandos

Cada comando pode ter sua própria documentação de ajuda personalizada.

### Como Implementar

1. **Adicione função `show_help()`** no script do comando:

```bash
#!/bin/bash

show_help() {
    echo "Instalação do Docker Engine"
    echo ""
    echo -e "${LIGHT_GREEN}Usage:${NC} susa setup docker [options]"
    echo ""
    echo -e "${LIGHT_GREEN}Description:${NC}"
    echo "  Instala o Docker Engine, CLI e Docker Compose no Ubuntu."
    echo ""
    echo -e "${LIGHT_GREEN}Options:${NC}"
    echo "  -h, --help    Mostra esta mensagem"
    echo ""
    echo -e "${LIGHT_GREEN}Examples:${NC}"
    echo "  susa setup docker"
}

install_docker() {
    # ... código de instalação
}

# Executa instalação se não for help
if [ "${1:-}" != "--help" ] && [ "${1:-}" != "-h" ]; then
    install_docker
fi
```

### Como Funciona

1. **Detecção**: Quando `--help` ou `-h` é passado, o CLI verifica se existe `show_help()` no script
2. **Execução**: Se existe, carrega o script e executa apenas `show_help()`
3. **Sem Help**: Se não existe, finaliza silenciosamente (não executa nada)
4. **Proteção**: O script deve proteger sua execução principal verificando argumentos

### Variáveis de Cor Disponíveis

Use as cores da `lib/color.sh`:

```bash
${LIGHT_GREEN}    # Verde claro (títulos)
${LIGHT_CYAN}     # Ciano claro (comandos)
${CYAN}           # Ciano (texto secundário)
${YELLOW}         # Amarelo (avisos)
${GRAY}           # Cinza (texto secundário)
${NC}             # Reset de cor
```

### Estrutura Recomendada

```bash
show_help() {
    echo "Título do Comando"
    echo ""
    echo -e "${LIGHT_GREEN}Usage:${NC} cli <categoria> <comando> [opcoes]"
    echo ""
    echo -e "${LIGHT_GREEN}Description:${NC}"
    echo "  Descrição detalhada do que o comando faz"
    echo ""
    echo -e "${LIGHT_GREEN}Options:${NC}"
    echo "  -h, --help       Mostra ajuda"
    echo "  -v, --verbose    Modo verboso"
    echo ""
    echo -e "${LIGHT_GREEN}Examples:${NC}"
    echo "  cli categoria comando"
    echo "  cli categoria comando --verbose"
    echo ""
    echo -e "${YELLOW}Nota: Informação importante${NC}"
}
```

---

## Bibliotecas Disponíveis

O CLI fornece bibliotecas utilitárias que podem ser usadas nos scripts de comando.

### lib/logger.sh

Funções de logging com timestamp:

```bash
log_info "Mensagem informativa"      # [INFO] timestamp - mensagem
log_success "Operação bem-sucedida"  # [SUCCESS] timestamp - mensagem
log_warning "Aviso importante"        # [WARNING] timestamp - mensagem
log_error "Erro encontrado"           # [ERROR] timestamp - mensagem
```

### lib/color.sh

Variáveis de cor ANSI:

```bash
${RED}, ${GREEN}, ${YELLOW}, ${BLUE}, ${MAGENTA}, ${CYAN}, ${WHITE}
${LIGHT_RED}, ${LIGHT_GREEN}, ${LIGHT_YELLOW}, ${LIGHT_BLUE}
${LIGHT_MAGENTA}, ${LIGHT_CYAN}, ${LIGHT_WHITE}
${GRAY}, ${LIGHT_GRAY}
${BOLD}, ${UNDERLINE}, ${REVERSE}
${NC}  # Reset
```

### lib/os.sh

Detecção de sistema operacional:

```bash
$OS_TYPE              # "debian", "macos", "fedora", "unknown"
get_simple_os         # Retorna "linux" ou "mac"
```

### lib/sudo.sh

Gerenciamento de sudo:

```bash
check_sudo           # Verifica se está rodando como root
required_sudo        # Requer sudo ou falha
```

---

## Sistema de Plugins

O CLI suporta extensão via **plugins externos** hospedados em repositórios Git.

### O que são Plugins?

Plugins são repositórios Git que adicionam **categorias e comandos** ao CLI sem modificar o código principal.

### Estrutura de um Plugin

```text
myplugin/                    # Repositório Git
├── README.md
├── version.txt              # Versão do plugin (opcional)
└── deploy/                  # Categoria adicionada
    ├── config.yaml
    ├── dev/
    │   ├── config.yaml
    │   └── main.sh
    └── prod/
        ├── config.yaml
        └── main.sh
```

### Gerenciamento de Plugins

O CLI fornece comandos para gerenciar plugins:

```bash
susa self plugin install <url>      # Instala plugin de repositório Git
susa self plugin list                # Lista plugins instalados
susa self plugin update <nome>       # Atualiza plugin específico
susa self plugin remove <nome>       # Remove plugin
```

### Registry de Plugins

Plugins instalados são registrados em `plugins/registry.yaml`:

```yaml
version: "1.0.0"

plugins:
  - name: "myplugin"
    source: "https://github.com/user/myplugin.git"
    version: "1.2.0"
    installed_at: "2026-01-12T14:30:00Z"
```

### Como Funciona

1. **Instalação**: Plugin é clonado para `plugins/<nome>/`
2. **Discovery**: Categorias do plugin são descobertas automaticamente
3. **Integração**: Comandos aparecem junto com comandos nativos
4. **Isolamento**: Cada plugin fica em seu diretório próprio

### Exemplo de Uso

```bash
# Instalar plugin do GitHub
susa self plugin install https://github.com/user/devops-tools.git

# Ou formato curto
susa self plugin install user/devops-tools

# Comandos do plugin ficam disponíveis imediatamente
susa deploy dev
```

Para mais detalhes, veja [Sistema de Plugins](../plugins/overview.md).

---

## Bibliotecas Disponíveis

O CLI fornece **12 bibliotecas** utilitárias que podem ser usadas nos scripts de comando.

### Principais Bibliotecas

#### lib/logger.sh
Funções de logging com timestamp e cores:

```bash
log_info "Mensagem informativa"      # [INFO] timestamp - mensagem
log_success "Operação bem-sucedida"  # [SUCCESS] timestamp - mensagem
log_warning "Aviso importante"        # [WARNING] timestamp - mensagem
log_error "Erro encontrado"           # [ERROR] timestamp - mensagem
log_debug "Debug info"                # [DEBUG] apenas com DEBUG=true
```

#### lib/color.sh
Variáveis de cor ANSI:

```bash
${RED}, ${GREEN}, ${YELLOW}, ${BLUE}, ${CYAN}
${LIGHT_RED}, ${LIGHT_GREEN}, ${LIGHT_CYAN}
${GRAY}, ${BOLD}, ${UNDERLINE}
${NC}  # Reset
```

#### lib/os.sh
Detecção de sistema operacional:

```bash
$OS_TYPE              # "debian", "macos", "fedora", "unknown"
get_simple_os         # Retorna "linux" ou "mac"
```

#### lib/sudo.sh
Gerenciamento de sudo:

```bash
check_sudo           # Verifica se está rodando como root
required_sudo        # Requer sudo ou falha
```

#### lib/dependencies.sh
Instalação automática de dependências:

```bash
ensure_curl_installed    # Instala curl se necessário
ensure_jq_installed      # Instala jq se necessário
ensure_yq_installed      # Instala yq v4+ se necessário
ensure_fzf_installed     # Instala fzf se necessário
```

#### lib/string.sh
Manipulação de strings e arrays:

```bash
to_uppercase "text"              # TEXTO
to_lowercase "TEXT"              # texto
strip_whitespace "  text  "      # text
parse_comma_separated arr        # Divide "a,b,c" em elementos
join_to_comma_separated arr      # Junta elementos em "a,b,c"
```

#### lib/shell.sh
Detecção de shell:

```bash
detect_shell_config    # Retorna ~/.zshrc, ~/.bashrc ou ~/.profile
```

#### lib/kubernetes.sh
Funções para Kubernetes:

```bash
check_kubectl_installed "exit_on_error"
check_namespace_exists "namespace" "exit_on_error"
get_current_context
print_current_context
```

#### lib/yaml.sh
Parser YAML com yq (uso interno principalmente):

```bash
get_yaml_global_field "$YAML" "field"
get_category_info "$YAML" "category" "field"
get_command_info "$YAML" "category" "command" "field"
is_command_dir "$dir"
discover_items_in_category "$base" "$category" "commands"
```

#### lib/plugin.sh
Gerenciamento de plugins:

```bash
ensure_git_installed
detect_plugin_version "$dir"
count_plugin_commands "$dir"
clone_plugin "$url" "$dest"
normalize_git_url "user/repo"
extract_plugin_name "$url"
```

#### lib/registry.sh
Gerenciamento de registry.yaml:

```bash
registry_add_plugin "$file" "$name" "$url" "$version"
registry_remove_plugin "$file" "$name"
registry_list_plugins "$file"
registry_get_plugin_info "$file" "$name" "field"
```

#### lib/cli.sh
Funções auxiliares do CLI:

```bash
show_version      # Mostra nome e versão
show_usage        # Mostra mensagem de uso
```

### Documentação Completa

Para documentação detalhada de cada biblioteca com exemplos, veja [Referência de Bibliotecas](../reference/libraries.md).

### Como Usar nos Scripts

As bibliotecas estão disponíveis através de imports explícitos:

```bash
#!/bin/bash
set -euo pipefail

# Obtém diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Importa bibliotecas necessárias
source "$CLI_DIR/lib/logger.sh"
source "$CLI_DIR/lib/color.sh"
source "$CLI_DIR/lib/os.sh"
source "$CLI_DIR/lib/dependencies.sh"

# Usa as funções
log_info "Sistema: $OS_TYPE"

current_os=$(get_simple_os)
if [ "$current_os" = "linux" ]; then
    log_info "Instalando via APT..."
    ensure_curl_installed || exit 1
    sudo apt-get install package
fi

log_success "Instalação concluída!"
```

---

## Como Adicionar Novos Comandos

### Método Atual: Discovery Automático

#### Passo 1: Criar Estrutura de Diretórios

```bash
mkdir -p commands/<categoria>/<comando>
```

Exemplo:

```bash
mkdir -p commands/install/postgresql
```

#### Passo 2: Criar config.yaml do Comando

Crie `commands/<categoria>/<comando>/config.yaml`:

```yaml
name: "PostgreSQL"
description: "Instala servidor PostgreSQL"
script: "main.sh"
sudo: true
os: ["linux"]
group: "databases"  # opcional
```

#### Passo 3: Criar Script do Comando

Crie `commands/<categoria>/<comando>/main.sh`:

```bash
#!/bin/bash
set -euo pipefail

# Obtém diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Importa bibliotecas
source "$CLI_DIR/lib/logger.sh"
source "$CLI_DIR/lib/color.sh"

# Função de help (opcional mas recomendada)
show_help() {
    echo "Instalação do PostgreSQL"
    echo ""
    echo -e "${LIGHT_GREEN}Usage:${NC} susa setup postgresql [version]"
    echo ""
    echo -e "${LIGHT_GREEN}Description:${NC}"
    echo "  Instala PostgreSQL no sistema"
    echo ""
    echo -e "${LIGHT_GREEN}Options:${NC}"
    echo "  version    Versão a instalar (padrão: 15)"
    echo "  -h, --help Mostra esta ajuda"
}

# Função principal
install_postgresql() {
    local version="${1:-15}"
    
    log_info "Instalando PostgreSQL $version..."
    
    # Sua lógica aqui
    sudo apt-get update
    sudo apt-get install -y postgresql-$version
    
    log_success "PostgreSQL $version instalado com sucesso!"
}

# Executa apenas se não for help
if [ "${1:-}" != "--help" ] && [ "${1:-}" != "-h" ]; then
    install_postgresql "$@"
fi
```

#### Passo 4: Dar permissão de execução

```bash
chmod +x commands/install/postgresql/main.sh
```

#### Passo 5: Testar

```bash
susa setup              # Lista comandos (postgresql deve aparecer)
susa setup postgresql   # Executa instalação
susa setup postgresql --help  # Mostra ajuda
```

### Pronto! Comando Disponível Automaticamente

O sistema de **discovery automático** encontra o novo comando sem precisar editar o `cli.yaml`. O comando aparece automaticamente na listagem e pode ser executado imediatamente.

### Criando Subcategorias

Para criar uma subcategoria:

```bash
mkdir -p commands/install/python
mkdir -p commands/install/python/tools
mkdir -p commands/install/python/tools/pip
```

Crie `config.yaml` e `main.sh` em `pip/`:

```bash
# commands/install/python/tools/pip/config.yaml
name: "pip"
description: "Instala e atualiza pip"
script: "main.sh"
os: ["linux", "mac"]

# commands/install/python/tools/pip/main.sh
#!/bin/bash
# ... script aqui ...
```

Uso:

```bash
susa setup python tools pip
```

```bash
./susa setup                    # Verifica se aparece na lista
./susa setup postgresql --help  # Testa o help
./susa setup postgresql         # Testa a execução
### Guia Detalhado

Para instruções passo-a-passo completas, veja [Adicionar Comandos](adding-commands.md).

---

## Boas Práticas Gerais

### Organização de Comandos

1. **Agrupe por funcionalidade**: Use categorias lógicas (install, deploy, backup)
2. **Use nomes descritivos**: `docker`, `nodejs`, não `d`, `n`
3. **Descrições claras**: Explique o que o comando faz, não como
4. **Hierarquia simples**: Evite mais de 3 níveis de subcategorias

### Scripts de Comando

1. **Sempre implemente `show_help()`**: Documenta o uso do comando
2. **Use as bibliotecas**: `log_*` para mensagens consistentes
3. **Valide entrada**: Verifique argumentos antes de executar
4. **Trate erros**: Use `set -euo pipefail` no início
5. **Seja idempotente**: Comando pode ser executado múltiplas vezes com segurança

### Manutenção

1. **Estrutura limpa**: Cada comando em sua pasta com config.yaml
2. **Documente mudanças**: Atualize versão em cli.yaml
3. **Teste multi-plataforma**: Se suportar mac e linux, teste em ambos
4. **Revise permissões**: Garanta que `sudo` está correto no config.yaml
5. **Use yq**: Para manipular YAML nos scripts, use `yq` (instalado automaticamente)

---

## Referência Rápida

### Comandos do CLI

```bash
cli                           # Lista categorias
susa --help, -h               # Ajuda principal
susa --version, -V            # Versão do Susa CLI
susa self version             # Versão do Susa CLI (alternativo)
susa <categoria>              # Lista comandos e subcategorias
susa <categoria> <comando>    # Executa comando
susa <cat> <subcat> <cmd>     # Executa comando em subcategoria
susa <cat> <cmd> --help       # Help do comando (se disponível)
```

### Comandos de Plugin

```bash
susa self plugin install <url>      # Instala plugin do Git
susa self plugin list                # Lista plugins instalados
susa self plugin update <nome>       # Atualiza plugin específico
susa self plugin remove <nome>       # Remove plugin
```

### Estrutura de Arquivos (Arquitetura Atual)

```text
cli/
├── cli                      # Executável principal
├── cli.yaml                 # Config global (metadados)
├── Makefile                 # Automação (install, uninstall, docs)
├── install.sh               # Script de instalação
├── uninstall.sh             # Script de desinstalação
├── commands/                # Comandos nativos
│   ├── install/
│   │   ├── config.yaml     # Config da categoria
│   │   ├── docker/
│   │   │   ├── config.yaml # Config do comando
│   │   │   └── main.sh     # Script executável
│   │   └── python/         # Subcategoria
│   │       ├── config.yaml
│   │       ├── basic/
│   │       └── tools/      # Sub-subcategoria
│   └── self/
│       ├── version/
│       └── plugin/
├── plugins/                 # Plugins externos
│   ├── registry.yaml       # Registry de plugins instalados
│   └── <nome-plugin>/      # Plugin clonado do Git
│       └── <categoria>/
├── lib/                     # Bibliotecas compartilhadas
│   ├── yaml.sh             # Parser YAML (yq)
│   ├── dependencies.sh     # Gestão de dependências
│   ├── logger.sh           # Sistema de logs
│   ├── color.sh            # Cores ANSI
│   ├── os.sh               # Detecção de SO
│   ├── sudo.sh             # Gestão sudo
│   ├── string.sh           # Manipulação strings
│   ├── shell.sh            # Detecção shell
│   ├── kubernetes.sh       # Funções K8s
│   ├── plugin.sh           # Gestão plugins
│   ├── registry.sh         # Gestão registry
│   ├── cli.sh              # Funções CLI
│   └── utils.sh            # Agregador
├── docs/                    # Documentação MkDocs
│   ├── index.md
│   ├── quick-start.md
│   ├── first-steps.md
│   ├── guides/
│   │   ├── adding-commands.md
│   │   ├── features.md
│   │   ├── subcategories.md
│   │   └── configuration.md
│   ├── plugins/
│   │   ├── overview.md
│   │   └── architecture.md
│   ├── reference/
│   │   ├── libraries.md
│   │   └── changelog-v2.md
│   └── about/
│       ├── contributing.md
│       └── license.md
├── mkdocs.yml               # Configuração MkDocs
└── .github/
    └── workflows/
        └── docs.yml         # Deploy automático GitHub Pages
```

### Campos config.yaml - Referência

#### Global (cli.yaml)
```yaml
command: string              # Nome do executável
name: string                 # Nome do CLI
description: string          # Descrição
version: string              # Versão semântica
commands_dir: string         # Diretório de comandos (padrão: "commands")
plugins_dir: string          # Diretório de plugins (padrão: "plugins")
```

#### Categoria (<categoria>/config.yaml)
```yaml
name: string                 # Nome da categoria
description: string          # Descrição
```

#### Comando (<comando>/config.yaml)
```yaml
name: string                 # Nome (obrigatório)
description: string          # Descrição (obrigatório)
script: string               # Arquivo .sh (obrigatório)
sudo: boolean                # Requer sudo (opcional)
os: array                    # ["linux"|"mac"] (opcional)
group: string                # Nome do grupo (opcional)
```

---

## Dependências do Sistema

### Obrigatórias

- **Bash 4.0+**: Shell script
- **Git**: Para sistema de plugins
- **yq v4+**: Parser YAML (instalado automaticamente se ausente)

### Opcionais (instaladas automaticamente quando necessário)

- **curl**: Para downloads (instalado por dependencies.sh)
- **jq**: Para parsear JSON (instalado por dependencies.sh)
- **fzf**: Para seleção interativa (instalado por dependencies.sh)

### Verificação de Dependências

O CLI verifica e instala dependências automaticamente:

```bash
# yq é verificado e instalado ao iniciar
# lib/dependencies.sh: ensure_yq_installed()

# Outras dependências são instaladas sob demanda
# Exemplo: lib/dependencies.sh: ensure_curl_installed()
```

---

## Migração para yq

O CLI usa **yq v4+** para parsear YAML ao invés de awk/grep.

### Por que yq?

- ✅ Parser YAML completo e robusto
- ✅ Suporta estruturas complexas e aninhadas
- ✅ Menos propenso a erros de parsing
- ✅ Sintaxe clara e legível
- ✅ Instalação automática gerenciada

### Instalação Automática

O yq é instalado automaticamente na primeira execução:

1. Detecta plataforma (linux/darwin) e arquitetura (amd64/arm64/386)
2. Baixa última versão do GitHub
3. Instala em `/usr/local/bin/yq`
4. Requer sudo para instalação

### Uso Interno

```bash
# lib/yaml.sh usa yq internamente
yq eval '.name' cli.yaml
yq eval '.categories | keys | .[]' config.yaml
yq eval '.script' commands/install/docker/config.yaml
```

### Para Desenvolvedores

Se você criar scripts que precisam ler YAML:

```bash
#!/bin/bash
source "$CLI_DIR/lib/dependencies.sh"

# Garante yq disponível
ensure_yq_installed || exit 1

# Usa yq
name=$(yq eval '.name' config.yaml)
version=$(yq eval '.version' config.yaml)
```

---

## Recursos Adicionais

### Documentação

- **[Início Rápido](../quick-start.md)** - Instalação e primeiros passos
- **[Guia de Subcategorias](subcategories.md)** - Navegação hierárquica
- **[Adicionar Comandos](adding-commands.md)** - Passo-a-passo detalhado
- **[Sistema de Plugins](../plugins/overview.md)** - Extensão via Git
- **[Arquitetura de Plugins](../plugins/architecture.md)** - Detalhes técnicos
- **[Referência de Bibliotecas](../reference/libraries.md)** - API completa
- **[Changelog v2](../reference/changelog-v2.md)** - Mudanças arquiteturais
- **[Contribuir](../about/contributing.md)** - Como contribuir

### Automação (Makefile)

```bash
# CLI
make cli-install      # Instala CLI no sistema
make cli-uninstall    # Remove CLI do sistema
make test             # Testa CLI

# Documentação
make install          # Instala dependências MkDocs
make serve            # Serve docs localmente (http://127.0.0.1:8000)
make build            # Gera site estático
make deploy           # Deploy manual para GitHub Pages
make clean            # Remove arquivos gerados

# Ajuda
make help             # Mostra todos os comandos disponíveis
```

### GitHub Pages

A documentação é publicada automaticamente no GitHub Pages via GitHub Actions:

- **Trigger**: Push em `main` com mudanças em `docs/**` ou `mkdocs.yml`
- **URL**: `https://<usuario>.github.io/<repositorio>/`
- **Tema**: Material for MkDocs com suporte dark/light mode

---

## Conclusão

Este CLI oferece um framework flexível e extensível para criar ferramentas de linha de comando:

✅ **Discovery Automático** - Comandos descobertos da estrutura de diretórios  
✅ **Configuração Descentralizada** - Cada comando com seu config.yaml  
✅ **Subcategorias Multi-nível** - Hierarquia ilimitada  
✅ **Sistema de Plugins** - Extensão via Git  
✅ **12 Bibliotecas Úteis** - Logger, OS detection, dependencies, etc  
✅ **Parser YAML Robusto** - yq v4+ com instalação automática  
✅ **Documentação Profissional** - MkDocs + GitHub Pages  
✅ **Multi-plataforma** - Linux e macOS  

Para começar a usar, veja [Início Rápido](../quick-start.md).

Para adicionar seu primeiro comando, veja [Adicionar Comandos](adding-commands.md).
