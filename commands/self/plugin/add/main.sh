#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source necessary libraries
source "$LIB_DIR/internal/registry.sh"
source "$LIB_DIR/internal/plugin.sh"
source "$LIB_DIR/internal/args.sh"

# Help function
show_help() {
    show_description
    log_output ""
    show_usage "<git-url|user/repo> [opções]"
    log_output ""
    log_output "${LIGHT_GREEN}Formato:${NC}"
    log_output "  susa self plugin add ${GRAY}<git-url>${NC}"
    log_output "  susa self plugin add ${GRAY}<user>/<repo>${NC}  ${GRAY}# GitHub (padrão)${NC}"
    log_output "  susa self plugin add ${GRAY}<user>/<repo>${NC} --gitlab"
    log_output "  susa self plugin add ${GRAY}<user>/<repo>${NC} --bitbucket"
    log_output "  susa self plugin add ${GRAY}<caminho-local>${NC}  ${GRAY}# Modo desenvolvimento${NC}"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  # GitHub"
    log_output "  susa self plugin add user/susa-plugin-name"
    log_output "  susa self plugin add https://github.com/user/plugin.git"
    log_output ""
    log_output "  # Caminho local (desenvolvimento)"
    log_output "  susa self plugin add /caminho/completo/para/meu-plugin"
    log_output "  susa self plugin add ~/projects/meu-plugin"
    log_output "  susa self plugin add ./meu-plugin"
    log_output "  susa self plugin add ."
    log_output "  susa self plugin add"
    log_output ""
    log_output "  # GitLab"
    log_output "  susa self plugin add user/susa-plugin-name --gitlab"
    log_output "  susa self plugin add https://gitlab.com/user/plugin.git"
    log_output ""
    log_output "  # Bitbucket"
    log_output "  susa self plugin add user/susa-plugin-name --bitbucket"
    log_output "  susa self plugin add https://bitbucket.org/user/plugin.git"
    log_output ""
    log_output "  # Privados com SSH"
    log_output "  susa self plugin add organization/private-plugin --ssh"
    log_output "  susa self plugin add user/private-plugin --gitlab --ssh"
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -v, --verbose     Modo verbose (debug)"
    log_output "  -q, --quiet       Modo silencioso (mínimo de output)"
    log_output "  --gitlab      Usa GitLab (para formato user/repo)"
    log_output "  --bitbucket   Usa Bitbucket (para formato user/repo)"
    log_output "  --ssh         Força uso de SSH (recomendado para repos privados)"
    log_output "  -h, --help    Mostra esta mensagem de ajuda"
    log_output ""
    log_output "${LIGHT_GREEN}Modo Desenvolvimento:${NC}"
    log_output "  Use caminho local para testar plugins sem publicar no Git."
    log_output "  O plugin será marcado como 'dev' e apontará para o diretório local."
    log_output "  ${YELLOW}Útil durante desenvolvimento - alterações refletem imediatamente!${NC}"
    log_output ""
    log_output "${LIGHT_GREEN}Repositórios Privados:${NC}"
    log_output "  Para repos privados, configure SSH ou use token HTTPS."
    log_output "  O sistema detecta automaticamente se você tem SSH configurado."
}

# Check if path is a local directory
is_local_path() {
    local path="$1"

    # Check if it starts with /, ./, ../, or ~
    if [[ "$path" =~ ^(/|\./|\.\./|~) ]]; then
        return 0
    fi

    # Check if it's an existing directory
    if [ -d "$path" ]; then
        return 0
    fi

    return 1
}

# Validate local plugin structure
validate_local_plugin() {
    local plugin_dir="$1"

    # Expand ~ to home directory
    plugin_dir="${plugin_dir/#\~/$HOME}"

    # Check if directory exists first
    if [ ! -d "$plugin_dir" ]; then
        log_error "Diretório não encontrado: $1"
        return 1
    fi

    # Convert to absolute path
    plugin_dir="$(cd "$plugin_dir" && pwd)" || {
        log_error "Falha ao converter para caminho absoluto: $1"
        return 1
    }
    # Validate plugin.json exists and is valid
    if ! validate_plugin_config "$plugin_dir"; then
        log_error "Plugin inválido: plugin.json não encontrado ou inválido"
        log_output ""
        log_output "${LIGHT_YELLOW}O arquivo plugin.json é obrigatório e deve conter:${NC}"
        log_output "  • ${BOLD}name${NC}: Nome do plugin (obrigatório)"
        log_output "  • ${BOLD}version${NC}: Versão no formato semver (obrigatório)"
        log_output "  • ${BOLD}description${NC}: Descrição do plugin (opcional)"
        log_output "  • ${BOLD}directory${NC}: Diretório dos comandos (opcional)"
        log_output ""
        log_output "${LIGHT_YELLOW}Exemplo de plugin.json:${NC}"
        log_output '  {'
        log_output '    "name": "meu-plugin",'
        log_output '    "version": "1.0.0",'
        log_output '    "description": "Descrição do plugin",'
        log_output '    "directory": "src"'
        log_output '  }'
        return 1
    fi
    # Get the configured directory for plugin commands (if any)
    local commands_dir="$plugin_dir"
    local configured_dir=$(get_plugin_directory "$plugin_dir" 2> /dev/null || echo "")

    if [ -n "$configured_dir" ]; then
        commands_dir="$plugin_dir/$configured_dir"
        log_debug "Plugin usa diretório configurado: $configured_dir"
    fi

    # Check if commands directory exists
    if [ ! -d "$commands_dir" ]; then
        log_error "Diretório de comandos não existe: $commands_dir"
        return 1
    fi

    # Check if it has plugin structure (at least one category with command.json)
    local found_configs=$(find "$commands_dir" -mindepth 3 -maxdepth 3 -type f -name "command.json" 2> /dev/null | head -1)

    if [ -z "$found_configs" ]; then
        log_error "Estrutura de plugin inválida"
        log_output "" >&2
        log_output "${LIGHT_YELLOW}Estrutura esperada:${NC}" >&2
        if [ -n "$configured_dir" ]; then
            log_output "  plugin/" >&2
            log_output "    $configured_dir/" >&2
            log_output "      categoria/" >&2
            log_output "        category.json" >&2
            log_output "        comando/" >&2
            log_output "          command.json" >&2
            log_output "          main.sh" >&2
        else
            log_output "  plugin/" >&2
            log_output "    categoria/" >&2
            log_output "      category.json" >&2
            log_output "      comando/" >&2
            log_output "        command.json" >&2
            log_output "        main.sh" >&2
        fi
        return 1
    fi

    echo "$plugin_dir"
    return 0
}

# Install local plugin in development mode
install_local_plugin() {
    local plugin_path="$1"
    local plugin_name="$2"

    log_info "Instalando plugin local em modo desenvolvimento: $plugin_name"
    log_debug "Caminho: $plugin_path"

    # Validate structure
    local validated_path
    validated_path=$(validate_local_plugin "$plugin_path")
    local validate_result=$?

    if [ $validate_result -ne 0 ]; then
        return 1
    fi

    # Register plugin in registry
    if ! update_plugin_registry "$plugin_name" "$validated_path" "true"; then
        log_error "Falha ao registrar plugin no registry"
        return 1
    fi

    # Update lock file
    if ! update_lock_file; then
        log_error "Falha ao atualizar o lock"
        return 1
    fi

    # Read metadata for display
    local plugin_version=$(detect_plugin_version "$validated_path")
    local cmd_count=$(count_plugin_commands "$validated_path")
    local categories=$(get_plugin_categories "$validated_path")

    # Show success message
    log_success "Plugin ${BOLD}$plugin_name${NC} instalado em modo desenvolvimento!"
    log_output ""
    show_plugin_details "$plugin_name" "$plugin_version" "$cmd_count" "$categories" "" "" "$validated_path" "" "true"
    log_output ""
    log_output "${LIGHT_CYAN}💡 Dica:${NC} Alterações no plugin serão refletidas automaticamente"
    log_output "${LIGHT_CYAN}💡 Dica:${NC} Use ${LIGHT_CYAN}susa self plugin list${NC} para ver todos os plugins"
    log_output ""

    log_info "Os comandos do plugin já estão disponíveis!"
    log_info "Execute 'susa --help' para ver as novas categorias"

    return 0
}

# Check if plugin source already exists in registry
check_plugin_source_exists() {
    local plugin_source="$1"
    local registry_file="$PLUGINS_DIR/registry.json"

    # Use registry library function
    local existing_plugin=$(registry_get_plugin_by_source "$registry_file" "$plugin_source")

    if [ -n "$existing_plugin" ]; then
        echo "$existing_plugin"
        return 0
    fi

    return 1
}

# Check if plugin is already installed and show information
check_plugin_already_installed() {
    local plugin_name="$1"
    local plugin_source="${2:-}" # Optional source path

    # Check if plugin source already exists (for dev plugins)
    if [ -n "$plugin_source" ]; then
        local existing_name=$(check_plugin_source_exists "$plugin_source")
        if [ -n "$existing_name" ]; then
            log_warning "Este plugin já está instalado: ${BOLD}$existing_name${NC}"
            log_output ""

            local registry_file="$PLUGINS_DIR/registry.json"
            local current_version=""
            local install_date=""

            if [ -f "$registry_file" ]; then
                current_version=$(registry_get_plugin_info "$registry_file" "$existing_name" "version" | head -1)
                install_date=$(registry_get_plugin_info "$registry_file" "$existing_name" "installedAt" | head -1)
            fi

            show_plugin_details "$existing_name" "$current_version" "" "" "" "" "$plugin_source" "$install_date" "true"
            log_output ""
            log_output "${LIGHT_YELLOW}Opções disponíveis:${NC}"
            log_output "  • Atualizar plugin:  ${LIGHT_CYAN}susa self plugin update $existing_name${NC}"
            log_output "  • Remover plugin:  ${LIGHT_CYAN}susa self plugin remove $existing_name${NC}"
            log_output "  • Listar plugins:   ${LIGHT_CYAN}susa self plugin list${NC}"
            return 0
        fi
    fi

    # Check if plugin exists in plugins directory (installed via Git)
    local is_git_plugin=false
    if [ -d "$PLUGINS_DIR/$plugin_name" ]; then
        is_git_plugin=true
    fi

    # Check if plugin exists in registry (could be dev plugin)
    local registry_file="$PLUGINS_DIR/registry.json"
    local in_registry=false
    local is_dev=false

    if registry_plugin_exists "$registry_file" "$plugin_name"; then
        in_registry=true
        if registry_is_dev_plugin "$registry_file" "$plugin_name"; then
            is_dev=true
        fi
    fi

    # If plugin is not installed at all, return
    if [ "$is_git_plugin" = false ] && [ "$in_registry" = false ]; then
        log_debug "Plugin não encontrado"
        return 1
    fi

    log_warning "Plugin ${BOLD}$plugin_name${NC} já está instalado"

    log_output ""

    # Gather plugin information
    local source_path=""
    local current_version=""
    local install_date=""
    local dev_mode="false"

    if [ "$is_dev" = true ]; then
        dev_mode="true"
        source_path=$(registry_get_plugin_info "$registry_file" "$plugin_name" "source" | head -1)
    fi

    # Show plugin information from registry
    if [ -f "$registry_file" ]; then
        log_debug "Lendo informações do registry"
        current_version=$(registry_get_plugin_info "$registry_file" "$plugin_name" "version" | head -1)
        install_date=$(registry_get_plugin_info "$registry_file" "$plugin_name" "installedAt" | head -1)
    fi

    show_plugin_details "$plugin_name" "$current_version" "" "" "" "" "$source_path" "$install_date" "$dev_mode"

    log_output ""
    log_output "${LIGHT_YELLOW}Opções disponíveis:${NC}"
    log_output "  • Atualizar plugin:  ${LIGHT_CYAN}susa self plugin update $plugin_name${NC}"
    log_output "  • Remover plugin:  ${LIGHT_CYAN}susa self plugin remove $plugin_name${NC}"
    log_output "  • Listar plugins:   ${LIGHT_CYAN}susa self plugin list${NC}"

    return 0
}

# Show installation success message
show_installation_success() {
    local plugin_name="$1"
    local plugin_url="$2"
    local plugin_version="$3"
    local cmd_count="$4"

    log_success "Plugin ${BOLD}$plugin_name${NC} instalado com sucesso!"
    log_output ""
    show_plugin_details "$plugin_name" "$plugin_version" "$cmd_count" "" "" "" "$plugin_url"
    log_output ""
    log_output "Use ${LIGHT_CYAN}susa self plugin list${NC} para ver todos os plugins"
}

# Main function
main() {
    local plugin_url="$1"
    local use_ssh="${2:-false}"
    local provider="${3:-github}"

    log_debug "Plugin URL/Path: $plugin_url"
    log_debug "Use SSH: $use_ssh"
    log_debug "Provider: $provider"

    # Check if it's a local path
    if is_local_path "$plugin_url"; then
        log_debug "Detectado caminho local"

        # Convert to absolute path to extract proper name
        local abs_path="$plugin_url"
        abs_path="${abs_path/#\~/$HOME}" # Expand ~

        # Convert relative paths to absolute
        if [[ ! "$abs_path" =~ ^/ ]]; then
            abs_path="$(cd "$abs_path" 2> /dev/null && pwd)" || {
                log_error "Diretório não encontrado: $plugin_url"
                exit 1
            }
        fi

        # Validate structure first
        local validated_path
        validated_path=$(validate_local_plugin "$abs_path")
        local validate_result=$?

        if [ $validate_result -ne 0 ]; then
            exit 1
        fi

        # Get plugin name from plugin.json (not from directory name)
        local plugin_name=$(get_plugin_name "$validated_path")
        if [ $? -ne 0 ]; then
            log_error "Não foi possível ler o nome do plugin.json"
            exit 1
        fi
        log_debug "Nome do plugin (do plugin.json): $plugin_name"

        # Check if already installed (check both by name and by source path)
        if check_plugin_already_installed "$plugin_name" "$validated_path"; then
            exit 0
        fi

        # Create plugins directory if needed
        mkdir -p "$PLUGINS_DIR"

        # Install as local/dev plugin
        install_local_plugin "$validated_path" "$plugin_name"
        exit $?
    fi

    # It's a Git URL - proceed with normal installation
    log_debug "Detectado URL Git"

    # Normalize URL (convert user/repo to full URL)
    plugin_url=$(normalize_git_url "$plugin_url" "$use_ssh" "$provider")
    log_debug "URL normalizada: $plugin_url"

    # Extract temporary plugin name from URL (will be replaced by plugin.json name)
    log_debug "Extraindo nome temporário do plugin da URL"
    local temp_plugin_name=$(extract_plugin_name "$plugin_url")
    log_debug "Nome temporário: $temp_plugin_name"

    log_info "Instalando plugin de: $plugin_url"
    log_debug "Provider: $provider"
    log_output ""

    # Check if git is installed
    ensure_git_installed || exit 1

    # Validate repository access
    if ! validate_repo_access "$plugin_url"; then
        log_error "Não foi possível acessar o repositório"
        log_debug "Falha na validação de acesso ao repositório"
        log_output ""
        log_output "${LIGHT_YELLOW}Possíveis causas:${NC}"
        log_output "  • Repositório não existe"
        log_output "  • Repositório é privado e você não tem acesso"
        log_output "  • Credenciais Git não configuradas"
        log_output ""
        log_output "${LIGHT_YELLOW}Para repositórios privados:${NC}"
        log_output "  • Use --ssh e configure chave SSH no GitHub/GitLab"
        log_output "  • Configure credential helper: ${CYAN}git config --global credential.helper store${NC}"
        exit 1
    fi
    log_debug "Acesso ao repositório validado com sucesso"

    # Create plugins directory if it doesn't exist
    mkdir -p "$PLUGINS_DIR"

    # Clone the repository
    log_debug "Clonando de $plugin_url..."
    log_debug "Destino: $PLUGINS_DIR/$temp_plugin_name"
    if ! clone_plugin "$plugin_url" "$PLUGINS_DIR/$temp_plugin_name"; then
        log_error "Falha ao clonar o repositório"
        rm -rf "${PLUGINS_DIR:?}/${temp_plugin_name:?}"
        exit 1
    fi
    log_debug "Clone concluído com sucesso"

    # Validate that plugin has plugin.json
    if ! validate_plugin_config "$PLUGINS_DIR/$temp_plugin_name"; then
        log_error "Plugin inválido: plugin.json não encontrado ou inválido"
        log_output ""
        log_output "${LIGHT_YELLOW}O plugin clonado não contém um plugin.json válido.${NC}"
        log_output ""
        log_output "${LIGHT_YELLOW}O arquivo plugin.json é obrigatório e deve conter:${NC}"
        log_output "  • ${BOLD}name${NC}: Nome do plugin (obrigatório)"
        log_output "  • ${BOLD}version${NC}: Versão no formato semver (obrigatório)"
        log_output "  • ${BOLD}description${NC}: Descrição do plugin (opcional)"
        log_output "  • ${BOLD}directory${NC}: Diretório dos comandos (opcional)"
        log_output ""
        log_output "${LIGHT_YELLOW}Exemplo de plugin.json:${NC}"
        log_output '  {'
        log_output '    "name": "meu-plugin",'
        log_output '    "version": "1.0.0",'
        log_output '    "description": "Descrição do plugin",'
        log_output '    "directory": "src"'
        log_output '  }'
        log_output ""
        log_output "${LIGHT_YELLOW}Entre em contato com o mantenedor do plugin.${NC}"
        rm -rf "${PLUGINS_DIR:?}/${temp_plugin_name:?}"
        exit 1
    fi
    log_debug "plugin.json validado com sucesso"

    # Get the actual plugin name from plugin.json
    local plugin_name=$(get_plugin_name "$PLUGINS_DIR/$temp_plugin_name")
    if [ $? -ne 0 ]; then
        log_error "Não foi possível ler o nome do plugin.json"
        rm -rf "${PLUGINS_DIR:?}/${temp_plugin_name:?}"
        exit 1
    fi
    log_debug "Nome do plugin (do plugin.json): $plugin_name"

    # Check if plugin is already installed (before renaming/moving files)
    # Check registry first - if plugin exists there with different source, it's a conflict
    local registry_file="$PLUGINS_DIR/registry.json"
    if registry_plugin_exists "$registry_file" "$plugin_name"; then
        log_warning "Plugin ${BOLD}$plugin_name${NC} já está instalado"
        log_output ""

        local current_version=$(registry_get_plugin_info "$registry_file" "$plugin_name" "version" | head -1)
        local install_date=$(registry_get_plugin_info "$registry_file" "$plugin_name" "installedAt" | head -1)
        local source_path=$(registry_get_plugin_info "$registry_file" "$plugin_name" "source" | head -1)
        local is_dev="false"
        if registry_is_dev_plugin "$registry_file" "$plugin_name"; then
            is_dev="true"
        fi

        show_plugin_details "$plugin_name" "$current_version" "" "" "" "" "$source_path" "$install_date" "$is_dev"

        log_output ""
        log_output "${LIGHT_YELLOW}Opções disponíveis:${NC}"
        log_output "  • Atualizar plugin:  ${LIGHT_CYAN}susa self plugin update $plugin_name${NC}"
        log_output "  • Remover plugin:  ${LIGHT_CYAN}susa self plugin remove $plugin_name${NC}"
        log_output "  • Listar plugins:   ${LIGHT_CYAN}susa self plugin list${NC}"

        rm -rf "${PLUGINS_DIR:?}/${temp_plugin_name:?}"
        exit 0
    fi

    # If temp name differs from actual name, rename the directory
    if [ "$temp_plugin_name" != "$plugin_name" ]; then
        log_debug "Renomeando diretório de $temp_plugin_name para $plugin_name"
        if [ -d "$PLUGINS_DIR/$plugin_name" ]; then
            log_error "Diretório $plugin_name já existe"
            rm -rf "${PLUGINS_DIR:?}/${temp_plugin_name:?}"
            exit 1
        fi
        mv "$PLUGINS_DIR/$temp_plugin_name" "$PLUGINS_DIR/$plugin_name"
    fi

    # Register plugin in registry with Git URL
    if ! update_plugin_registry "$plugin_name" "$PLUGINS_DIR/$plugin_name" "false" "$plugin_url"; then
        log_error "Falha ao registrar plugin no registry"
        rm -rf "${PLUGINS_DIR:?}/${plugin_name:?}"
        exit 1
    fi

    # Update lock file to make plugin commands available
    if ! update_lock_file; then
        log_error "Falha ao atualizar o lock"
        rm -rf "${PLUGINS_DIR:?}/${plugin_name:?}"
        exit 1
    fi

    # Read metadata for display
    local plugin_version=$(detect_plugin_version "$PLUGINS_DIR/$plugin_name")
    local cmd_count=$(count_plugin_commands "$PLUGINS_DIR/$plugin_name")

    # Show success message
    show_installation_success "$plugin_name" "$plugin_url" "$plugin_version" "$cmd_count"

    log_output ""
    log_info "💡 Os comandos do plugin já estão disponíveis!"
    log_info "Execute 'susa --help' para ver as novas categorias"
}

# Parse arguments first, before running main
USE_SSH="false"
PROVIDER="github"
PLUGIN_ARG=""

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
        --ssh)
            USE_SSH="true"
            shift
            ;;
        --gitlab)
            PROVIDER="gitlab"
            shift
            ;;
        --bitbucket)
            PROVIDER="bitbucket"
            shift
            ;;
        *)
            # Argumento é a URL/nome do plugin
            PLUGIN_ARG="$1"
            shift
            ;;
    esac
done

# If no plugin argument provided, use current directory
if [ -z "$PLUGIN_ARG" ]; then
    log_debug "Nenhum argumento fornecido, usando diretório atual"
    PLUGIN_ARG="."
fi

# Execute main function
main "$PLUGIN_ARG" "$USE_SSH" "$PROVIDER"
