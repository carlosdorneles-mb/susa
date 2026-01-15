#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- String Helper Functions --- #

# Converts a string to uppercase.
# Usage:
#   string_to_upper "your_string"
# Example:
#   result=$(string_to_upper "hello world")
#   echo "$result"  # Output: HELLO WORLD
string_to_upper() {
    echo "${1^^}"
}

# Converts a string to lowercase.
# Usage:
#   string_to_lower "YOUR_STRING"
# Example:
#   result=$(string_to_lower "HELLO WORLD")
#   echo "$result"  # Output: hello world
string_to_lower() {
    echo "${1,,}"
}

# Strips leading and trailing whitespace from a string.
# Usage:
#   string_trim "  your string  "
# Example:
#   result=$(string_trim "  hello world  ")
#   echo "$result"  # Output: hello world
string_trim() {
    echo "$1" | xargs
}

# Check if string contains a substring
# Usage:
#   string_contains "your_string" "substring"
# Example:
#   if string_contains "hello world" "world"; then
#       echo "Contains substring"
#   fi
string_contains() {
    [[ "$1" == *"$2"* ]]
}

# Check if string starts with a prefix
# Usage:
#   string_starts_with "your_string" "prefix"
# Example:
#   if string_starts_with "hello world" "hello"; then
#       echo "Starts with prefix"
#   fi
string_starts_with() {
    [[ "$1" == "$2"* ]]
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
            IFS=',' read -r -a split_arr <<<"$temp"
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
    joined="$(
        IFS=','
        echo "${arr_ref[*]}"
    )"
    arr_ref=("$joined")
}
