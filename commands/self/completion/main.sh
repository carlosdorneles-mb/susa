#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source completion library
source "$LIB_DIR/internal/completion.sh"

# Help function
show_help() {
    show_description
    log_output ""
    show_usage "[shell] [options]"
    log_output ""
    log_output "${LIGHT_GREEN}Description:${NC}"
    log_output "  Gera e instala scripts de autocompletar (tab completion) para seu shell."
    log_output "  O autocompletar sugere categorias, comandos e subcategorias automaticamente."
    log_output ""
    log_output "${LIGHT_GREEN}Shells suportados:${NC}"
    log_output "  bash              Gera completion para Bash"
    log_output "  zsh               Gera completion para Zsh"
    log_output "  fish              Gera completion para Fish"
    log_output ""
    log_output "${LIGHT_GREEN}Options:${NC}"
    log_output "  -v, --verbose     Modo verbose (debug)"
    log_output "  -q, --quiet       Modo silencioso (mínimo de output)"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  -i, --install     Instala o completion no shell atual"
    log_output "  --uninstall       Remove o completion do shell"
    log_output "  -p, --print       Apenas imprime o script (não instala)"
    log_output ""
    log_output "${LIGHT_GREEN}Examples:${NC}"
    log_output "  susa self completion bash --install       # Instala completion para bash"
    log_output "  susa self completion zsh --install        # Instala completion para zsh"
    log_output "  susa self completion fish --install       # Instala completion para fish"
    log_output "  susa self completion bash --print         # Mostra o script bash"
    log_output "  susa self completion --uninstall          # Remove completion"
    log_output ""
    log_output "${LIGHT_GREEN}Post-installation:${NC}"
    log_output "  Após a instalação, reinicie o terminal ou execute:"
    log_output "    source ~/.bashrc   (para Bash)"
    log_output "    source ~/.zshrc    (para Zsh)"
    log_output "    (Fish carrega automaticamente)"
}

# Discover available categories dynamically
get_categories() {
    local commands_dir="$CLI_DIR/commands"
    local categories=""

    if [ -d "$commands_dir" ]; then
        for dir in "$commands_dir"/*/; do
            if [ -d "$dir" ]; then
                local category=$(basename "$dir")
                categories="$categories $category"
            fi
        done
    fi

    echo "$categories"
}

# Discover commands from a category dynamically
get_category_commands() {
    local category="$1"
    local category_dir="$CLI_DIR/commands/$category"
    local commands=""

    if [ -d "$category_dir" ]; then
        for item in "$category_dir"/*/; do
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

# Generate completion script for Bash
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

# Generate script completion for Zsh
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

# Generate completion script for Fish
generate_fish_completion() {
    cat << 'FISH_COMPLETION_EOF'
# Susa CLI - Fish Completion
# Gerado automaticamente por: susa self completion fish

# Função para obter o diretório do susa
function __susa_get_dir
    set -l susa_path (command -v susa)
    if test -n "$susa_path"
        dirname (readlink -f $susa_path)
    end
end

# Função para listar categorias
function __susa_categories
    set -l susa_dir (__susa_get_dir)
    test -z "$susa_dir"; and return

    set -l categories

    # Lista de commands/
    if test -d "$susa_dir/commands"
        for dir in $susa_dir/commands/*/
            test -d $dir; and set -a categories (basename $dir)
        end
    end

    # Lista de plugins/
    if test -d "$susa_dir/plugins"
        for plugin_dir in $susa_dir/plugins/*/
            if test -d $plugin_dir
                for cat_dir in $plugin_dir*/
                    test -d $cat_dir; and set -a categories (basename $cat_dir)
                end
            end
        end
    end

    # Remove duplicatas e imprime
    printf '%s\n' $categories | sort -u
end

# Função para listar comandos de uma categoria
function __susa_commands
    set -l category $argv[1]
    set -l susa_dir (__susa_get_dir)
    test -z "$susa_dir"; and return

    set -l commands

    # Lista de commands/categoria/
    if test -d "$susa_dir/commands/$category"
        for item in $susa_dir/commands/$category/*/
            set -l cmd (basename $item)
            if test -d $item; and test "$cmd" != "config.yaml"
                set -a commands $cmd
            end
        end
    end

    # Lista de plugins/*/categoria/
    if test -d "$susa_dir/plugins"
        for plugin_dir in $susa_dir/plugins/*/
            if test -d "$plugin_dir/$category"
                for item in $plugin_dir/$category/*/
                    set -l cmd (basename $item)
                    if test -d $item; and test "$cmd" != "config.yaml"
                        set -a commands $cmd
                    end
                end
            end
        end
    end

    # Remove duplicatas e imprime
    printf '%s\n' $commands | sort -u
end

# Função para listar subcomandos
function __susa_subcommands
    set -l path $argv[1]
    set -l susa_dir (__susa_get_dir)
    test -z "$susa_dir"; and return

    set -l subcommands

    # Lista de commands/path/
    if test -d "$susa_dir/commands/$path"
        for item in $susa_dir/commands/$path/*/
            set -l sub (basename $item)
            if test -d $item; and test "$sub" != "config.yaml"
                set -a subcommands $sub
            end
        end
    end

    # Lista de plugins/*/path/
    if test -d "$susa_dir/plugins"
        for plugin_dir in $susa_dir/plugins/*/
            if test -d "$plugin_dir/$path"
                for item in $plugin_dir/$path/*/
                    set -l sub (basename $item)
                    if test -d $item; and test "$sub" != "config.yaml"
                        set -a subcommands $sub
                    end
                end
            end
        end
    end

    # Remove duplicatas e imprime
    printf '%s\n' $subcommands | sort -u
end

# Condições para quando completar
function __susa_needs_category
    not __fish_seen_subcommand_from (__susa_categories)
end

function __susa_needs_command
    __fish_seen_subcommand_from (__susa_categories); and not __fish_seen_subcommand_from (__susa_commands (commandline -opc)[2])
end

# Completions principais
complete -c susa -f

# Opções globais
complete -c susa -s h -l help -d "Mostra ajuda"
complete -c susa -s V -l version -d "Mostra versão"

# Nível 1: Categorias
complete -c susa -n __susa_needs_category -a "(__susa_categories)" -d "Categoria"

# Nível 2: Comandos da categoria
complete -c susa -n __susa_needs_command -a "(__susa_commands (commandline -opc)[2])" -d "Comando"

# Nível 3+: Subcomandos (para subcategorias)
complete -c susa -n "test (count (commandline -opc)) -ge 3" -a "(__susa_subcommands (string join / (commandline -opc)[2..-1]))" -d "Subcomando"
FISH_COMPLETION_EOF
}

# Install autocomplete for Bash
install_bash_completion() {
    log_info "Instalando o autocompletar para Bash..."
    log_debug "Verificando se completion já está instalado"

    # Check if already installed
    if is_completion_installed "bash"; then
        log_warning "Autocompletar para Bash já está instalado"
        local completion_file=$(get_completion_file_path "bash")
        log_output "${LIGHT_YELLOW}Para reinstalar, primeiro desinstale: ${LIGHT_CYAN}susa self completion --uninstall${NC}"
        return 1
    fi

    local completion_dir=$(get_completion_dir_path "bash")
    local completion_file=$(get_completion_file_path "bash")
    local shell_config=$(detect_shell_config)

    log_debug "Diretório de completion: $completion_dir"
    log_debug "Arquivo de completion: $completion_file"
    log_debug "Config do shell: $shell_config"

    # Create directory if it doesn't exist
    mkdir -p "$completion_dir"
    log_debug "Diretório criado/verificado"

    # Generate and save the script
    log_debug "Gerando script de completion"
    generate_bash_completion > "$completion_file"
    chmod +x "$completion_file"
    log_debug "Script gerado e permissões configuradas"

    log_success "Autocompletar instalado em: $completion_file"
    log_output ""
    log_output "${LIGHT_YELLOW}Próximos passos:${NC}"
    log_output "  1. Reinicie o terminal ou execute: ${LIGHT_CYAN}source $shell_config${NC}"
    log_output "  2. Teste: ${LIGHT_CYAN}susa <TAB><TAB>${NC}"
}

# Install completion for Zsh
install_zsh_completion() {
    log_info "Instalando autocompletar para Zsh..."
    log_debug "Verificando se completion já está instalado"

    # Check if already installed
    if is_completion_installed "zsh"; then
        log_warning "Autocompletar para Zsh já está instalado"
        local completion_file=$(get_completion_file_path "zsh")
        log_output "${LIGHT_YELLOW}Para reinstalar, primeiro desinstale: ${LIGHT_CYAN}susa self completion --uninstall${NC}"
        return 1
    fi

    local completion_dir=$(get_completion_dir_path "zsh")
    local completion_file=$(get_completion_file_path "zsh")
    local shell_config=$(detect_shell_config)

    log_debug "Diretório de completion: $completion_dir"
    log_debug "Arquivo de completion: $completion_file"
    log_debug "Config do shell: $shell_config"

    # Create directory if it doesn't exist
    mkdir -p "$completion_dir"
    log_debug "Diretório criado/verificado"

    # Generate and save the script
    log_debug "Gerando script de completion"
    generate_zsh_completion > "$completion_file"
    chmod +x "$completion_file"
    log_debug "Script gerado e permissões configuradas"

    # Add to path if necessary
    if [ -f "$shell_config" ]; then
        if ! grep -q "fpath=.*$completion_dir" "$shell_config"; then
            echo "" >> "$shell_config"
            echo "# Susa CLI completion" >> "$shell_config"
            echo "fpath=($completion_dir \$fpath)" >> "$shell_config"
            echo "autoload -Uz compinit && compinit" >> "$shell_config"
        fi
    fi

    log_success "Autocompletar instalado em: $completion_file"
    log_output ""
    log_output "${LIGHT_YELLOW}Próximos passos:${NC}"
    log_output "  1. Reinicie o terminal ou execute: ${LIGHT_CYAN}source $shell_config${NC}"
    log_output "  2. Teste: ${LIGHT_CYAN}susa <TAB>${NC}"
}

# Install completion for Fish
install_fish_completion() {
    log_info "Instalando autocompletar para Fish..."
    log_debug "Verificando se completion já está instalado"

    # Check if already installed
    if is_completion_installed "fish"; then
        log_warning "Autocompletar para Fish já está instalado"
        local completion_file=$(get_completion_file_path "fish")
        log_output "${LIGHT_YELLOW}Para reinstalar, primeiro desinstale: ${LIGHT_CYAN}susa self completion --uninstall${NC}"
        return 1
    fi

    local completion_dir=$(get_completion_dir_path "fish")
    local completion_file=$(get_completion_file_path "fish")

    log_debug "Diretório de completion: $completion_dir"
    log_debug "Arquivo de completion: $completion_file"

    # Create directory if it doesn't exist
    mkdir -p "$completion_dir"
    log_debug "Diretório criado/verificado"

    # Generate and save the script
    log_debug "Gerando script de completion"
    generate_fish_completion > "$completion_file"
    chmod +x "$completion_file"
    log_debug "Script gerado e permissões configuradas"

    log_success "Autocompletar instalado em: $completion_file"
    log_output ""
    log_output "${LIGHT_YELLOW}Próximos passos:${NC}"
    log_output "  1. O Fish carrega automaticamente os completions"
    log_output "  2. Abra um novo terminal ou execute: ${LIGHT_CYAN}fish${NC}"
    log_debug "Procurando completions instalados"

    local removed=false

    # Remove bash completion
    if is_completion_installed "bash"; then
        local bash_completion=$(get_completion_file_path "bash")
        log_debug "Removendo completion bash: $bash_completion"
        rm "$bash_completion"
        log_debug "Removido: $bash_completion"
        removed=true
    fi

    # Remove zsh completion
    if is_completion_installed "zsh"; then
        local zsh_completion=$(get_completion_file_path "zsh")
        log_debug "Removendo completion zsh: $zsh_completion"
        rm "$zsh_completion"
        log_debug "Removido: $zsh_completion"
        removed=true
    fi

    # Remove fish completion
    if is_completion_installed "fish"; then
        local fish_completion=$(get_completion_file_path "fish")
        log_debug "Removendo completion fish: $fish_completion"
        removed=true
    fi

    # Remove fish completion
    if is_completion_installed "fish"; then
        local fish_completion=$(get_completion_file_path "fish")
        rm "$fish_completion"
        log_debug "Removido: $fish_completion"
        removed=true
    fi

    if [ "$removed" = true ]; then
        log_success "Autocompletar removido com sucesso!"
        log_output ""
        log_output "${LIGHT_YELLOW}Nota:${NC} Reinicie o terminal para aplicar as mudanças"
    else
        log_warning "Nenhum autocompletar encontrado para remover"
    fi
}

# Handle install action
handle_install() {
    local shell_type="$1"

    log_debug "Iniciando instalação de completion"

    # Detecta shell se não especificado
    if [ -z "$shell_type" ]; then
        log_debug "Shell não especificado, detectando automaticamente"
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
            install_fish_completion
            ;;
        *)
            log_error "Shell não suportado: $shell_type"
            return 1
            ;;
    esac
}

# Handle print action
handle_print() {
    local shell_type="$1"

    if [ -z "$shell_type" ]; then
        log_error "Especifique o shell: bash, zsh ou fish"
        return 1
    fi

    case "$shell_type" in
        bash)
            generate_bash_completion
            ;;
        zsh)
            generate_zsh_completion
            ;;
        fish)
            generate_fish_completion
            ;;
        *)
            log_error "Shell não suportado: $shell_type"
            return 1
            ;;
    esac
}

# Main function
main() {
    local shell_type=""
    local action=""

    # If there are no arguments, show help
    if [ $# -eq 0 ]; then
        show_help
        return 0
    fi

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h | --help)
                show_help
                return 0
                ;;
            -v | --verbose)
                export DEBUG=1
                log_debug "Modo verbose ativado"
                shift
                ;;
            -q | --quiet)
                export SILENT=1
                shift
                ;;
            -i | --install)
                action="install"
                shift
                ;;
            --uninstall)
                action="uninstall"
                shift
                ;;
            -p | --print)
                action="print"
                shift
                ;;
            bash | zsh | fish)
                shell_type="$1"
                shift
                ;;
            *)
                log_error "Argumento inválido: $1"
                log_output ""
                show_help
                return 1
                ;;
        esac
    done

    # If no action was specified, show help
    if [ -z "$action" ]; then
        show_help
        return 0
    fi

    # Performs corresponding action
    case "$action" in
        install)
            handle_install "$shell_type"
            ;;
        uninstall)
            uninstall_completion
            ;;
        print)
            handle_print "$shell_type"
            ;;
    esac
}

# Executes (does not execute if it has already been called via source for show_help)
if [ "${SUSA_SHOW_HELP_CALLED:-false}" != "true" ]; then
    main "$@"
fi
