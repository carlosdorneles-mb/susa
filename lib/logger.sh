#!/bin/bash

# --- Log Helper Functions ---

log() {
  # How to use: log "Your message here"
  echo -e "[MESSAGE] ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1"
}

log_info() {
  # How to use: log_info "Your info message here"
  echo -e "${CYAN}[INFO]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1"
}

log_success() {
  # How to use: log_success "Your success message here"
  echo -e "${GREEN}[SUCCESS]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1"
}

log_warning() {
  # How to use: log_warning "Your warning message here"
  echo -e "${YELLOW}[WARNING]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1"
}

log_error() {
  # How to use: log_error "Your error message here"
  echo -e "${RED}[ERROR]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1" >&2
}

log_debug() {
  # How to use: log_debug "Your debug message here"
  local debug_value
  debug_value=$(to_lowercase "${DEBUG:-}")
  if [[ "$debug_value" == "true" || "$debug_value" == "1" || "$debug_value" == "on" ]]; then
    echo -e "${GRAY}[DEBUG]${NC} ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1"
  fi
}