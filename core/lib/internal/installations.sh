#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# Installation Tracking Library
# ============================================================
# Functions to track software installations in lock file

source "$LIB_DIR/internal/json.sh"

# Returns the absolute path to susa.lock file
# Usage: lock_file=$(get_lock_file_path)
get_lock_file_path() {
    echo "${CLI_DIR}/susa.lock"
}

# Internal: Marks software as installed in lock file with version and timestamp
# Args: software_name, version (optional, defaults to "unknown")
# Usage: _mark_installed_software_in_lock "docker" "24.0.5"
_mark_installed_software_in_lock() {
    local software_name="$1"
    local version="${2:-unknown}"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        log_warning "Lock file not found. Run 'susa self lock' first."
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Check if software already tracked
    local exists=$(jq -r ".installations[] | select(.name == \"$software_name\") | .name" "$lock_file" 2> /dev/null)

    if [ -n "$exists" ] && [ "$exists" != "null" ]; then
        # Update existing entry
        local temp_file=$(mktemp)
        jq --arg name "$software_name" --arg ver "$version" --arg ts "$timestamp" \
            '(.installations[] | select(.name == $name)) |= {name: $name, installed: true, version: $ver, installedAt: $ts}' \
            "$lock_file" > "$temp_file" && mv "$temp_file" "$lock_file"
    else
        # Add new entry
        local temp_file=$(mktemp)
        jq --arg name "$software_name" --arg ver "$version" --arg ts "$timestamp" \
            '.installations += [{name: $name, installed: true, version: $ver, installedAt: $ts}]' \
            "$lock_file" > "$temp_file" && mv "$temp_file" "$lock_file"
    fi

    return 0
}

# Internal: Updates version and timestamp for already registered software
# Args: software_name, version
# Returns: 0 if updated, 1 if not found
# Usage: _update_software_version_in_lock "docker" "24.0.6"
_update_software_version_in_lock() {
    local software_name="$1"
    local version="$2"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Check if software is tracked
    local exists=$(jq -r ".installations[] | select(.name == \"$software_name\") | .name" "$lock_file" 2> /dev/null)

    if [ -n "$exists" ] && [ "$exists" != "null" ]; then
        local temp_file=$(mktemp)
        jq --arg name "$software_name" --arg ver "$version" --arg ts "$timestamp" \
            '(.installations[] | select(.name == $name)) |= (.version = $ver | .updatedAt = $ts)' \
            "$lock_file" > "$temp_file" && mv "$temp_file" "$lock_file"
        return 0
    fi

    return 1
}

# Smart function: registers new or updates existing software in lock file
# Args: software_name (optional, defaults to $COMMAND_NAME), version (optional, defaults to "unknown")
# Usage: register_or_update_software_in_lock "docker" "24.0.6"
register_or_update_software_in_lock() {
    local software_name="${1:-${COMMAND_NAME:-}}"
    local version="${2:-unknown}"

    if [ -z "$software_name" ]; then
        log_error "Nome do software não especificado e COMMAND_NAME não definida"
        return 1
    fi

    if is_installed "$software_name"; then
        _update_software_version_in_lock "$software_name" "$version"
    else
        _mark_installed_software_in_lock "$software_name" "$version"
    fi

    return 0
}

# Marks software as uninstalled (installed: false) and clears version
# Args: software_name (optional, defaults to $COMMAND_NAME)
# Usage: remove_software_in_lock "docker"
remove_software_in_lock() {
    local software_name="${1:-${COMMAND_NAME:-}}"

    if [ -z "$software_name" ]; then
        log_error "Nome do software não especificado e COMMAND_NAME não definida"
        return 1
    fi

    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 0
    fi

    # Check if software is tracked
    local exists=$(jq -r ".installations[] | select(.name == \"$software_name\") | .name" "$lock_file" 2> /dev/null)

    if [ -n "$exists" ] && [ "$exists" != "null" ]; then
        # Mark as uninstalled and clear version
        local temp_file=$(mktemp)
        jq --arg name "$software_name" \
            '(.installations[] | select(.name == $name)) |= {name: $name, installed: false, version: null} |
             (.installations[] | select(.name == $name)) |= del(.installedAt)' \
            "$lock_file" > "$temp_file" && mv "$temp_file" "$lock_file"
    fi

    return 0
}

# Checks if software is marked as installed in lock file (not system check)
# Args: software_name (optional, defaults to $COMMAND_NAME)
# Returns: 0 if installed in lock, 1 otherwise
# Usage: if is_installed "docker"; then ...
is_installed() {
    local software_name="${1:-${COMMAND_NAME:-}}"

    if [ -z "$software_name" ]; then
        return 1
    fi

    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    local installed=$(jq -r ".installations[] | select(.name == \"$software_name\") | .installed" "$lock_file" 2> /dev/null)

    if [ "$installed" = "true" ]; then
        return 0
    fi

    return 1
}

# Gets version stored in lock file (not current system version)
# Args: software_name (optional, defaults to $COMMAND_NAME)
# Returns: 0 with version string, 1 if not found
# Usage: version=$(get_installed_version "docker")
get_installed_version() {
    local software_name="${1:-${COMMAND_NAME:-}}"

    if [ -z "$software_name" ]; then
        return 1
    fi

    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    local version=$(jq -r ".installations[] | select(.name == \"$software_name\") | .version" "$lock_file" 2> /dev/null)

    if [ -n "$version" ] && [ "$version" != "null" ]; then
        echo "$version"
        return 0
    fi

    return 1
}

# Gets complete installation JSON object from lock file
# Args: software_name (optional, defaults to $COMMAND_NAME)
# Returns: 0 with JSON output, 1 if not found
# Usage: get_installation_info "docker"
get_installation_info() {
    local software_name="${1:-${COMMAND_NAME:-}}"

    if [ -z "$software_name" ]; then
        return 1
    fi

    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    jq -r ".installations[] | select(.name == \"$software_name\")" "$lock_file" 2> /dev/null
    return 0
}

# Lists all software marked as installed in lock file
# Returns: 0 with newline-separated names, 1 if lock not found
# Usage: list_installed
list_installed() {
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    jq -r '.installations[] | select(.installed == true) | .name' "$lock_file" 2> /dev/null
    return 0
}

# Scans commands/setup directory and lists available setup commands
# Returns: 0 with newline-separated command names, 1 if dir not found
# Usage: get_available_setup_commands
get_available_setup_commands() {
    local cli_dir="${CLI_DIR}"
    local setup_dir="${cli_dir}/commands/setup"

    if [ ! -d "$setup_dir" ]; then
        return 1
    fi

    for cmd_dir in "$setup_dir"/*; do
        [ ! -d "$cmd_dir" ] && continue
        local cmd_name=$(basename "$cmd_dir")
        [ -f "$cmd_dir/main.sh" ] && echo "$cmd_name"
    done
}

# Checks if software is actually installed on system (not lock file)
# Uses custom --check-installation if implemented, falls back to command -v
# Args: software_name (optional, defaults to $COMMAND_NAME)
# Returns: 0 if installed, 1 if not
# Usage: if check_software_installed "docker"; then ...
check_software_installed() {
    local software_name="${1:-${COMMAND_NAME:-}}"

    if [ -z "$software_name" ]; then
        return 1
    fi

    local setup_command_file="${CLI_DIR}/commands/setup/${software_name}/main.sh"

    # Check if setup command exists
    if [ -f "$setup_command_file" ]; then
        # Try to execute custom check via susa CLI
        "${CORE_DIR}/susa" setup "$software_name" --check-installation &> /dev/null
        local custom_check_result=$?

        # If command supports --check-installation, use its result
        # Exit code 0 = installed, 1 = not installed, 2 = flag not supported
        if [ $custom_check_result -ne 2 ]; then
            return $custom_check_result
        fi
    fi

    # Fallback to generic check: try command -v
    command -v "$software_name" &> /dev/null
}

# Gets current version from system (via --get-current-version flag)
# Also updates lock file with detected version
# Args: software_name (optional, defaults to $COMMAND_NAME)
# Returns: version string or "N/A"
# Usage: version=$(get_current_software_version "docker")
get_current_software_version() {
    local software_name="${1:-${COMMAND_NAME:-}}"

    if [ -z "$software_name" ]; then
        log_debug "Nome do software não especificado e COMMAND_NAME não definida"
        echo "N/A"
        return 1
    fi

    local setup_command_file="${CLI_DIR}/commands/setup/${software_name}/main.sh"

    # Check if setup command file exists
    if [ ! -f "$setup_command_file" ]; then
        log_debug "Comando de configuração não encontrado: commands/setup/${software_name}/main.sh"
        echo "N/A"
        return 0
    fi

    # Execute through susa CLI to ensure all environment variables are loaded
    local version=$("${CORE_DIR}/susa" setup "$software_name" --get-current-version 2> /dev/null)
    local exit_code=$?

    # Validate and return version
    if [ $exit_code -eq 0 ] && [ -n "$version" ] && [ "$version" != "desconhecida" ]; then
        echo "$version"
        register_or_update_software_in_lock "$software_name" "$version"
        return 0
    fi

    log_debug "Não foi possível obter a versão atual de '$software_name' (exit code: $exit_code)"
    echo "N/A"
    return 0
}

# Gets latest available version from remote source (via --get-latest-version)
# Args: software_name (optional, defaults to $COMMAND_NAME)
# Returns: version string or "N/A"
# Usage: version=$(get_latest_software_version "docker")
get_latest_software_version() {
    local software_name="${1:-${COMMAND_NAME:-}}"

    if [ -z "$software_name" ]; then
        log_debug "Nome do software não especificado e COMMAND_NAME não definida"
        echo "N/A"
        return 1
    fi

    local setup_command_file="${CLI_DIR}/commands/setup/${software_name}/main.sh"

    # Check if setup command file exists
    if [ ! -f "$setup_command_file" ]; then
        log_debug "Comando de configuração não encontrado: commands/setup/${software_name}/main.sh"
        echo "N/A"
        return 0
    fi

    # Execute through susa CLI to ensure all environment variables are loaded
    local version=$("${CORE_DIR}/susa" setup "$software_name" --get-latest-version 2> /dev/null)
    local exit_code=$?

    # Validate and return version
    if [ $exit_code -eq 0 ] && [ -n "$version" ] && [ "$version" != "desconhecida" ]; then
        echo "$version"
        return 0
    fi

    log_debug "Não foi possível obter a última versão de '$software_name' (exit code: $exit_code)"
    echo "N/A"
    return 0
}

# Displays formatted installation info: status, location, versions, updates
# Calls show_additional_info() if defined for custom information
# Args: software_name (optional, defaults to $COMMAND_NAME)
# Usage: show_software_info "docker"
show_software_info() {
    local software_name="${1:-${COMMAND_NAME:-}}"

    if [ -z "$software_name" ]; then
        log_error "Nome do software não especificado e COMMAND_NAME não definida"
        return 1
    fi

    local lock_file="${CLI_DIR}/susa.lock"

    # Get display name from lock file
    local display_name=$(jq -r ".commands[] | select(.name == \"$software_name\") | .displayName // \"$software_name\"" "$lock_file" 2> /dev/null)
    [ -z "$display_name" ] || [ "$display_name" = "null" ] && display_name="$software_name"

    # Get installation location
    local install_location=$(which "$software_name" 2> /dev/null || echo "N/A")

    # Get current version
    local current_version=$(get_current_software_version "$software_name" 2> /dev/null)
    [ -z "$current_version" ] || [ "$current_version" = "desconhecida" ] && current_version="N/A"

    # Get latest version
    local latest_version=$(get_latest_software_version "$software_name" 2> /dev/null)
    [ -z "$latest_version" ] || [ "$latest_version" = "desconhecida" ] && latest_version="N/A"

    # Display information
    log_output "${LIGHT_GREEN}Informações do $display_name:${NC}"
    log_output ""
    log_output "  ${CYAN}Nome:${NC} $display_name"

    if check_software_installed "$software_name"; then
        log_output "  ${CYAN}Status:${NC} ${GREEN}Instalado${NC}"
        log_output "  ${CYAN}Local:${NC} $install_location"
        log_output "  ${CYAN}Versão atual:${NC} $current_version"

        if [ -n "$latest_version" ] && [ "$latest_version" != "N/A" ] && [ "$current_version" != "N/A" ]; then
            # Normalize versions for comparison (remove 'v' prefix if present)
            local current_normalized="${current_version#v}"
            local latest_normalized="${latest_version#v}"

            if [ "$latest_normalized" != "$current_normalized" ]; then
                log_output "  ${CYAN}Última versão:${NC} ${YELLOW}$latest_version (atualização disponível)${NC}"
            else
                log_output "  ${CYAN}Última versão:${NC} $latest_version"
            fi
        elif [ -n "$latest_version" ] && [ "$latest_version" != "N/A" ]; then
            log_output "  ${CYAN}Última versão:${NC} $latest_version"
        fi

        # Call custom additional info function if it exists
        if declare -f show_additional_info > /dev/null 2>&1; then
            show_additional_info
        fi
    else
        log_output "  ${CYAN}Status:${NC} ${RED}Não instalado${NC}"
        if [ -n "$latest_version" ] && [ "$latest_version" != "N/A" ]; then
            log_output "  ${CYAN}Última versão disponível:${NC} $latest_version"
        fi
    fi

    log_output ""
}

# Syncs system state with lock file: adds new installations, marks removed ones
# Two-pass scan: system → lock, then lock → system
# Usage: sync_installations
sync_installations() {
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        log_error "Lock file not found. Run 'susa self lock' first."
        return 1
    fi

    local synced_count=0
    local removed_count=0
    local temp_add_file="/tmp/susa_sync_add_$$"
    local temp_remove_file="/tmp/susa_sync_remove_$$"

    log_debug "Verificando instalações no sistema..."

    # Get all available setup commands
    local commands_output=$(get_available_setup_commands)

    if [ -z "$commands_output" ]; then
        log_warning "Nenhum comando de setup encontrado"
        return 0
    fi

    # First pass: Check for new installations (system → lock)
    while IFS= read -r software_name; do
        [ -z "$software_name" ] && continue

        log_debug "Verificando: $software_name"

        # Check if software is installed on system
        if check_software_installed "$software_name"; then
            # Check if it's tracked in lock file
            if ! is_installed "$software_name"; then
                # Get version (also registers in lock file automatically)
                local version=$(get_current_software_version "$software_name")
                [ -z "$version" ] || [ "$version" = "N/A" ] && version="unknown"

                log_success "Sincronizado: $software_name ($version)"

                # Track synced count in temp file
                echo "1" >> "$temp_add_file"
            else
                log_debug "$software_name já está no lock file"
            fi
        else
            log_debug "$software_name não está instalado"
        fi
    done <<< "$commands_output"

    # Second pass: Check for removed installations (lock → system)
    log_debug "Verificando instalações removidas..."

    # Get list of software marked as installed in lock file
    local installed_in_lock=$(jq -r '.installations[] | select(.installed == true) | .name' "$lock_file" 2> /dev/null)

    if [ -n "$installed_in_lock" ]; then
        while IFS= read -r software_name; do
            [ -z "$software_name" ] && continue

            log_debug "Verificando se $software_name ainda está instalado..."

            # Check if software is still installed on system
            if ! check_software_installed "$software_name"; then
                # Software was uninstalled, update lock file
                remove_software_in_lock "$software_name"
                log_warning "Removido do lock: $software_name (não está mais instalado)"

                # Track removed count in temp file
                echo "1" >> "$temp_remove_file"
            fi
        done <<< "$installed_in_lock"
    fi

    # Count changes from temp files
    if [ -f "$temp_add_file" ]; then
        synced_count=$(wc -l < "$temp_add_file")
        rm -f "$temp_add_file"
    fi

    if [ -f "$temp_remove_file" ]; then
        removed_count=$(wc -l < "$temp_remove_file")
        rm -f "$temp_remove_file"
    fi

    # Show summary
    echo ""
    if [ $synced_count -eq 0 ] && [ $removed_count -eq 0 ]; then
        log_info "Nenhuma alteração encontrada."
    else
        if [ $synced_count -gt 0 ]; then
            log_success "$synced_count software(s) adicionado(s) ao lock file."
        fi
        if [ $removed_count -gt 0 ]; then
            log_success "$removed_count software(s) removido(s) do lock file."
        fi
    fi

    return 0
}
