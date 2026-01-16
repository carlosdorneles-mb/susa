#!/bin/bash

# ============================================================
# GitHub Release Management Library
# ============================================================
# Funções reutilizáveis para baixar e verificar releases do GitHub

# Obtém a última versão de um repositório GitHub
# Args: owner/repo
# Retorna: tag_name da última release
github_get_latest_version() {
    local repo="$1"
    local api_url="https://api.github.com/repos/${repo}/releases/latest"
    local max_time="${GITHUB_API_MAX_TIME:-10}"
    local connect_timeout="${GITHUB_API_CONNECT_TIMEOUT:-5}"

    log_debug "Consultando última versão de $repo..."

    local version=$(curl -s \
        --max-time "$max_time" \
        --connect-timeout "$connect_timeout" \
        "$api_url" 2> /dev/null |
        grep '"tag_name":' |
        sed -E 's/.*"([^"]+)".*/\1/')

    if [ -z "$version" ]; then
        log_error "Não foi possível obter a versão mais recente de $repo"
        log_debug "Verifique sua conexão com a internet ou tente novamente"
        return 1
    fi

    log_debug "Última versão: $version"
    echo "$version"
}

# Detecta sistema operacional e arquitetura para download
# Retorna: os_name:arch no formato adequado para releases
github_detect_os_arch() {
    local os_format="${1:-standard}" # standard, darwin-macos, linux-gnu

    # Detectar OS
    local os_name=""
    case "$(uname -s)" in
        Linux*)
            case "$os_format" in
                darwin-macos) os_name="linux" ;;
                linux-gnu) os_name="linux-gnu" ;;
                *) os_name="linux" ;;
            esac
            ;;
        Darwin*)
            case "$os_format" in
                darwin-macos) os_name="darwin" ;;
                *) os_name="macos" ;;
            esac
            ;;
        *)
            log_error "Sistema operacional não suportado: $(uname -s)"
            return 1
            ;;
    esac

    # Detectar arquitetura
    local arch=$(uname -m)
    case "$arch" in
        x86_64) arch="x64" ;;
        aarch64 | arm64) arch="arm64" ;;
        armv7l) arch="armv7" ;;
        i686) arch="x86" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    log_debug "Sistema detectado: ${os_name}:${arch}"
    echo "${os_name}:${arch}"
}

# Constrói URL de download para release do GitHub
# Args: owner/repo version os_name arch file_pattern
# file_pattern pode conter: {version}, {os}, {arch}
# Exemplo: "tool-{version}-{os}-{arch}.tar.gz"
github_build_download_url() {
    local repo="$1"
    local version="$2"
    local os_name="$3"
    local arch="$4"
    local file_pattern="$5"

    # Remove 'v' prefix se presente na versão
    local version_clean="${version#v}"

    # Substitui placeholders
    local filename="${file_pattern//\{version\}/$version_clean}"
    filename="${filename//\{os\}/$os_name}"
    filename="${filename//\{arch\}/$arch}"

    local url="https://github.com/${repo}/releases/download/${version}/${filename}"

    log_debug "URL de download: $url"
    echo "$url"
}

# Baixa arquivo de release do GitHub
# Args: url output_file [description]
# Retorna: 0 em sucesso, 1 em erro
github_download_release() {
    local download_url="$1"
    local output_file="$2"
    local description="${3:-arquivo}"

    log_info "Baixando $description..."
    log_debug "URL: $download_url"
    log_debug "Destino: $output_file"

    # Criar diretório se não existir
    mkdir -p "$(dirname "$output_file")"

    # Download com barra de progresso
    if curl -L --progress-bar \
        --connect-timeout 30 \
        --max-time 300 \
        --retry 3 \
        --retry-delay 2 \
        "$download_url" -o "$output_file" 2>&1 |
        while IFS= read -r line; do
            # Redireciona progresso para stderr
            echo "$line" >&2
        done; then

        if [ ! -f "$output_file" ] || [ ! -s "$output_file" ]; then
            log_error "Arquivo baixado está vazio ou não foi criado"
            rm -f "$output_file"
            return 1
        fi

        log_debug "Download concluído: $(du -h "$output_file" | cut -f1)"
        return 0
    else
        local exit_code=$?
        log_error "Falha ao baixar $description (código: $exit_code)"
        rm -f "$output_file"
        return 1
    fi
}

# Verifica checksum SHA256 de um arquivo
# Args: file checksum_file_or_hash [algorithm]
# algorithm: sha256 (default), sha512, md5
github_verify_checksum() {
    local file="$1"
    local checksum_source="$2"
    local algorithm="${3:-sha256}"

    if [ ! -f "$file" ]; then
        log_error "Arquivo não encontrado: $file"
        return 1
    fi

    # Determinar comando de hash
    local hash_cmd=""
    case "$algorithm" in
        sha256)
            if command -v sha256sum &> /dev/null; then
                hash_cmd="sha256sum"
            elif command -v shasum &> /dev/null; then
                hash_cmd="shasum -a 256"
            else
                log_warning "Comando sha256sum não disponível, pulando verificação"
                return 0
            fi
            ;;
        sha512)
            if command -v sha512sum &> /dev/null; then
                hash_cmd="sha512sum"
            elif command -v shasum &> /dev/null; then
                hash_cmd="shasum -a 512"
            else
                log_warning "Comando sha512sum não disponível, pulando verificação"
                return 0
            fi
            ;;
        md5)
            if command -v md5sum &> /dev/null; then
                hash_cmd="md5sum"
            elif command -v md5 &> /dev/null; then
                hash_cmd="md5 -r"
            else
                log_warning "Comando md5sum não disponível, pulando verificação"
                return 0
            fi
            ;;
        *)
            log_error "Algoritmo não suportado: $algorithm"
            return 1
            ;;
    esac

    # Calcular hash do arquivo
    local computed_hash=$($hash_cmd "$file" | awk '{print $1}')
    log_debug "Hash calculado: $computed_hash"

    # Obter hash esperado
    local expected_hash=""
    if [ -f "$checksum_source" ]; then
        # É um arquivo de checksum
        log_debug "Lendo checksum de arquivo: $checksum_source"
        local filename=$(basename "$file")

        # Tentar encontrar o hash do arquivo (com ou sem ./ no início)
        expected_hash=$(grep -i "$filename" "$checksum_source" | awk '{print $1}' | head -1)

        # Se não encontrou, tenta com ./ no início
        if [ -z "$expected_hash" ]; then
            expected_hash=$(grep -i "./$filename" "$checksum_source" | awk '{print $1}' | head -1)
        fi

        # Se ainda não encontrou, tenta pegar a primeira linha
        if [ -z "$expected_hash" ]; then
            expected_hash=$(head -1 "$checksum_source" | awk '{print $1}')
        fi
    else
        # É o hash direto
        expected_hash="$checksum_source"
    fi

    if [ -z "$expected_hash" ]; then
        log_warning "Não foi possível obter hash esperado, pulando verificação"
        return 0
    fi

    log_debug "Hash esperado: $expected_hash"

    # Comparar hashes (case insensitive)
    if [ "${computed_hash,,}" = "${expected_hash,,}" ]; then
        log_success "✓ Verificação de integridade bem-sucedida"
        return 0
    else
        log_error "✗ Verificação de integridade falhou!"
        log_error "  Esperado: $expected_hash"
        log_error "  Obtido:   $computed_hash"
        return 1
    fi
}

# Baixa e verifica checksum de release usando repo e version
# Args: repo version download_url output_file checksum_filename [algorithm]
github_download_and_verify() {
    local repo="$1"
    local version="$2"
    local download_url="$3"
    local output_file="$4"
    local checksum_filename="$5"
    local algorithm="${6:-sha256}"

    # Construir URL do checksum
    local checksum_url=""
    if [ -n "$checksum_filename" ] && [ "$checksum_filename" != "none" ]; then
        checksum_url="https://github.com/${repo}/releases/download/${version}/${checksum_filename}"
    fi

    # Chamar a função interna com URLs completas
    github_download_and_verify_internal "$download_url" "$checksum_url" "$output_file" "$algorithm" "release"
}

# Função interna que aceita URLs completas
# Args: download_url checksum_url output_file [algorithm] [description]
github_download_and_verify_internal() {
    local download_url="$1"
    local checksum_url="$2"
    local output_file="$3"
    local algorithm="${4:-sha256}"
    local description="${5:-release}"

    # Baixar arquivo principal
    if ! github_download_release "$download_url" "$output_file" "$description"; then
        return 1
    fi

    # Se não há URL de checksum, retorna sucesso
    if [ -z "$checksum_url" ] || [ "$checksum_url" = "none" ]; then
        log_debug "Verificação de checksum não disponível"
        return 0
    fi

    # Baixar arquivo de checksum
    local checksum_file="${output_file}.${algorithm}"
    log_info "Baixando checksum..."

    if ! github_download_release "$checksum_url" "$checksum_file" "checksum" 2> /dev/null; then
        log_warning "Não foi possível baixar arquivo de checksum, pulando verificação"
        return 0
    fi

    # Verificar checksum
    if ! github_verify_checksum "$output_file" "$checksum_file" "$algorithm"; then
        rm -f "$output_file" "$checksum_file"
        return 1
    fi

    # Limpar arquivo de checksum
    rm -f "$checksum_file"
    return 0
}

# Extrai arquivo tar.gz e retorna o diretório/arquivo extraído
# Args: tar_file [extract_dir]
github_extract_tarball() {
    local tar_file="$1"
    local extract_dir="${2:-/tmp/github-extract-$$}"

    if [ ! -f "$tar_file" ]; then
        log_error "Arquivo não encontrado: $tar_file"
        return 1
    fi

    log_info "Extraindo arquivo..."
    log_debug "Origem: $tar_file"
    log_debug "Destino: $extract_dir"

    mkdir -p "$extract_dir"

    if tar -xzf "$tar_file" -C "$extract_dir" 2>&1 |
        while read -r line; do log_debug "tar: $line"; done; then

        log_debug "Extração concluída"
        echo "$extract_dir"
        return 0
    else
        log_error "Falha ao extrair arquivo"
        rm -rf "$extract_dir"
        return 1
    fi
}

# Instala binário de release extraído
# Args: extracted_dir binary_name install_dir
github_install_binary() {
    local extracted_dir="$1"
    local binary_name="$2"
    local install_dir="$3"

    # Procurar binário
    local binary_path=$(find "$extracted_dir" -type f -name "$binary_name" | head -1)

    if [ -z "$binary_path" ]; then
        log_error "Binário '$binary_name' não encontrado no arquivo extraído"
        rm -rf "$extracted_dir"
        return 1
    fi

    log_debug "Binário encontrado: $binary_path"

    # Criar diretório de instalação
    mkdir -p "$install_dir"

    # Instalar binário
    local target_path="$install_dir/$binary_name"
    mv "$binary_path" "$target_path"
    chmod +x "$target_path"

    # Limpar arquivos temporários
    rm -rf "$extracted_dir"

    log_debug "Binário instalado em: $target_path"
    echo "$target_path"
}

# Função completa: baixa, verifica e instala release do GitHub
# Args: owner/repo version binary_name install_dir file_pattern [checksum_pattern] [algorithm]
github_install_release() {
    local repo="$1"
    local version="$2"
    local binary_name="$3"
    local install_dir="$4"
    local file_pattern="$5"
    local checksum_pattern="${6:-}"
    local algorithm="${7:-sha256}"

    # Detectar OS e arquitetura
    local os_arch
    os_arch=$(github_detect_os_arch "standard")
    [ $? -ne 0 ] && return 1

    local os_name="${os_arch%:*}"
    local arch="${os_arch#*:}"

    # Construir URLs
    local download_url=$(github_build_download_url "$repo" "$version" "$os_name" "$arch" "$file_pattern")
    local checksum_url=""

    if [ -n "$checksum_pattern" ]; then
        checksum_url=$(github_build_download_url "$repo" "$version" "$os_name" "$arch" "$checksum_pattern")
    fi

    # Arquivo temporário
    local temp_file="/tmp/${binary_name}-${version}.tar.gz"

    # Baixar e verificar
    if ! github_download_and_verify_internal "$download_url" "$checksum_url" "$temp_file" "$algorithm" "$binary_name"; then
        return 1
    fi

    # Extrair
    local extracted_dir=$(github_extract_tarball "$temp_file")
    if [ $? -ne 0 ]; then
        rm -f "$temp_file"
        return 1
    fi

    rm -f "$temp_file"

    # Instalar binário
    github_install_binary "$extracted_dir" "$binary_name" "$install_dir"
}
