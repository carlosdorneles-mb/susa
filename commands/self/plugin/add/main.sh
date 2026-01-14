#!/bin/bash
set -euo pipefail

setup_command_env

# Source necessary libraries
source "$LIB_DIR/registry.sh"
source "$LIB_DIR/plugin.sh"

# Help function
show_help() {
    show_description
    echo ""
    show_usage "<git-url|user/repo> [opções]"
    echo ""
    echo -e "${LIGHT_GREEN}Formato:${NC}"
    echo -e "  susa self plugin add ${GRAY}<git-url>${NC}"
    echo -e "  susa self plugin add ${GRAY}<user>/<repo>${NC}  ${GRAY}# GitHub (padrão)${NC}"
    echo -e "  susa self plugin add ${GRAY}<user>/<repo>${NC} --gitlab"
    echo -e "  susa self plugin add ${GRAY}<user>/<repo>${NC} --bitbucket"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo -e "  # GitHub"
    echo -e "  susa self plugin add user/susa-plugin-name"
    echo -e "  susa self plugin add https://github.com/user/plugin.git"
    echo ""
    echo -e "  # GitLab"
    echo -e "  susa self plugin add user/susa-plugin-name --gitlab"
    echo -e "  susa self plugin add https://gitlab.com/user/plugin.git"
    echo ""
    echo -e "  # Bitbucket"
    echo -e "  susa self plugin add user/susa-plugin-name --bitbucket"
    echo -e "  susa self plugin add https://bitbucket.org/user/plugin.git"
    echo ""
    echo -e "  # Privados com SSH"
    echo -e "  susa self plugin add organization/private-plugin --ssh"
    echo -e "  susa self plugin add user/private-plugin --gitlab --ssh"
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo -e "  --gitlab      Usa GitLab (para formato user/repo)"
    echo -e "  --bitbucket   Usa Bitbucket (para formato user/repo)"
    echo -e "  --ssh         Força uso de SSH (recomendado para repos privados)"
    echo -e "  -h, --help    Mostra esta mensagem de ajuda"
    echo ""
    echo -e "${LIGHT_GREEN}Repositórios Privados:${NC}"
    echo -e "  Para repos privados, configure SSH ou use token HTTPS."
    echo -e "  O sistema detecta automaticamente se você tem SSH configurado."
}

# Check if plugin is already installed and show information
check_plugin_already_installed() {
    local plugin_name="$1"

    if [ ! -d "$PLUGINS_DIR/$plugin_name" ]; then
        return 1
    fi

    log_warning "Plugin '$plugin_name' já está instalado"
    echo ""

    # Show plugin information
    local registry_file="$PLUGINS_DIR/registry.yaml"
    if [ -f "$registry_file" ]; then
        local current_version=$(registry_get_plugin_info "$registry_file" "$plugin_name" "version")
        local install_date=$(registry_get_plugin_info "$registry_file" "$plugin_name" "installed_at")

        if [ -n "$current_version" ]; then
            echo -e "  ${GRAY}Versão atual: $current_version${NC}"
        fi
        if [ -n "$install_date" ]; then
            echo -e "  ${GRAY}Instalado em: $install_date${NC}"
        fi
    fi

    echo ""
    echo -e "${LIGHT_YELLOW}Opções disponíveis:${NC}"
    echo -e "  • Atualizar plugin:  ${LIGHT_CYAN}susa self plugin update $plugin_name${NC}"
    echo -e "  • Remover plugin:  ${LIGHT_CYAN}susa self plugin remove $plugin_name${NC}"
    echo -e "  • Listar plugins:   ${LIGHT_CYAN}susa self plugin list${NC}"

    return 0
}

# Ensure registry.yaml file exists
ensure_registry_exists() {
    local registry_file="$1"

    if [ -f "$registry_file" ]; then
        return 0
    fi

    log_debug "Creating registry.yaml file"
    cat > "$registry_file" << 'EOF'
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

    if registry_add_plugin "$registry_file" "$plugin_name" "$plugin_url" "$plugin_version"; then
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

    echo ""
    log_success "Plugin '$plugin_name' instalado com sucesso!"
    echo -e "  ${GRAY}Origem: $plugin_url${NC}"
    echo -e "  ${GRAY}Versão: $plugin_version${NC}"
    echo -e "  ${GRAY}Comandos: $cmd_count${NC}"
    echo ""
    echo -e "Use ${LIGHT_CYAN}susa self plugin list${NC} para ver todos os plugins"
}

# Main function
main() {
    local plugin_url="$1"
    local use_ssh="${2:-false}"
    local provider="${3:-github}"

    # Normalize URL (convert user/repo to full URL)
    plugin_url=$(normalize_git_url "$plugin_url" "$use_ssh" "$provider")

    # Extract plugin name from URL
    local plugin_name=$(extract_plugin_name "$plugin_url")

    log_info "Instalando plugin: $plugin_name"
    log_debug "URL: $plugin_url"
    log_debug "Provider: $provider"
    echo ""

    # Check if plugin is already installed
    if check_plugin_already_installed "$plugin_name"; then
        exit 0
    fi

    # Check if git is installed
    ensure_git_installed || exit 1

    # Validate repository access
    if ! validate_repo_access "$plugin_url"; then
        log_error "Não foi possível acessar o repositório"
        echo ""
        echo -e "${LIGHT_YELLOW}Possíveis causas:${NC}"
        echo -e "  • Repositório não existe"
        echo -e "  • Repositório é privado e você não tem acesso"
        echo -e "  • Credenciais Git não configuradas"
        echo ""
        echo -e "${LIGHT_YELLOW}Para repositórios privados:${NC}"
        echo -e "  • Use --ssh e configure chave SSH no GitHub/GitLab"
        echo -e "  • Configure credential helper: ${CYAN}git config --global credential.helper store${NC}"
        exit 1
    fi

    # Create plugins directory if it doesn't exist
    mkdir -p "$PLUGINS_DIR"

    # Clone the repository
    log_info "Clonando de $plugin_url..."
    if ! clone_plugin "$plugin_url" "$PLUGINS_DIR/$plugin_name"; then
        log_error "Falha ao clonar o repositório"
        rm -rf "$PLUGINS_DIR/$plugin_name"
        exit 1
    fi

    # Detect plugin version
    local plugin_version=$(detect_plugin_version "$PLUGINS_DIR/$plugin_name")

    # Register in registry.yaml
    local registry_file="$PLUGINS_DIR/registry.yaml"
    ensure_registry_exists "$registry_file"
    register_plugin "$registry_file" "$plugin_name" "$plugin_url" "$plugin_version"

    # Count installed commands
    local cmd_count=$(count_plugin_commands "$PLUGINS_DIR/$plugin_name")

    # Show success message
    show_installation_success "$plugin_name" "$plugin_url" "$plugin_version" "$cmd_count"

    # Update lock file if it exists
    if [ -f "$CLI_DIR/susa.lock" ]; then
        log_info "Atualizando arquivo susa.lock..."
        "$CORE_DIR/susa" self lock > /dev/null 2>&1 || log_warning "Não foi possível atualizar o susa.lock. Execute 'susa self lock' manualmente."
    fi
}

# Parse arguments first, before running main
USE_SSH="false"
PROVIDER="github"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
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

# Checks if URL was provided
if [ -z "${PLUGIN_ARG:-}" ]; then
    log_error "URL ou nome do plugin não fornecido"
    show_usage "<git-url|user/repo> [opções]"
    exit 1
fi

# Execute main function
main "$PLUGIN_ARG" "$USE_SSH" "$PROVIDER"
