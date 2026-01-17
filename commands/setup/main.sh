#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source "$LIB_DIR/internal/installations.sh"
source "$LIB_DIR/internal/cache.sh"
source "$LIB_DIR/sudo.sh"

show_help() {
    echo ""
    log_output "${LIGHT_GREEN}Comandos disponíveis para a categoria 'setup':${NC}"
    log_output "  --group                Agrupa a saída por status de atualização"
    log_output "  --list                 Lista todos os softwares instalados"
    log_output "  --check-updates        Lista e verifica atualizações disponíveis dos softwares"
    log_output "  -u, --upgrade          Atualiza todos os softwares instalados ${YELLOW}[sudo]${NC}"
    log_output "  -us, --update-system   Atualiza também dependências do sistema operacional ${YELLOW}[sudo]${NC}"
    echo ""
    log_output "Use ${LIGHT_CYAN}susa setup <comando> --help${NC} para ver mais detalhes sobre um comando específico."
    echo ""
}

# Show complement help for the category
# This function is called by the CLI when user runs `susa setup`
# It shows additional options related to the category itself
show_complement_help() {
    echo ""
    log_output "${LIGHT_GREEN}Opções da categoria:${NC}"
    log_output "  --group 			  Agrupa a saída por status de atualização"
    log_output "  --list                 Lista todos os softwares instalados"
    log_output "  --check-updates        Lista e verifica atualizações disponíveis dos softwares"
    log_output "  -u, --upgrade          Atualiza todos os softwares instalados ${YELLOW}[sudo]${NC}"
    log_output "  -us, --update-system   Atualiza também dependências do sistema operacional ${YELLOW}[sudo]${NC}"
}

# Update system dependencies based on OS
update_system_dependencies() {
    local os_type=$(uname -s)

    log_output "${LIGHT_GREEN}📦 Atualizando dependências do sistema operacional...${NC}"
    echo ""

    case "$os_type" in
        Linux)
            # Detect package manager
            if command -v apt-get &> /dev/null; then
                log_info "Atualizando pacotes APT..."
                sudo apt-get update 2>&1 | sed 's/^/    /'
                sudo apt-get upgrade -y 2>&1 | sed 's/^/    /'
                log_success "✓ Pacotes APT atualizados"
            elif command -v dnf &> /dev/null; then
                log_info "Atualizando pacotes DNF..."
                sudo dnf upgrade -y 2>&1 | sed 's/^/    /'
                log_success "✓ Pacotes DNF atualizados"
            elif command -v yum &> /dev/null; then
                log_info "Atualizando pacotes YUM..."
                sudo yum update -y 2>&1 | sed 's/^/    /'
                log_success "✓ Pacotes YUM atualizados"
            elif command -v pacman &> /dev/null; then
                log_info "Atualizando pacotes Pacman..."
                sudo pacman -Syu --noconfirm 2>&1 | sed 's/^/    /'
                log_success "✓ Pacotes Pacman atualizados"
            else
                log_warning "Gerenciador de pacotes não identificado"
                return 1
            fi
            ;;
        Darwin)
            if command -v brew &> /dev/null; then
                log_info "Atualizando Homebrew..."
                brew update 2>&1 | sed 's/^/    /'
                brew upgrade 2>&1 | sed 's/^/    /'
                log_success "✓ Homebrew atualizado"
            else
                log_warning "Homebrew não está instalado"
                return 1
            fi
            ;;
        *)
            log_warning "Sistema operacional não suportado: $os_type"
            return 1
            ;;
    esac

    echo ""
    return 0
}

# Upgrade all installed software from this category
upgrade_all() {
    local update_system="$1"

    # Request sudo access upfront
    required_sudo

    # Update system dependencies if requested
    if [ "$update_system" = true ]; then
        update_system_dependencies
        if [ $? -ne 0 ]; then
            log_warning "Continuando com atualização dos softwares..."
            echo ""
        fi
    fi

    # Load cache and get installed software from cache
    cache_load
    local installations=$(get_installed_from_cache)

    if [ -z "$installations" ]; then
        echo ""
        log_warning "Nenhum software instalado encontrado."
        echo ""
        return 0
    fi

    local total=$(echo "$installations" | wc -l | tr -d ' ')

    echo ""
    log_output "${LIGHT_GREEN}🔄 Iniciando atualização de $total software(s)...${NC}"
    echo ""

    local current=0
    local success=0
    local failed=0
    local failed_list=""

    while IFS= read -r software; do
        [ -z "$software" ] && continue

        current=$((current + 1))

        log_output "${CYAN}[$current/$total]${NC} Atualizando ${LIGHT_CYAN}$software${NC}..."

        # Execute update command with --quiet flag
        if "$CORE_DIR/susa" setup "$software" --upgrade --quiet 2>&1 | sed 's/^/    /'; then
            success=$((success + 1))
            log_success "  ✓ $software atualizado com sucesso"
        else
            failed=$((failed + 1))
            failed_list="${failed_list}${failed_list:+, }$software"
            log_error "  ✗ Falha ao atualizar $software"
        fi

        echo ""
    done <<< "$installations"

    # Show final summary
    log_output "${LIGHT_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log_output "${LIGHT_GREEN}✓ Atualização concluída!${NC}"
    echo ""
    log_output "  ${CYAN}Total processado:${NC} $total"
    log_output "  ${GREEN}✓ Sucesso:${NC} $success"

    if [ $failed -gt 0 ]; then
        log_output "  ${RED}✗ Falhas:${NC} $failed"
        log_output "  ${YELLOW}  Softwares com falha: ${failed_list}${NC}"
    fi

    echo ""
}

# Main function
main() {
    # Parse arguments
    local list_mode=false
    local check_updates=false
    local upgrade_mode=false
    local update_system=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --list)
                list_mode=true
                shift
                ;;
            -cu | --check-updates)
                check_updates=true
                list_mode=true # --check-updates implies listing
                shift
                ;;
            -us | --update-system)
                update_system=true
                shift
                ;;
            -u | --upgrade)
                upgrade_mode=true
                shift
                ;;
            *)
                # Unknown option - let the CLI handle it as a command
                log_error "Opção desconhecida: $1"
                echo ""
                log_output "Use ${LIGHT_CYAN}susa setup --help${NC} para ver as opções disponíveis"
                log_output "Ou execute ${LIGHT_CYAN}susa setup${NC} para ver os comandos disponíveis"
                exit 1
                ;;
        esac
    done

    # Execute upgrade if requested
    if [ "$upgrade_mode" = true ]; then
        upgrade_all "$update_system"
        exit 0
    fi

    # Execute list if requested
    if [ "$list_mode" = true ]; then
        if [ "$check_updates" = true ]; then
            list_installed --check-updates
        else
            list_installed
        fi
        exit 0
    fi

    # If no arguments, this shouldn't happen as CLI shows command list
    # But just in case, show help
    show_help
}

# Execute main
if [ "${SUSA_SKIP_MAIN:-}" != "1" ]; then
    main "$@"
fi
