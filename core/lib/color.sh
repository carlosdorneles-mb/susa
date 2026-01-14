#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

NC='\033[0m'                    # RESET
RESET='\033[0m'                 # RESET

# --- Colors for console output ---

RED='\033[0;31m'                # Red
LIGHT_RED='\033[0;91m'          # Light Red
GREEN='\033[0;32m'              # Green
LIGHT_GREEN='\033[0;92m'        # Light Green
YELLOW='\033[0;33m'             # Yellow
LIGHT_YELLOW='\033[0;93m'       # Light Yellow
BLUE='\033[0;34m'               # Blue
LIGHT_BLUE='\033[0;94m'         # Light Blue
MAGENTA='\033[0;35m'            # Magenta
LIGHT_MAGENTA='\033[0;95m'      # Light Magenta
CYAN='\033[0;36m'               # Cyan
LIGHT_CYAN='\033[0;96m'         # Light Cyan
GRAY='\033[0;90m'               # Gray
LIGHT_GRAY='\033[2;37m'         # Light Gray
WHITE='\033[1;37m'              # Bright White

# --- Additional styles ---

BOLD='\033[1m'                  # Bold
ITALIC='\033[3m'                # Italic
UNDERLINE='\033[4m'             # Underline
DIM='\033[2m'                   # Dim/Dark
