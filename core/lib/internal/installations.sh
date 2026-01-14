#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# Installation Tracking Library
# ============================================================
# Functions to track software installations in lock file

# Ensure yq is available
source "$LIB_DIR/dependencies.sh"
ensure_yq_installed || {
    echo "Error: yq is required" >&2
    exit 1
}

# Get lock file path
get_lock_file_path() {
    echo "${CLI_DIR}/susa.lock"
}

# Mark software as installed in lock file
# Usage: mark_installed "docker" "24.0.5"
mark_installed() {
    local software_name="$1"
    local version="${2:-unknown}"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        log_warning "Lock file not found. Run 'susa self lock' first."
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Check if installations section exists
    if ! yq eval '.installations' "$lock_file" &>/dev/null || [ "$(yq eval '.installations' "$lock_file")" = "null" ]; then
        # Create installations section
        yq eval -i '.installations = []' "$lock_file"
    fi

    # Check if software already tracked
    local exists=$(yq eval ".installations[] | select(.name == \"$software_name\") | .name" "$lock_file" 2>/dev/null)

    if [ -n "$exists" ] && [ "$exists" != "null" ]; then
        # Update existing entry
        yq eval -i "(.installations[] | select(.name == \"$software_name\") | .installed) = true" "$lock_file"
        yq eval -i "(.installations[] | select(.name == \"$software_name\") | .version) = \"$version\"" "$lock_file"
        yq eval -i "(.installations[] | select(.name == \"$software_name\") | .installed_at) = \"$timestamp\"" "$lock_file"
    else
        # Add new entry
        yq eval -i ".installations += [{\"name\": \"$software_name\", \"installed\": true, \"version\": \"$version\", \"installed_at\": \"$timestamp\"}]" "$lock_file"
    fi

    return 0
}

# Mark software as uninstalled in lock file
# Usage: mark_uninstalled "docker"
mark_uninstalled() {
    local software_name="$1"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 0
    fi

    # Check if software is tracked
    local exists=$(yq eval ".installations[] | select(.name == \"$software_name\") | .name" "$lock_file" 2>/dev/null)

    if [ -n "$exists" ] && [ "$exists" != "null" ]; then
        # Mark as uninstalled and clear version
        yq eval -i "(.installations[] | select(.name == \"$software_name\") | .installed) = false" "$lock_file"
        yq eval -i "(.installations[] | select(.name == \"$software_name\") | .version) = null" "$lock_file"
        yq eval -i "del(.installations[] | select(.name == \"$software_name\") | .installed_at)" "$lock_file"
    fi

    return 0
}

# Update software version in lock file
# Usage: update_version "docker" "24.0.6"
update_version() {
    local software_name="$1"
    local version="$2"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Check if software is tracked
    local exists=$(yq eval ".installations[] | select(.name == \"$software_name\") | .name" "$lock_file" 2>/dev/null)

    if [ -n "$exists" ] && [ "$exists" != "null" ]; then
        yq eval -i "(.installations[] | select(.name == \"$software_name\") | .version) = \"$version\"" "$lock_file"
        yq eval -i "(.installations[] | select(.name == \"$software_name\") | .updated_at) = \"$timestamp\"" "$lock_file"
        return 0
    fi

    return 1
}

# Check if software is installed
# Usage: if is_installed "docker"; then ...
is_installed() {
    local software_name="$1"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    local installed=$(yq eval ".installations[] | select(.name == \"$software_name\") | .installed" "$lock_file" 2>/dev/null)

    if [ "$installed" = "true" ]; then
        return 0
    fi

    return 1
}

# Get installed version
# Usage: version=$(get_installed_version "docker")
get_installed_version() {
    local software_name="$1"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    local version=$(yq eval ".installations[] | select(.name == \"$software_name\") | .version" "$lock_file" 2>/dev/null)

    if [ -n "$version" ] && [ "$version" != "null" ]; then
        echo "$version"
        return 0
    fi

    return 1
}

# Get installation info
# Usage: get_installation_info "docker"
get_installation_info() {
    local software_name="$1"
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    yq eval ".installations[] | select(.name == \"$software_name\")" "$lock_file" 2>/dev/null
    return 0
}

# List all installed software
# Usage: list_installed
list_installed() {
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        return 1
    fi

    yq eval '.installations[] | select(.installed == true) | .name' "$lock_file" 2>/dev/null
    return 0
}

# Get list of available setup commands
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

# Check if a specific software is actually installed (without prompts)
# Usage: if check_software_installed "docker"; then ...
check_software_installed() {
    local software_name="$1"

    case "$software_name" in
        docker)
            command -v docker &>/dev/null
            ;;
        podman)
            command -v podman &>/dev/null
            ;;
        mise)
            command -v mise &>/dev/null
            ;;
        asdf)
            [ -d "$HOME/.asdf" ] && [ -f "$HOME/.asdf/bin/asdf" ]
            ;;
        poetry)
            command -v poetry &>/dev/null
            ;;
        uv)
            command -v uv &>/dev/null
            ;;
        tilix)
            command -v tilix &>/dev/null || ([ "$(uname)" = "Linux" ] && dpkg -l | grep -q tilix)
            ;;
        iterm)
            [ "$(uname)" = "Darwin" ] && [ -d "/Applications/iTerm.app" ]
            ;;
        toolbox|jetbrains-toolbox)
            command -v jetbrains-toolbox &>/dev/null || [ -f "$HOME/.local/bin/jetbrains-toolbox" ]
            ;;
        *)
            # Try generic command check
            command -v "$software_name" &>/dev/null
            ;;
    esac
}

# Get version of installed software (without prompts)
# Usage: version=$(get_software_version "docker")
get_software_version() {
    local software_name="$1"

    case "$software_name" in
        docker)
            if command -v docker &>/dev/null; then
                docker --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown"
            fi
            ;;
        podman)
            if command -v podman &>/dev/null; then
                podman --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown"
            fi
            ;;
        mise)
            if command -v mise &>/dev/null; then
                mise --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown"
            fi
            ;;
        asdf)
            if [ -f "$HOME/.asdf/bin/asdf" ]; then
                "$HOME/.asdf/bin/asdf" --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown"
            fi
            ;;
        poetry)
            if command -v poetry &>/dev/null; then
                poetry --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown"
            fi
            ;;
        uv)
            if command -v uv &>/dev/null; then
                uv --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown"
            fi
            ;;
        tilix)
            if command -v tilix &>/dev/null; then
                tilix --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown"
            fi
            ;;
        toolbox|jetbrains-toolbox)
            if command -v jetbrains-toolbox &>/dev/null; then
                jetbrains-toolbox --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown"
            elif [ -f "$HOME/.local/bin/jetbrains-toolbox" ]; then
                "$HOME/.local/bin/jetbrains-toolbox" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Sync installed software to lock file (scan system and update lock)
# Usage: sync_installations
sync_installations() {
    local lock_file=$(get_lock_file_path)

    if [ ! -f "$lock_file" ]; then
        log_error "Lock file not found. Run 'susa self lock' first."
        return 1
    fi

    local found_count=0
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
            ((found_count++))

            # Check if it's tracked in lock file
            if ! is_installed "$software_name"; then
                # Get version
                local version=$(get_software_version "$software_name")
                [ -z "$version" ] && version="unknown"

                # Add to lock file
                mark_installed "$software_name" "$version"
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
    local installed_in_lock=$(yq eval '.installations[] | select(.installed == true) | .name' "$lock_file" 2>/dev/null)

    if [ -n "$installed_in_lock" ]; then
        while IFS= read -r software_name; do
            [ -z "$software_name" ] && continue

            log_debug "Verificando se $software_name ainda está instalado..."

            # Check if software is still installed on system
            if ! check_software_installed "$software_name"; then
                # Software was uninstalled, update lock file
                mark_uninstalled "$software_name"
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
