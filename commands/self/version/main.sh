#!/bin/bash

# Obtém o diretório do CLI
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
GLOBAL_CONFIG_FILE="$CLI_DIR/cli.yaml"

# Source libs
source "$CLI_DIR/lib/color.sh"
source "$CLI_DIR/lib/yaml.sh"

# Mostra a versão
name=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "name")
version=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "version")
echo -e "${BOLD}$name${NC} (version ${GRAY}$version${NC})"
