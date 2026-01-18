#!/bin/bash
#
# table.sh - Generic table rendering system
#
# Provides functions to create and display formatted tables using column.
#
# Usage:
#   source "$LIB_DIR/table.sh"
#
#   table_init
#   table_add_row "Name" "Age" "City"  # Header
#   table_add_row "John" "25" "NY"
#   table_add_row "Mary" "30" "LA"
#   table_render
#

# Global variable to store table data
_TABLE_DATA=""
_TABLE_INDENT="  "
_TABLE_SEPARATOR=$'\t'
_TABLE_AUTO_NUMBER=true
_TABLE_ROW_COUNT=0
_TABLE_NUMBER_COLOR="${LIGHT_CYAN:-}"

# Initialize a new table
# Clears any previous data
#
# Options:
#   --no-number    Disable automatic row numbering (enabled by default)
#
# Example:
#   table_init              # With auto-numbering
#   table_init --no-number  # Without auto-numbering
# shellcheck disable=SC2120
table_init() {
    _TABLE_DATA=""
    _TABLE_ROW_COUNT=0
    _TABLE_AUTO_NUMBER=true

    if [ "${1:-}" = "--no-number" ]; then
        _TABLE_AUTO_NUMBER=false
    fi
}

# Set table indentation (default: 2 spaces)
# Args: indentation (string)
table_set_indent() {
    _TABLE_INDENT="$1"
}

# Add a row to the table
# Args: column values (one or more arguments)
#
# Note: If auto-numbering is enabled, the row number is automatically
#       added as the first column. You don't need to pass it manually.
#
# Example:
#   table_add_row "Col1" "Col2" "Col3"
#   table_add_row "${CYAN}value1${NC}" "value2" "value3"
table_add_row() {
    local row="${_TABLE_INDENT}"
    local first=true

    # Auto-number: add row number as first column (only for data rows, not header)
    if [ "$_TABLE_AUTO_NUMBER" = true ] && [ $_TABLE_ROW_COUNT -gt 0 ]; then
        row+="${_TABLE_NUMBER_COLOR}${_TABLE_ROW_COUNT}${NC:-}"
        first=false
        _TABLE_ROW_COUNT=$((_TABLE_ROW_COUNT + 1))
    fi

    for value in "$@"; do
        if [ "$first" = true ]; then
            row+="$value"
            first=false
        else
            row+="${_TABLE_SEPARATOR}${value}"
        fi
    done

    _TABLE_DATA+="${row}\n"
}

# Add a header row (with bold/gray formatting)
# Args: column values
#
# Note: If auto-numbering is enabled, the "#" column is automatically
#       added as the first column. You don't need to pass it manually.
#
# Example:
#   table_add_header "Name" "Age" "City"
table_add_header() {
    local row="${_TABLE_INDENT}"
    local first=true

    # Load colors if available
    if command -v source &> /dev/null && [ -f "${LIB_DIR:-}/color.sh" ]; then
        source "${LIB_DIR}/color.sh" 2> /dev/null || true
    fi

    # Auto-number: add "#" as first column header
    if [ "$_TABLE_AUTO_NUMBER" = true ]; then
        row+="${BOLD:-}${GRAY:-}#${NC:-}"
        first=false
        _TABLE_ROW_COUNT=1 # Start counting from 1 for data rows
    fi

    for value in "$@"; do
        if [ "$first" = true ]; then
            row+="${BOLD:-}${GRAY:-}${value}${NC:-}"
            first=false
        else
            row+="${_TABLE_SEPARATOR}${BOLD:-}${GRAY:-}${value}${NC:-}"
        fi
    done

    _TABLE_DATA+="${row}\n"
}

# Render the table using column for alignment
# Display result to stdout
#
# Options:
#   --no-clear    Don't clear table after rendering
table_render() {
    local clear_after=true

    if [ "${1:-}" = "--no-clear" ]; then
        clear_after=false
    fi

    if [ -z "$_TABLE_DATA" ]; then
        echo "Empty table" >&2
        return 1
    fi

    # Render using column
    echo -e "$_TABLE_DATA" | column -t -s "$_TABLE_SEPARATOR"

    # Clear data after rendering (default behavior)
    if [ "$clear_after" = true ]; then
        table_init
    fi
}

# Get current table content (useful for debugging)
table_get_data() {
    echo -e "$_TABLE_DATA"
}

# Count the number of rows in the table
table_count_rows() {
    if [ -z "$_TABLE_DATA" ]; then
        echo "0"
        return
    fi

    echo -e "$_TABLE_DATA" | grep -c "^"
}
