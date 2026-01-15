# dependencies.sh

Gerenciamento automático de dependências externas e helpers para operações com gerenciadores de pacotes.

## Funções

### `command_exists()`

Verifica se um comando existe no sistema.

**Parâmetros:**

- `$1` - Nome do comando

**Retorno:**

- `0` - Comando existe
- `1` - Comando não encontrado

**Uso:**

```bash
if command_exists "docker"; then
    echo "Docker está instalado"
else
    echo "Docker não encontrado"
fi

# Verificar antes de usar
if command_exists "jq"; then
    version=$(cat file.json | jq -r '.version')
fi
```

### `check_dependencies()`

Verifica se múltiplas dependências estão instaladas.

**Parâmetros:**

- `$@` - Lista de comandos a verificar

**Retorno:**

- `0` - Todas as dependências estão instaladas
- `1` - Uma ou mais dependências estão faltando (exibe log de erro)

**Uso:**

```bash
# Verificar múltiplas dependências
if check_dependencies "git" "curl" "jq"; then
    echo "Todas as dependências estão instaladas"
    # Prosseguir com a operação
else
    echo "Instale as dependências faltando"
    exit 1
fi

# Exemplo prático
check_dependencies "docker" "docker-compose" || exit 1
docker-compose up -d
```

**Mensagem de erro:**

Quando dependências estão faltando, a função exibe:

```text
[ERROR] Dependências faltando: docker git
```

### `wait_for_apt_lock()`

Aguarda até que o lock do apt seja liberado antes de executar comandos apt-get.

**Parâmetros:** Nenhum

**Retorno:**

- `0` - Lock liberado, pode prosseguir
- `1` - Timeout (60 segundos)

**Comportamento:**

1. Verifica se há locks ativos em `/var/lib/apt/lists/lock`, `/var/lib/dpkg/lock` e `/var/lib/dpkg/lock-frontend`
2. Aguarda até 60 segundos para os processos finalizarem
3. Mostra mensagem informativa ao usuário
4. Verifica a cada 2 segundos

**Uso:**

```bash
# Antes de usar apt-get, aguarde o lock ser liberado
wait_for_apt_lock || exit 1

sudo apt-get update
sudo apt-get install -y podman
```

**Cenário comum:**

```bash
# Evita erro "Could not get lock /var/lib/apt/lists/lock"
if command -v apt-get &>/dev/null; then
    wait_for_apt_lock || return 1
    sudo apt-get update -qq
    sudo apt-get install -y meu-pacote
fi
```

### `ensure_curl_installed()`

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
ensure_curl_installed || exit 1
curl -O https://example.com/file.zip
```

### `ensure_jq_installed()`

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

### `ensure_yq_installed()`

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

### `ensure_fzf_installed()`

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

### `ensure_pip3_installed()`

Garante que pip3 está instalado, tentando instalar automaticamente se necessário.

**Retorno:**

- `0` - pip3 disponível
- `1` - Falha na instalação

**Suporte:**

- Debian/Ubuntu: `apt-get install python3-pip`
- Fedora/RHEL: `dnf/yum install python3-pip`

**Comportamento:**

1. Verifica se `pip3` já está disponível
2. Se não, detecta o gerenciador de pacotes (apt/dnf/yum)
3. Para apt-get, chama `wait_for_apt_lock()` antes de instalar
4. Instala `python3-pip` usando o gerenciador apropriado
5. Verifica se a instalação foi bem-sucedida

**Uso:**

```bash
ensure_pip3_installed || exit 1

pip3 install --user podman-compose
pip3 install --user ansible
```

**Uso com pacotes Python:**

```bash
# Instalar pip3 e depois um pacote
if ensure_pip3_installed; then
    log_info "Instalando podman-compose..."
    pip3 install --user podman-compose
else
    log_error "pip3 é necessário mas não pôde ser instalado"
    exit 1
fi
```

## Exemplo Completo

```bash
#!/bin/bash
source "$LIB_DIR/dependencies.sh"
source "$LIB_DIR/logger.sh"

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

## Exemplo com Gerenciador de Pacotes

```bash
#!/bin/bash
source "$LIB_DIR/dependencies.sh"
source "$LIB_DIR/logger.sh"

install_package() {
    local package_name="$1"

    if command -v apt-get &>/dev/null; then
        log_info "Instalando $package_name via apt-get..."

        # Aguarda lock ser liberado
        wait_for_apt_lock || return 1

        sudo apt-get update -qq
        sudo apt-get install -y "$package_name"

    elif command -v dnf &>/dev/null; then
        log_info "Instalando $package_name via dnf..."
        sudo dnf install -y "$package_name"

    elif command -v yum &>/dev/null; then
        log_info "Instalando $package_name via yum..."
        sudo yum install -y "$package_name"

    else
        log_error "Gerenciador de pacotes não suportado"
        return 1
    fi
}

# Instala pacotes
install_package "curl"
install_package "git"
```

## Boas Práticas

1. Sempre verifique dependências no início do script
2. Use `|| exit 1` para falhar rápido se dependência não instalar
3. Informe o usuário sobre instalações automáticas
4. **Sempre use `wait_for_apt_lock()` antes de comandos apt-get** para evitar conflitos
5. Detecte o gerenciador de pacotes correto (apt/dnf/yum) para melhor compatibilidade
