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
    ubuntu|debian)
      OS_TYPE="debian"
      ;;
    fedora|rhel|centos|rocky|almalinux)
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
get_simple_os() {
    if [[ "$OS_TYPE" == "macos" ]]; then
        echo "mac"
    elif [[ "$OS_TYPE" == "debian" ]] || [[ "$OS_TYPE" == "fedora" ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}
