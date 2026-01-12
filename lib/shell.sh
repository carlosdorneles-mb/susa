#!/bin/bash

# --- Shell Helper Functions ---

# Detecta o tipo de shell do usuário
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
            # Fallback: tenta detectar pelo ambiente de execução
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


# Detecta o arquivo de configuração do shell
detect_shell_config() {
    # Detecta qual arquivo de configuração do shell usar
    # Verifica o shell do usuário via $SHELL
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
