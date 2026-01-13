#!/bin/bash
set -euo pipefail

# Setup command environment
setup_command_env

source "$LIB_DIR/logger.sh"
source "$LIB_DIR/yaml.sh"

# ============================================================
# Help Function
# ============================================================

show_help() {
    show_description
    echo ""
    show_usage --no-options
    echo ""
    echo -e "${LIGHT_GREEN}Descrição:${NC}"
    echo "  Este comando varre os diretórios 'commands/' e 'plugins/' para"
    echo "  descobrir todas as categorias, subcategorias e comandos disponíveis,"
    echo "  gerando um arquivo de cache (susa.lock) que acelera a inicialização"
    echo "  do CLI em aproximadamente 38%."
    echo ""
    echo -e "${LIGHT_GREEN}Quando executar:${NC}"
    echo "  • Após adicionar novos comandos manualmente em 'commands/'"
    echo "  • Após modificar a estrutura de categorias"
    echo "  • Se o arquivo susa.lock foi deletado ou corrompido"
    echo ""
    echo -e "${LIGHT_GREEN}Nota:${NC}"
    echo "  O arquivo é atualizado automaticamente ao instalar, remover ou"
    echo "  atualizar plugins. Na maioria dos casos, você não precisará"
    echo "  executar este comando manualmente."
}

# ============================================================
# Functions
# ============================================================

# Scans a category directory and returns its structure
scan_category_dir() {
    local base_dir="$1"
    local category_path="$2"
    local full_path="$base_dir/$category_path"

    if [ ! -d "$full_path" ]; then
        return 0
    fi

    local result=""

    # List items in the category
    for item_dir in "$full_path"/*; do
        [ ! -d "$item_dir" ] && continue

        local item_name=$(basename "$item_dir")

        # Check if it's a command (has script field in config.yaml)
        if [ -f "$item_dir/config.yaml" ]; then
            local script_name=$(yq eval '.script' "$item_dir/config.yaml" 2>/dev/null)

            if [ -n "$script_name" ] && [ "$script_name" != "null" ] && [ -f "$item_dir/$script_name" ]; then
                # It's a command
                echo "COMMAND|$category_path|$item_name"

                # Read additional metadata
                local description=$(yq eval '.description' "$item_dir/config.yaml" 2>/dev/null)
                local os=$(yq eval '.os' "$item_dir/config.yaml" 2>/dev/null)
                local sudo=$(yq eval '.sudo' "$item_dir/config.yaml" 2>/dev/null)
                local group=$(yq eval '.group' "$item_dir/config.yaml" 2>/dev/null)

                [ "$description" != "null" ] && echo "META|description|${description}"
                [ "$os" != "null" ] && echo "META|os|${os}"
                [ "$sudo" != "null" ] && echo "META|sudo|${sudo}"
                [ "$group" != "null" ] && echo "META|group|${group}"
            else
                # It's a subcategory - scan recursively
                scan_category_dir "$base_dir" "$category_path/$item_name"
            fi
        else
            # No config.yaml means it's a subcategory
            scan_category_dir "$base_dir" "$category_path/$item_name"
        fi
    done
}

# Scans all categories and commands
scan_all_structure() {
    local cli_dir="${CLI_DIR}"
    local commands_dir="${cli_dir}/commands"
    local plugins_dir="${cli_dir}/plugins"

    # Scan commands/
    if [ -d "$commands_dir" ]; then
        for cat_dir in "$commands_dir"/*; do
            [ ! -d "$cat_dir" ] && continue
            local cat_name=$(basename "$cat_dir")

            # Read category info
            if [ -f "$cat_dir/config.yaml" ]; then
                local cat_desc=$(yq eval '.description' "$cat_dir/config.yaml" 2>/dev/null)
                echo "CATEGORY|$cat_name|$cat_desc|commands"
            else
                echo "CATEGORY|$cat_name||commands"
            fi

            # Scan category structure
            scan_category_dir "$commands_dir" "$cat_name"
        done
    fi

    # Scan plugins/
    if [ -d "$plugins_dir" ]; then
        for plugin_dir in "$plugins_dir"/*; do
            [ ! -d "$plugin_dir" ] && continue
            local plugin_name=$(basename "$plugin_dir")

            # Ignore special files
            [ "$plugin_name" = "registry.yaml" ] && continue
            [ "$plugin_name" = "README.md" ] && continue

            # Scan each top-level category in the plugin
            for cat_dir in "$plugin_dir"/*; do
                [ ! -d "$cat_dir" ] && continue
                local cat_name=$(basename "$cat_dir")

                # Read category info
                if [ -f "$cat_dir/config.yaml" ]; then
                    local cat_desc=$(yq eval '.description' "$cat_dir/config.yaml" 2>/dev/null)
                    echo "CATEGORY|$cat_name|$cat_desc|$plugin_name"
                else
                    echo "CATEGORY|$cat_name||$plugin_name"
                fi

                # Scan category structure
                scan_category_dir "$plugin_dir" "$cat_name"
            done
        done
    fi
}

# Generates the susa.lock file
generate_lock_file() {
    local lock_file="$CLI_DIR/susa.lock"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local version=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "version")

    log_info "Gerando arquivo susa.lock..."

    # Create lock file header
    cat > "$lock_file" << EOF
# Susa Lock File
# This file contains the discovered commands and categories structure
# Generated at: $timestamp
# Do not edit manually - run 'susa self lock' to regenerate

version: "$version"
generated_at: "$timestamp"

categories:
EOF

    # Scan and process structure
    local scan_output=$(scan_all_structure)

    # First pass: process categories
    while IFS='|' read -r type field1 field2 field3 field4; do
        if [ "$type" = "CATEGORY" ]; then
            local cat_name="$field1"
            local cat_desc="$field2"
            local cat_source="$field3"

            # Add category to lock file
            echo "  - name: \"$cat_name\"" >> "$lock_file"
            [ -n "$cat_desc" ] && echo "    description: \"$cat_desc\"" >> "$lock_file"
            echo "    source: \"$cat_source\"" >> "$lock_file"
        fi
    done <<< "$scan_output"

    # Add commands section
    echo "" >> "$lock_file"
    echo "commands:" >> "$lock_file"

    # Second pass: process commands
    local current_command=""
    while IFS='|' read -r type field1 field2 field3 field4; do
        if [ "$type" = "COMMAND" ]; then
            local cmd_category="$field1"
            local cmd_name="$field2"

            current_command="$cmd_name"

            # Add command to commands section
            echo "  - category: \"$cmd_category\"" >> "$lock_file"
            echo "    name: \"$cmd_name\"" >> "$lock_file"

        elif [ "$type" = "META" ]; then
            local meta_key="$field1"
            local meta_value="$field2"

            # Add metadata to current command
            if [ -n "$meta_value" ] && [ "$meta_value" != "null" ]; then
                # Handle array fields (os)
                if [ "$meta_key" = "os" ] && echo "$meta_value" | grep -q '^\['; then
                    # Convert to YAML array format
                    echo "    $meta_key: $meta_value" >> "$lock_file"
                else
                    echo "    $meta_key: \"$meta_value\"" >> "$lock_file"
                fi
            fi
        fi
    done <<< "$scan_output"

    log_success "Arquivo susa.lock gerado com sucesso!"
    log_debug "Localização: $lock_file"
}

# ============================================================
# Main
# ============================================================

main() {
    # Check for help flag
    if [ $# -gt 0 ] && ([ "$1" = "--help" ] || [ "$1" = "-h" ]); then
        show_help
        exit 0
    fi

    generate_lock_file
}

main "$@"
