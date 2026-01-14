#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# Argument Parsing Library
# ============================================================
# Functions to parse command-line arguments consistently

# Parse standard help argument and show help if needed
# Usage: parse_help_arg "$@"
# Returns: 0 if help was shown (exits), 1 if no help requested
parse_help_arg() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                # Not a help arg, return to continue parsing
                return 1
                ;;
        esac
        shift
    done
    return 1
}

# Require at least one argument, show help if none provided
# Usage: require_arguments "$@"
require_arguments() {
    if [ $# -eq 0 ]; then
        show_help
        exit 1
    fi
}

# Parse a simple command with only --help option (no other arguments expected)
# Usage: parse_simple_help_only "$@"
parse_simple_help_only() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_usage
                exit 1
                ;;
        esac
        shift
    done
}

# Extract first positional argument from args
# Usage: PLUGIN_NAME=$(extract_first_positional "$@")
extract_first_positional() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -*)
                # Skip flags
                shift
                ;;
            *)
                # Found positional argument
                echo "$1"
                return 0
                ;;
        esac
    done
    return 1
}

# Validate that a required argument is not empty
# Usage: validate_required_arg "$PLUGIN_NAME" "Nome do plugin" "<plugin-name>"
validate_required_arg() {
    local arg_value="$1"
    local arg_description="$2"
    local arg_format="${3:-}"

    if [ -z "$arg_value" ]; then
        log_error "$arg_description não fornecido"
        if [ -n "$arg_format" ]; then
            show_usage "$arg_format"
        else
            show_usage
        fi
        exit 1
    fi
}
