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

    log_debug "Validando estrutura do plugin local: $plugin_dir"

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

    # Check if directory exists
    if [ ! -d "$plugin_dir" ]; then
        log_error "Diretório não existe: $plugin_dir"
        return 1
    fi

    # Check if it has plugin structure (at least one category with config.yaml)
    local found_configs=$(find "$plugin_dir" -mindepth 2 -maxdepth 2 -type f -name "config.yaml" 2>/dev/null | head -1)

    if [ -z "$found_configs" ]; then
        log_error "Estrutura de plugin inválida"
        log_output "" >&2
        log_output "${LIGHT_YELLOW}Estrutura esperada:${NC}" >&2
        log_output "  plugin/" >&2
        log_output "    categoria/" >&2
        log_output "      config.yaml" >&2
        log_output "      comando/" >&2
        log_output "        config.yaml" >&2
        log_output "        main.sh" >&2
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

    log_output ""

    # Detect version
    local plugin_version=$(detect_plugin_version "$validated_path")
    if [ -z "$plugin_version" ] || [ "$plugin_version" = "0.0.0" ]; then
        plugin_version="dev"
    fi
    log_debug "Versão detectada: $plugin_version"

    # Count commands
    local cmd_count=$(count_plugin_commands "$validated_path")
    log_debug "Total de comandos: $cmd_count"

    # Get categories
    local categories=$(get_plugin_categories "$validated_path")
    log_debug "Categorias: $categories"

    # Register in registry with dev flag
    local registry_file="$PLUGINS_DIR/registry.yaml"
    ensure_registry_exists "$registry_file"

    log_debug "Registrando plugin em modo desenvolvimento"
    if registry_add_plugin "$registry_file" "$plugin_name" "$validated_path" "$plugin_version" "true" "$cmd_count" "$categories"; then
        log_debug "Plugin registrado com sucesso"
    else
        log_warning "Plugin já existe no registry"
    fi

    # Show success message
    log_success "Plugin '$plugin_name' instalado em modo desenvolvimento!"
    log_output ""
    log_output "Detalhes do plugin:"
    log_output "  ${GRAY}Caminho: $validated_path${NC}"
    log_output "  ${GRAY}Versão: $plugin_version${NC}"
    log_output "  ${GRAY}Comandos: $cmd_count${NC}"
    log_output "  ${YELLOW}Modo: desenvolvimento (alterações refletem imediatamente)${NC}"
    log_output ""
    log_output "${LIGHT_CYAN}💡 Dica:${NC} Alterações no plugin serão refletidas automaticamente"
    log_output "${LIGHT_CYAN}💡 Dica:${NC} Use ${LIGHT_CYAN}susa self plugin list${NC} para ver todos os plugins"
    log_output ""

    # Update lock file
    log_debug "Atualizando lock file"
    update_lock_file

    log_output ""
    log_info "Os comandos do plugin já estão disponíveis!"
    log_info "Execute 'susa --help' para ver as novas categorias"

    return 0
}

# Check if plugin is already installed and show information
check_plugin_already_installed() {
    local plugin_name="$1"

    log_debug "Verificando se plugin '$plugin_name' já está instalado"

    # Check if plugin exists in plugins directory (installed via Git)
    local is_git_plugin=false
    if [ -d "$PLUGINS_DIR/$plugin_name" ]; then
        is_git_plugin=true
    fi

    # Check if plugin exists in registry (could be dev plugin)
    local registry_file="$PLUGINS_DIR/registry.yaml"
    local in_registry=false
    local is_dev=false

    if [ -f "$registry_file" ]; then
        local plugin_count=$(yq eval ".plugins[] | select(.name == \"$plugin_name\") | .name" "$registry_file" 2>/dev/null | wc -l)
        if [ "$plugin_count" -gt 0 ]; then
            in_registry=true
            local dev_flag=$(yq eval ".plugins[] | select(.name == \"$plugin_name\") | .dev" "$registry_file" 2>/dev/null | head -1)
            if [ "$dev_flag" = "true" ]; then
                is_dev=true
            fi
        fi
    fi

    # If plugin is not installed at all, return
    if [ "$is_git_plugin" = false ] && [ "$in_registry" = false ]; then
        log_debug "Plugin não encontrado"
        return 1
    fi

    log_warning "Plugin '$plugin_name' já está instalado"
    log_output ""

    if [ "$is_dev" = true ]; then
        log_output "Detalhes do plugin:"
        log_output "  ${YELLOW}Modo: desenvolvimento${NC}"
        local source_path=$(yq eval ".plugins[] | select(.name == \"$plugin_name\") | .source" "$registry_file" 2>/dev/null | head -1)
        if [ -n "$source_path" ]; then
            log_output "  ${GRAY}Local do plugin: $source_path${NC}"
        fi
    else
        log_debug "Diretório encontrado: $PLUGINS_DIR/$plugin_name"
    fi

    # Show plugin information from registry
    if [ -f "$registry_file" ]; then
        log_debug "Lendo informações do registry"
        local current_version=$(registry_get_plugin_info "$registry_file" "$plugin_name" "version" | head -1)
        local install_date=$(registry_get_plugin_info "$registry_file" "$plugin_name" "installed_at" | head -1)

        if [ -n "$current_version" ]; then
            log_output "  ${GRAY}Versão atual: $current_version${NC}"
        fi
        if [ -n "$install_date" ]; then
            log_output "  ${GRAY}Instalado em: $install_date${NC}"
        fi
    fi

    log_output ""

    if [ "$is_dev" = true ]; then
        log_output "${LIGHT_YELLOW}Opções disponíveis:${NC}"
        log_output "  • Remover plugin:   ${LIGHT_CYAN}susa self plugin remove $plugin_name${NC}"
        log_output "  • Listar plugins:   ${LIGHT_CYAN}susa self plugin list${NC}"
    else
        log_output "${LIGHT_YELLOW}Opções disponíveis:${NC}"
        log_output "  • Atualizar plugin:  ${LIGHT_CYAN}susa self plugin update $plugin_name${NC}"
        log_output "  • Remover plugin:  ${LIGHT_CYAN}susa self plugin remove $plugin_name${NC}"
        log_output "  • Listar plugins:   ${LIGHT_CYAN}susa self plugin list${NC}"
    fi

    return 0
}

# Ensure registry.yaml file exists
ensure_registry_exists() {
    local registry_file="$1"

    if [ -f "$registry_file" ]; then
        return 0
    fi

    log_debug "Creating registry.yaml file"
    cat >"$registry_file" <<'EOF'
# Plugin Registry
# This file keeps track of all installed plugins

plugins:
EOF
}

# Register plugin in registry.yaml
register_plugin() {
    local registry_file="$1"
    local plugin_name="$2"
    local plugin_url="$3"
    local plugin_version="$4"
    local cmd_count="$5"
    local categories="$6"

    if registry_add_plugin "$registry_file" "$plugin_name" "$plugin_url" "$plugin_version" "false" "$cmd_count" "$categories"; then
        log_debug "Plugin registrado no registry.yaml"
        return 0
    else
        log_warning "Não foi possível registrar no registry (plugin pode já existir)"
        return 1
    fi
}

# Show installation success message
show_installation_success() {
    local plugin_name="$1"
    local plugin_url="$2"
    local plugin_version="$3"
    local cmd_count="$4"

    log_output ""
    log_success "Plugin '$plugin_name' instalado com sucesso!"
    log_output ""
    log_output "Detalhes do plugin:"
    log_output "  ${GRAY}Origem: $plugin_url${NC}"
    log_output "  ${GRAY}Versão: $plugin_version${NC}"
    log_output "  ${GRAY}Comandos: $cmd_count${NC}"
    log_output ""
    log_output "Use ${LIGHT_CYAN}susa self plugin list${NC} para ver todos os plugins"
    log_output ""
}

# Main function
main() {
    local plugin_url="$1"
    local use_ssh="${2:-false}"
    local provider="${3:-github}"

    log_debug "=== Iniciando instalação de plugin ==="
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
            abs_path="$(cd "$abs_path" 2>/dev/null && pwd)" || {
                log_error "Diretório não encontrado: $plugin_url"
                exit 1
            }
        fi

        # Extract plugin name from absolute path
        local plugin_name=$(basename "$abs_path")
        log_debug "Nome do plugin: $plugin_name"

        # Check if already installed
        if check_plugin_already_installed "$plugin_name"; then
            exit 0
        fi

        # Create plugins directory if needed
        mkdir -p "$PLUGINS_DIR"

        # Install as local/dev plugin
        install_local_plugin "$plugin_url" "$plugin_name"
        exit $?
    fi

    # It's a Git URL - proceed with normal installation
    log_debug "Detectado URL Git"

    # Normalize URL (convert user/repo to full URL)
    log_debug "Normalizando URL do plugin"
    plugin_url=$(normalize_git_url "$plugin_url" "$use_ssh" "$provider")
    log_debug "URL normalizada: $plugin_url"

    # Extract plugin name from URL
    log_debug "Extraindo nome do plugin da URL"
    local plugin_name=$(extract_plugin_name "$plugin_url")
    log_debug "Nome do plugin: $plugin_name"

    log_info "Instalando plugin: $plugin_name"
    log_debug "URL: $plugin_url"
    log_debug "Provider: $provider"
    log_output ""

    # Check if plugin is already installed
    log_debug "Verificando se plugin já está instalado"
    if check_plugin_already_installed "$plugin_name"; then
        exit 0
    fi

    # Check if git is installed
    log_debug "Verificando se Git está instalado"
    ensure_git_installed || exit 1

    # Validate repository access
    log_debug "Validando acesso ao repositório"
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
    log_debug "Criando diretório de plugins se necessário: $PLUGINS_DIR"
    mkdir -p "$PLUGINS_DIR"

    # Clone the repository
    log_info "Clonando de $plugin_url..."
    log_debug "Destino: $PLUGINS_DIR/$plugin_name"
    if ! clone_plugin "$plugin_url" "$PLUGINS_DIR/$plugin_name"; then
        log_error "Falha ao clonar o repositório"
        log_debug "Removendo diretório parcial"
        rm -rf "${PLUGINS_DIR:?}/${plugin_name:?}"
        exit 1
    fi
    log_debug "Clone concluído com sucesso"

    # Detect plugin version
    log_debug "Detectando versão do plugin"
    local plugin_version=$(detect_plugin_version "$PLUGINS_DIR/$plugin_name")
    log_debug "Versão detectada: $plugin_version"

    # Count installed commands and get categories
    log_debug "Contando comandos do plugin"
    local cmd_count=$(count_plugin_commands "$PLUGINS_DIR/$plugin_name")
    log_debug "Total de comandos: $cmd_count"

    log_debug "Obtendo categorias do plugin"
    local categories=$(get_plugin_categories "$PLUGINS_DIR/$plugin_name")
    log_debug "Categorias: $categories"

    # Register in registry.yaml
    local registry_file="$PLUGINS_DIR/registry.yaml"
    log_debug "Registry file: $registry_file"
    log_debug "Garantindo existência do registry"
    ensure_registry_exists "$registry_file"

    log_debug "Registrando plugin no registry"
    register_plugin "$registry_file" "$plugin_name" "$plugin_url" "$plugin_version" "$cmd_count" "$categories"

    # Show success message
    show_installation_success "$plugin_name" "$plugin_url" "$plugin_version" "$cmd_count"

    # Update lock file to make plugin commands available
    log_debug "Atualizando lock file para disponibilizar comandos do plugin"
    update_lock_file
    log_debug "=== Instalação concluída ==="

    log_output ""
    log_info "💡 Os comandos do plugin já estão disponíveis!"
    log_info "Execute 'susa --help' para ver as novas categorias"
}

# Parse arguments first, before running main
USE_SSH="false"
PROVIDER="github"
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

# Validate required argument
validate_required_arg "${PLUGIN_ARG:-}" "URL ou nome do plugin" "<git-url|user/repo> [opções]"

# Execute main function
main "$PLUGIN_ARG" "$USE_SSH" "$PROVIDER"
