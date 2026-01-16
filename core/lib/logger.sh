#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- Log Helper Functions ---

log_output() {
    # How to use: log_output "${GREEN}Your colored message${NC} with ${CYAN}variables: ${var}${NC}"
    if ! strtobool "${SILENT:-false}"; then
        echo -e "$1" >&2
    fi
}

log_message() {
    # How to use: log_message "Your message here"
    if ! strtobool "${SILENT:-false}"; then
        echo -e "[MESSAGE] ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1" >&2
    fi
}

log_info() {
    # How to use: log_info "Your info message here"
    if ! strtobool "${SILENT:-false}"; then
        echo -e "${CYAN}[INFO]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1" >&2
    fi
}

log_success() {
    # How to use: log_success "Your success message here"
    if ! strtobool "${SILENT:-false}"; then
        echo -e "${GREEN}[SUCCESS]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1" >&2
    fi
}

log_warning() {
    # How to use: log_warning "Your warning message here"
    if ! strtobool "${SILENT:-false}"; then
        echo -e "${YELLOW}[WARNING]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1" >&2
    fi
}

log_error() {
    # How to use: log_error "Your error message here"
    if ! strtobool "${SILENT:-false}"; then
        echo -e "${RED}[ERROR]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1" >&2
    fi
}

log_debug() {
    # How to use: log_debug "Your debug message here"
    if strtobool "${DEBUG:-false}"; then
        if ! strtobool "${SILENT:-false}"; then
            echo -e "${GRAY}[DEBUG]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1" >&2
        fi
    fi
}
