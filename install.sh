#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ===============
# CLI Installer
# ===============

CLI_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$CLI_SOURCE_DIR/core/cli.yaml"
CLI_NAME="susa"

# Detects the operating system and sets the installation directory
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    OS_TYPE="macOS"
    INSTALL_DIR="$HOME/.local/bin"
    SHELL_CONFIG="$HOME/.zshrc ou $HOME/.bash_profile"
else
    # Linux
    OS_TYPE="Linux"
    INSTALL_DIR="$HOME/.local/bin"
    SHELL_CONFIG="$HOME/.bashrc ou $HOME/.zshrc"
fi

# Check if CLI is already installed
if [ -L "$INSTALL_DIR/$CLI_NAME" ] || [ -f "$INSTALL_DIR/$CLI_NAME" ]; then
    INSTALLED_PATH=$(readlink -f "$INSTALL_DIR/$CLI_NAME" 2>/dev/null || echo "$INSTALL_DIR/$CLI_NAME")

    # Check if it's pointing to a different directory (not this installation)
    if [[ "$INSTALLED_PATH" != "$CLI_SOURCE_DIR/core/$CLI_NAME" ]]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  ⚠  Susa CLI já está instalado"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Instalação detectada em: $INSTALLED_PATH"
        echo ""
        echo "Para atualizar para a versão mais recente, use:"
        echo ""
        echo "  $CLI_NAME self update"
        echo ""
        echo "Para reinstalar de qualquer forma, primeiro remova a instalação atual."
        echo ""
        exit 0
    fi
fi

# Create installation directory if it doesn't exist
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Instalando Susa CLI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ! -d "$INSTALL_DIR" ]; then
    echo "→ Criando diretório de instalação..."
    mkdir -p "$INSTALL_DIR"
    echo "  ✓ Diretório criado: $INSTALL_DIR"
else
    echo "→ Verificando diretório de instalação..."
    echo "  ✓ Diretório existe: $INSTALL_DIR"
fi

# Create symlink for the CLI
echo "→ Criando link simbólico..."
ln -sf "$CLI_SOURCE_DIR/core/susa" "$INSTALL_DIR/$CLI_NAME"
echo "  ✓ Executável instalado"

# Checks if the directory is in the PATH
echo "→ Configurando shells disponíveis..."
echo ""

# Function to configure a shell
configure_shell() {
    local shell_name="$1"
    local shell_config="$2"

    if [ -f "$shell_config" ]; then
        # Backup existing file
        cp "$shell_config" "${shell_config}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    fi

    # Check if PATH is already configured
    if grep -q "# Susa CLI" "$shell_config" 2>/dev/null; then
        echo "  ✓ $shell_name já configurado"
        return 0
    fi

    # Add PATH configuration
    cat >>"$shell_config" <<'EOF'

# Path Bin
export PATH="$HOME/.local/bin:$PATH"
EOF
    echo "  ✓ $shell_name configurado"
}

# Detect and configure available shells
shells_configured=0
shells_not_found=()

# Bash configuration
if command -v bash &>/dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Configure both .bashrc and .bash_profile
        configure_shell "Bash (.bashrc)" "$HOME/.bashrc"
        configure_shell "Bash (.bash_profile)" "$HOME/.bash_profile"

        # Ensure .bash_profile sources .bashrc
        if [ -f "$HOME/.bash_profile" ]; then
            if ! grep -q "source.*bashrc" "$HOME/.bash_profile" 2>/dev/null; then
                cat >>"$HOME/.bash_profile" <<'EOF'

# Source .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi
EOF
            fi
        fi
    else
        # Linux: Configure .bashrc
        configure_shell "Bash" "$HOME/.bashrc"
    fi
    shells_configured=$((shells_configured + 1))
else
    shells_not_found+=("Bash")
fi

# Zsh configuration
if command -v zsh &>/dev/null; then
    configure_shell "Zsh" "$HOME/.zshrc"
    shells_configured=$((shells_configured + 1))
else
    shells_not_found+=("Zsh")
fi

echo ""
if [ ${#shells_not_found[@]} -gt 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ℹ  Shells não encontrados"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    for shell in "${shells_not_found[@]}"; do
        echo "  • $shell não está instalado"
    done
    echo ""
    echo "Se você instalar algum destes shells no futuro,"
    echo "configure manualmente adicionando ao arquivo de configuração:"
    echo ""
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

# Checks if the directory is in the current PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ⚠  Recarregamento do shell necessário"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Para usar o Susa CLI, recarregue seu shell:"
    echo ""

    # Detect current shell
    current_shell=$(basename "$SHELL")
    case "$current_shell" in
        bash)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                echo "  source ~/.bash_profile"
            else
                echo "  source ~/.bashrc"
            fi
            ;;
        zsh)
            echo "  source ~/.zshrc"
            ;;
        *)
            echo "  Reinicie seu terminal"
            ;;
    esac

    echo ""
    echo "Ou simplesmente abra um novo terminal."
else
    echo "→ Verificando PATH no shell atual..."
    echo "  ✓ Diretório já está no PATH"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Shell Completion (Autocompletar)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running in interactive mode
if [ -t 0 ]; then
    # Interactive mode - ask user
    echo "Instalar autocompletar (tab completion)?"
    echo "Permite usar TAB para completar comandos."
    echo ""
    read -p "Instalar agora? (s/N): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        echo ""
        echo "→ Instalando autocompletar..."
        if "$CLI_SOURCE_DIR/core/susa" self completion --install 2>&1 | grep -q "instalado em:"; then
            echo "  ✓ Autocompletar instalado"
            echo ""
            echo "  Nota: Reinicie o terminal ou execute 'source' no seu shell config"
        fi
    else
        echo ""
        echo "  Você pode instalar depois com:"
        echo "  $CLI_NAME self completion --install"
    fi
else
    # Non-interactive mode (piped from curl, etc.) - skip completion
    echo "Modo não-interativo detectado."
    echo "Instalação do autocompletar será pulada."
    echo ""
    echo "  Você pode instalar depois com:"
    echo "  $CLI_NAME self completion --install"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━"
echo "  Comandos Úteis"
echo "━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Uso básico:"
echo "    $CLI_NAME <categoria> <comando> [opções]"
echo ""
echo "  Exemplos:"
echo "    $CLI_NAME setup docker        # Instalar Docker"
echo "    $CLI_NAME self info           # Info da instalação"
echo "    $CLI_NAME self version        # Versão do CLI"
echo ""
echo "  Ajuda completa:"
echo "    $CLI_NAME --help"
echo ""
