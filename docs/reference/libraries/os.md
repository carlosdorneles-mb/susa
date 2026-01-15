# os.sh

Detecção de sistema operacional e funções relacionadas.

## Variáveis

### `OS_TYPE`

Tipo do sistema operacional detectado.

**Valores possíveis:**

- `macos` - macOS / Darwin
- `debian` - Ubuntu, Debian e derivados
- `fedora` - Fedora, RHEL, CentOS, Rocky, AlmaLinux
- `unknown` - Sistema não reconhecido

**Exemplo:**

```bash
source "$LIB_DIR/os.sh"

if [ "$OS_TYPE" = "macos" ]; then
    echo "Executando no macOS"
fi
```

## Funções

### `get_simple_os()`

Retorna nome simplificado do OS (linux ou mac).

**Retorno:**

- `mac` - macOS
- `linux` - Qualquer Linux (Debian, Fedora, etc.)
- `unknown` - Sistema não reconhecido

**Uso:**

```bash
source "$LIB_DIR/os.sh"

simple_os=$(get_simple_os)

if [ "$simple_os" = "mac" ]; then
    # Código específico para macOS
    brew install package
elif [ "$simple_os" = "linux" ]; then
    # Código específico para Linux
    sudo apt-get install package
fi
```

### `get_os_name()`

Alias para `get_simple_os()`. Retorna nome simplificado do OS.

**Retorno:**

- `mac` - macOS
- `linux` - Qualquer Linux
- `unknown` - Sistema não reconhecido

**Uso:**

```bash
os_name=$(get_os_name)
echo "Sistema operacional: $os_name"
```

### `is_linux()`

Verifica se está rodando em Linux.

**Retorno:**

- `0` (true) - Sistema é Linux (Debian ou Fedora-based)
- `1` (false) - Sistema não é Linux

**Uso:**

```bash
if is_linux; then
    echo "Rodando em Linux"
    sudo apt-get update
fi

# Lógica específica para Linux
if is_linux; then
    # Instalar dependências Linux
    install_linux_packages
fi
```

### `is_mac()`

Verifica se está rodando em macOS.

**Retorno:**

- `0` (true) - Sistema é macOS
- `1` (false) - Sistema não é macOS

**Uso:**

```bash
if is_mac; then
    echo "Rodando em macOS"
    brew install package
fi

# Configurações específicas do macOS
if is_mac; then
    defaults write com.apple.finder AppleShowAllFiles YES
fi
```

## Exemplo Completo

```bash
#!/bin/bash
source "$LIB_DIR/os.sh"
source "$LIB_DIR/logger.sh"

log_info "Sistema detectado: $OS_TYPE"

# Usando funções booleanas
if is_mac; then
    log_info "Instalando via Homebrew..."
    brew install docker
elif is_linux; then
    log_info "Instalando via gerenciador de pacotes Linux..."

    # Lógica específica por distribuição
    case "$OS_TYPE" in
        debian)
            sudo apt-get update
            sudo apt-get install -y docker.io
            ;;
        fedora)
            sudo dnf install -y docker
            ;;
    esac
else
    log_error "Sistema operacional não suportado"
    exit 1
fi

# Usando get_os_name para lógica simples
os_name=$(get_os_name)
log_info "Configurando para: $os_name"
```

## Boas Práticas

1. Use `is_linux()` e `is_mac()` para condicionais simples e legíveis
2. Use `get_os_name()` ou `get_simple_os()` para lógica de dois caminhos (mac/linux)
3. Use `$OS_TYPE` para lógica específica de distribuição
4. Sempre trate o caso `unknown` para SOs não suportados
