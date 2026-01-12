# 📚 Referência de Bibliotecas

Esta página documenta todas as bibliotecas disponíveis em `lib/` e suas funções públicas.

---

## 🎨 color.sh

Define constantes de cores para formatação de texto no console.

### Variáveis Disponíveis

#### Cores Básicas

```bash
RED              # Vermelho
GREEN            # Verde
YELLOW           # Amarelo
BLUE             # Azul
MAGENTA          # Magenta
CYAN             # Ciano
GRAY             # Cinza
WHITE            # Branco
```

#### Cores Claras

```bash
LIGHT_RED        # Vermelho claro
LIGHT_GREEN      # Verde claro
LIGHT_YELLOW     # Amarelo claro
LIGHT_BLUE       # Azul claro
LIGHT_MAGENTA    # Magenta claro
LIGHT_CYAN       # Ciano claro
LIGHT_GRAY       # Cinza claro
```

#### Cores Escuras

```bash
CYAN_DARK        # Ciano escuro
```

#### Estilos

```bash
BOLD             # Negrito
ITALIC           # Itálico
UNDERLINE        # Sublinhado
DIM              # Escurecido

NC               # Reset (No Color)
RESET            # Reset (alias para NC)
```

### Exemplo de Uso

```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/color.sh"

echo -e "${GREEN}Sucesso!${NC}"
echo -e "${RED}${BOLD}Erro crítico!${NC}"
echo -e "${YELLOW}Atenção: ${GRAY}mensagem de aviso${NC}"
```

---

## 📝 logger.sh

Sistema de logs com níveis diferentes e timestamps automáticos.

### Funções

#### `log()`

Log básico sem nível específico.

**Uso:**

```bash
log "Mensagem informativa"
```

**Saída:**

```text
[MESSAGE] 2026-01-12 14:30:45 - Mensagem informativa
```

---

#### `log_info()`

Log de informação (azul ciano).

**Uso:**

```bash
log_info "Iniciando processo..."
```

**Saída:**

```text
[INFO] 2026-01-12 14:30:45 - Iniciando processo...
```

---

#### `log_success()`

Log de sucesso (verde).

**Uso:**

```bash
log_success "Instalação concluída com sucesso!"
```

**Saída:**

```text
[SUCCESS] 2026-01-12 14:30:45 - Instalação concluída com sucesso!
```

---

#### `log_warning()`

Log de aviso (amarelo).

**Uso:**

```bash
log_warning "Recurso em versão experimental"
```

**Saída:**

```text
[WARNING] 2026-01-12 14:30:45 - Recurso em versão experimental
```

---

#### `log_error()`

Log de erro (vermelho, escreve para stderr).

**Uso:**

```bash
log_error "Falha ao conectar ao servidor"
```

**Saída (stderr):**

```text
[ERROR] 2026-01-12 14:30:45 - Falha ao conectar ao servidor
```

---

#### `log_debug()`

Log de debug (cinza, só aparece se `DEBUG=true`).

**Uso:**

```bash
DEBUG=true
log_debug "Variável X = $X"
```

**Saída (somente com DEBUG=true):**

```text
[DEBUG] 2026-01-12 14:30:45 - Variável X = 42
```

**Ativação:**

```bash
# Ativa debug com qualquer um dos valores:
DEBUG=true
DEBUG=1
DEBUG=on
```

### Exemplo Completo

```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/logger.sh"

log_info "Verificando dependências..."

if command -v docker &>/dev/null; then
    log_success "Docker encontrado"
else
    log_error "Docker não está instalado"
    exit 1
fi

log_warning "Usando configuração padrão"
DEBUG=true log_debug "PATH=$PATH"
```

---

## 🖥️ os.sh

Detecção de sistema operacional e funções relacionadas.

### Variáveis

#### `OS_TYPE`

Tipo do sistema operacional detectado.

**Valores possíveis:**

- `macos` - macOS / Darwin
- `debian` - Ubuntu, Debian e derivados
- `fedora` - Fedora, RHEL, CentOS, Rocky, AlmaLinux
- `unknown` - Sistema não reconhecido

**Exemplo:**

```bash
source "$(dirname "$0")/../../lib/os.sh"

if [ "$OS_TYPE" = "macos" ]; then
    echo "Executando no macOS"
fi
```

### Funções

#### `get_simple_os()`

Retorna nome simplificado do OS (linux ou mac).

**Retorno:**

- `mac` - macOS
- `linux` - Qualquer Linux (Debian, Fedora, etc.)
- `unknown` - Sistema não reconhecido

**Uso:**
```bash
source "$(dirname "$0")/../../lib/os.sh"

simple_os=$(get_simple_os)

if [ "$simple_os" = "mac" ]; then
    # Código específico para macOS
    brew install package
elif [ "$simple_os" = "linux" ]; then
    # Código específico para Linux
    sudo apt-get install package
fi
```

### Exemplo Completo
```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/os.sh"
source "$(dirname "$0")/../../lib/logger.sh"

log_info "Sistema detectado: $OS_TYPE"

case "$OS_TYPE" in
    macos)
        log_info "Instalando via Homebrew..."
        brew install tool
        ;;
    debian)
        log_info "Instalando via APT..."
        sudo apt-get install tool
        ;;
    fedora)
        log_info "Instalando via DNF/YUM..."
        sudo dnf install tool
        ;;
    *)
        log_error "Sistema operacional não suportado"
        exit 1
        ;;
esac
```

---

## 🔧 string.sh

Funções auxiliares para manipulação de strings e arrays.

### Funções de String

#### `to_uppercase()`
Converte string para maiúsculas.

**Uso:**
```bash
result=$(to_uppercase "hello world")
echo "$result"  # HELLO WORLD
```

---

#### `to_lowercase()`
Converte string para minúsculas.

**Uso:**
```bash
result=$(to_lowercase "HELLO WORLD")
echo "$result"  # hello world
```

---

#### `strip_whitespace()`
Remove espaços do início e fim da string.

**Uso:**
```bash
result=$(strip_whitespace "  hello world  ")
echo "$result"  # hello world
```

### Funções de Array

#### `parse_comma_separated()`
Divide elementos do array separados por vírgula em elementos individuais.

**Uso:**
```bash
arr=("a,b,c" "d")
parse_comma_separated arr
# arr agora é: ("a" "b" "c" "d")

echo "${arr[@]}"  # a b c d
```

---

#### `join_to_comma_separated()`
Junta todos os elementos do array em uma única string separada por vírgulas.

**Uso:**
```bash
arr=("a" "b" "c")
join_to_comma_separated arr
# arr agora é: ("a,b,c")

echo "${arr[@]}"  # a,b,c
```

### Exemplo Completo
```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/string.sh"

# Strings
user_input="  Ubuntu  "
normalized=$(strip_whitespace "$user_input")
normalized=$(to_lowercase "$normalized")

echo "Sistema: $normalized"  # Sistema: ubuntu

# Arrays
os_list=("linux,mac" "windows")
parse_comma_separated os_list

for os in "${os_list[@]}"; do
    echo "- $os"
done
# Output:
# - linux
# - mac
# - windows
```

---

## 🔐 sudo.sh

Funções para gerenciamento de privilégios de superusuário.

### Funções

#### `check_sudo()`
Verifica se o script está sendo executado como root.

**Retorno:**
- `0` - Executando como root
- `1` - Não está executando como root (imprime aviso)

**Uso:**
```bash
if check_sudo; then
    echo "Executando como root"
else
    echo "Sem privilégios de root"
fi
```

---

#### `required_sudo()`
Garante privilégios sudo ou sai com erro.

**Comportamento:**
- Se já é root: não faz nada
- Se não é root: pede senha sudo
- Se falhar: sai com exit 1

**Uso:**
```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/sudo.sh"

# Garante que temos sudo antes de continuar
required_sudo

# Aqui já temos sudo garantido
apt-get update
apt-get install package
```

### Exemplo Completo
```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/sudo.sh"
source "$(dirname "$0")/../../lib/logger.sh"

# Verifica se precisa de sudo
if ! check_sudo; then
    log_warning "Este comando requer privilégios sudo"
    required_sudo
fi

log_info "Atualizando sistema..."
apt-get update

log_success "Sistema atualizado!"
```

---

## 🐚 shell.sh

Funções para detectar e configurar o shell do usuário.

### Funções

#### `detect_shell_type()`
Detecta o tipo de shell do usuário.

**Retorno:**
- `zsh` - Se o shell atual é zsh
- `bash` - Se o shell atual é bash
- `fish` - Se o shell atual é fish
- `unknown` - Shell não reconhecido

**Lógica de detecção:**
1. Verifica variável `$SHELL`
2. Fallback para variáveis de ambiente específicas (`$ZSH_VERSION`, `$BASH_VERSION`)

**Uso:**
```bash
shell=$(detect_shell_type)

case "$shell" in
    zsh)
        echo "Usando Zsh"
        ;;
    bash)
        echo "Usando Bash"
        ;;
    *)
        echo "Shell desconhecido"
        ;;
esac
```

---

#### `detect_shell_config()`
Detecta qual arquivo de configuração do shell usar (.zshrc, .bashrc, etc.).

**Retorno:**
- `$HOME/.zshrc` - Se o shell atual é zsh
- `$HOME/.bashrc` - Se o shell atual é bash
- `$HOME/.profile` - Fallback padrão

**Lógica de detecção:**
1. Verifica variável `$SHELL`
2. Se zsh e `.zshrc` existe → retorna `.zshrc`
3. Se bash e `.bashrc` existe → retorna `.bashrc`
4. Se `.zshrc` existe → retorna `.zshrc`
5. Se `.bashrc` existe → retorna `.bashrc`
6. Caso contrário → retorna `.profile`

**Uso:**
```bash
source "$(dirname "$0")/../../lib/shell.sh"

shell_config=$(detect_shell_config)
echo "export PATH=\"\$PATH:/opt/cli/bin\"" >> "$shell_config"

echo "Configuração adicionada em: $shell_config"
```

### Exemplo Completo
```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/shell.sh"
source "$(dirname "$0")/../../lib/logger.sh"

# Adiciona PATH ao shell config
shell_config=$(detect_shell_config)
cli_path="/opt/mycli/bin"

if ! grep -q "$cli_path" "$shell_config"; then
    echo "export PATH=\"\$PATH:$cli_path\"" >> "$shell_config"
    log_success "PATH adicionado a $shell_config"
    log_info "Execute: source $shell_config"
else
    log_info "PATH já configurado em $shell_config"
fi
```

---

## 📦 dependencies.sh

Gerenciamento automático de dependências externas.

### Funções

#### `ensure_curl_installed()`
Garante que curl está instalado, tentando instalar automaticamente se necessário.

**Retorno:**
- `0` - curl disponível
- `1` - Falha na instalação

**Suporte:**
- Debian/Ubuntu: `apt-get install curl`
- Fedora/RHEL: `dnf/yum install curl`
- macOS: `brew install curl`

**Uso:**
```bash
source "$(dirname "$0")/../../lib/dependencies.sh"

ensure_curl_installed || exit 1
curl -O https://example.com/file.zip
```

---

#### `ensure_jq_installed()`
Garante que jq está instalado, tentando instalar automaticamente se necessário.

**Retorno:**
- `0` - jq disponível
- `1` - Falha na instalação

**Suporte:**
- Debian/Ubuntu: `apt-get install jq`
- Fedora/RHEL: `dnf/yum install jq`
- macOS: `brew install jq`

**Uso:**
```bash
ensure_jq_installed || exit 1

version=$(curl -s https://api.github.com/repos/owner/repo/releases/latest | jq -r '.tag_name')
```

---

#### `ensure_yq_installed()`
Garante que yq está instalado, baixando da última release do GitHub se necessário.

**Retorno:**
- `0` - yq disponível
- `1` - Falha na instalação

**Comportamento:**
1. Verifica se `yq` já está disponível
2. Se não, descobre a versão mais recente do GitHub
3. Detecta plataforma (linux/darwin) e arquitetura (amd64/arm64/386)
4. Baixa binário correto
5. Instala em `/usr/local/bin/yq` (requer sudo)

**Dependências:** Requer `curl` e `jq` (instala automaticamente)

**Uso:**
```bash
ensure_yq_installed || exit 1

name=$(yq eval '.name' config.yaml)
```

---

#### `ensure_fzf_installed()`
Garante que fzf está instalado, baixando da última release do GitHub se necessário.

**Retorno:**
- `0` - fzf disponível
- `1` - Falha na instalação

**Comportamento:**
1. Verifica se `fzf` já está disponível
2. Se não, descobre a versão mais recente do GitHub
3. Detecta plataforma e arquitetura
4. Baixa e extrai tarball correto
5. Instala em `/usr/local/bin/fzf` (requer sudo)

**Dependências:** Requer `curl` e `jq` (instala automaticamente)

**Uso:**
```bash
ensure_fzf_installed || exit 1

selected=$(echo -e "option1\noption2\noption3" | fzf)
```

### Exemplo Completo
```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/dependencies.sh"
source "$(dirname "$0")/../../lib/logger.sh"

log_info "Verificando dependências..."

# Garante todas as dependências
ensure_curl_installed || exit 1
ensure_jq_installed || exit 1
ensure_yq_installed || exit 1
ensure_fzf_installed || exit 1

log_success "Todas as dependências instaladas!"

# Usa as dependências
config_name=$(yq eval '.name' cli.yaml)
selected_env=$(echo -e "dev\nstaging\nprod" | fzf --prompt="Ambiente: ")

log_info "CLI: $config_name"
log_info "Ambiente selecionado: $selected_env"
```

---

## ☸️ kubernetes.sh

Funções auxiliares para trabalhar com Kubernetes (kubectl).

### Funções

#### `check_kubectl_installed()`
Verifica se kubectl está instalado.

**Parâmetros:**
- `exit_on_error` (opcional) - Se passado, sai do script com erro se kubectl não estiver instalado

**Retorno:**
- `0` - kubectl disponível
- `1` - kubectl não encontrado

**Uso:**
```bash
# Apenas verifica
if check_kubectl_installed; then
    echo "kubectl disponível"
fi

# Força instalação ou sai
check_kubectl_installed "exit_on_error"
```

---

#### `check_namespace_exists()`
Verifica se um namespace Kubernetes existe.

**Parâmetros:**
- `$1` - Nome do namespace
- `exit_on_error` (opcional) - Se passado, sai do script com erro se namespace não existir

**Retorno:**
- `0` - Namespace existe
- `1` - Namespace não existe

**Uso:**
```bash
# Apenas verifica
if check_namespace_exists "production"; then
    echo "Namespace production existe"
fi

# Força existência ou sai
check_namespace_exists "production" "exit_on_error"
```

---

#### `get_current_context()`
Retorna o contexto atual do kubectl.

**Retorno:** String com o nome do contexto

**Uso:**
```bash
context=$(get_current_context)
echo "Contexto atual: $context"
```

---

#### `print_current_context()`
Imprime o contexto atual formatado no console.

**Uso:**
```bash
print_current_context
# Output: O contexto atual do kubectl é: minikube
```

### Exemplo Completo
```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/kubernetes.sh"
source "$(dirname "$0")/../../lib/logger.sh"

# Garante kubectl instalado
check_kubectl_installed "exit_on_error"

# Mostra contexto atual
print_current_context

# Valida namespace
namespace="${1:-default}"
check_namespace_exists "$namespace" "exit_on_error"

log_success "Namespace $namespace está acessível"

# Lista pods
log_info "Pods no namespace $namespace:"
kubectl get pods -n "$namespace"
```

---

## 🔌 plugin.sh

Funções para gerenciamento de plugins.

### Funções

#### `ensure_git_installed()`
Verifica se git está instalado.

**Retorno:**
- `0` - git disponível
- `1` - git não encontrado

**Uso:**
```bash
ensure_git_installed || {
    echo "Git é necessário"
    exit 1
}
```

---

#### `detect_plugin_version()`
Detecta a versão de um plugin no diretório.

**Parâmetros:**
- `$1` - Diretório do plugin

**Retorno:** String com a versão (padrão: "1.0.0")

**Lógica:**
1. Verifica `version.txt`
2. Se não existe, verifica `VERSION`
3. Se não existe, retorna "1.0.0"

**Uso:**
```bash
version=$(detect_plugin_version "/opt/cli/plugins/myplugin")
echo "Versão: $version"
```

---

#### `count_plugin_commands()`
Conta quantos comandos um plugin possui.

**Parâmetros:**
- `$1` - Diretório do plugin

**Retorno:** Número de arquivos `config.yaml` encontrados

**Uso:**
```bash
count=$(count_plugin_commands "/opt/cli/plugins/myplugin")
echo "Plugin tem $count comandos"
```

---

#### `clone_plugin()`
Clona plugin de um repositório Git e remove pasta .git.

**Parâmetros:**
- `$1` - URL do repositório
- `$2` - Diretório de destino

**Retorno:**
- `0` - Clone bem-sucedido
- `1` - Falha no clone

**Uso:**
```bash
if clone_plugin "https://github.com/user/plugin.git" "/opt/cli/plugins/plugin"; then
    echo "Plugin clonado com sucesso"
fi
```

---

#### `normalize_git_url()`
Converte formato `user/repo` para URL completa do GitHub.

**Parâmetros:**
- `$1` - URL ou formato `user/repo`

**Retorno:** URL completa do repositório

**Uso:**
```bash
url=$(normalize_git_url "user/repo")
echo "$url"  # https://github.com/user/repo.git

url=$(normalize_git_url "https://gitlab.com/user/repo.git")
echo "$url"  # https://gitlab.com/user/repo.git
```

---

#### `extract_plugin_name()`
Extrai nome do plugin da URL.

**Parâmetros:**
- `$1` - URL do repositório

**Retorno:** Nome do plugin (sem .git)

**Uso:**
```bash
name=$(extract_plugin_name "https://github.com/user/awesome-plugin.git")
echo "$name"  # awesome-plugin
```

### Exemplo Completo
```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/plugin.sh"
source "$(dirname "$0")/../../lib/logger.sh"

# Garante git instalado
ensure_git_installed || exit 1

# Normaliza URL
url=$(normalize_git_url "$1")
name=$(extract_plugin_name "$url")

log_info "Instalando plugin: $name"

# Clone plugin
plugin_dir="/opt/cli/plugins/$name"

if clone_plugin "$url" "$plugin_dir"; then
    version=$(detect_plugin_version "$plugin_dir")
    count=$(count_plugin_commands "$plugin_dir")
    
    log_success "Plugin $name v$version instalado"
    log_info "Total de comandos: $count"
else
    log_error "Falha ao clonar plugin"
    exit 1
fi
```

---

## 📋 registry.sh

Gerenciamento do arquivo `registry.yaml` de plugins.

### Funções

#### `registry_add_plugin()`
Adiciona um plugin ao registry.

**Parâmetros:**
- `$1` - Caminho do arquivo registry.yaml
- `$2` - Nome do plugin
- `$3` - URL do repositório
- `$4` - Versão (opcional, padrão: "1.0.0")

**Retorno:**
- `0` - Plugin adicionado
- `1` - Plugin já existe

**Uso:**
```bash
registry_file="/opt/cli/plugins/registry.yaml"

registry_add_plugin "$registry_file" "myplugin" "https://github.com/user/plugin.git" "1.2.0"
```

---

#### `registry_remove_plugin()`
Remove um plugin do registry.

**Parâmetros:**
- `$1` - Caminho do arquivo registry.yaml
- `$2` - Nome do plugin

**Retorno:**
- `0` - Plugin removido
- `1` - Registry não existe

**Uso:**
```bash
registry_remove_plugin "$registry_file" "myplugin"
```

---

#### `registry_list_plugins()`
Lista todos os plugins do registry em formato delimitado por `|`.

**Parâmetros:**
- `$1` - Caminho do arquivo registry.yaml

**Retorno:** Linhas no formato: `nome|source|version|installed_at`

**Uso:**
```bash
registry_list_plugins "$registry_file" | while IFS='|' read -r name source version installed; do
    echo "Plugin: $name"
    echo "  Source: $source"
    echo "  Version: $version"
    echo "  Installed: $installed"
done
```

---

#### `registry_get_plugin_info()`
Obtém informação específica de um plugin.

**Parâmetros:**
- `$1` - Caminho do arquivo registry.yaml
- `$2` - Nome do plugin
- `$3` - Campo (source, version, installed_at)

**Retorno:** Valor do campo solicitado

**Uso:**
```bash
source=$(registry_get_plugin_info "$registry_file" "myplugin" "source")
version=$(registry_get_plugin_info "$registry_file" "myplugin" "version")

echo "Plugin myplugin: $version ($source)"
```

### Exemplo Completo
```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/registry.sh"

registry_file="$CLI_DIR/plugins/registry.yaml"

# Adiciona plugin
registry_add_plugin "$registry_file" "awesome" "https://github.com/user/awesome.git" "2.0.0"

# Lista todos
echo "Plugins instalados:"
registry_list_plugins "$registry_file" | while IFS='|' read -r name source version installed; do
    echo "- $name v$version (instalado em: $installed)"
done

# Obtém info específica
version=$(registry_get_plugin_info "$registry_file" "awesome" "version")
echo "Versão do awesome: $version"

# Remove plugin
registry_remove_plugin "$registry_file" "awesome"
```

---

## 📄 yaml.sh

Parser YAML usando yq para configurações centralizadas e descentralizadas.

### Variáveis Requeridas

Antes de usar, configure:
```bash
GLOBAL_CONFIG_FILE="/path/to/cli.yaml"  # Config global
CLI_DIR="/path/to/cli"           # Diretório raiz do CLI
```

### Funções - Config Global

#### `get_yaml_field()`
Obtém campos do arquivo cli.yaml.

**Parâmetros:**
- `$1` - Caminho do arquivo yaml
- `$2` - Campo (name, description, version, commands_dir, plugins_dir)

**Retorno:** Valor do campo

**Uso:**
```bash
name=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "name")
version=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "version")
```

---

#### `parse_yaml_categories()`
Lê categorias do YAML (se houver).

**Parâmetros:**
- `$1` - Caminho do arquivo yaml

**Retorno:** Lista de nomes de categorias

**Uso:**
```bash
categories=$(parse_yaml_categories "$GLOBAL_CONFIG_FILE")
```

---

#### `discover_categories()`
Descobre categorias da estrutura de diretórios (commands/ e plugins/).

**Retorno:** Lista de categorias de nível 1

**Uso:**
```bash
categories=$(discover_categories)
for cat in $categories; do
    echo "Categoria: $cat"
done
```

---

#### `get_all_categories()`
Obtém todas as categorias (YAML + descobertas via filesystem).

**Parâmetros:**
- `$1` - Caminho do arquivo yaml

**Retorno:** Lista unificada e deduplic ada de categorias

**Uso:**
```bash
all_categories=$(get_all_categories "$GLOBAL_CONFIG_FILE")
```

---

#### `get_category_info()`
Obtém informações de uma categoria do config.yaml dela.

**Parâmetros:**
- `$1` - Caminho do arquivo yaml global
- `$2` - Nome da categoria
- `$3` - Campo (name, description)

**Retorno:** Valor do campo da categoria

**Uso:**
```bash
desc=$(get_category_info "$GLOBAL_CONFIG_FILE" "install" "description")
echo "Categoria install: $desc"
```

### Funções - Discovery de Comandos

#### `is_command_dir()`
Verifica se um diretório é um comando (tem config.yaml com campo script).

**Parâmetros:**
- `$1` - Diretório a verificar

**Retorno:**
- `0` - É um comando
- `1` - Não é comando (é subcategoria)

**Uso:**
```bash
if is_command_dir "/opt/cli/commands/install/docker"; then
    echo "É um comando"
else
    echo "É uma subcategoria"
fi
```

---

#### `discover_items_in_category()`
Descobre comandos e subcategorias em uma categoria.

**Parâmetros:**
- `$1` - Diretório base (commands/ ou plugins/nome)
- `$2` - Caminho da categoria (ex: "install" ou "install/python")
- `$3` - Tipo: "commands", "subcategories", ou "all" (padrão: "all")

**Retorno:** Linhas no formato `command:nome` ou `subcategory:nome`

**Uso:**
```bash
# Todos os itens
discover_items_in_category "$CLI_DIR/commands" "install" "all"

# Apenas comandos
discover_items_in_category "$CLI_DIR/commands" "install" "commands" | sed 's/^command://'

# Apenas subcategorias
discover_items_in_category "$CLI_DIR/commands" "install" "subcategories" | sed 's/^subcategory://'
```

---

#### `get_category_commands()`
Obtém comandos de uma categoria (busca em commands/ e plugins/).

**Parâmetros:**
- `$1` - Nome da categoria (pode ser aninhada: "install/python")

**Retorno:** Lista de nomes de comandos

**Uso:**
```bash
commands=$(get_category_commands "install")
for cmd in $commands; do
    echo "Comando: $cmd"
done
```

---

#### `get_category_subcategories()`
Obtém subcategorias de uma categoria.

**Parâmetros:**
- `$1` - Nome da categoria

**Retorno:** Lista de subcategorias

**Uso:**
```bash
subcats=$(get_category_subcategories "install")
for subcat in $subcats; do
    echo "Subcategoria: $subcat"
done
```

### Funções - Config de Comandos

#### `get_command_config_field()`
Lê um campo do config.yaml de um comando.

**Parâmetros:**
- `$1` - Caminho do arquivo config.yaml
- `$2` - Campo (name, description, script, sudo, os, group)

**Retorno:** Valor do campo

**Uso:**
```bash
name=$(get_command_config_field "/opt/cli/commands/install/docker/config.yaml" "name")
```

---

#### `find_command_config()`
Encontra o arquivo config.yaml de um comando.

**Parâmetros:**
- `$1` - Categoria (pode ser aninhada: "install/python")
- `$2` - ID do comando

**Retorno:** Caminho completo do config.yaml

**Uso:**
```bash
config=$(find_command_config "install" "docker")
echo "$config"  # /opt/cli/commands/install/docker/config.yaml
```

---

#### `get_command_info()`
Obtém informação de um comando específico.

**Parâmetros:**
- `$1` - Arquivo yaml global (mantido por compatibilidade)
- `$2` - Categoria
- `$3` - ID do comando
- `$4` - Campo (name, description, script, sudo, os, group)

**Retorno:** Valor do campo

**Uso:**
```bash
script=$(get_command_info "$GLOBAL_CONFIG_FILE" "install" "docker" "script")
needs_sudo=$(get_command_info "$GLOBAL_CONFIG_FILE" "install" "docker" "sudo")
```

---

#### `is_command_compatible()`
Verifica se comando é compatível com o SO atual.

**Parâmetros:**
- `$1` - Arquivo yaml global
- `$2` - Categoria
- `$3` - ID do comando
- `$4` - SO atual (linux ou mac)

**Retorno:**
- `0` - Compatível
- `1` - Incompatível

**Uso:**
```bash
current_os=$(get_simple_os)

if is_command_compatible "$GLOBAL_CONFIG_FILE" "install" "docker" "$current_os"; then
    echo "Comando compatível"
fi
```

---

#### `requires_sudo()`
Verifica se comando requer sudo.

**Parâmetros:**
- `$1` - Arquivo yaml global
- `$2` - Categoria
- `$3` - ID do comando

**Retorno:**
- `0` - Requer sudo
- `1` - Não requer sudo

**Uso:**
```bash
if requires_sudo "$GLOBAL_CONFIG_FILE" "install" "docker"; then
    log_warning "Este comando requer sudo"
fi
```

---

#### `get_command_group()`
Obtém o grupo de um comando (para agrupamento visual).

**Parâmetros:**
- `$1` - Arquivo yaml global
- `$2` - Categoria
- `$3` - ID do comando

**Retorno:** Nome do grupo ou vazio

**Uso:**
```bash
group=$(get_command_group "$GLOBAL_CONFIG_FILE" "install" "docker")
echo "Grupo: $group"
```

---

#### `get_category_groups()`
Obtém lista única de grupos em uma categoria.

**Parâmetros:**
- `$1` - Arquivo yaml global
- `$2` - Categoria
- `$3` - SO atual

**Retorno:** Lista de grupos (sem duplicatas)

**Uso:**
```bash
current_os=$(get_simple_os)
groups=$(get_category_groups "$GLOBAL_CONFIG_FILE" "install" "$current_os")

for group in $groups; do
    echo "Grupo: $group"
done
```

### Exemplo Completo
```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/yaml.sh"
source "$(dirname "$0")/../../lib/os.sh"

# Configuração
GLOBAL_CONFIG_FILE="/opt/cli/cli.yaml"
CLI_DIR="/opt/cli"

# Obtém info global
cli_name=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "name")
cli_version=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "version")

echo "$cli_name v$cli_version"
echo ""

# Lista todas as categorias
categories=$(get_all_categories "$GLOBAL_CONFIG_FILE")

for category in $categories; do
    cat_desc=$(get_category_info "$GLOBAL_CONFIG_FILE" "$category" "description")
    echo "=== $category ==="
    echo "    $cat_desc"
    echo ""
    
    # Lista comandos da categoria
    commands=$(get_category_commands "$category")
    current_os=$(get_simple_os)
    
    for cmd in $commands; do
        # Verifica compatibilidade
        if ! is_command_compatible "$GLOBAL_CONFIG_FILE" "$category" "$cmd" "$current_os"; then
            continue
        fi
        
        cmd_name=$(get_command_info "$GLOBAL_CONFIG_FILE" "$category" "$cmd" "name")
        cmd_desc=$(get_command_info "$GLOBAL_CONFIG_FILE" "$category" "$cmd" "description")
        
        echo "  - $cmd_name: $cmd_desc"
        
        if requires_sudo "$GLOBAL_CONFIG_FILE" "$category" "$cmd"; then
            echo "    (requer sudo)"
        fi
    done
    
    # Lista subcategorias
    subcats=$(get_category_subcategories "$category")
    if [ -n "$subcats" ]; then
        echo ""
        echo "  Subcategorias: $subcats"
    fi
    
    echo ""
done
```

---

## 🛠️ cli.sh

Funções auxiliares específicas do CLI.

### Funções

#### `setup_command_env()`
Configura o ambiente do comando determinando SCRIPT_DIR e CONFIG_FILE.

**Comportamento:**
- Define `SCRIPT_DIR` como o diretório do script que chamou a função
- Define `CONFIG_FILE` como `$SCRIPT_DIR/config.yaml`
- Exporta ambas as variáveis para uso em subprocessos

**Uso:**
```bash
#!/bin/bash

setup_command_env

# Agora você tem acesso a:
echo "Script dir: $SCRIPT_DIR"
echo "Config file: $CONFIG_FILE"
```

---

#### `build_command_path()`
Constrói o caminho do comando baseado no SCRIPT_DIR.

**Parâmetros:**
- `$1` - Diretório do script (opcional, usa SCRIPT_DIR se não fornecido)

**Retorno:** Caminho do comando sem barras (separado por espaços)

**Exemplo:**
```bash
# Se SCRIPT_DIR = /opt/cli/commands/self/plugin/install
path=$(build_command_path)
echo "$path"  # self plugin install
```

---

#### `show_usage()`
Mostra mensagem de uso do comando com argumentos customizáveis.

**Parâmetros:**
- `$@` - Argumentos opcionais (padrão: "[opções]")

**Uso:**
```bash
show_usage
# Output: Uso: susa <comando> [opções]

show_usage "<arquivo> <destino>"
# Output: Uso: susa setup docker <arquivo> <destino>
```

---

#### `show_description()`
Exibe a descrição do comando do arquivo config.yaml.

**Requisitos:**
- Variável `CONFIG_FILE` deve estar definida (use `setup_command_env`)
- O arquivo config.yaml deve ter um campo "description"

**Uso:**
```bash
setup_command_env
show_description
# Output: Instala Docker no sistema
```

---

#### `show_version()`
Mostra nome e versão do CLI formatados.

**Uso:**
```bash
show_version
# Output: Susa (versão 2.0.0)
```

---

#### `show_number_version()`
Mostra apenas o número da versão do CLI.

**Retorno:** String com o número da versão

**Uso:**
```bash
version=$(show_number_version)
echo "$version"  # 2.0.0
```

### Exemplo Completo
```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/cli.sh"

# Setup do ambiente
setup_command_env

if [ $# -eq 0 ]; then
    show_description
    echo ""
    show_usage
    exit 0
fi

# Mostra versão se solicitado
if [ "$1" = "--version" ]; then
    show_version
    exit 0
fi
```

---

## 📦 utils.sh

Agregador que importa os módulos principais.

### Importações Automáticas

Ao fazer `source utils.sh`, você automaticamente carrega:
- `cli.sh`
- `shell.sh`
- `dependencies.sh`

**Uso:**
```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/utils.sh"

# Agora tem acesso a:
show_version
detect_shell_config
ensure_yq_installed
# etc.
```

---

## 📖 Padrões de Uso

### Estrutura Típica de um Comando

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
source "$CLI_DIR/lib/sudo.sh"
source "$CLI_DIR/lib/dependencies.sh"

# Lógica do comando
log_info "Iniciando instalação..."

# Detecta SO
simple_os=$(get_simple_os)

# Verifica dependências
ensure_curl_installed || exit 1

# Requer sudo se necessário
if [ "$simple_os" = "linux" ]; then
    required_sudo
fi

# Executa instalação
case "$simple_os" in
    mac)
        log_info "Instalando no macOS..."
        brew install package
        ;;
    linux)
        log_info "Instalando no Linux..."
        apt-get install package
        ;;
    *)
        log_error "Sistema operacional não suportado"
        exit 1
        ;;
esac

log_success "Instalação concluída!"
```

### Uso de YAML Parser

```bash
#!/bin/bash
source "$CLI_DIR/lib/yaml.sh"
source "$CLI_DIR/lib/os.sh"

# Configuração
GLOBAL_CONFIG_FILE="$CLI_DIR/cli.yaml"

# Obtém categorias
categories=$(get_all_categories "$GLOBAL_CONFIG_FILE")
current_os=$(get_simple_os)

for category in $categories; do
    # Obtém comandos compatíveis
    commands=$(get_category_commands "$category")
    
    for cmd in $commands; do
        if is_command_compatible "$GLOBAL_CONFIG_FILE" "$category" "$cmd" "$current_os"; then
            # Processa comando
            name=$(get_command_info "$GLOBAL_CONFIG_FILE" "$category" "$cmd" "name")
            echo "Comando disponível: $name"
        fi
    done
done
```

### Gerenciamento de Plugins

```bash
#!/bin/bash
source "$CLI_DIR/lib/plugin.sh"
source "$CLI_DIR/lib/registry.sh"
source "$CLI_DIR/lib/logger.sh"

# Configuração
registry_file="$CLI_DIR/plugins/registry.yaml"
plugins_dir="$CLI_DIR/plugins"

# Instalar plugin
plugin_url="$1"
normalized_url=$(normalize_git_url "$plugin_url")
plugin_name=$(extract_plugin_name "$normalized_url")
plugin_path="$plugins_dir/$plugin_name"

log_info "Instalando plugin: $plugin_name"

# Clone
if clone_plugin "$normalized_url" "$plugin_path"; then
    version=$(detect_plugin_version "$plugin_path")
    
    # Registra
    registry_add_plugin "$registry_file" "$plugin_name" "$normalized_url" "$version"
    
    log_success "Plugin $plugin_name v$version instalado!"
else
    log_error "Falha ao instalar plugin"
    exit 1
fi
```

---

## 🔗 Dependências Entre Bibliotecas

```
utils.sh
├── cli.sh
│   ├── color.sh
│   └── yaml.sh
│       ├── registry.sh
│       └── dependencies.sh
│           └── logger.sh
│               └── color.sh
├── shell.sh
└── dependencies.sh

Independentes:
- os.sh
- string.sh
- sudo.sh (requer color.sh)
- kubernetes.sh (requer color.sh)
- plugin.sh
```

**Nota:** Sempre faça `source` das dependências antes de usar uma biblioteca.

---

## 🎯 Boas Práticas

1. **Sempre use `set -euo pipefail`** no início dos scripts
2. **Importe apenas o necessário** para reduzir overhead
3. **Use `log_*` ao invés de `echo`** para mensagens consistentes
4. **Detecte SO antes de comandos específicos** usando `get_simple_os()`
5. **Valide dependências cedo** com `ensure_*_installed`
6. **Use cores para destacar** informações importantes
7. **Documente scripts complexos** com comentários
8. **Teste compatibilidade de SO** com `is_command_compatible()`
9. **Use yq para YAML** ao invés de awk/grep
10. **Mantenha registry atualizado** ao instalar/remover plugins

---

## 📚 Recursos Adicionais

- [Guia de Subcategorias](../guides/subcategories.md) - Como usar yaml.sh para navegar subcategorias
- [Adicionar Comandos](../guides/adding-commands.md) - Como criar novos comandos
- [Sistema de Plugins](../plugins/overview.md) - Como plugins funcionam
- [Funcionalidades](../guides/features.md) - Visão geral do sistema
