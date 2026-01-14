#!/bin/bash

# --- Log Helper Functions ---

log_output() {
  # How to use: log_output "${GREEN}Your colored message${NC} with ${CYAN}variables: ${var}${NC}"
  if ! strtobool "${SILENT:-false}"; then
    echo -e "$1"
  fi
}

log_message() {
  # How to use: log_message "Your message here"
  if ! strtobool "${SILENT:-false}"; then
    echo -e "[MESSAGE] ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1"
  fi
}

log_info() {
  # How to use: log_info "Your info message here"
  if ! strtobool "${SILENT:-false}"; then
    echo -e "${CYAN}[INFO]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1"
  fi
}

log_success() {
  # How to use: log_success "Your success message here"
  if ! strtobool "${SILENT:-false}"; then
    echo -e "${GREEN}[SUCCESS]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1"
  fi
}

log_warning() {
  # How to use: log_warning "Your warning message here"
  if ! strtobool "${SILENT:-false}"; then
    echo -e "${YELLOW}[WARNING]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1"
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
      echo -e "${GRAY}[DEBUG]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1"
    fi
  fi
}

strtobool() {
  # How to use: strtobool "value"
  local value
  value=$(to_lowercase "$1")
  case "$value" in
    "true" | "1" | "on" | "yes")
      return 0
      ;;
    "false" | "0" | "off" | "no")
      return 1
      ;;
    *)
      log_error "Invalid boolean value: $1"
      return 1
      ;;
  esac
}
