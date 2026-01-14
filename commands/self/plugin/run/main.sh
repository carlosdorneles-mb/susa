#!/bin/bash
set -euo pipefail

setup_command_env

# Source required libraries
source "$LIB_DIR/registry.sh"
source "$LIB_DIR/plugin.sh"

# Check if command exists in lock file
# Returns: "found:is_dev" or "not_found"
check_command_in_lock() {
    local plugin_name="$1"
    local category="$2"
    local command="$3"

    if ! has_valid_lock_file; then
        log_debug "[check_command_in_lock] Lock file não disponível" >&2
        echo "not_found"
        return 1
    fi

    local lock_file="$CLI_DIR/susa.lock"

    # Check if command exists with this plugin
    local command_exists=$(yq eval ".commands[] | select(.category == \"$category\" and .name == \"$command\" and .plugin.name == \"$plugin_name\") | .name" "$lock_file" 2>/dev/null | head -1)

    if [ -z "$command_exists" ] || [ "$command_exists" = "null" ]; then
        log_debug "[check_command_in_lock] Comando não encontrado" >&2
        echo "not_found"
        return 1
    fi

    # Check if it's a dev plugin
    local is_dev=$(yq eval ".commands[] | select(.category == \"$category\" and .name == \"$command\" and .plugin.name == \"$plugin_name\") | .dev" "$lock_file" 2>/dev/null | head -1)

    if [ "$is_dev" = "true" ]; then
        log_debug "[check_command_in_lock] Encontrado (modo dev)" >&2
        echo "found:true"
    else
        log_debug "[check_command_in_lock] Encontrado (instalado)" >&2
        echo "found:false"
    fi

    return 0
}

# Get command information from lock file
# Returns: script_path or empty
get_command_script_from_lock() {
    local plugin_name="$1"
    local category="$2"
    local command="$3"

    local lock_file="$CLI_DIR/susa.lock"

    # Get entrypoint name from lock
    local script_name=$(yq eval ".commands[] | select(.category == \"$category\" and .name == \"$command\" and .plugin.name == \"$plugin_name\") | .entrypoint" "$lock_file" 2>/dev/null | head -1)

    if [ -z "$script_name" ] || [ "$script_name" = "null" ]; then
        script_name="main.sh"
    fi

    # Get plugin directory
    local plugin_dir=""
    local is_dev=$(yq eval ".commands[] | select(.category == \"$category\" and .name == \"$command\" and .plugin.name == \"$plugin_name\") | .dev" "$lock_file" 2>/dev/null | head -1)

    if [ "$is_dev" = "true" ]; then
        # For dev plugins, get source from registry
        local registry_file="$PLUGINS_DIR/registry.yaml"
        plugin_dir=$(yq eval ".plugins[] | select(.name == \"$plugin_name\" and .dev == true) | .source" "$registry_file" 2>/dev/null | head -1)
    else
        # For installed plugins, use standard directory
        plugin_dir="$PLUGINS_DIR/$plugin_name"
    fi

    if [ -z "$plugin_dir" ]; then
        log_error "[get_command_script_from_lock] Não foi possível determinar o diretório do plugin" >&2
        return 1
    fi

    local script_path="$plugin_dir/$category/$command/$script_name"

    if [ ! -f "$script_path" ]; then
        log_error "[get_command_script_from_lock] Script não encontrado: $script_path" >&2
        return 1
    fi

    log_debug "[get_command_script_from_lock] ✓ Script: $script_path" >&2
    echo "$script_path"
    return 0
}

# Try to add dev plugin from current directory
try_add_dev_plugin() {
    local plugin_name="$1"
    local current_dir="$PWD"

    log_debug "[try_add_dev_plugin] Verificando estrutura em: $current_dir" >&2

    # Check if current directory structure looks like a plugin
    local found_configs=$(find "$current_dir" -mindepth 2 -maxdepth 2 -type f -name "config.yaml" 2>/dev/null | head -1)

    if [ -z "$found_configs" ]; then
        log_debug "[try_add_dev_plugin] ✗ Estrutura de plugin não encontrada" >&2
        return 1
    fi

    log_debug "[try_add_dev_plugin] ✓ Estrutura válida, adicionando ao registry/lock" >&2

    # Add to registry
    add_dev_plugin_to_registry "$current_dir" "$plugin_name"

    # Regenerate lock file (will include the dev plugin just added to registry)
    regenerate_lock

    return 0
}

# Add dev plugin to registry
add_dev_plugin_to_registry() {
    local plugin_dir="$1"
    local plugin_name="$2"
    local registry_file="$PLUGINS_DIR/registry.yaml"

    # Get version from plugin
    local version=$(detect_plugin_version "$plugin_dir")
    if [ -z "$version" ] || [ "$version" = "0.0.0" ]; then
        version="dev"
    fi

    # Count commands and get categories
    local cmd_count=$(count_plugin_commands "$plugin_dir")
    local categories=$(get_plugin_categories "$plugin_dir")

    log_debug "[add_dev_plugin_to_registry] Adicionando: $plugin_name (v$version)" >&2

    # Use PWD as source for dev plugins and mark as dev
    registry_add_plugin "$registry_file" "$plugin_name" "$plugin_dir" "$version" "true" "$cmd_count" "$categories"
}

# Remove dev plugin from registry
remove_dev_plugin_from_registry() {
    local plugin_name="$1"
    local registry_file="$PLUGINS_DIR/registry.yaml"

    log_debug "[remove_dev_plugin_from_registry] Removendo: $plugin_name" >&2

    # Remove the plugin entry by source path
    yq eval -i "del(.plugins[] | select(.name == \"$plugin_name\" and .dev == true))" "$registry_file" 2>/dev/null || true
}

# Regenerate lock file
# Note: This regenerates the lock based on current registry state
# - If dev plugin is in registry, lock will include it
# - If dev plugin was removed from registry, lock won't include it
regenerate_lock() {
    log_debug "[regenerate_lock] Regenerando susa.lock" >&2

    # Call through the main susa command to ensure proper environment setup
    "$CORE_DIR/susa" self lock >/dev/null 2>&1
}

# Cleanup dev plugin after execution
cleanup_dev_plugin() {
    local plugin_name="$1"

    log_debug "[cleanup_dev_plugin] Limpando: $plugin_name" >&2

    # Remove from registry first
    remove_dev_plugin_from_registry "$plugin_name"

    # Then regenerate lock (will NOT include the dev plugin anymore)
    regenerate_lock
}

# Help function
show_help() {
    show_description
    echo ""
    show_usage
    echo ""
    echo -e "${LIGHT_GREEN}O que faz:${NC}"
    echo "  Executa um plugin instalado ou em modo de desenvolvimento."
    echo "  Útil para testar plugins durante o desenvolvimento sem instalá-los."
    echo ""
    echo -e "${LIGHT_GREEN}Ordem de busca:${NC}"
    echo "  1. Busca comando no susa.lock (plugins instalados)"
    echo "  2. Se não encontrar, tenta adicionar do diretório atual (modo dev)"
    echo "  3. Busca novamente no susa.lock após atualização"
    echo ""
    echo -e "${LIGHT_GREEN}Argumentos:${NC}"
    echo "  plugin-name       Nome do plugin a ser executado"
    echo "  category          Categoria do comando no plugin"
    echo "                    Use barras (/) para subcategorias: category/subcat"
    echo "  command           Comando a ser executado"
    echo "  [args...]         Argumentos adicionais para o comando"
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  -h, --help        Mostra esta mensagem de ajuda"
    echo "  -v, --verbose     Habilita saída detalhada para depuração"
    echo "  --prepare         Apenas adiciona plugin ao registry/lock sem executar"
    echo "  --cleanup         Apenas remove plugin dev do registry/lock"
    echo "  --                Separa opções do run de argumentos do plugin"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo "  # Executar comando de plugin instalado"
    echo "  susa self plugin run my-plugin text hello"
    echo ""
    echo "  # Executar comando em subcategoria"
    echo "  susa self plugin run my-plugin text/examples hello"
    echo ""
    echo "  # Executar plugin em desenvolvimento no diretório atual"
    echo "  cd ~/meu-plugin"
    echo "  susa self plugin run meu-plugin text comando"
    echo ""
	echo "  # Passar argumentos do plugin que conflitam com opções do run"
    echo "  susa self plugin run my-plugin text hello -- --help --verbose"
	echo ""
    echo "  # Apenas preparar plugin dev (adicionar ao registry/lock)"
    echo "  cd ~/meu-plugin"
    echo "  susa self plugin run --prepare meu-plugin text comando"
    echo ""
    echo "  # Remover plugin dev do registry/lock"
    echo "  susa self plugin run --cleanup meu-plugin text comando"
    echo ""
    echo -e "${LIGHT_GREEN}Modo de desenvolvimento:${NC}"
    echo "  Para testar um plugin em desenvolvimento:"
    echo ""
    echo -e "  ${BOLD}Modo automático (com cleanup):${NC}"
    echo "  1. Navegue até o diretório do plugin"
    echo "  2. Execute: susa self plugin run <plugin-name> <category> <command>"
    echo "  3. O plugin será temporariamente adicionado ao lock"
    echo "  4. Após execução, será automaticamente removido"
    echo ""
    echo -e "  ${BOLD}Modo manual (sem cleanup automático):${NC}"
    echo "  1. susa self plugin run --prepare meu-plugin text cmd    # Adiciona ao lock"
    echo "  2. susa meu-plugin text cmd                              # Executa normalmente"
    echo "  3. susa meu-plugin text outro-cmd                        # Executa outro comando"
    echo "  4. susa self plugin run --cleanup meu-plugin text cmd    # Remove do lock"
    echo ""
    echo -e "${LIGHT_GREEN}Estrutura esperada do plugin:${NC}"
    echo "  plugin-name/"
    echo "    .version              # Versão do plugin (ou version.txt)"
    echo "    categoria1/"
    echo "      config.yaml         # Configuração da categoria"
    echo "      comando1/"
    echo "        config.yaml       # Configuração do comando"
    echo "        main.sh           # Script do comando"
    echo "      subcategoria/       # Subcategorias (acessadas com /)"
    echo "        config.yaml"
    echo "        comando2/"
    echo "          config.yaml"
    echo "          main.sh"
    echo "    categoria2/           # Múltiplas categorias"
    echo "      config.yaml"
    echo "      ..."
    echo ""
    echo -e "${LIGHT_GREEN}Uso de Subcategorias:${NC}"
    echo "  Para comandos em subcategorias, use barra (/) para indicar a hierarquia:"
    echo ""
    echo "  Estrutura:"
    echo "    plugin/categoria/subcategoria/comando/"
    echo ""
    echo "  Execução:"
    echo "    susa self plugin run plugin-name categoria/subcategoria comando"
    echo ""
    echo "  Exemplo:"
    echo "    susa self plugin run tools database/admin migrate"
}

# Execute plugin command
execute_plugin_command() {
    local script_path="$1"
    local plugin_name="$2"
    local category="$3"
    shift 3
    local args=("$@")

    log_debug "[execute_plugin_command] Executando: $script_path" >&2

    # Get plugin directory from script path
    local plugin_dir=$(dirname $(dirname $(dirname "$script_path")))

    # Setup plugin environment
    export PLUGIN_DIR="$plugin_dir"
    export PLUGIN_CATEGORY="$category"

    # Check if help was requested
    for arg in "${args[@]}"; do
        if [[ "$arg" =~ ^(-h|--help|help)$ ]]; then
            # Source the script to access show_help function if it exists
            (
                source "$script_path" --help 2>/dev/null || cat "$script_path" | grep -A 50 "show_help()" | head -60
            )
            return 0
        fi
    done

    # Execute the command script
    source "$script_path" "${args[@]}"
    local exit_code=$?

    log_debug "[execute_plugin_command] Exit code: $exit_code" >&2
    return $exit_code
}

# Run plugin command - main orchestration
run_plugin_command() {
    local plugin_name="$1"
    local category="$2"
    local command="$3"
    local mode="${4:-execute}"  # execute, prepare, cleanup
    shift 3
    # Skip mode parameter if present
    if [[ "$1" == "prepare" ]] || [[ "$1" == "cleanup" ]] || [[ "$1" == "execute" ]]; then
        shift
    fi
    local args=("$@")

    # Mode: cleanup only
    if [ "$mode" = "cleanup" ]; then
        log_debug "=== MODO: CLEANUP ===" >&2
        log_info "Removendo plugin dev: $plugin_name"
        cleanup_dev_plugin "$plugin_name"
        log_success "Plugin dev removido do registry e lock"
        return 0
    fi

    # Step 1: Check if command exists in lock
    log_debug "=== Verificando comando no lock ===" >&2
    local check_result=$(check_command_in_lock "$plugin_name" "$category" "$command")

    local is_dev_plugin=false

    # Step 2: If not found, try to add from dev directory
    if [ "$check_result" = "not_found" ]; then
        log_debug "=== Tentando adicionar plugin dev ===" >&2

        if try_add_dev_plugin "$plugin_name"; then
            # Check again after adding dev plugin
            check_result=$(check_command_in_lock "$plugin_name" "$category" "$command")
            log_debug "✓ Plugin dev adicionado e verificado" >&2
        fi
    fi

    # Step 3: Check if command was found
    if [ "$check_result" = "not_found" ]; then
        log_error "Comando '$command' não encontrado no plugin '$plugin_name' na categoria '$category'"
        log_output ""
        log_output "Procurado em:"
        log_output "  - Plugins instalados (via susa.lock)"
        log_output "  - Diretório atual: $PWD"
        log_output ""
        log_output "Verifique se:"
        log_output "  • O plugin está instalado: susa self plugin list"
        log_output "  • Você está no diretório correto do plugin (modo dev)"
        log_output "  • A estrutura do plugin está correta"
        log_output ""
        log_output "Para instalar o plugin:"
        log_output "  susa self plugin add <repository-url>"
        return 1
    fi

    # Parse check result
    IFS=':' read -r found is_dev <<< "$check_result"
    if [ "$is_dev" = "true" ]; then
        is_dev_plugin=true
        log_debug "Plugin: DEV" >&2
    else
        log_debug "Plugin: INSTALADO" >&2
    fi

    # Mode: prepare only
    if [ "$mode" = "prepare" ]; then
        log_debug "=== MODO: PREPARE ===" >&2
        if [ "$is_dev_plugin" = true ]; then
            log_success "Plugin dev preparado e adicionado ao lock: $plugin_name"
            log_output ""
            log_output "Para remover do lock:"
            log_output "  susa self plugin run --cleanup $plugin_name $category $command"
        else
            log_info "Plugin já está instalado globalmente: $plugin_name"
        fi
        return 0
    fi

    # Step 4: Get script path from lock
    log_debug "=== Obtendo script do comando ===" >&2
    local script_path=$(get_command_script_from_lock "$plugin_name" "$category" "$command")

    if [ $? -ne 0 ] || [ -z "$script_path" ]; then
        log_error "Erro ao obter informações do comando do lock"

        # Cleanup if we added dev plugin
        if [ "$is_dev_plugin" = true ]; then
            cleanup_dev_plugin "$plugin_name"
        fi

        return 1
    fi

    # Step 5: Show execution message
    log_debug "=== Preparando execução ===" >&2
    if [ "$is_dev_plugin" = true ]; then
        log_info "Executando plugin em modo de desenvolvimento: $plugin_name"
        log_output "  ${MAGENTA}[DEV]${NC} Diretório: $(dirname $(dirname $(dirname "$script_path")))"
    else
        log_info "Executando plugin instalado: $plugin_name"
    fi

	echo ""

    # Step 6: Execute command
    log_debug "=== Executando comando ===" >&2
    execute_plugin_command "$script_path" "$plugin_name" "$category" "${args[@]}"
    local exit_code=$?

    # Step 7: Cleanup dev plugin if needed (only in execute mode)
    if [ "$is_dev_plugin" = true ]; then
        log_debug "=== Limpeza de plugin dev ===" >&2
        cleanup_dev_plugin "$plugin_name"
    fi

    return $exit_code
}

# Main function
main() {
    local mode="execute"

    # Parse options (only run command options, not plugin arguments)
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                export DEBUG=1
                log_debug "Modo verbose ativado" >&2
                shift
                ;;
            --prepare)
                mode="prepare"
                log_debug "Modo: prepare (apenas preparar plugin dev)" >&2
                shift
                ;;
            --cleanup)
                mode="cleanup"
                log_debug "Modo: cleanup (apenas remover plugin dev)" >&2
                shift
                ;;
            -*)
                log_error "Opção desconhecida: $1"
                show_usage
                exit 1
                ;;
            *)
                # First non-option argument, stop parsing run options
                break
                ;;
        esac
    done

    # Check arguments
    if [ $# -lt 3 ]; then
        log_error "Argumentos insuficientes"
        log_output ""
        show_usage
        log_output ""
        log_output "Uso:"
        log_output "  susa self plugin run <plugin-name> <category> <command> [args...]"
        log_output "  susa self plugin run --prepare <plugin-name> <category> <command>"
        log_output "  susa self plugin run --cleanup <plugin-name> <category> <command>"
        log_output ""
        log_output "Exemplos:"
        log_output "  susa self plugin run my-plugin text hello -- --help"
        log_output "  susa self plugin run my-plugin text hello"
        log_output "  susa self plugin run my-plugin text hello --name World"
        log_output "  susa self plugin run --prepare my-plugin text hello"
        log_output "  susa self plugin run --cleanup my-plugin text hello"
        exit 1
    fi

    local plugin_name="$1"
    local category="$2"
    local command="$3"
    shift 3

    # Check for -- separator and skip it
    if [[ $# -gt 0 && "$1" == "--" ]]; then
        shift
    fi

    # Run the plugin command with specified mode
    run_plugin_command "$plugin_name" "$category" "$command" "$mode" "$@"
    exit $?
}

# Execute main function
main "$@"
