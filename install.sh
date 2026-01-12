#!/bin/bash

# ===============
# CLI Installer
# ===============

set -e

CLI_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$CLI_SOURCE_DIR/cli.yaml"
CLI_NAME="susa"

# Detects the operating system and sets the installation directory
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    OS_TYPE="macOS"
    INSTALL_DIR="$HOME/.local/bin"
    SHELL_CONFIG="~/.zshrc ou ~/.bash_profile"
else
    # Linux
    OS_TYPE="Linux"
    INSTALL_DIR="$HOME/.local/bin"
    SHELL_CONFIG="~/.bashrc ou ~/.zshrc"
fi

# Create installation directory if it doesn't exist
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Instalando Susa CLI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
ln -sf "$CLI_SOURCE_DIR/susa" "$INSTALL_DIR/$CLI_NAME"
echo "  ✓ Executável instalado"

# Checks if the directory is in the PATH
echo ""
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ⚠  Configuração do PATH necessária"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "$INSTALL_DIR não está no seu PATH."
    echo ""
    echo "Adicione ao seu $SHELL_CONFIG:"
    echo ""
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Execute: source ~/.zshrc  (ou ~/.bash_profile)"
    else
        echo "Execute: source ~/.bashrc  (ou ~/.zshrc)"
    fi
else
    echo "→ Verificando PATH..."
    echo "  ✓ Diretório já está no PATH"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Shell Completion (Autocompletar)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Instalar autocompletar (tab completion)?"
echo "Permite usar TAB para completar comandos."
echo ""
read -p "Instalar agora? (s/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[SsYy]$ ]]; then
    echo ""
    echo "→ Instalando autocompletar..."
    if "$CLI_SOURCE_DIR/susa" self completion --install 2>&1 | grep -q "instalado em:"; then
        echo "  ✓ Autocompletar instalado"
        echo ""
        echo "  Nota: Reinicie o terminal ou execute 'source' no seu shell config"
    fi
else
    echo ""
    echo "  Você pode instalar depois com:"
    echo "  $CLI_NAME self completion --install"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Comandos Úteis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
