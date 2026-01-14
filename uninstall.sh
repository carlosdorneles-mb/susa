#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# =================
# CLI Uninstaller
# =================

CLI_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$CLI_SOURCE_DIR/core/cli.yaml"
CLI_NAME="susa"

# Detects the operating system
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macOS"
else
    OS_TYPE="Linux"
fi

INSTALL_DIR="$HOME/.local/bin"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Desinstalando Susa CLI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Remove completion using existing command
if [ -x "$CLI_SOURCE_DIR/core/susa" ]; then
    echo "→ Removendo autocompletar..."
    if "$CLI_SOURCE_DIR/core/susa" self completion --uninstall 2>&1 | grep -q "removido com sucesso"; then
        echo "  ✓ Autocompletar removido"
    fi
fi

# Remove the symbolic link
if [ -L "$INSTALL_DIR/$CLI_NAME" ]; then
    echo "→ Removendo executável..."
    rm "$INSTALL_DIR/$CLI_NAME"
    echo "  ✓ Executável removido"
else
    echo "→ Executável não encontrado em $INSTALL_DIR"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Susa CLI desinstalado com sucesso!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Nota: Reinicie o terminal para aplicar todas as mudanças"
echo ""
