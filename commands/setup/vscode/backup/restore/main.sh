#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Restore VSCode configurations from backup
# Source libraries
source "$LIB_DIR/os.sh"

# Default backup directory
DEFAULT_BACKUP_DIR="$HOME/.susa/backups/vscode"
BACKUP_DIR="${VSCODE_BACKUP_DIR:-$DEFAULT_BACKUP_DIR}"

# Get VSCode configuration paths based on OS
get_vscode_config_paths() {
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$os_name" in
        darwin)
            VSCODE_CONFIG_DIR="$HOME/Library/Application Support/Code"
            VSCODE_USER_DIR="$HOME/.vscode"
            ;;
        linux)
            VSCODE_CONFIG_DIR="$HOME/.config/Code"
            VSCODE_USER_DIR="$HOME/.vscode"
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    return 0
}

# Check if VSCode is installed
check_vscode_installation() {
    if ! command -v code &> /dev/null; then
        log_error "VS Code não está instalado"
        log_info "Use: susa setup vscode"
        return 1
    fi

    return 0
}

# Show help
show_help() {
    show_description
    log_output ""
    show_usage "<nome-do-backup> [opções]"
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help              Mostra esta mensagem de ajuda"
    log_output "  --no-extensions         Não reinstalar extensões"
    log_output "  -y, --yes               Pula confirmação"
    log_output "  --info                  Mostra informações do backup sem restaurar"
    log_output "  --dir <diretório>       Diretório de onde restaurar o backup"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup vscode backup restore my-backup              # Restaura backup específico"
    log_output "  susa setup vscode backup restore my-backup -y           # Restaura sem confirmação"
    log_output "  susa setup vscode backup restore my-backup --info       # Mostra info do backup"
    log_output "  susa setup vscode backup restore my-backup --no-extensions  # Restaura sem extensões"
    log_output ""
    log_output "${LIGHT_GREEN}Nota:${NC}"
    log_output "  Um backup de segurança das configurações atuais é criado automaticamente"
    log_output "  antes da restauração, permitindo reverter se necessário."
}

# Show backup information
show_backup_info() {
    local backup_name="$1"
    local backup_archive="$BACKUP_DIR/$backup_name.tar.gz"

    if [ ! -f "$backup_archive" ]; then
        log_error "Backup não encontrado: $backup_name"
        log_info "Use: susa setup vscode backup list"
        return 1
    fi

    log_info "Informações do backup: $backup_name"
    log_output ""

    # Extract backup info
    local temp_dir=$(mktemp -d)
    tar -xzf "$backup_archive" -C "$temp_dir" vscode-backup/backup-info.json 2> /dev/null || true

    if [ -f "$temp_dir/vscode-backup/backup-info.json" ]; then
        local created_at=$(jq -r '.created_at' "$temp_dir/vscode-backup/backup-info.json" 2> /dev/null || echo "unknown")
        local os_type=$(jq -r '.os' "$temp_dir/vscode-backup/backup-info.json" 2> /dev/null || echo "unknown")
        local vscode_version=$(jq -r '.vscode_version' "$temp_dir/vscode-backup/backup-info.json" 2> /dev/null || echo "unknown")
        local include_extensions=$(jq -r '.include_extensions' "$temp_dir/vscode-backup/backup-info.json" 2> /dev/null || echo "unknown")

        log_output "${LIGHT_GREEN}Data de criação:${NC} $created_at"
        log_output "${LIGHT_GREEN}Sistema operacional:${NC} $os_type"
        log_output "${LIGHT_GREEN}Versão do VS Code:${NC} $vscode_version"
        log_output "${LIGHT_GREEN}Inclui extensões:${NC} $include_extensions"
    fi

    local backup_size=$(du -h "$backup_archive" | cut -f1)
    log_output "${LIGHT_GREEN}Tamanho do backup:${NC} $backup_size"

    # Clean up
    rm -rf "$temp_dir"

    log_output ""
}

# Restore backup
restore_backup() {
    local backup_name="$1"
    local install_extensions="${2:-true}"
    local skip_confirm="${3:-false}"

    # Check if VSCode is installed
    if ! check_vscode_installation; then
        return 1
    fi

    # Get configuration paths
    if ! get_vscode_config_paths; then
        return 1
    fi

    local backup_archive="$BACKUP_DIR/$backup_name.tar.gz"

    # Check if backup exists
    if [ ! -f "$backup_archive" ]; then
        log_error "Backup não encontrado: $backup_name"
        log_info "Use: susa setup vscode backup list"
        return 1
    fi

    # Show backup info
    show_backup_info "$backup_name"

    # Confirm restoration
    if [ "$skip_confirm" = "false" ]; then
        log_output "${YELLOW}Deseja restaurar este backup? Isso substituirá suas configurações atuais. (s/N)${NC}"
        read -r response

        if [[ ! "$response" =~ ^[sSyY]$ ]]; then
            log_info "Restauração cancelada"
            return 0
        fi
    fi

    log_info "Restaurando backup do VS Code..."

    # Create backup of current configuration before restoring
    local current_backup_name="vscode-pre-restore-$(date +%Y%m%d-%H%M%S)"
    log_info "Criando backup das configurações atuais..."

    # Create a safety backup (simple version)
    if [ -d "$VSCODE_CONFIG_DIR" ]; then
        local temp_backup_dir=$(mktemp -d)
        local safety_backup="$BACKUP_DIR/$current_backup_name.tar.gz"
        mkdir -p "$BACKUP_DIR"
        tar -czf "$safety_backup" -C "$(dirname "$VSCODE_CONFIG_DIR")" "$(basename "$VSCODE_CONFIG_DIR")" > /dev/null 2>&1 || true
        log_debug "Backup de segurança criado: $current_backup_name"
    fi

    # Extract backup to temporary directory
    local temp_restore_dir=$(mktemp -d)
    log_info "Extraindo backup..."
    tar -xzf "$backup_archive" -C "$temp_restore_dir" > /dev/null 2>&1

    local backup_content_dir="$temp_restore_dir/vscode-backup"

    if [ ! -d "$backup_content_dir" ]; then
        log_error "Backup corrompido ou inválido"
        rm -rf "$temp_restore_dir"
        return 1
    fi

    # Create VSCode configuration directory if it doesn't exist
    mkdir -p "$VSCODE_CONFIG_DIR/User"

    # Restore User settings
    if [ -d "$backup_content_dir/User" ]; then
        log_info "Restaurando configurações do usuário..."
        cp -r "$backup_content_dir/User"/* "$VSCODE_CONFIG_DIR/User/" 2> /dev/null || true
    fi

    # Restore profiles
    if [ -d "$backup_content_dir/User/profiles" ]; then
        log_info "Restaurando perfis de usuário..."
        mkdir -p "$VSCODE_CONFIG_DIR/User/profiles"
        cp -r "$backup_content_dir/User/profiles"/* "$VSCODE_CONFIG_DIR/User/profiles/" 2> /dev/null || true
    fi

    # Restore snippets
    if [ -d "$backup_content_dir/User/snippets" ]; then
        log_info "Restaurando snippets..."
        mkdir -p "$VSCODE_CONFIG_DIR/User/snippets"
        cp -r "$backup_content_dir/User/snippets"/* "$VSCODE_CONFIG_DIR/User/snippets/" 2> /dev/null || true
    fi

    # Restore keybindings
    if [ -f "$backup_content_dir/User/keybindings.json" ]; then
        log_info "Restaurando keybindings..."
        cp "$backup_content_dir/User/keybindings.json" "$VSCODE_CONFIG_DIR/User/" 2> /dev/null || true
    fi

    # Restore extensions
    if [ "$install_extensions" = "true" ] && [ -f "$backup_content_dir/extensions.txt" ]; then
        log_info "Restaurando extensões..."
        log_output ""

        local extension_count=$(wc -l < "$backup_content_dir/extensions.txt")
        log_info "Instalando $extension_count extensões..."

        local installed=0
        local failed=0

        while IFS= read -r extension; do
            if [ -n "$extension" ]; then
                log_debug "Instalando extensão: $extension"
                if code --install-extension "$extension" --force > /dev/null 2>&1; then
                    installed=$((installed + 1))
                else
                    failed=$((failed + 1))
                    log_warning "Falha ao instalar: $extension"
                fi
            fi
        done < "$backup_content_dir/extensions.txt"

        log_output ""
        log_info "Extensões instaladas: $installed"
        if [ $failed -gt 0 ]; then
            log_warning "Extensões com falha: $failed"
        fi
    fi

    # Clean up temporary directory
    rm -rf "$temp_restore_dir"

    log_success "✓ Backup restaurado com sucesso!"
    log_output ""
    log_output "${LIGHT_GREEN}Próximos passos:${NC}"
    log_output "  1. Reinicie o VS Code para aplicar todas as configurações"
    log_output "  2. Verifique se suas configurações foram restauradas corretamente"

    if [ -n "${current_backup_name:-}" ]; then
        log_output ""
        log_output "${LIGHT_GREEN}Backup de segurança criado:${NC} $current_backup_name"
        log_output "  Para reverter: susa setup vscode backup restore $current_backup_name"
    fi

    return 0
}

# Main function
main() {
    local backup_name=""
    local install_extensions="true"
    local skip_confirm="false"
    local show_info=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                show_help
                exit 0
                ;;
            --no-extensions)
                install_extensions="false"
                shift
                ;;
            -y | --yes)
                skip_confirm="true"
                shift
                ;;
            --info)
                show_info=true
                shift
                ;;
            --dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            -*)
                log_error "Opção desconhecida: $1"
                show_usage "<nome-do-backup> [opções]"
                exit 1
                ;;
            *)
                # First non-option argument is the backup name
                if [ -z "$backup_name" ]; then
                    backup_name="$1"
                    shift
                else
                    log_error "Argumento inesperado: $1"
                    show_usage "<nome-do-backup> [opções]"
                    exit 1
                fi
                ;;
        esac
    done

    # Check if backup name was provided
    if [ -z "$backup_name" ]; then
        log_error "Nome do backup não especificado"
        show_usage "<nome-do-backup> [opções]"
        exit 1
    fi

    # Execute action
    if [ "$show_info" = true ]; then
        show_backup_info "$backup_name"
    else
        restore_backup "$backup_name" "$install_extensions" "$skip_confirm"
    fi
}

# Execute main
main "$@"
