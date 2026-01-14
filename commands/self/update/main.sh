#!/bin/bash
set -euo pipefail
IFS=$'\n\t'


# Source libraries
source "$LIB_DIR/internal/args.sh"

# Settings
REPO_URL="${CLI_REPO_URL:-https://github.com/duducp/susa.git}"
REPO_BRANCH="${CLI_REPO_BRANCH:-main}"
TEMP_DIR=$(mktemp -d)

# Cleanup function to remove temp directory on exit
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT # Execute cleanup on script exit

# Help function
show_help() {
    show_description
    echo ""
    show_usage "[options]"
    echo ""
    echo -e "${LIGHT_GREEN}Descrição:${NC}"
    echo "  Atualiza o Susa CLI para a versão mais recente disponível no repositório."
    echo "  Verifica se há atualizações e, se disponível, baixa e instala a nova versão."
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  -v, --verbose     Modo verbose (debug)"
    echo "  -q, --quiet       Modo silencioso (mínimo de output)"
    echo "  -h, --help        Exibe esta mensagem de ajuda"
    echo ""
    echo -e "${LIGHT_GREEN}Como funciona:${NC}"
    echo "  • Compara a versão atual com a versão mais recente no GitHub"
    echo "  • Preserva plugins instalados e configurações personalizadas"
    echo "  • Baixa a nova versão em diretório temporário"
    echo "  • Atualiza os arquivos mantendo o registry de plugins"
    echo "  • Remove arquivos temporários automaticamente"
    echo ""
    echo -e "${LIGHT_GREEN}Variáveis de ambiente:${NC}"
    echo "  CLI_REPO_URL      URL do repositório (padrão: github.com/duducp/susa)"
    echo "  CLI_REPO_BRANCH   Branch a usar (padrão: main)"
    echo "  DEBUG             Ativa logs de debug (true, 1, on)"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo "  susa self update              # Verifica e atualiza se houver nova versão"
    echo "  DEBUG=true susa self update   # Atualiza com logs de debug"
    echo "  susa self update --help       # Exibe esta ajuda"
    echo ""
}

# Function to get the current version
get_current_version() {
    log_debug "Obtendo versão atual do config"
    local version=$(get_yaml_field "$GLOBAL_CONFIG_FILE" "version")
    log_debug "Versão atual: $version"
    echo "$version"
}

# Function to get the latest version from the repository
get_latest_version() {
    local latest_version
    local method=""

    log_debug "Tentando obter versão via GitHub API"

    # Try to obtain via GitHub API
    latest_version=$(curl -s --max-time 10 --connect-timeout 5 \
        https://api.github.com/repos/duducp/susa/releases/latest 2>/dev/null \
        | grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')

    if [[ -n "$latest_version" ]]; then
        log_debug "Versão obtida via API: $latest_version"
        echo "$latest_version|api"
        return 0
    fi

    log_debug "API falhou, tentando via arquivo cli.yaml remoto"

    # If it fails, try to get the version of cli.yaml from the remote repository
    latest_version=$(curl -s --max-time 10 --connect-timeout 5 \
        "https://raw.githubusercontent.com/duducp/susa/${REPO_BRANCH}/cli.yaml" 2>/dev/null \
        | grep 'version:' | head -1 | sed -E 's/.*version: *"?([^"]+)"?/\1/')

    if [[ -n "$latest_version" ]]; then
        log_debug "Versão obtida via cli.yaml: $latest_version"
        echo "$latest_version|raw"
        return 0
    fi

    log_debug "Não foi possível obter versão remota"
    return 1
}

# Function to compare versions
version_greater_than() {
    local version1=$1
    local version2=$2

    log_debug "Comparando versões: $version1 vs $version2"

    # Remove prefix 'v' if exists
    version1=${version1#v}
    version2=${version2#v}

    # Uses sort -V for version comparison
    local higher=$(echo -e "$version1\n$version2" | sort -V | tail -n1)

    log_debug "Versão maior: $higher"

    [[ "$version2" == "$higher" && "$version1" != "$version2" ]]
}

# Main update function
perform_update() {
    log_info "Iniciando atualização do Susa CLI..."
    log_debug "Diretório temporário: $TEMP_DIR"
    log_debug "CLI_DIR: $CLI_DIR"

    # Clones the repository
    cd "$TEMP_DIR"
    log_info "Baixando versão mais recente do repositório..."
    log_debug "Clonando de: $REPO_URL (branch: $REPO_BRANCH)"

    if ! git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" susa-update 2>/dev/null; then
        log_error "Falha ao baixar atualização do repositório"
        log_info "Verifique sua conexão com a internet e tente novamente"
        return 1
    fi

    log_debug "Clone concluído, entrando no diretório susa-update"
    cd susa-update

    # Check if cli.yaml exists
    log_debug "Verificando arquivo cli.yaml"
    if [ ! -f "cli.yaml" ]; then
        log_error "Arquivo de configuração não encontrado na versão baixada"
        return 1
    fi

    log_debug "Arquivo cli.yaml encontrado"

    # Preserve critical files before updating
    log_info "Preservando configurações de plugins..."
    log_debug "Verificando existência de registry.yaml"
    local backup_registry=""
    if [ -f "$CLI_DIR/plugins/registry.yaml" ]; then
        backup_registry="$TEMP_DIR/registry.yaml.backup"
        cp "$CLI_DIR/plugins/registry.yaml" "$backup_registry"
        log_debug "Backup do registry de plugins criado em: $backup_registry"
    else
        log_debug "Nenhum registry de plugins para preservar"
    fi

    # Copy new files (except .git)
    log_info "Instalando arquivos atualizados..."
    log_debug "Destino: $CLI_DIR"

    # Remove .git directory before copying
    log_debug "Removendo diretório .git"
    rm -rf .git
    log_debug "Diretório .git removido"

    # Copy all files to the CLI directory
    log_debug "Copiando arquivos para $CLI_DIR"
    cp -rf ./* "$CLI_DIR/"
    log_debug "Arquivos copiados com sucesso"

    # Restores plugin registry if there was a backup
    if [ -n "$backup_registry" ] && [ -f "$backup_registry" ]; then
        log_debug "Restaurando registry de plugins"
        cp "$backup_registry" "$CLI_DIR/plugins/registry.yaml"
        log_debug "Registry de plugins restaurado"
    fi

    log_success "Arquivos atualizados com sucesso!"

    # Update lock file after successful update
    log_info "Atualizando arquivo de cache..."
    log_debug "Executando: $CORE_DIR/susa self lock"
    if "$CORE_DIR/susa" self lock > /dev/null 2>&1; then
        log_debug "Lock file atualizado com sucesso"
    else
        log_warning "Não foi possível atualizar o lock file. Execute 'susa self lock' manualmente."
    fi

    return 0
}

# Main function
main() {
    log_info "Verificando atualizações..."
    log_debug "CLI_DIR: $CLI_DIR"
    log_debug "GLOBAL_CONFIG_FILE: $GLOBAL_CONFIG_FILE"

    # Get current version
    CURRENT_VERSION=$(get_current_version)
    log_debug "Versão atual obtida do arquivo: $CURRENT_VERSION"
    log_info "Versão atual: $CURRENT_VERSION"

    # Get latest version
    log_debug "Tentando obter versão mais recente via GitHub..."
    LATEST_VERSION_RESULT=$(get_latest_version)

    if [[ -z "$LATEST_VERSION_RESULT" ]]; then
        log_debug "Falha ao obter versão mais recente por todos os métodos"
        log_error "Não foi possível obter informações sobre a versão mais recente"
        log_info "Verifique sua conexão com a internet e tente novamente"
        exit 1
    fi

    # Parse result (version|method)
    IFS='|' read -r LATEST_VERSION METHOD <<< "$LATEST_VERSION_RESULT"

    if [[ "$METHOD" == "api" ]]; then
        log_debug "Versão obtida via GitHub API: $LATEST_VERSION"
    elif [[ "$METHOD" == "raw" ]]; then
        log_debug "API do GitHub falhou, versão obtida via raw content: $LATEST_VERSION"
    fi

    log_info "Última versão disponível: $LATEST_VERSION"

    # Compare versions
    log_debug "Comparando versões: $CURRENT_VERSION vs $LATEST_VERSION"
    if version_greater_than "$CURRENT_VERSION" "$LATEST_VERSION"; then
        echo ""
        log_success "Nova atualização disponível! ($CURRENT_VERSION → $LATEST_VERSION)"
        echo ""

        # Ask if you want to update
        if [ -t 0 ]; then
            read -p "Deseja atualizar agora? (s/N): " -n 1 -r
            echo ""

            if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
                log_info "Atualização cancelada pelo usuário"
                exit 0
            fi
        fi

        echo ""

        # Run update
        if perform_update; then
            echo ""
            log_success "✓ Susa CLI atualizado para versão $LATEST_VERSION!"
            echo ""
            log_info "Execute 'susa self version' para confirmar a versão"
        else
            log_error "Falha ao atualizar o Susa CLI"
            exit 1
        fi
    else
        echo ""
        log_success "✓ Você já está usando a versão mais recente!"
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            export DEBUG=1
            log_debug "Modo verbose ativado"
            shift
            ;;
        -q|--quiet)
            export SILENT=1
            shift
            ;;
        *)
            log_error "Argumento inválido: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
done

# Execute main function
main
