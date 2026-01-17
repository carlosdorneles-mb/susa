#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- OS Detection ---

# OS_TYPE will be one of: "debian", "macos", "fedora", or "unknown"
if [[ "$(uname)" == "Darwin" ]]; then
    OS_TYPE="macos"
elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
        ubuntu | debian)
            OS_TYPE="debian"
            ;;
        fedora | rhel | centos | rocky | almalinux)
            OS_TYPE="fedora"
            ;;
        *)
            OS_TYPE="unknown"
            ;;
    esac
else
    OS_TYPE="unknown"
fi

# Function to get the simplified name of the OS (linux or mac)
# Usage:
#   os_name=$(get_simple_os)
#   echo "$os_name"  # Output: linux or mac
get_simple_os() {
    if [[ "$OS_TYPE" == "macos" ]]; then
        echo "mac"
    elif [[ "$OS_TYPE" == "debian" ]] || [[ "$OS_TYPE" == "fedora" ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Check if running on Linux
# Usage:
#   if is_linux; then
#       echo "Running on Linux"
#   fi
is_linux() {
    [[ "$OS_TYPE" == "debian" ]] || [[ "$OS_TYPE" == "fedora" ]]
}

# Check if running on macOS
# Usage:
#   if is_mac; then
#       echo "Running on macOS"
#   fi
is_mac() {
    [[ "$OS_TYPE" == "macos" ]]
}

# Check if running on Arch-based distro
# Usage:
#   if is_arch; then
#       echo "Running on Arch"
#   fi
is_arch() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        [[ "$ID" == "arch" || "$ID" == "manjaro" ]]
    else
        return 1
    fi
}

# Get the appropriate package manager for RedHat-based systems
# Returns: "dnf" if available, otherwise "yum"
# Usage:
#   pkg_manager=$(get_redhat_pkg_manager)
#   sudo $pkg_manager install package
get_redhat_pkg_manager() {
    if command -v dnf &> /dev/null; then
        echo "dnf"
    else
        echo "yum"
    fi
}

# Get the Linux distribution ID from /etc/os-release
# Returns: The $ID value (e.g., "ubuntu", "fedora", "arch")
# Usage:
#   distro=$(get_distro_id)
get_distro_id() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}
