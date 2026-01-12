#!/bin/bash

# ============================================================
# Instalador do CLI
# ============================================================

set -e

CLI_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$CLI_SOURCE_DIR/cli.yaml"

# Carrega a biblioteca YAML
source "$CLI_SOURCE_DIR/lib/yaml.sh"

# Lê o nome do CLI do arquivo de configuração
CLI_NAME=$(get_yaml_field "$CONFIG_FILE" "command")
if [ -z "$CLI_NAME" ]; then
    CLI_NAME="cli"
fi

# Detecta o sistema operacional e define o diretório de instalação
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

# Cria diretório de instalação se não existir
if [ ! -d "$INSTALL_DIR" ]; then
    echo "→ Criando diretório $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
fi

# Cria symlink para o CLI
echo "→ Criando link simbólico..."
ln -sf "$CLI_SOURCE_DIR/susa" "$INSTALL_DIR/$CLI_NAME"

# Verifica se o diretório está no PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo "⚠  ATENÇÃO: $INSTALL_DIR não está no seu PATH"
    echo ""
    echo "Adicione a seguinte linha ao seu $SHELL_CONFIG:"
    echo ""
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Depois execute: source ~/.zshrc  (ou ~/.bash_profile)"
    else
        echo "Depois execute: source ~/.bashrc  (ou ~/.zshrc)"
    fi
    echo ""
else
    echo "✓ Diretório já está no PATH"
fi

echo ""
echo "✓ Instalação concluída!"
echo ""

# Oferece instalar completion
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Shell Completion (Autocompletar)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Deseja instalar o autocompletar (tab completion)?"
echo "Isso permite usar TAB para completar comandos automaticamente."
echo ""
read -p "Instalar completion? (s/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[SsYy]$ ]]; then
    echo ""
    echo "→ Instalando completion..."
    "$CLI_SOURCE_DIR/susa" self completion --install
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Uso:"
echo "  $CLI_NAME <categoria> <comando> [opções]"
echo ""
echo "Exemplos:"
echo "  $CLI_NAME setup docker"
echo "  $CLI_NAME self version"
echo "  $CLI_NAME self plugin list"
echo ""
echo "Para instalar completion depois:"
echo "  $CLI_NAME self completion --install"
echo ""
echo "Para ver a ajuda completa:"
echo "  $CLI_NAME --help"
echo ""
