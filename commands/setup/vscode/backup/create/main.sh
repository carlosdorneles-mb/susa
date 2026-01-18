#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Create backup of VSCode configurations and profiles
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
        log_info "Use: susa setup vscode install"
        return 1
    fi

    return 0
}

# Show help
show_help() {
    show_description
    log_output ""
    show_usage "[opções]"
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help              Mostra esta mensagem de ajuda"
    log_output "  --name <nome>           Nome do backup (padrão: vscode-backup-YYYYMMDD-HHMMSS)"
    log_output "  --no-extensions         Não incluir extensões no backup"
    log_output "  --dir <diretório>       Diretório onde salvar o backup"
    log_output "  -v, --verbose           Habilita saída detalhada"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup vscode backup create                      # Cria backup com nome automático"
    log_output "  susa setup vscode backup create --name my-backup     # Cria backup com nome específico"
    log_output "  susa setup vscode backup create --no-extensions      # Backup sem extensões"
    log_output ""
    log_output "${LIGHT_GREEN}O que é incluído no backup:${NC}"
    log_output "  • Configurações do usuário (settings.json)"
    log_output "  • Perfis personalizados"
    log_output "  • Snippets personalizados"
    log_output "  • Keybindings (atalhos de teclado)"
    log_output "  • Lista de extensões instaladas"
    log_output "  • Metadados do backup (data, versão, etc.)"
}

# Create backup of VSCode configurations
create_backup() {
    local backup_name="${1:-}"
    local include_extensions="${2:-true}"

    # Check if VSCode is installed
    if ! check_vscode_installation; then
        return 1
    fi

    # Get configuration paths
    if ! get_vscode_config_paths; then
        return 1
    fi

    # Check if configuration directory exists
    if [ ! -d "$VSCODE_CONFIG_DIR" ]; then
        log_error "Diretório de configuração do VS Code não encontrado: $VSCODE_CONFIG_DIR"
        return 1
    fi

    # Generate backup name if not provided
    if [ -z "$backup_name" ]; then
        backup_name="vscode-backup-$(date +%Y%m%d-%H%M%S)"
    fi

    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"

    local backup_path="$BACKUP_DIR/$backup_name"
    local backup_archive="$backup_path.tar.gz"

    log_info "Criando backup do VS Code..."
    log_debug "Backup será salvo em: $backup_archive"

    # Create temporary directory for backup
    local temp_backup_dir=$(mktemp -d)
    local backup_content_dir="$temp_backup_dir/vscode-backup"
    mkdir -p "$backup_content_dir"

    # Backup User settings
    if [ -d "$VSCODE_CONFIG_DIR/User" ]; then
        log_info "Copiando configurações do usuário..."
        mkdir -p "$backup_content_dir/User"
        cp -r "$VSCODE_CONFIG_DIR/User"/* "$backup_content_dir/User/" 2> /dev/null || true
    fi

    # Backup User profiles
    if [ -d "$VSCODE_CONFIG_DIR/User/profiles" ]; then
        log_info "Copiando perfis de usuário..."
        mkdir -p "$backup_content_dir/User/profiles"
        cp -r "$VSCODE_CONFIG_DIR/User/profiles"/* "$backup_content_dir/User/profiles/" 2> /dev/null || true
    fi

    # Backup snippets
    if [ -d "$VSCODE_CONFIG_DIR/User/snippets" ]; then
        log_info "Copiando snippets..."
        mkdir -p "$backup_content_dir/User/snippets"
        cp -r "$VSCODE_CONFIG_DIR/User/snippets"/* "$backup_content_dir/User/snippets/" 2> /dev/null || true
    fi

    # Backup keybindings
    if [ -f "$VSCODE_CONFIG_DIR/User/keybindings.json" ]; then
        log_info "Copiando keybindings..."
        cp "$VSCODE_CONFIG_DIR/User/keybindings.json" "$backup_content_dir/User/" 2> /dev/null || true
    fi

    # Backup extensions list
    if [ "$include_extensions" = "true" ]; then
        log_info "Exportando lista de extensões..."
        code --list-extensions > "$backup_content_dir/extensions.txt" 2> /dev/null || true

        # Also backup extensions directory if it exists
        if [ -d "$VSCODE_USER_DIR/extensions" ]; then
            log_info "Copiando diretório de extensões..."
            mkdir -p "$backup_content_dir/extensions"
            # Only backup extension configuration, not the full extensions (too large)
            find "$VSCODE_USER_DIR/extensions" -name "package.json" -o -name "*.json" | while read -r file; do
                local rel_path="${file#"$VSCODE_USER_DIR"/extensions/}"
                local target_dir="$backup_content_dir/extensions/$(dirname "$rel_path")"
                mkdir -p "$target_dir"
                cp "$file" "$target_dir/" 2> /dev/null || true
            done
        fi
    fi

    # Create metadata file
    log_info "Criando arquivo de metadados..."
    cat > "$backup_content_dir/backup-info.json" << EOF
{
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "os": "$(uname -s)",
  "vscode_version": "$(code --version 2> /dev/null | head -1 || echo "unknown")",
  "backup_name": "$backup_name",
  "include_extensions": $include_extensions
}
EOF

    # Create compressed archive
    log_info "Compactando backup..."
    tar -czf "$backup_archive" -C "$temp_backup_dir" vscode-backup > /dev/null 2>&1

    # Clean up temporary directory
    rm -rf "$temp_backup_dir"

    if [ -f "$backup_archive" ]; then
        local backup_size=$(du -h "$backup_archive" | cut -f1)
        log_success "✓ Backup criado com sucesso!"
        log_output ""
        log_output "${LIGHT_GREEN}Local:${NC} $backup_archive"
        log_output "${LIGHT_GREEN}Tamanho:${NC} $backup_size"
        log_output ""
        log_output "${LIGHT_GREEN}Para restaurar:${NC}"
        log_output "  susa setup vscode backup restore $backup_name"
        return 0
    else
        log_error "Falha ao criar arquivo de backup"
        return 1
    fi
}

# Main function
main() {
    local backup_name=""
    local include_extensions="true"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                show_help
                exit 0
                ;;
            --name)
                backup_name="$2"
                shift 2
                ;;
            --no-extensions)
                include_extensions="false"
                shift
                ;;
            --dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            -v | --verbose)
                export DEBUG=true
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_usage "[opções]"
                exit 1
                ;;
        esac
    done

    # Create backup
    create_backup "$backup_name" "$include_extensions"
}

# Execute main
main "$@"
