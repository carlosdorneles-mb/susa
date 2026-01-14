#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- String Helper Functions --- #

# Converts a string to uppercase.
# Usage:
#   to_uppercase "your_string"
# Example:
#   result=$(to_uppercase "hello world")
#   echo "$result"  # Output: HELLO WORLD
to_uppercase() {
    echo "${1^^}"
}

# Converts a string to lowercase.
# Usage:
#   to_lowercase "YOUR_STRING"
# Example:
#   result=$(to_lowercase "HELLO WORLD")
#   echo "$result"  # Output: hello world
to_lowercase() {
    echo "${1,,}"
}

# Strips leading and trailing whitespace from a string.
# Usage:
#   strip_whitespace "  your string  "
# Example:
#   result=$(strip_whitespace "  hello world  ")
#   echo "$result"  # Output: hello world
strip_whitespace() {
    echo "$1" | xargs
}

# --- Array Helper Functions --- #

# Splits any comma-separated string elements in the referenced array into separate elements.
# Usage:
#   parse_comma_separated arr
# Example:
#   arr=("a,b,c") -> arr=("a" "b" "c")
parse_comma_separated() {
    local -n arr_ref=$1
    for i in "${!arr_ref[@]}"; do
        if [[ "${arr_ref[$i]}" == *","* ]]; then
            local temp="${arr_ref[$i]}"
            IFS=',' read -r -a split_arr <<< "$temp"
            arr_ref=("${arr_ref[@]:0:$i}" "${split_arr[@]}" "${arr_ref[@]:$((i + 1))}")
        fi
    done
}

# Joins all elements of the referenced array into a single comma-separated string element.
# Usage:
#   join_to_comma_separated arr
# Example:
#   arr=("a" "b" "c") -> arr=("a,b,c")
join_to_comma_separated() {
    local -n arr_ref=$1
    local joined
    joined="$(IFS=','; echo "${arr_ref[*]}")"
    arr_ref=("$joined")
}
