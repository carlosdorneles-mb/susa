#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- Command Existence Checks ---

# Check if a command exists in the system
# Usage:
#   command_exists "command_name"
# Example:
#   if command_exists "curl"; then
#       echo "curl is installed"
#   fi
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if multiple dependencies are installed
# Returns 0 if all are installed, 1 otherwise
# Usage:
#   check_dependencies "curl" "jq" "git"
# Example:
#   if ! check_dependencies "curl" "jq" "git"; then
#       echo "Some dependencies are missing."
#   fi
check_dependencies() {
    local missing=()

    for cmd in "$@"; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Dependências faltando: ${missing[*]}"
        return 1
    fi

    return 0
}

# --- Package Manager Lock Helper ---

# Wait for apt lock to be released
wait_for_apt_lock() {
    local max_wait=60
    local waited=0

    while sudo fuser /var/lib/apt/lists/lock > /dev/null 2>&1 ||
        sudo fuser /var/lib/dpkg/lock > /dev/null 2>&1 ||
        sudo fuser /var/lib/dpkg/lock-frontend > /dev/null 2>&1; do

        if [ $waited -eq 0 ]; then
            log_info "Aguardando outros processos apt finalizarem..."
        fi

        if [ $waited -ge $max_wait ]; then
            log_error "Timeout aguardando lock do apt"
            return 1
        fi

        sleep 2
        waited=$((waited + 2))
    done

    return 0
}

# --- Pip3 Helper Function ---

# Ensure pip3 is installed. If not, try installing.
ensure_pip3_installed() {
    if command -v pip3 &> /dev/null; then
        return 0
    fi

    log_warning "pip3 não encontrado. Tentando instalar python3-pip..."

    if command -v apt-get &> /dev/null; then
        wait_for_apt_lock || return 1
        sudo apt-get update -qq > /dev/null 2>&1
        sudo apt-get install -y python3-pip > /dev/null 2>&1
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y python3-pip > /dev/null 2>&1
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3-pip > /dev/null 2>&1
    else
        log_error "Gerenciador de pacotes não suportado para instalação do pip3"
        return 1
    fi

    if ! command -v pip3 &> /dev/null; then
        log_error "Falha ao instalar o pip3. Instale manualmente."
        return 1
    fi

    log_success "pip3 instalado com sucesso."
    return 0
}

# --- Curl Helper Function ---

# Ensure curl is installed. If not, try installing.
ensure_curl_installed() {
    if command -v curl &> /dev/null; then
        return 0
    fi

    log_warning "curl não encontrado. Tentando instalar curl..."

    case "$OS_TYPE" in
        debian)
            sudo apt-get update && sudo apt-get install -y curl
            ;;
        fedora)
            if command -v dnf &> /dev/null; then
                sudo dnf install -y curl
            else
                sudo yum install -y curl
            fi
            ;;
        macos)
            if command -v brew &> /dev/null; then
                brew install curl
            else
                log_error "Homebrew não encontrado. Instale o Homebrew ou o curl manualmente: https://brew.sh/"
                return 1
            fi
            ;;
        *)
            log_error "Sistema operacional não suportado para instalação automática do curl. Instale manualmente."
            return 1
            ;;
    esac

    if ! command -v curl &> /dev/null; then
        log_error "Falha ao instalar o curl. Instale manualmente."
        return 1
    fi

    log_success "curl instalado com sucesso."
    return 0
}

# --- JQ Helper Function ---

# Make sure jq is installed. If not, try installing.
ensure_jq_installed() {
    if command -v jq &> /dev/null; then
        return 0
    fi

    log_warning "jq não encontrado. Tentando instalar jq..."

    case "$OS_TYPE" in
        debian)
            sudo apt-get update && sudo apt-get install -y jq
            ;;
        fedora)
            if command -v dnf &> /dev/null; then
                sudo dnf install -y jq
            else
                sudo yum install -y jq
            fi
            ;;
        macos)
            if command -v brew &> /dev/null; then
                brew install jq
            else
                log_error "Homebrew não encontrado. Instale o Homebrew ou o jq manualmente: https://brew.sh/"
                return 1
            fi
            ;;
        *)
            log_error "Sistema operacional não suportado para instalação automática do jq. Instale manualmente."
            return 1
            ;;
    esac

    if ! command -v jq &> /dev/null; then
        log_error "Falha ao instalar o jq. Instale manualmente."
        return 1
    fi

    log_success "jq instalado com sucesso."
    return 0
}

# --- YQ Helper Function ---

ensure_yq_installed() {
    if command -v yq &> /dev/null; then
        return 0
    fi

    log_warning "yq não encontrado. Iniciando instalação da versão mais recente..."

    # Ensures dependencies to discover version and download
    ensure_curl_installed || return 1
    ensure_jq_installed || return 1

    # 1. Find out the latest version
    local latest_tag
    latest_tag=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r '.tag_name')
    local version_no_v="${latest_tag#v}"

    # 2. Detect Platform and Architecture
    local platform="linux"
    [[ "$OS_TYPE" == "macos" ]] && platform="darwin"

    local arch="amd64"
    local machine_arch
    machine_arch=$(uname -m)
    case "$machine_arch" in
        arm64 | aarch64) arch="arm64" ;;
        x86_64) arch="amd64" ;;
        i386 | i686) arch="386" ;;
    esac

    # 3. Download and Installation
    local binary="yq_${platform}_${arch}"
    local download_url="https://github.com/mikefarah/yq/releases/download/${latest_tag}/${binary}"
    local temp_dir
    temp_dir=$(mktemp -d)

    log_info "Baixando yq ${latest_tag} para ${platform}_${arch}..."

    if curl -L "$download_url" -o "${temp_dir}/yq"; then
        log_info "Instalando binário em /usr/local/bin (pode solicitar sudo)..."
        if sudo mv "${temp_dir}/yq" /usr/local/bin/yq; then
            sudo chmod +x /usr/local/bin/yq
            log_success "yq instalado com sucesso: $(yq --version)"
        else
            log_error "Falha ao mover o binário para /usr/local/bin."
            rm -rf "$temp_dir"
            return 1
        fi
    else
        log_error "Erro ao baixar o yq do GitHub. Verifique sua conexão."
        rm -rf "$temp_dir"
        return 1
    fi

    rm -rf "$temp_dir"
    return 0
}

# --- FZF Helper Function ---

# Checks if fzf is installed. If not, install the latest version from GitHub.
ensure_fzf_installed() {
    if command -v fzf &> /dev/null; then
        return 0
    fi

    log_warning "fzf não encontrado. Iniciando instalação da versão mais recente..."

    # Ensures dependencies to discover version and download
    ensure_curl_installed || return 1
    ensure_jq_installed || return 1

    # 1. Find out the latest version and prepare variables
    local latest_tag
    latest_tag=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | jq -r '.tag_name')
    local version_no_v="${latest_tag#v}"

    # 2. Detect Platform and Architecture
    local platform="linux"
    [[ "$OS_TYPE" == "macos" ]] && platform="darwin"

    local arch="amd64"
    local machine_arch
    machine_arch=$(uname -m)
    case "$machine_arch" in
        arm64 | aarch64) arch="arm64" ;;
        x86_64) arch="amd64" ;;
        i386 | i686) arch="386" ;;
    esac

    # 3. Download and Installation
    local tarball="fzf-${version_no_v}-${platform}_${arch}.tar.gz"
    local download_url="https://github.com/junegunn/fzf/releases/download/${latest_tag}/${tarball}"
    local temp_dir
    temp_dir=$(mktemp -d)

    log_info "A baixar fzf ${latest_tag} para ${platform}_${arch}..."

    if curl -L "$download_url" -o "${temp_dir}/${tarball}"; then
        tar -xzf "${temp_dir}/${tarball}" -C "${temp_dir}"

        log_info "A instalar binário em /usr/local/bin (pode solicitar sudo)..."
        if sudo mv "${temp_dir}/fzf" /usr/local/bin/fzf; then
            sudo chmod +x /usr/local/bin/fzf
            log_success "fzf instalado com sucesso: $(fzf --version)"
        else
            log_error "Falha ao mover o binário para /usr/local/bin."
            rm -rf "$temp_dir"
            return 1
        fi
    else
        log_error "Erro ao descarregar o fzf do GitHub. Verifique a sua ligação."
        rm -rf "$temp_dir"
        return 1
    fi

    rm -rf "$temp_dir"
    return 0
}
