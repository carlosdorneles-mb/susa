#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Setup command environment

source "$LIB_DIR/string.sh"
source "$LIB_DIR/internal/json.sh"
source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/internal/plugin.sh"

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

        # Validate item name
        if ! validate_name "$item_name"; then
            # Remove internal marker for display
            local display_source="${source%###DEV}"
            log_warning "Nome inválido ignorado: '$item_name' em '$category_path/' (fonte: $display_source)" >&2
            log_warning "  Use apenas letras minúsculas, números e hífens (ex: meu-comando)" >&2
            continue
        fi

        # Check if it's a command (has entrypoint field in command.json)
        if [ -f "$item_dir/command.json" ]; then
            local script_name=$(jq -r '.entrypoint // empty' "$item_dir/command.json" 2> /dev/null)

            if [ -n "$script_name" ] && [ -f "$item_dir/$script_name" ]; then
                # It's a command
                echo "COMMAND|$category_path|$item_name|$source"

                # Read additional metadata
                local display_name=$(jq -r '.name // empty' "$item_dir/command.json" 2> /dev/null)
                local description=$(jq -r '.description // empty' "$item_dir/command.json" 2> /dev/null)
                local script=$(jq -r '.entrypoint // empty' "$item_dir/command.json" 2> /dev/null)
                local os=$(jq -c '.os // empty' "$item_dir/command.json" 2> /dev/null)
                local sudo=$(jq -r '.sudo // empty' "$item_dir/command.json" 2> /dev/null)
                local group=$(jq -r '.group // empty' "$item_dir/command.json" 2> /dev/null)

                # Always output entrypoint (use default if not specified)
                if [ -z "$script" ]; then
                    script="main.sh"
                fi

                [ -n "$display_name" ] && echo "META|display_name|${display_name}"
                [ -n "$description" ] && echo "META|description|${description}"
                echo "META|entrypoint|${script}"
                [ -n "$os" ] && echo "META|os|${os}"
                [ -n "$sudo" ] && echo "META|sudo|${sudo}"
                [ -n "$group" ] && echo "META|group|${group}"
            else
                # It's a subcategory - check for category.json and register it
                if [ -f "$item_dir/category.json" ]; then
                    local subcat_desc=$(jq -r '.description // empty' "$item_dir/category.json" 2> /dev/null)
                    local subcat_entrypoint=$(jq -r '.entrypoint // empty' "$item_dir/category.json" 2> /dev/null)

                    if [ -n "$subcat_entrypoint" ] && [ "$subcat_entrypoint" != "" ]; then
                        echo "CATEGORY|$category_path/$item_name|$subcat_desc|$source|$subcat_entrypoint"
                    else
                        echo "CATEGORY|$category_path/$item_name|$subcat_desc|$source"
                    fi
                fi
                # Scan recursively
                scan_category_dir "$base_dir" "$category_path/$item_name" "$source"
            fi
        else
            # No command.json means it's a subcategory - check for category.json and register it
            if [ -f "$item_dir/category.json" ]; then
                local subcat_desc=$(jq -r '.description // empty' "$item_dir/category.json" 2> /dev/null)
                local subcat_entrypoint=$(jq -r '.entrypoint // empty' "$item_dir/category.json" 2> /dev/null)

                if [ -n "$subcat_entrypoint" ] && [ "$subcat_entrypoint" != "" ]; then
                    echo "CATEGORY|$category_path/$item_name|$subcat_desc|$source|$subcat_entrypoint"
                else
                    echo "CATEGORY|$category_path/$item_name|$subcat_desc|$source"
                fi
            fi
            # Scan recursively
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

            # Validate category name
            if ! validate_name "$cat_name"; then
                log_warning "Nome de categoria inválido ignorado: '$cat_name' (fonte: commands)" >&2
                log_warning "  Use apenas letras minúsculas, números e hífens (ex: minha-categoria)" >&2
                continue
            fi

            # Read category info
            if [ -f "$cat_dir/category.json" ]; then
                local cat_desc=$(jq -r '.description // empty' "$cat_dir/category.json" 2> /dev/null)
                local cat_entrypoint=$(jq -r '.entrypoint // empty' "$cat_dir/category.json" 2> /dev/null)

                if [ -n "$cat_entrypoint" ] && [ "$cat_entrypoint" != "" ]; then
                    echo "CATEGORY|$cat_name|$cat_desc|commands|$cat_entrypoint"
                else
                    echo "CATEGORY|$cat_name|$cat_desc|commands"
                fi
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
            [ "$plugin_name" = "registry.json" ] && continue
            [ "$plugin_name" = "README.md" ] && continue
            [ "$plugin_name" = ".gitkeep" ] && continue

            # Get the configured directory for plugin commands
            local commands_subdir=$(get_plugin_directory "$plugin_dir")
            local plugin_scan_dir="$plugin_dir"

            if [ -n "$commands_subdir" ]; then
                plugin_scan_dir="$plugin_dir/$commands_subdir"
            fi

            # Skip if the scan directory doesn't exist
            [ ! -d "$plugin_scan_dir" ] && continue

            # Scan each top-level category in the plugin
            for cat_dir in "$plugin_scan_dir"/*; do
                [ ! -d "$cat_dir" ] && continue
                local cat_name=$(basename "$cat_dir")

                # Validate category name
                if ! validate_name "$cat_name"; then
                    log_warning "Nome de categoria inválido ignorado: '$cat_name' (fonte: plugin '$plugin_name')" >&2
                    log_warning "  Use apenas letras minúsculas, números e hífens (ex: minha-categoria)" >&2
                    continue
                fi

                # Read category info
                if [ -f "$cat_dir/category.json" ]; then
                    local cat_desc=$(jq -r '.description // empty' "$cat_dir/category.json" 2> /dev/null)
                    local cat_entrypoint=$(jq -r '.entrypoint // empty' "$cat_dir/category.json" 2> /dev/null)

                    if [ -n "$cat_entrypoint" ] && [ "$cat_entrypoint" != "" ]; then
                        echo "CATEGORY|$cat_name|$cat_desc|$plugin_name|$cat_entrypoint"
                    else
                        echo "CATEGORY|$cat_name|$cat_desc|$plugin_name"
                    fi
                else
                    echo "CATEGORY|$cat_name||$plugin_name"
                fi

                # Scan category structure (use relative path from plugin_scan_dir)
                scan_category_dir "$plugin_scan_dir" "$cat_name" "$plugin_name"
            done
        done
    fi

    # Scan dev plugins from registry (plugins with local paths as source)
    local registry_file="$cli_dir/plugins/registry.json"
    if [ -f "$registry_file" ]; then
        # Get dev plugins (source is a local path and dev=true)
        local dev_plugins=$(jq -r '.plugins[] | select(.dev == true) | .name + "|" + .source // empty' "$registry_file" 2> /dev/null)

        while IFS='|' read -r plugin_name plugin_source; do
            [ -z "$plugin_name" ] && continue
            [ ! -d "$plugin_source" ] && continue

            # Get the configured directory for plugin commands
            local commands_subdir=$(get_plugin_directory "$plugin_source")
            local plugin_scan_dir="$plugin_source"

            if [ -n "$commands_subdir" ]; then
                plugin_scan_dir="$plugin_source/$commands_subdir"
            fi

            # Skip if the scan directory doesn't exist
            [ ! -d "$plugin_scan_dir" ] && continue

            # Scan each top-level category in the dev plugin
            for cat_dir in "$plugin_scan_dir"/*; do
                [ ! -d "$cat_dir" ] && continue
                local cat_name=$(basename "$cat_dir")

                # Skip non-category files
                [[ "$cat_name" =~ ^\. ]] && continue
                [ "$cat_name" = "README.md" ] && continue

                # Validate category name
                if ! validate_name "$cat_name"; then
                    log_warning "Nome de categoria inválido ignorado: '$cat_name' (fonte: dev plugin '$plugin_name')" >&2
                    log_warning "  Use apenas letras minúsculas, números e hífens (ex: minha-categoria)" >&2
                    continue
                fi

                # Read category info
                if [ -f "$cat_dir/category.json" ]; then
                    local cat_desc=$(jq -r '.description // empty' "$cat_dir/category.json" 2> /dev/null)
                    local cat_entrypoint=$(jq -r '.entrypoint // empty' "$cat_dir/category.json" 2> /dev/null)

                    if [ -n "$cat_entrypoint" ] && [ "$cat_entrypoint" != "" ]; then
                        echo "CATEGORY|$cat_name|$cat_desc|$plugin_name|$cat_entrypoint"
                    else
                        echo "CATEGORY|$cat_name|$cat_desc|$plugin_name"
                    fi
                else
                    echo "CATEGORY|$cat_name||$plugin_name"
                fi

                # Scan category structure - mark as dev (use relative path from plugin_scan_dir)
                scan_category_dir "$plugin_scan_dir" "$cat_name" "$plugin_name###DEV"
            done
        done <<< "$dev_plugins"
    fi
}

# Generates the susa.lock file
generate_lock_file() {
    local lock_file="$CLI_DIR/susa.lock"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local temp_installations="/tmp/susa_installations_backup_$$"

    # Backup existing installations section if lock file exists
    # Try to use cache first for better performance, fallback to direct file read
    if [ -f "$lock_file" ] && json_is_valid "$lock_file" 2> /dev/null; then
        log_debug "Fazendo backup da seção de instalações..."

        # Try cache first if available
        if cache_load 2> /dev/null; then
            local installations_json=$(cache_query '.installations' 2> /dev/null)
            if [ -n "$installations_json" ] && [ "$installations_json" != "null" ] && [ "$installations_json" != "[]" ]; then
                echo "$installations_json" > "$temp_installations"
                log_debug "Instalações obtidas do cache"
            else
                # Fallback to direct file read if cache doesn't have installations
                jq '.installations' "$lock_file" > "$temp_installations" 2> /dev/null
                log_debug "Instalações obtidas do arquivo de lock"
            fi
        else
            # Cache not available, read directly from file
            jq '.installations' "$lock_file" > "$temp_installations" 2> /dev/null
            log_debug "Instalações obtidas do arquivo de lock (cache indisponível)"
        fi
    fi

    # Change to CLI_DIR for consistent path resolution
    local original_dir="$PWD"
    cd "$CLI_DIR" || {
        log_error "Não foi possível acessar o diretório $CLI_DIR"
        rm -f "$temp_installations"
        return 1
    }

    local version=$(get_config_field "$GLOBAL_CONFIG_FILE" "version")
    [ -z "$version" ] && version="1.0.0"

    log_info "Gerando o lock..."

    # Scan and process structure
    local scan_output=$(scan_all_structure)

    # Initialize JSON structure
    local json_data='{}'
    json_data=$(echo "$json_data" | jq \
        --arg comment "Susa Lock File - This file contains the discovered commands and categories structure" \
        --arg generated "Do not edit manually - run 'susa self lock' to regenerate" \
        --arg version "$version" \
        --arg timestamp "$timestamp" \
        '. + {
            "_comment": $comment,
            "_generatedAt": $timestamp,
            "_note": $generated,
            "version": $version,
            "generatedAt": $timestamp,
            "categories": [],
            "plugins": [],
            "commands": []
        }')

    # First pass: process categories
    while IFS='|' read -r type field1 field2 field3 field4; do
        if [ "$type" = "CATEGORY" ]; then
            local cat_name="$field1"
            local cat_desc="$field2"
            local cat_source="$field3"
            local cat_entrypoint="$field4"

            # Build category JSON object
            local cat_obj=$(jq -n --arg name "$cat_name" '{name: $name}')

            # Add description if present
            if [ -n "$cat_desc" ] && [ "$cat_desc" != "" ]; then
                cat_obj=$(echo "$cat_obj" | jq --arg desc "$cat_desc" '. + {description: $desc}')
            fi

            # Add entrypoint if present
            if [ -n "$cat_entrypoint" ] && [ "$cat_entrypoint" != "" ]; then
                cat_obj=$(echo "$cat_obj" | jq --arg entry "$cat_entrypoint" '. + {entrypoint: $entry}')
            fi

            # Add category to JSON
            json_data=$(echo "$json_data" | jq --argjson cat "$cat_obj" '.categories += [$cat]')
        fi
    done <<< "$scan_output"

    # Add all plugins from registry to lock
    json_data=$(add_plugins_to_lock "$json_data")

    # Second pass: process commands
    local buffer=""
    local current_source=""
    local is_dev_plugin=false
    local cmd_obj=""

    while IFS='|' read -r type field1 field2 field3 field4; do
        if [ "$type" = "COMMAND" ]; then
            # If we have a buffered command, add it to JSON
            if [ -n "$cmd_obj" ]; then
                # Add plugin info if not from commands
                if [ "$current_source" != "commands" ]; then
                    local plugin_info=$(jq -n \
                        --arg name "$current_source" \
                        '{name: $name}')

                    # Add source path for all plugins
                    local registry_file="$CLI_DIR/plugins/registry.json"
                    local plugin_source_path=""

                    if [ "$is_dev_plugin" = true ]; then
                        # For dev plugins, get source from registry
                        plugin_source_path=$(jq -r ".plugins[] | select(.name == \"$current_source\" and .dev == true) | .source // empty" "$registry_file" 2> /dev/null | head -1)
                    else
                        # For installed plugins, use plugins directory
                        plugin_source_path="$CLI_DIR/plugins/$current_source"
                    fi

                    if [ -n "$plugin_source_path" ] && [ "$plugin_source_path" != "" ]; then
                        plugin_info=$(echo "$plugin_info" | jq --arg src "$plugin_source_path" '. + {source: $src}')
                    fi

                    cmd_obj=$(echo "$cmd_obj" | jq --argjson plugin "$plugin_info" '. + {plugin: $plugin}')

                    if [ "$is_dev_plugin" = true ]; then
                        cmd_obj=$(echo "$cmd_obj" | jq '. + {dev: true}')
                    fi
                fi

                json_data=$(echo "$json_data" | jq --argjson cmd "$cmd_obj" '.commands += [$cmd]')
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

            # Start new command object
            cmd_obj=$(jq -n \
                --arg category "$cmd_category" \
                --arg name "$cmd_name" \
                '{category: $category, name: $name}')

        elif [ "$type" = "META" ]; then
            local meta_key="$field1"
            local meta_value="$field2"

            # Convert snake_case keys to camelCase for JSON
            case "$meta_key" in
                display_name)
                    meta_key="displayName"
                    ;;
            esac

            # Add metadata to command object
            if [ -n "$meta_value" ] && [ "$meta_value" != "" ]; then
                # Handle array fields (os)
                if [ "$meta_key" = "os" ] && echo "$meta_value" | grep -q '^\['; then
                    # Value is already a JSON array, add it directly
                    cmd_obj=$(echo "$cmd_obj" | jq --argjson arr "$meta_value" --arg key "$meta_key" '.[$key] = $arr')
                else
                    cmd_obj=$(echo "$cmd_obj" | jq --arg key "$meta_key" --arg val "$meta_value" '.[$key] = $val')
                fi
            fi
        fi
    done <<< "$scan_output"

    # Write last buffered command
    if [ -n "$cmd_obj" ]; then
        # Add plugin info if not from commands
        if [ "$current_source" != "commands" ]; then
            local plugin_info=$(jq -n \
                --arg name "$current_source" \
                '{name: $name}')

            # Add source path for all plugins
            local registry_file="$CLI_DIR/plugins/registry.json"
            local plugin_source_path=""

            if [ "$is_dev_plugin" = true ]; then
                # For dev plugins, get source from registry
                plugin_source_path=$(jq -r ".plugins[] | select(.name == \"$current_source\" and .dev == true) | .source // empty" "$registry_file" 2> /dev/null | head -1)
            else
                # For installed plugins, use plugins directory
                plugin_source_path="$CLI_DIR/plugins/$current_source"
            fi

            if [ -n "$plugin_source_path" ] && [ "$plugin_source_path" != "" ]; then
                plugin_info=$(echo "$plugin_info" | jq --arg src "$plugin_source_path" '. + {source: $src}')
            fi

            cmd_obj=$(echo "$cmd_obj" | jq --argjson plugin "$plugin_info" '. + {plugin: $plugin}')

            if [ "$is_dev_plugin" = true ]; then
                cmd_obj=$(echo "$cmd_obj" | jq '. + {dev: true}')
            fi
        fi

        json_data=$(echo "$json_data" | jq --argjson cmd "$cmd_obj" '.commands += [$cmd]')
    fi

    # Restore installations section if it was backed up
    if [ -f "$temp_installations" ]; then
        log_debug "Restaurando seção de instalações..."
        local installations_data=$(cat "$temp_installations")
        json_data=$(echo "$json_data" | jq --argjson inst "$installations_data" '.installations = $inst')
        rm -f "$temp_installations"
    fi

    # Sort categories, plugins, and commands alphabetically
    # Keep "self" category always at the end
    log_debug "Ordenando categorias, plugins e comandos alfabeticamente..."
    json_data=$(echo "$json_data" | jq '
        .categories |= (
            map(select(.name != "self")) | sort_by(.name)
        ) + (
            map(select(.name == "self"))
        ) |
        .plugins |= sort_by(.name) |
        .commands |= (
            map(select(.category != "self")) | sort_by(.category, .name)
        ) + (
            map(select(.category == "self")) | sort_by(.name)
        )
    ')

    # Write JSON to lock file with pretty printing
    echo "$json_data" | jq '.' > "$lock_file"

    log_success "Lock gerado com sucesso!"

    # Refresh cache after updating lock file
    cache_refresh 2> /dev/null || true

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
