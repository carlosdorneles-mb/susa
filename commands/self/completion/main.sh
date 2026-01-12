#!/bin/bash

# ============================================================
# Susa CLI - Shell Completion Generator
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUSA_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SUSA_DIR/lib/logger.sh"
source "$SUSA_DIR/lib/color.sh"
source "$SUSA_DIR/lib/shell.sh"

show_help() {
    echo "Configuração de Autocompletar do Susa CLI"
    echo ""
    echo -e "${LIGHT_GREEN}Usage:${NC} susa self completion [shell] [options]"
    echo ""
    echo -e "${LIGHT_GREEN}Description:${NC}"
    echo "  Gera e instala scripts de autocompletar (tab completion) para seu shell."
    echo "  O autocompletar sugere categorias, comandos e subcategorias automaticamente."
    echo ""
    echo -e "${LIGHT_GREEN}Shells suportados:${NC}"
    echo "  bash              Gera completion para Bash"
    echo "  zsh               Gera completion para Zsh"
    echo ""
    echo -e "${LIGHT_GREEN}Options:${NC}"
    echo "  -h, --help        Mostra esta mensagem de ajuda"
    echo "  -i, --install     Instala o completion no shell atual"
    echo "  -u, --uninstall   Remove o completion do shell"
    echo "  -p, --print       Apenas imprime o script (não instala)"
    echo ""
    echo -e "${LIGHT_GREEN}Examples:${NC}"
    echo "  susa self completion bash --install       # Instala completion para bash"
    echo "  susa self completion zsh --install        # Instala completion para zsh"
    echo "  susa self completion bash --print         # Mostra o script bash"
    echo "  susa self completion --uninstall          # Remove completion"
    echo ""
    echo -e "${LIGHT_GREEN}Post-installation:${NC}"
    echo "  Após a instalação, reinicie o terminal ou execute:"
    echo "    source ~/.bashrc   (para Bash)"
    echo "    source ~/.zshrc    (para Zsh)"
}

# Descobre categorias disponíveis dinamicamente
get_categories() {
    local commands_dir="$SUSA_DIR/commands"
    local categories=""
    
    if [ -d "$commands_dir" ]; then
        for dir in "$commands_dir"/*/ ; do
            if [ -d "$dir" ]; then
                local category=$(basename "$dir")
                categories="$categories $category"
            fi
        done
    fi
    
    echo "$categories"
}

# Descobre comandos de uma categoria
get_category_commands() {
    local category="$1"
    local category_dir="$SUSA_DIR/commands/$category"
    local commands=""
    
    if [ -d "$category_dir" ]; then
        for item in "$category_dir"/*/ ; do
            if [ -d "$item" ]; then
                local cmd=$(basename "$item")
                # Ignora config.yaml
                if [ "$cmd" != "config.yaml" ]; then
                    commands="$commands $cmd"
                fi
            fi
        done
    fi
    
    echo "$commands"
}

# Gera script de completion para Bash
generate_bash_completion() {
    cat << 'BASH_COMPLETION_EOF'
# Susa CLI - Bash Completion
# Gerado automaticamente por: susa self completion bash

_susa_completion() {
    local cur prev words cword
    _init_completion || return
    
    local susa_dir="$(dirname "$(readlink -f "$(command -v susa)")")"
    
    # Função para listar categorias (commands + plugins)
    _susa_get_categories() {
        local categories=""
        
        # Lista de commands/
        if [ -d "$susa_dir/commands" ]; then
            categories="$(ls -1 "$susa_dir/commands" 2>/dev/null)"
        fi
        
        # Lista de plugins/
        if [ -d "$susa_dir/plugins" ]; then
            for plugin_dir in "$susa_dir/plugins"/*/ ; do
                if [ -d "$plugin_dir" ] && [ -f "$plugin_dir/config.yaml" ]; then
                    # Plugin pode ter suas próprias categorias
                    for cat_dir in "$plugin_dir"/*/ ; do
                        if [ -d "$cat_dir" ]; then
                            categories="$categories $(basename "$cat_dir")"
                        fi
                    done
                fi
            done
        fi
        
        echo "$categories" | tr ' ' '\n' | sort -u
    }
    
    # Função para listar comandos de uma categoria (commands + plugins)
    _susa_get_commands() {
        local category="$1"
        local commands=""
        
        # Lista de commands/categoria/
        if [ -d "$susa_dir/commands/$category" ]; then
            commands="$(ls -1 "$susa_dir/commands/$category" 2>/dev/null | grep -v "config.yaml")"
        fi
        
        # Lista de plugins/*/categoria/
        if [ -d "$susa_dir/plugins" ]; then
            for plugin_dir in "$susa_dir/plugins"/*/ ; do
                if [ -d "$plugin_dir/$category" ]; then
                    local plugin_cmds="$(ls -1 "$plugin_dir/$category" 2>/dev/null | grep -v "config.yaml")"
                    commands="$commands $plugin_cmds"
                fi
            done
        fi
        
        echo "$commands" | tr ' ' '\n' | sort -u
    }
    
    # Função para listar subcomandos (commands + plugins)
    _susa_get_subcommands() {
        local path="$1"
        local subcommands=""
        
        # Lista de commands/path/
        if [ -d "$susa_dir/commands/$path" ]; then
            subcommands="$(ls -1 "$susa_dir/commands/$path" 2>/dev/null | grep -v "config.yaml")"
        fi
        
        # Lista de plugins/*/path/
        if [ -d "$susa_dir/plugins" ]; then
            for plugin_dir in "$susa_dir/plugins"/*/ ; do
                if [ -d "$plugin_dir/$path" ]; then
                    local plugin_subs="$(ls -1 "$plugin_dir/$path" 2>/dev/null | grep -v "config.yaml")"
                    subcommands="$subcommands $plugin_subs"
                fi
            done
        fi
        
        echo "$subcommands" | tr ' ' '\n' | sort -u
    }
    
    # Primeiro nível: categorias
    if [ $cword -eq 1 ]; then
        COMPREPLY=( $(compgen -W "$(_susa_get_categories)" -- "$cur") )
        return 0
    fi
    
    # Segundo nível: comandos da categoria
    if [ $cword -eq 2 ]; then
        local category="${words[1]}"
        COMPREPLY=( $(compgen -W "$(_susa_get_commands "$category")" -- "$cur") )
        return 0
    fi
    
    # Terceiro nível e além: subcomandos
    if [ $cword -ge 3 ]; then
        local path="${words[1]}"
        for ((i=2; i<cword; i++)); do
            path="$path/${words[i]}"
        done
        COMPREPLY=( $(compgen -W "$(_susa_get_subcommands "$path")" -- "$cur") )
        return 0
    fi
}

complete -F _susa_completion susa
BASH_COMPLETION_EOF
}

# Gera script de completion para Zsh
generate_zsh_completion() {
    cat << 'ZSH_COMPLETION_EOF'
#compdef susa
# Susa CLI - Zsh Completion
# Gerado automaticamente por: susa self completion zsh

_susa() {
    local line state
    
    local susa_dir="$(dirname "$(readlink -f "$(command -v susa)")")"
    
    _arguments -C \
        "1: :->category" \
        "2: :->command" \
        "*::arg:->args"
    
    case $state in
        category)
            local categories=()
            
            # Lista de commands/
            if [ -d "$susa_dir/commands" ]; then
                for dir in "$susa_dir/commands"/*/; do
                    [ -d "$dir" ] && categories+=(${dir:t})
                done
            fi
            
            # Lista de plugins/
            if [ -d "$susa_dir/plugins" ]; then
                for plugin_dir in "$susa_dir/plugins"/*/; do
                    if [ -d "$plugin_dir" ] && [ -f "$plugin_dir/config.yaml" ]; then
                        for cat_dir in "$plugin_dir"*/; do
                            [ -d "$cat_dir" ] && categories+=(${cat_dir:t})
                        done
                    fi
                done
            fi
            
            # Remove duplicatas
            categories=(${(u)categories})
            _describe 'category' categories
            ;;
        command)
            local category=$line[1]
            local commands=()
            
            # Lista de commands/categoria/
            if [ -d "$susa_dir/commands/$category" ]; then
                for item in "$susa_dir/commands/$category"/*/; do
                    [ -d "$item" ] && commands+=(${item:t})
                done
            fi
            
            # Lista de plugins/*/categoria/
            if [ -d "$susa_dir/plugins" ]; then
                for plugin_dir in "$susa_dir/plugins"/*/; do
                    if [ -d "$plugin_dir/$category" ]; then
                        for item in "$plugin_dir/$category"/*/; do
                            [ -d "$item" ] && commands+=(${item:t})
                        done
                    fi
                done
            fi
            
            # Remove duplicatas
            commands=(${(u)commands})
            _describe 'command' commands
            ;;
        args)
            # Suporte para subcomandos em níveis mais profundos
            local path="$line[1]/$line[2]"
            local subcommands=()
            
            # Lista de commands/path/
            if [ -d "$susa_dir/commands/$path" ]; then
                for item in "$susa_dir/commands/$path"/*/; do
                    [ -d "$item" ] && subcommands+=(${item:t})
                done
            fi
            
            # Lista de plugins/*/path/
            if [ -d "$susa_dir/plugins" ]; then
                for plugin_dir in "$susa_dir/plugins"/*/; do
                    if [ -d "$plugin_dir/$path" ]; then
                        for item in "$plugin_dir/$path"/*/; do
                            [ -d "$item" ] && subcommands+=(${item:t})
                        done
                    fi
                done
            fi
            
            # Remove duplicatas
            subcommands=(${(u)subcommands})
            _describe 'subcommand' subcommands
            ;;
    esac
}

_susa "$@"
ZSH_COMPLETION_EOF
}

# Instala completion para Bash
install_bash_completion() {
    log_info "Instalando completion para Bash..."
    
    local completion_dir="$HOME/.local/share/bash-completion/completions"
    local completion_file="$completion_dir/susa"
    local shell_config=$(detect_shell_config)
    
    # Cria diretório se não existir
    mkdir -p "$completion_dir"
    
    # Gera e salva o script
    generate_bash_completion > "$completion_file"
    chmod +x "$completion_file"
    
    log_success "Completion instalado em: $completion_file"
    echo ""
    echo -e "${LIGHT_YELLOW}Próximos passos:${NC}"
    echo -e "  1. Reinicie o terminal ou execute: ${LIGHT_CYAN}source $shell_config${NC}"
    echo -e "  2. Teste: ${LIGHT_CYAN}susa <TAB><TAB>${NC}"
}

# Instala completion para Zsh
install_zsh_completion() {
    log_info "Instalando completion para Zsh..."
    
    local completion_dir="$HOME/.local/share/zsh/site-functions"
    local completion_file="$completion_dir/_susa"
    local shell_config=$(detect_shell_config)
    
    # Cria diretório se não existir
    mkdir -p "$completion_dir"
    
    # Gera e salva o script
    generate_zsh_completion > "$completion_file"
    chmod +x "$completion_file"
    
    # Adiciona ao fpath se necessário
    if [ -f "$shell_config" ]; then
        if ! grep -q "fpath=.*$completion_dir" "$shell_config"; then
            echo "" >> "$shell_config"
            echo "# Susa CLI completion" >> "$shell_config"
            echo "fpath=($completion_dir \$fpath)" >> "$shell_config"
            echo "autoload -Uz compinit && compinit" >> "$shell_config"
        fi
    fi
    
    log_success "Completion instalado em: $completion_file"
    echo ""
    echo -e "${LIGHT_YELLOW}Próximos passos:${NC}"
    echo -e "  1. Reinicie o terminal ou execute: ${LIGHT_CYAN}source $shell_config${NC}"
    echo -e "  2. Teste: ${LIGHT_CYAN}susa <TAB>${NC}"
}

# Remove completion
uninstall_completion() {
    log_info "Removendo completion..."
    
    local removed=false
    
    # Remove bash completion
    local bash_completion="$HOME/.local/share/bash-completion/completions/susa"
    if [ -f "$bash_completion" ]; then
        rm "$bash_completion"
        log_debug "Removido: $bash_completion"
        removed=true
    fi
    
    # Remove zsh completion
    local zsh_completion="$HOME/.local/share/zsh/site-functions/_susa"
    if [ -f "$zsh_completion" ]; then
        rm "$zsh_completion"
        log_debug "Removido: $zsh_completion"
        removed=true
    fi
    
    if [ "$removed" = true ]; then
        log_success "Completion removido com sucesso!"
        echo ""
        echo -e "${LIGHT_YELLOW}Nota:${NC} Reinicie o terminal para aplicar as mudanças"
    else
        log_warning "Nenhum completion encontrado para remover"
    fi
}

# Parse argumentos
main() {
    local shell_type=""
    local action="help"
    
    # Se não houver argumentos, mostra help
    if [ $# -eq 0 ]; then
        show_help
        return 0
    fi
    
    # Parse argumentos
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                return 0
                ;;
            -i|--install)
                action="install"
                shift
                ;;
            -u|--uninstall)
                action="uninstall"
                shift
                ;;
            -p|--print)
                action="print"
                shift
                ;;
            bash|zsh|fish)
                shell_type="$1"
                shift
                ;;
            *)
                log_error "Argumento inválido: $1"
                echo ""
                show_help
                return 1
                ;;
        esac
    done
    
    # Executa ação
    case "$action" in
        install)
            # Detecta shell se não especificado
            if [ -z "$shell_type" ]; then
                shell_type=$(detect_shell_type)
                if [ "$shell_type" = "unknown" ]; then
                    log_error "Não foi possível detectar seu shell. Especifique: bash ou zsh"
                    return 1
                fi
                log_debug "Shell detectado: $shell_type"
            fi
            
            case "$shell_type" in
                bash)
                    install_bash_completion
                    ;;
                zsh)
                    install_zsh_completion
                    ;;
                fish)
                    log_error "Fish shell ainda não suportado"
                    return 1
                    ;;
                *)
                    log_error "Shell não suportado: $shell_type"
                    return 1
                    ;;
            esac
            ;;
        uninstall)
            uninstall_completion
            ;;
        print)
            if [ -z "$shell_type" ]; then
                log_error "Especifique o shell: bash ou zsh"
                return 1
            fi
            
            case "$shell_type" in
                bash)
                    generate_bash_completion
                    ;;
                zsh)
                    generate_zsh_completion
                    ;;
                *)
                    log_error "Shell não suportado: $shell_type"
                    return 1
                    ;;
            esac
            ;;
        help)
            show_help
            ;;
    esac
}

# Executa
main "$@"
