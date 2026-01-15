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
    log_output "  susa self completion --install            # Instala em todos os shells"
    log_output "  susa self completion bash --install       # Instala apenas no bash"
    log_output "  susa self completion zsh --install        # Instala apenas no zsh"
    log_output "  susa self completion fish --install       # Instala apenas no fish"
    log_output "  susa self completion bash --print         # Mostra o script bash"
    log_output "  susa self completion --uninstall          # Remove de todos os shells"
    log_output "  susa self completion zsh --uninstall      # Remove apenas do zsh"
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

    local susa_dir="$(dirname "$(dirname "$(readlink -f "$(command -v susa)")")")"  # Volta 2 níveis

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
    local curcontext="$curcontext" state line
    typeset -A opt_args

    local susa_dir="$(dirname "$(dirname "$(readlink -f "$(command -v susa)")")")"  # Volta 2 níveis

    # Função para listar itens de um diretório
    _susa_list_items() {
        local path="$1"
        local items=()

        # Lista de commands/path/
        if [ -d "$susa_dir/commands/$path" ]; then
            for item in "$susa_dir/commands/$path"/*/; do
                if [ -d "$item" ]; then
                    local name="${item:t}"
                    [ "$name" != "config.yaml" ] && items+=("$name")
                fi
            done
        fi

        # Lista de plugins/*/path/
        if [ -d "$susa_dir/plugins" ]; then
            for plugin_dir in "$susa_dir/plugins"/*/; do
                if [ -d "$plugin_dir/$path" ]; then
                    for item in "$plugin_dir/$path"/*/; do
                        if [ -d "$item" ]; then
                            local name="${item:t}"
                            [ "$name" != "config.yaml" ] && items+=("$name")
                        fi
                    done
                fi
            done
        fi

        # Remove duplicatas
        items=(${(u)items})
        echo "${items[@]}"
    }

    # Função recursiva para completion
    _susa_complete() {
        local -a completions
        local path=""

        # Constrói o path baseado nos argumentos já fornecidos
        for ((i=2; i<=$CURRENT; i++)); do
            if [ -n "$words[$i]" ] && [ "$i" -lt "$CURRENT" ]; then
                if [ -z "$path" ]; then
                    path="$words[$i]"
                else
                    path="$path/$words[$i]"
                fi
            fi
        done

        # Lista os itens do diretório atual
        local items=($(_susa_list_items "$path"))

        if [ ${#items[@]} -gt 0 ]; then
            completions=("${items[@]}")
            _describe -t commands 'command' completions
        fi
    }

    _susa_complete
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
        dirname (dirname (readlink -f $susa_path))  # Volta 2 níveis (core/susa -> core -> raiz)
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

    log_debug "Instalando em: $completion_file"

    # Create directory if it doesn't exist
    mkdir -p "$completion_dir"

    # Generate and save the script
    generate_bash_completion > "$completion_file"
    chmod +x "$completion_file"

    log_success "   ✅ Instalado: $completion_file"
    return 0
}

# Install completion for Zsh
install_zsh_completion() {
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

    log_debug "Instalando em: $completion_file"

    # Create directory if it doesn't exist
    mkdir -p "$completion_dir"

    # Generate and save the script
    generate_zsh_completion > "$completion_file"
    chmod +x "$completion_file"

    # Add to path if necessary
    if [ -f "$shell_config" ]; then
        if ! grep -q "fpath=.*$completion_dir" "$shell_config"; then
            echo "" >> "$shell_config"
            echo "# Susa CLI completion" >> "$shell_config"
            echo "fpath=($completion_dir \$fpath)" >> "$shell_config"
            echo "autoload -Uz compinit && compinit" >> "$shell_config"
            log_debug "Configuração adicionada ao shell"
        fi
    fi

    # Clear zsh completion cache
    rm -f ~/.zcompdump* 2> /dev/null || true

    log_success "   ✅ Instalado: $completion_file"
    return 0
}

# Install completion for Fish
install_fish_completion() {
    # Check if already installed
    if is_completion_installed "fish"; then
        log_warning "Autocompletar para Fish já está instalado"
        local completion_file=$(get_completion_file_path "fish")
        log_output "${LIGHT_YELLOW}Para reinstalar, primeiro desinstale: ${LIGHT_CYAN}susa self completion --uninstall${NC}"
        return 1
    fi

    local completion_dir=$(get_completion_dir_path "fish")
    local completion_file=$(get_completion_file_path "fish")

    log_debug "Instalando em: $completion_file"

    # Create directory if it doesn't exist
    mkdir -p "$completion_dir"

    # Generate and save the script
    generate_fish_completion > "$completion_file"
    chmod +x "$completion_file"

    log_success "   ✅ Instalado: $completion_file"
    return 0
}

# Uninstall completion from one or all shells
handle_uninstall() {
    local shell_type="$1"

    # Se não especificou shell, remove de todos instalados
    if [ -z "$shell_type" ]; then
        log_info "Removendo autocompletar de todos os shells instalados..."
        log_output ""

        local removed_count=0
        local shells_to_remove=()

        # Detecta shells com completion instalado
        if is_completion_installed "bash"; then
            shells_to_remove+=("bash")
        fi

        if is_completion_installed "zsh"; then
            shells_to_remove+=("zsh")
        fi

        if is_completion_installed "fish"; then
            shells_to_remove+=("fish")
        fi

        if [ ${#shells_to_remove[@]} -eq 0 ]; then
            log_warning "Nenhum completion instalado encontrado"
            return 0
        fi

        log_info "Completions encontrados: ${shells_to_remove[*]}"
        log_output ""

        # Remove completion de cada shell encontrado
        for shell in "${shells_to_remove[@]}"; do
            log_info "Removendo completion do $shell..."

            local completion_file=$(get_completion_file_path "$shell")

            if rm "$completion_file" 2> /dev/null; then
                log_success "✅ Completion do $shell removido"
                removed_count=$((removed_count + 1))
            else
                log_error "Erro ao remover completion do $shell"
            fi
            log_output ""
        done

        if [ $removed_count -gt 0 ]; then
            # Limpa cache do zsh se foi removido
            if [[ " ${shells_to_remove[*]} " =~ " zsh " ]]; then
                rm -f ~/.zcompdump* 2> /dev/null
            fi

            log_success "✅ Completion removido de $removed_count shell(s)!"
            log_output ""
            log_output "${LIGHT_YELLOW}Próximos passos:${NC}"
            log_output "  • Abra um novo terminal para aplicar as mudanças"
            log_output "  • Ou execute ${LIGHT_CYAN}exec \$SHELL${NC} no terminal atual"
        else
            log_error "Nenhum completion foi removido"
            return 1
        fi

        return 0
    fi

    # Se especificou um shell, remove apenas dele
    case "$shell_type" in
        bash | zsh | fish)
            if ! is_completion_installed "$shell_type"; then
                log_warning "Completion para $shell_type não está instalado"
                return 0
            fi

            local completion_file=$(get_completion_file_path "$shell_type")
            log_info "Removendo completion do $shell_type..."

            if rm "$completion_file" 2> /dev/null; then
                # Limpa cache do zsh se necessário
                if [ "$shell_type" = "zsh" ]; then
                    rm -f ~/.zcompdump* 2> /dev/null
                fi

                log_success "Completion do $shell_type removido com sucesso!"
                log_output ""
                log_output "${LIGHT_YELLOW}Nota:${NC} Reinicie o terminal para aplicar as mudanças"
                return 0
            else
                log_error "Erro ao remover completion do $shell_type"
                return 1
            fi
            ;;
        *)
            log_error "Shell não suportado: $shell_type"
            return 1
            ;;
    esac
}

# Handle install action
handle_install() {
    local shell_type="$1"

    # Se não especificou shell, instala em todos disponíveis
    if [ -z "$shell_type" ]; then
        log_info "Detectando shells disponíveis no sistema..."
        log_output ""

        local installed_count=0
        local shells_to_install=()

        # Detecta shells disponíveis
        if command -v bash > /dev/null 2>&1; then
            shells_to_install+=("bash")
        fi

        if command -v zsh > /dev/null 2>&1; then
            shells_to_install+=("zsh")
        fi

        if command -v fish > /dev/null 2>&1; then
            shells_to_install+=("fish")
        fi

        if [ ${#shells_to_install[@]} -eq 0 ]; then
            log_error "Nenhum shell suportado encontrado no sistema"
            return 1
        fi

        log_info "Shells encontrados: $(printf '%s, ' "${shells_to_install[@]}" | sed 's/, $//')"
        log_output ""

        # Instala completion para cada shell encontrado
        for shell in "${shells_to_install[@]}"; do
            log_info "📦 Instalando completion para $shell..."

            if is_completion_installed "$shell"; then
                log_warning "Completion para $shell já está instalado (pulando)"
            else
                case "$shell" in
                    bash)
                        if install_bash_completion; then
                            installed_count=$((installed_count + 1))
                        fi
                        ;;
                    zsh)
                        if install_zsh_completion; then
                            installed_count=$((installed_count + 1))
                        fi
                        ;;
                    fish)
                        if install_fish_completion; then
                            installed_count=$((installed_count + 1))
                        fi
                        ;;
                esac
            fi
        done

        if [ $installed_count -gt 0 ]; then
            log_output ""
            log_success "🎉 Completion instalado com sucesso em $installed_count shell(s)!"
            log_output ""
            log_output "${LIGHT_YELLOW}Para ativar:${NC}"
            log_output "  • Abra um novo terminal, ou"
            log_output "  • Execute: ${LIGHT_CYAN}exec \$SHELL${NC}"
            log_output ""
            log_output "${LIGHT_YELLOW}Teste:${NC} ${LIGHT_CYAN}susa <TAB>${NC}"
        else
            log_info "Nenhum completion novo foi instalado"
        fi

        return 0
    fi

    # Se especificou um shell, instala apenas nele
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
            handle_uninstall "$shell_type"
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
