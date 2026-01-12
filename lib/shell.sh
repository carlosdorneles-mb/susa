#!/bin/bash

# --- Shell Helper Functions ---

# Detect user shell type
detect_shell_type() {
    local user_shell=$(basename "${SHELL:-}")
    
    case "$user_shell" in
        zsh)
            echo "zsh"
            ;;
        bash)
            echo "bash"
            ;;
        fish)
            echo "fish"
            ;;
        *)
            # Fallback: tries to detect by the execution environment
            if [ -n "${ZSH_VERSION:-}" ]; then
                echo "zsh"
            elif [ -n "${BASH_VERSION:-}" ]; then
                echo "bash"
            else
                echo "unknown"
            fi
            ;;
    esac
}


# Detect shell configuration file
detect_shell_config() {
    # Detect which shell configuration file to use
    # Checks the user's shell via $SHELL
    local user_shell=$(basename "$SHELL")
    
    if [[ "$user_shell" == "zsh" ]] && [ -f "$HOME/.zshrc" ]; then
        echo "$HOME/.zshrc"
    elif [[ "$user_shell" == "bash" ]] && [ -f "$HOME/.bashrc" ]; then
        echo "$HOME/.bashrc"
    elif [ -f "$HOME/.zshrc" ]; then
        echo "$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        echo "$HOME/.bashrc"
    else
        echo "$HOME/.profile"
    fi
}
