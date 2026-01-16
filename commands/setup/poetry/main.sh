#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source installations library
source "$LIB_DIR/internal/installations.sh"

# Help function
show_help() {
    show_description
    echo ""
    show_usage
    echo ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Poetry é um gerenciador de dependências e empacotamento para Python."
    log_output "  Facilita o gerenciamento de bibliotecas, criação de ambientes virtuais"
    log_output "  e publicação de pacotes Python de forma simplificada."
    echo ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala o Poetry do sistema"
    log_output "  --update          Atualiza o Poetry para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    echo ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup poetry              # Instala o Poetry"
    log_output "  susa setup poetry --update     # Atualiza o Poetry"
    log_output "  susa setup poetry --uninstall  # Desinstala o Poetry"
    echo ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Após a instalação, reinicie o terminal ou execute:"
    echo "    source ~/.bashrc   (para Bash)"
    echo "    source ~/.zshrc    (para Zsh)"
    echo ""
    log_output "${LIGHT_GREEN}Próximos passos:${NC}"
    log_output "  poetry new meu-projeto              # Criar novo projeto"
    log_output "  poetry add requests                 # Adicionar dependência"
    log_output "  poetry install                      # Instalar dependências"
    log_output "  poetry run python script.py         # Executar script"
}
# Get latest Poetry version
get_latest_poetry_version() {
    github_get_latest_version "python-poetry/poetry"
}

# Get installed Poetry version
get_poetry_version() {
    if command -v poetry &> /dev/null; then
        poetry --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}

# Get Poetry installation path
get_poetry_home() {
    echo "$POETRY_HOME"
}

# Check if Poetry is already installed
check_existing_installation() {

    if ! command -v poetry &> /dev/null; then
        log_debug "Poetry não está instalado"
        return 0
    fi

    local current_version=$(get_poetry_version)
    log_info "Poetry $current_version já está instalado."

    # Mark as installed in lock file
    mark_installed "poetry" "$current_version"

    # Check for updates
    local latest_version=$(get_latest_poetry_version)
    if [ $? -eq 0 ] && [ -n "$latest_version" ]; then
        if [ "$current_version" != "$latest_version" ]; then
            echo ""
            log_output "${YELLOW}Nova versão disponível ($latest_version).${NC}"
            log_output "Para atualizar, execute: ${LIGHT_CYAN}susa setup poetry --update${NC}"
        fi
    else
        log_warning "Não foi possível verificar atualizações"
    fi

    return 1
}

# Configure shell to use Poetry
configure_shell() {
    local poetry_home="$1"
    local shell_config=$(detect_shell_config)

    log_debug "Arquivo de configuração: $shell_config"

    # Check if Poetry is already configured
    if grep -q "POETRY_HOME\|poetry/bin" "$shell_config" 2> /dev/null; then
        log_debug "Poetry já configurado em $shell_config"
        return 0
    fi

    log_debug "Configurando $shell_config..."

    echo "" >> "$shell_config"
    echo "# Poetry (Python dependency manager)" >> "$shell_config"
    echo "export POETRY_HOME=\"$poetry_home\"" >> "$shell_config"
    echo "export PATH=\"\$POETRY_HOME/bin:\$PATH\"" >> "$shell_config"

    log_debug "Configuração adicionada ao shell"
}

# Setup Poetry environment for current session
setup_poetry_environment() {
    local poetry_home="$1"

    export POETRY_HOME="$poetry_home"
    export PATH="$POETRY_HOME/bin:$PATH"

    log_debug "Ambiente configurado para sessão atual"
    log_debug "POETRY_HOME: $POETRY_HOME"
    log_debug "PATH atualizado com: $POETRY_HOME/bin"
}

# Install Poetry
install_poetry() {
    log_info "Iniciando instalação do Poetry..."

    local poetry_home=$(get_poetry_home)

    # Download and install Poetry using official installer
    log_info "Baixando instalador do Poetry..."

    local install_script="/tmp/poetry-installer-$$.py"

    if ! curl -sSL "$POETRY_INSTALL_URL" -o "$install_script"; then
        log_error "Falha ao baixar o instalador do Poetry"
        rm -f "$install_script"
        return 1
    fi

    log_debug "Instalador baixado em: $install_script"

    # Run installer
    log_info "Instalando Poetry..."
    log_debug "Executando instalador Python..."

    export POETRY_HOME="$poetry_home"

    if python3 "$install_script" 2>&1 | while read -r line; do log_debug "installer: $line"; done; then
        log_debug "Instalação concluída com sucesso"
    else
        log_error "Falha ao executar o instalador do Poetry"
        rm -f "$install_script"
        return 1
    fi

    rm -f "$install_script"
    log_debug "Instalador removido"

    # Configure shell
    configure_shell "$poetry_home"

    # Setup environment for current session
    setup_poetry_environment "$poetry_home"

    # Verify installation
    if command -v poetry &> /dev/null; then
        local version=$(get_poetry_version)

        # Mark as installed in lock file
        mark_installed "poetry" "$version"

        log_success "Poetry $version instalado com sucesso!"

        echo ""
        echo "Próximos passos:"
        local shell_config=$(detect_shell_config)
        log_output "  1. Reinicie o terminal ou execute: ${LIGHT_CYAN}source $shell_config${NC}"
        log_output "  2. Crie um novo projeto: ${LIGHT_CYAN}poetry new meu-projeto${NC}"
        log_output "  3. Use ${LIGHT_CYAN}susa setup poetry --help${NC} para mais informações"

        return 0
    else
        log_error "Poetry foi instalado mas não está disponível no PATH"
        local shell_config=$(detect_shell_config)
        log_info "Tente reiniciar o terminal ou executar: source $shell_config"
        return 1
    fi
}

# Update Poetry
update_poetry() {
    log_info "Atualizando Poetry..."

    # Check if Poetry is installed
    if ! command -v poetry &> /dev/null; then
        log_error "Poetry não está instalado"
        echo ""
        log_output "${YELLOW}Para instalar, execute:${NC} ${LIGHT_CYAN}susa setup poetry${NC}"
        return 1
    fi

    local current_version=$(get_poetry_version)
    log_info "Versão atual: $current_version"

    # Update Poetry using self update command
    log_info "Executando atualização do Poetry..."

    if poetry self update 2>&1 | while read -r line; do log_debug "poetry: $line"; done; then
        log_debug "Comando de atualização executado com sucesso"
    else
        log_error "Falha ao atualizar o Poetry"
        return 1
    fi

    # Verify update
    if command -v poetry &> /dev/null; then
        local new_version=$(get_poetry_version)

        if [ "$current_version" = "$new_version" ]; then
            log_info "Poetry já está na versão mais recente ($current_version)"
        else
            # Update version in lock file
            update_version "poetry" "$new_version"

            log_success "Poetry atualizado de $current_version para $new_version!"
            log_debug "Atualização concluída com sucesso"
        fi

        return 0
    else
        log_error "Falha na atualização do Poetry"
        return 1
    fi
}

# Uninstall Poetry
uninstall_poetry() {
    log_info "Desinstalando Poetry..."

    # Check if Poetry is installed

    if ! command -v poetry &> /dev/null; then
        log_warning "Poetry não está instalado"
        log_info "Nada a fazer"
        return 0
    fi

    local version=$(get_poetry_version)
    log_debug "Versão a ser removida: $version"

    # Confirm uninstallation
    echo ""
    log_output "${YELLOW}Deseja realmente desinstalar o Poetry $version? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sSyY]$ ]]; then
        log_info "Desinstalação cancelada"
        return 1
    fi

    local poetry_home=$(get_poetry_home)

    # Download uninstaller
    log_info "Baixando desinstalador do Poetry..."

    local uninstall_script="/tmp/poetry-uninstaller-$$.py"

    if ! curl -sSL "$POETRY_INSTALL_URL" -o "$uninstall_script"; then
        log_error "Falha ao baixar o desinstalador"
        rm -f "$uninstall_script"

        # Fallback: remove manually
        log_info "Removendo manualmente..."
        rm -rf "$poetry_home"
    else
        log_debug "Desinstalador baixado em: $uninstall_script"

        # Run uninstaller
        log_info "Executando desinstalador..."

        export POETRY_HOME="$poetry_home"
        python3 "$uninstall_script" --uninstall 2>&1 | while read -r line; do log_debug "uninstaller: $line"; done || {
            log_debug "Desinstalador falhou, removendo manualmente..."
            rm -rf "$poetry_home"
        }

        rm -f "$uninstall_script"
        log_debug "Desinstalador removido"
    fi

    # Remove shell configurations
    local shell_config=$(detect_shell_config)

    if [ -f "$shell_config" ] && grep -q "POETRY_HOME\|poetry/bin" "$shell_config" 2> /dev/null; then
        local backup_file="${shell_config}.backup.$(date +%Y%m%d%H%M%S)"

        # Create backup
        cp "$shell_config" "$backup_file"
        log_debug "Backup criado: $backup_file"

        # Remove Poetry lines
        sed -i.tmp '/# Poetry (Python dependency manager)/d' "$shell_config"
        sed -i.tmp '/POETRY_HOME/d' "$shell_config"
        sed -i.tmp '/poetry\/bin/d' "$shell_config"
        rm -f "${shell_config}.tmp"

        log_debug "Configurações removidas"
    else
        log_debug "Nenhuma configuração encontrada em $shell_config"
    fi

    # Verify removal

    if ! command -v poetry &> /dev/null; then
        # Mark as uninstalled in lock file
        mark_uninstalled "poetry"

        log_success "Poetry desinstalado com sucesso!"

        echo ""
        log_info "Reinicie o terminal ou execute: source $shell_config"
    else
        log_warning "Poetry removido, mas executável ainda encontrado no PATH"
        local poetry_path=$(command -v poetry 2> /dev/null || echo "desconhecido")
        log_debug "Pode ser necessário remover manualmente de: $poetry_path"
    fi

    # Ask about cache and config removal
    echo ""
    log_output "${YELLOW}Deseja remover também o cache e configurações do Poetry? (s/N)${NC}"
    read -r config_response

    if [[ "$config_response" =~ ^[sSyY]$ ]]; then
        rm -rf "$HOME/.cache/pypoetry" 2> /dev/null || true

        rm -rf "$HOME/.config/pypoetry" 2> /dev/null || true
        log_debug "Configurações removidas: ~/.config/pypoetry"

        log_success "Cache e configurações removidos"
    else
        log_info "Cache e configurações mantidos"
    fi
}

# Main function
main() {
    local action="install"

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
            --uninstall)
                action="uninstall"
                shift
                ;;
            --update)
                action="update"
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Execute action

    case "$action" in
        install)
            if ! check_existing_installation; then
                exit 0
            fi
            install_poetry
            ;;
        update)
            update_poetry
            ;;
        uninstall)
            uninstall_poetry
            ;;
        *)
            log_error "Ação desconhecida: $action"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
