#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Setup command environment

source "$LIB_DIR/logger.sh"
source "$LIB_DIR/internal/yaml.sh"
source "$LIB_DIR/internal/installations.sh"

# ============================================================
# Help Function
# ============================================================

show_help() {
    show_description
    log_output ""
    show_usage --no-options
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  --sync            Sincroniza instalações: verifica aplicações instaladas"
    log_output "                    no sistema e atualiza o lock file:"
    log_output "                    • Adiciona novas instalações ao lock"
    log_output "                    • Remove instalações que foram desinstaladas"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output ""
    log_output "${LIGHT_GREEN}Descrição:${NC}"
    log_output "  Este comando varre os diretórios 'commands/' e 'plugins/' para"
    log_output "  descobrir todas as categorias, subcategorias e comandos disponíveis,"
    log_output "  gerando um arquivo de cache (susa.lock) que acelera a inicialização"
    log_output "  do CLI em aproximadamente 38%."
    log_output ""
    log_output "${LIGHT_GREEN}Quando executar:${NC}"
    log_output "  • Após adicionar novos comandos manualmente em 'commands/'"
    log_output "  • Após modificar a estrutura de categorias"
    log_output "  • Se o arquivo susa.lock foi deletado ou corrompido"
    log_output "  • Use --sync após instalar/desinstalar aplicações manualmente fora do susa"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa self lock              # Regenera o arquivo de lock"
    log_output "  susa self lock --sync       # Regenera e sincroniza instalações"
    log_output ""
    log_output "${LIGHT_GREEN}Nota:${NC}"
    log_output "  O arquivo é atualizado automaticamente ao instalar, remover ou"
    log_output "  atualizar plugins. Na maioria dos casos, você não precisará"
    log_output "  executar este comando manualmente."
}

# ============================================================
# Functions
# ============================================================

# Scans a category directory and returns its structure
scan_category_dir() {
    local base_dir="$1"
    local category_path="$2"
    local source="$3" # 'commands' or plugin name
    local full_path="$base_dir/$category_path"

    if [ ! -d "$full_path" ]; then
        return 0
    fi

    local result=""

    # List items in the category
    for item_dir in "$full_path"/*; do
        [ ! -d "$item_dir" ] && continue

        local item_name=$(basename "$item_dir")

        # Check if it's a command (has entrypoint field in config.yaml)
        if [ -f "$item_dir/config.yaml" ]; then
            local script_name=$(yq eval '.entrypoint' "$item_dir/config.yaml" 2>/dev/null)

            if [ -n "$script_name" ] && [ "$script_name" != "null" ] && [ -f "$item_dir/$script_name" ]; then
                # It's a command
                echo "COMMAND|$category_path|$item_name|$source"

                # Read additional metadata
                local description=$(yq eval '.description' "$item_dir/config.yaml" 2>/dev/null)
                local script=$(yq eval '.entrypoint' "$item_dir/config.yaml" 2>/dev/null)
                local os=$(yq eval '.os' "$item_dir/config.yaml" 2>/dev/null)
                local sudo=$(yq eval '.sudo' "$item_dir/config.yaml" 2>/dev/null)
                local group=$(yq eval '.group' "$item_dir/config.yaml" 2>/dev/null)

                # Always output entrypoint (use default if not specified)
                if [ -z "$script" ] || [ "$script" = "null" ]; then
                    script="main.sh"
                fi

                [ "$description" != "null" ] && echo "META|description|${description}"
                echo "META|entrypoint|${script}"
                [ "$os" != "null" ] && echo "META|os|${os}"
                [ "$sudo" != "null" ] && echo "META|sudo|${sudo}"
                [ "$group" != "null" ] && echo "META|group|${group}"
            else
                # It's a subcategory - scan recursively
                scan_category_dir "$base_dir" "$category_path/$item_name" "$source"
            fi
        else
            # No config.yaml means it's a subcategory
            scan_category_dir "$base_dir" "$category_path/$item_name" "$source"
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
            scan_category_dir "$commands_dir" "$cat_name" "commands"
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
            [ "$plugin_name" = ".gitkeep" ] && continue

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
                scan_category_dir "$plugin_dir" "$cat_name" "$plugin_name"
            done
        done
    fi

    # Scan dev plugins from registry (plugins with local paths as source)
    local registry_file="$cli_dir/plugins/registry.yaml"
    if [ -f "$registry_file" ]; then
        # Get dev plugins (source is a local path and dev=true)
        local dev_plugins=$(yq eval '.plugins[] | select(.dev == true) | .name + "|" + .source' "$registry_file" 2>/dev/null)

        while IFS='|' read -r plugin_name plugin_source; do
            [ -z "$plugin_name" ] && continue
            [ ! -d "$plugin_source" ] && continue

            # Scan each top-level category in the dev plugin
            for cat_dir in "$plugin_source"/*; do
                [ ! -d "$cat_dir" ] && continue
                local cat_name=$(basename "$cat_dir")

                # Skip non-category files
                [[ "$cat_name" =~ ^\. ]] && continue
                [ "$cat_name" = "README.md" ] && continue

                # Read category info
                if [ -f "$cat_dir/config.yaml" ]; then
                    local cat_desc=$(yq eval '.description' "$cat_dir/config.yaml" 2>/dev/null)
                    echo "CATEGORY|$cat_name|$cat_desc|$plugin_name"
                else
                    echo "CATEGORY|$cat_name||$plugin_name"
                fi

                # Scan category structure - mark as dev
                scan_category_dir "$plugin_source" "$cat_name" "$plugin_name###DEV"
            done
        done <<<"$dev_plugins"
    fi
}

# Generates the susa.lock file
generate_lock_file() {
    local lock_file="$CLI_DIR/susa.lock"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local temp_installations="/tmp/susa_installations_backup_$$"

    # Backup existing installations section if lock file exists
    if [ -f "$lock_file" ] && yq eval '.installations' "$lock_file" &>/dev/null; then
        local has_installations=$(yq eval '.installations | length' "$lock_file" 2>/dev/null)
        if [ "$has_installations" != "0" ] && [ "$has_installations" != "null" ]; then
            log_debug "Fazendo backup da seção de instalações..."
            yq eval '.installations' "$lock_file" >"$temp_installations" 2>/dev/null
        fi
    fi

    # Change to CLI_DIR for consistent path resolution
    local original_dir="$PWD"
    cd "$CLI_DIR" || {
        log_error "Não foi possível acessar o diretório $CLI_DIR"
        rm -f "$temp_installations"
        return 1
    }

    local version=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "version")

    log_info "Gerando arquivo susa.lock..."

    # Create lock file header
    cat >"$lock_file" <<EOF
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
            echo "  - name: \"$cat_name\"" >>"$lock_file"
            [ -n "$cat_desc" ] && echo "    description: \"$cat_desc\"" >>"$lock_file"
            echo "    source: \"$cat_source\"" >>"$lock_file"
        fi
    done <<<"$scan_output"

    # Add commands section
    echo "" >>"$lock_file"
    echo "commands:" >>"$lock_file"

    # Second pass: process commands with buffering
    local buffer=""
    local current_source=""
    local is_dev_plugin=false
    while IFS='|' read -r type field1 field2 field3 field4; do
        if [ "$type" = "COMMAND" ]; then
            # If we have a buffer, write it out with plugin info if needed
            if [ -n "$buffer" ]; then
                echo "$buffer" >>"$lock_file"
                if [ "$current_source" != "commands" ]; then
                    # Add dev flag if it's a dev plugin
                    if [ "$is_dev_plugin" = true ]; then
                        echo "    dev: true" >>"$lock_file"
                    fi
                    echo "    plugin:" >>"$lock_file"
                    echo "      name: \"$current_source\"" >>"$lock_file"

                    # Add source path for all plugins
                    local registry_file="$CLI_DIR/plugins/registry.yaml"
                    local plugin_source=""

                    if [ "$is_dev_plugin" = true ]; then
                        # For dev plugins, get source from registry
                        plugin_source=$(yq eval ".plugins[] | select(.name == \"$current_source\" and .dev == true) | .source" "$registry_file" 2>/dev/null | head -1)
                    else
                        # For installed plugins, use plugins directory
                        plugin_source="$CLI_DIR/plugins/$current_source"
                    fi

                    if [ -n "$plugin_source" ] && [ "$plugin_source" != "null" ]; then
                        echo "      source: \"$plugin_source\"" >>"$lock_file"
                    fi
                fi
            fi

            local cmd_category="$field1"
            local cmd_name="$field2"
            local source_with_marker="$field3"

            # Check if this is a dev plugin (source contains ###DEV marker)
            if [[ "$source_with_marker" == *"###DEV" ]]; then
                current_source="${source_with_marker%###DEV}"
                is_dev_plugin=true
            else
                current_source="$source_with_marker"
                is_dev_plugin=false
            fi

            # Start new buffer
            buffer="  - category: \"$cmd_category\"
    name: \"$cmd_name\""

        elif [ "$type" = "META" ]; then
            local meta_key="$field1"
            local meta_value="$field2"

            # Add metadata to buffer
            if [ -n "$meta_value" ] && [ "$meta_value" != "null" ]; then
                # Handle array fields (os)
                if [ "$meta_key" = "os" ] && echo "$meta_value" | grep -q '^\['; then
                    # Convert to YAML array format
                    buffer="$buffer
    $meta_key: $meta_value"
                else
                    buffer="$buffer
    $meta_key: \"$meta_value\""
                fi
            fi
        fi
    done <<<"$scan_output"

    # Write last buffered command
    if [ -n "$buffer" ]; then
        echo "$buffer" >>"$lock_file"
        if [ "$current_source" != "commands" ]; then
            # Add dev flag if it's a dev plugin
            if [ "$is_dev_plugin" = true ]; then
                echo "    dev: true" >>"$lock_file"
            fi
            echo "    plugin:" >>"$lock_file"
            echo "      name: \"$current_source\"" >>"$lock_file"

            # Add source path for all plugins
            local registry_file="$CLI_DIR/plugins/registry.yaml"
            local plugin_source=""

            if [ "$is_dev_plugin" = true ]; then
                # For dev plugins, get source from registry
                plugin_source=$(yq eval ".plugins[] | select(.name == \"$current_source\" and .dev == true) | .source" "$registry_file" 2>/dev/null | head -1)
            else
                # For installed plugins, use plugins directory
                plugin_source="$CLI_DIR/plugins/$current_source"
            fi

            if [ -n "$plugin_source" ] && [ "$plugin_source" != "null" ]; then
                echo "      source: \"$plugin_source\"" >>"$lock_file"
            fi
        fi
    fi

    # Restore installations section if it was backed up
    if [ -f "$temp_installations" ]; then
        log_debug "Restaurando seção de instalações..."
        echo "" >>"$lock_file"
        echo "installations:" >>"$lock_file"
        # Indent the installations content
        sed 's/^/  /' "$temp_installations" >>"$lock_file"
        rm -f "$temp_installations"
    fi

    log_success "Arquivo susa.lock gerado com sucesso!"
    log_debug "Localização: $lock_file"

    # Return to original directory
    cd "$original_dir" || true
}

# ============================================================
# Main
# ============================================================

main() {
    local should_sync=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                show_help
                exit 0
                ;;
            -v | --verbose)
                export DEBUG=1
                log_debug "Modo verbose ativado"
                shift
                ;;
            -q | --quiet)
                export SILENT=1
                shift
                ;;
            --sync)
                should_sync=true
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                echo "Use 'susa self lock --help' para ver as opções disponíveis"
                exit 1
                ;;
        esac
    done

    # Generate lock file first
    generate_lock_file

    # Sync installations if requested
    if [ "$should_sync" = true ]; then
        echo ""
        log_info "Sincronizando instalações..."
        sync_installations || {
            log_error "Falha ao sincronizar instalações"
            return 1
        }
    fi
}

main "$@"
