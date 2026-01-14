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

## Exemplo Completo

```bash
#!/bin/bash
source "$LIB_DIR/os.sh"
source "$LIB_DIR/logger.sh"

log_info "Sistema detectado: $OS_TYPE"

case "$OS_TYPE" in
    macos)
        log_info "Instalando via Homebrew..."
        brew install docker
        ;;
    debian)
        log_info "Instalando via APT..."
        sudo apt-get install -y docker.io
        ;;
    fedora)
        log_info "Instalando via DNF/YUM..."
        sudo dnf install -y docker
        ;;
    *)
        log_error "Sistema operacional não suportado"
        exit 1
        ;;
esac
```

## Boas Práticas

1. Use `get_simple_os()` para lógica de dois caminhos (mac/linux)
2. Use `$OS_TYPE` para lógica específica de distribuição
3. Sempre trate o caso `unknown` para SOs não suportados
