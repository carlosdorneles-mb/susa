# Padrões de Comandos Setup

Este documento descreve os padrões e convenções utilizados nos comandos da categoria `setup`, que são responsáveis pela instalação e gerenciamento de ferramentas de desenvolvimento.

## 📋 Índice

- [Estrutura de Arquivos](#estrutura-de-arquivos)
- [Arquivo command.json](#arquivo-commandjson)
- [Estrutura do main.sh](#estrutura-do-mainsh)
- [Funções Obrigatórias](#funções-obrigatórias)
- [Funções Auxiliares Comuns](#funções-auxiliares-comuns)
- [Integração com Biblioteca](#integração-com-biblioteca)
- [Fluxo de Execução](#fluxo-de-execução)
- [Boas Práticas](#boas-práticas)
- [Exemplos de Implementação](#exemplos-de-implementação)

---

## Estrutura de Arquivos

Cada comando de setup deve seguir esta estrutura:

```text
commands/setup/
└── nome-ferramenta/
    ├── command.json     # Configuração do comando
    └── main.sh          # Script de instalação
```

### Arquivos Opcionais

Alguns comandos podem incluir:

- Subcomandos em subdiretórios (não é comum em setup)

---

## Arquivo command.json

Configuração padrão com metadados e variáveis de ambiente:

```json
{
  "name": "Nome da Ferramenta",
  "description": "Breve descrição do que a ferramenta faz",
  "entrypoint": "main.sh",
  "sudo": false,
  "os": ["linux", "mac"],
  "group": "categoria",
  "envs": {
    "TOOL_GITHUB_API_URL": "https://api.github.com/repos/owner/repo/releases/latest",
    "TOOL_GITHUB_REPO_URL": "https://github.com/owner/repo.git",
    "TOOL_INSTALL_SCRIPT_URL": "https://install.example.com",
    "TOOL_API_MAX_TIME": "10",
    "TOOL_API_CONNECT_TIMEOUT": "5",
    "TOOL_GIT_TIMEOUT": "5",
    "TOOL_HOME": "$HOME/.local/share/tool",
    "TOOL_LOCAL_BIN_DIR": "$HOME/.local/bin"
  }
}
```

**Nota:** JSON não suporta comentários. Use a documentação ou README para explicar os campos.

### Convenções de Nomenclatura

- **Prefixo**: Todas as variáveis devem começar com o nome da ferramenta em UPPERCASE
- **Sufixos comuns**:
  - `_API_URL` - URL da API do GitHub para obter versões
  - `_REPO_URL` - URL do repositório Git
  - `_INSTALL_SCRIPT_URL` - URL do script de instalação oficial
  - `_MAX_TIME` - Timeout máximo para operações
  - `_CONNECT_TIMEOUT` - Timeout de conexão
  - `_HOME` - Diretório principal da ferramenta
  - `_LOCAL_BIN_DIR` - Diretório de executáveis

---

## Estrutura do main.sh

Todo arquivo `main.sh` deve seguir esta estrutura básica:

```bash
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Source installations library
source "$LIB_DIR/internal/installations.sh"

# Help function
show_help() {
    # Implementação do help
}

# Funções de obtenção de versão
get_latest_tool_version() {
    # Implementação
}

get_tool_version() {
    # Implementação
}

# Verificação de instalação existente
check_existing_installation() {
    # Implementação
}

# Funções de instalação por SO
install_tool_linux() {
    # Implementação
}

install_tool_macos() {
    # Implementação
}

# Função principal de instalação
install_tool() {
    # Implementação
}

# Função de atualização
update_tool() {
    # Implementação
}

# Função de desinstalação
uninstall_tool() {
    # Implementação
}

# Main function
main() {
    # Parse de argumentos e execução
}

# Execute main function
main "$@"
```

---

## Funções Obrigatórias

### 1. show_help()

Exibe ajuda completa do comando com estrutura padronizada:

```bash
show_help() {
    show_description  # Função da biblioteca
    log_output ""
    show_usage        # Função da biblioteca
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Descrição detalhada da ferramenta e seu propósito."
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra esta mensagem de ajuda"
    log_output "  --uninstall       Desinstala a ferramenta do sistema"
    log_output "  --update          Atualiza a ferramenta para a versão mais recente"
    log_output "  -v, --verbose     Habilita saída detalhada para depuração"
    log_output "  -q, --quiet       Minimiza a saída, desabilita mensagens de depuração"
    log_output ""
    log_output "${LIGHT_GREEN}Exemplos:${NC}"
    log_output "  susa setup tool              # Instala a ferramenta"
    log_output "  susa setup tool --update     # Atualiza a ferramenta"
    log_output "  susa setup tool --uninstall  # Desinstala a ferramenta"
    log_output ""
    log_output "${LIGHT_GREEN}Pós-instalação:${NC}"
    log_output "  Instruções específicas pós-instalação"
    log_output ""
    log_output "${LIGHT_GREEN}Próximos passos:${NC}"
    log_output "  Comandos úteis para começar a usar"
}
```

**Seções obrigatórias:**

- `O que é` - Descrição da ferramenta
- `Opções` - Lista de argumentos aceitos
- `Exemplos` - Exemplos de uso comum
- `Pós-instalação` - Passos necessários após instalação (se aplicável)
- `Próximos passos` - Comandos básicos para iniciar

### 2. get_latest_tool_version()

Obtém a versão mais recente da ferramenta com fallback:

```bash
get_latest_tool_version() {
    # Método 1: API do GitHub (preferencial)
    local latest_version=$(curl -s \
        --max-time "${TOOL_API_MAX_TIME:-10}" \
        --connect-timeout "${TOOL_API_CONNECT_TIMEOUT:-5}" \
        "${TOOL_GITHUB_API_URL}" 2>/dev/null | \
        grep '"tag_name":' | \
        sed -E 's/.*"([^"]+)".*/\1/')

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via API do GitHub: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    # Método 2: Git ls-remote (fallback)
    log_debug "API do GitHub falhou, tentando via git ls-remote..." >&2
    latest_version=$(timeout "${TOOL_GIT_TIMEOUT:-5}" \
        git ls-remote --tags --refs "${TOOL_GITHUB_REPO_URL}" 2>/dev/null | \
        grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+$' | \
        sort -V | \
        tail -1)

    if [ -n "$latest_version" ]; then
        log_debug "Versão obtida via git ls-remote: $latest_version" >&2
        echo "$latest_version"
        return 0
    fi

    # Falha em obter versão
    log_error "Não foi possível obter a versão mais recente" >&2
    log_error "Verifique sua conexão com a internet e tente novamente" >&2
    return 1
}
```

**Características:**

- Dois métodos com fallback
- Timeouts configuráveis
- Log de debug para troubleshooting
- Tratamento de erros

### 3. get_tool_version()

Obtém a versão atualmente instalada:

```bash
get_tool_version() {
    if command -v tool &>/dev/null; then
        tool --version 2>/dev/null | \
            grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | \
            head -1 || echo "desconhecida"
    else
        echo "desconhecida"
    fi
}
```

### 4. check_existing_installation()

Verifica se já está instalado e oferece atualização:

```bash
check_existing_installation() {
    log_debug "Verificando instalação existente..."

    if ! command -v tool &>/dev/null; then
        log_debug "Ferramenta não está instalada"
        return 0
    fi

    local current_version=$(get_tool_version)
    log_info "Ferramenta $current_version já está instalada."

    # Mark as installed in lock file
    mark_installed "tool" "$current_version"

    # Check for updates
    log_debug "Obtendo última versão..."
    local latest_version=$(get_latest_tool_version)

    if [ $? -eq 0 ] && [ -n "$latest_version" ]; then
        if [ "$current_version" != "$latest_version" ]; then
            log_output ""
            log_output "${YELLOW}Nova versão disponível ($latest_version).${NC}"
            log_output "Para atualizar, execute: ${LIGHT_CYAN}susa setup tool --update${NC}"
        fi
    else
        log_warning "Não foi possível verificar atualizações"
    fi

    return 1  # Retorna 1 para indicar que já está instalado
}
```

**Responsabilidades:**

- Verificar se o comando existe
- Registrar no lock file
- Verificar atualizações disponíveis
- Informar usuário sobre nova versão

### 5. install_tool()

Função principal de instalação:

```bash
install_tool() {
    log_info "Instalando ferramenta..."

    # Verificar instalação existente
    if ! check_existing_installation; then
        log_info "Ferramenta já instalada. Use --update para atualizar."
        return 0
    fi

    # Detectar SO
    local os_type=$(detect_os)
    log_debug "Sistema operacional detectado: $os_type"

    # Instalar baseado no SO
    case "$os_type" in
        linux)
            install_tool_linux
            ;;
        macos)
            install_tool_macos
            ;;
        *)
            log_error "Sistema operacional não suportado: $os_type"
            return 1
            ;;
    esac

    # Verificar instalação
    if command -v tool &>/dev/null; then
        local installed_version=$(get_tool_version)
        mark_installed "tool" "$installed_version"
        log_success "Ferramenta $installed_version instalada com sucesso!"

        # Instruções pós-instalação
        log_output ""
        log_info "Próximos passos:"
        log_output "  tool --version    # Verificar instalação"
    else
        log_error "Falha na instalação"
        return 1
    fi
}
```

### 6. update_tool()

Atualiza a ferramenta para a versão mais recente:

```bash
update_tool() {
    log_info "Atualizando ferramenta..."

    if ! command -v tool &>/dev/null; then
        log_error "Ferramenta não está instalada"
        log_info "Execute: susa setup tool"
        return 1
    fi

    local current_version=$(get_tool_version)
    local latest_version=$(get_latest_tool_version)

    if [ "$current_version" = "$latest_version" ]; then
        log_info "Ferramenta já está na versão mais recente ($current_version)"
        return 0
    fi

    log_info "Atualizando de $current_version para $latest_version..."

    # Executar instalação (geralmente sobrescreve)
    install_tool

    # Atualizar lock file
    update_version "tool" "$latest_version"
}
```

### 7. uninstall_tool()

Remove a ferramenta do sistema:

```bash
uninstall_tool() {
    log_info "Desinstalando ferramenta..."

    if ! command -v tool &>/dev/null; then
        log_warning "Ferramenta não está instalada"
        return 0
    fi

    # Confirmar desinstalação
    log_output ""
    log_output "${YELLOW}Deseja realmente desinstalar? (s/N)${NC}"
    read -r response

    if [[ ! "$response" =~ ^[sS]$ ]]; then
        log_info "Desinstalação cancelada"
        return 0
    fi

    # Detectar SO e desinstalar
    local os_type=$(detect_os)
    case "$os_type" in
        linux)
            uninstall_tool_linux
            ;;
        macos)
            uninstall_tool_macos
            ;;
    esac

    # Verificar desinstalação
    if ! command -v tool &>/dev/null; then
        mark_uninstalled "tool"
        log_success "Ferramenta desinstalada com sucesso!"
    else
        log_error "Falha ao desinstalar completamente"
        return 1
    fi
}
```

### 8. main()

Ponto de entrada com parse de argumentos:

```bash
main() {
    local action="install"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                show_help
                exit 0
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
            --uninstall)
                action="uninstall"
                shift
                ;;
            --update)
                action="update"
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Execute action
    log_debug "Ação selecionada: $action"

    case "$action" in
        install)
            install_tool
            ;;
        update)
            update_tool
            ;;
        uninstall)
            uninstall_tool
            ;;
        *)
            log_error "Ação desconhecida: $action"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
```

---

## Funções Auxiliares Comuns

### detect_os_and_arch()

Detecta sistema operacional e arquitetura:

```bash
detect_os_and_arch() {
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)

    case "$os_name" in
        darwin) os_name="macos" ;;
        linux) os_name="linux" ;;
        *)
            log_error "Sistema operacional não suportado: $os_name"
            return 1
            ;;
    esac

    case "$arch" in
        x86_64) arch="x86_64" ;;
        aarch64 | arm64) arch="aarch64" ;;
        armv7l) arch="armhf" ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            return 1
            ;;
    esac

    echo "${os_name}:${arch}"
}
```

### get_local_bin_dir()

Retorna diretório de binários locais:

```bash
get_local_bin_dir() {
    echo "${TOOL_LOCAL_BIN_DIR:-$HOME/.local/bin}"
}
```

---

## Integração com Biblioteca

### Funções da Biblioteca installations.sh

Todos os comandos devem usar estas funções para rastreamento:

```bash
# Marcar como instalado
mark_installed "tool" "1.2.3"

# Marcar como desinstalado
mark_uninstalled "tool"

# Atualizar versão
update_version "tool" "1.3.0"

# Verificar se está instalado
if is_installed "tool"; then
    # ...
fi

# Obter versão instalada
version=$(get_installed_version "tool")
```

### Funções de Log

Use as funções de log padronizadas:

```bash
log_info "Mensagem informativa"
log_success "Operação bem-sucedida"
log_warning "Aviso importante"
log_error "Erro crítico"
log_debug "Mensagem de debug (só aparece com -v)"
```

---

## Fluxo de Execução

### Instalação Normal

```text
1. main() recebe argumentos
2. Parse de --help, --verbose, --quiet
3. Action = "install"
4. install_tool()
5. check_existing_installation()
   - Se já instalado, retorna 1
   - Se não instalado, continua
6. detect_os_and_arch()
7. install_tool_linux() ou install_tool_macos()
8. mark_installed()
9. Mensagem de sucesso + próximos passos
```

### Atualização

```text
1. main() recebe --update
2. Action = "update"
3. update_tool()
4. Verifica versão atual vs. última
5. Se diferente, chama install_tool()
6. update_version()
7. Mensagem de sucesso
```

### Desinstalação

```text
1. main() recebe --uninstall
2. Action = "uninstall"
3. uninstall_tool()
4. Confirmação do usuário
5. uninstall_tool_linux() ou uninstall_tool_macos()
6. mark_uninstalled()
7. Mensagem de sucesso
```

---

## Boas Práticas

### 1. Segurança

```bash
# Sempre no início do arquivo
set -euo pipefail
IFS=$'\n\t'

# Validar entradas do usuário
if [[ ! "$response" =~ ^[sS]$ ]]; then
    # ...
fi

# Usar timeouts em operações de rede
curl --max-time 10 --connect-timeout 5 URL
timeout 5 git ls-remote URL
```

### 2. Suporte à Flag --quiet

**IMPORTANTE**: Use sempre `log_output` em vez de `echo` para mensagens de saída:

```bash
# ❌ ERRADO - echo não respeita a flag --quiet
echo "Mensagem para o usuário"
echo ""
echo -e "${GREEN}Sucesso!${NC}"

# ✅ CORRETO - log_output respeita a flag --quiet
log_output "Mensagem para o usuário"
log_output ""
log_output "${GREEN}Sucesso!${NC}"
```

**Exceções** - Use `echo` apenas para:

```bash
# Retornos de função (valores, não mensagens)
get_version() {
    echo "1.2.3"  # OK - retorna um valor
}

# Redirecionamento para arquivos
echo "export PATH=..." >> ~/.bashrc  # OK - escreve em arquivo

# Pipes que não são saída para o usuário
echo "content" | sudo tee /etc/config  # OK - pipe para comando
```

**Por que isso é importante:**

- `log_output` respeita a variável `SILENT` definida por `--quiet`
- Permite que usuários suprimam saída em scripts automatizados
- Mantém consistência com outras funções de log (`log_info`, `log_error`, etc.)
- Facilita debugging com `--verbose` e `--quiet`

### 3. Mensagens Claras

```bash
# Informar o que está acontecendo
log_info "Baixando ferramenta..."
log_info "Configurando permissões..."
log_success "Instalação concluída!"

# Usar debug para troubleshooting
log_debug "URL da API: $API_URL"
log_debug "Versão detectada: $version"
```

### 4. Tratamento de Erros

```bash
# Verificar comandos antes de usar
if ! command -v curl &>/dev/null; then
    log_error "curl não está instalado"
    return 1
fi

# Validar resultados
if [ -z "$version" ]; then
    log_error "Falha ao obter versão"
    return 1
fi

# Fallback em caso de falha
version=$(get_from_api) || version=$(get_from_git) || return 1
```

### 5. Consistência

- Use sempre as mesmas convenções de nomenclatura
- Mantenha a ordem das funções consistente
- Siga o padrão de mensagens do show_help()
- Use as cores padronizadas ($YELLOW, $GREEN, etc.)
- **Use `log_output` em vez de `echo` para mensagens de saída**

### 6. Documentação

```bash
# Comentar decisões importantes
# Fallback to git ls-remote if API fails
version=$(git ls-remote ...)

# Explicar comportamentos não óbvios
# Docker requires logout/login after adding user to group
log_info "Faça logout/login ou execute: newgrp docker"
```

---

## Exemplos de Implementação

### Exemplo Mínimo

Comando simples que instala via script oficial:

```bash
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source "$LIB_DIR/internal/installations.sh"

show_help() {
    show_description
    log_output ""
    show_usage
    log_output ""
    log_output "${LIGHT_GREEN}O que é:${NC}"
    log_output "  Descrição da ferramenta"
    log_output ""
    log_output "${LIGHT_GREEN}Opções:${NC}"
    log_output "  -h, --help        Mostra ajuda"
    log_output "  --uninstall       Desinstala"
    log_output "  --update          Atualiza"
}

get_tool_version() {
    command -v tool &>/dev/null && \
        tool --version | grep -oE '[0-9.]+' || \
        echo "desconhecida"
}

install_tool() {
    log_info "Instalando ferramenta..."

    curl -fsSL "$TOOL_INSTALL_URL" | bash

    if command -v tool &>/dev/null; then
        mark_installed "tool" "$(get_tool_version)"
        log_success "Instalado com sucesso!"
    else
        log_error "Falha na instalação"
        return 1
    fi
}

update_tool() {
    log_info "Atualizando..."
    install_tool
}

uninstall_tool() {
    log_info "Desinstalando..."
    rm -f "$HOME/.local/bin/tool"
    mark_uninstalled "tool"
    log_success "Desinstalado!"
}

main() {
    case "${1:-install}" in
        -h|--help) show_help ;;
        --update) update_tool ;;
        --uninstall) uninstall_tool ;;
        install) install_tool ;;
    esac
}

main "$@"
```

### Exemplo Completo

Ver arquivos reais:

- `commands/setup/docker/main.sh` - Instalação complexa com Docker
- `commands/setup/poetry/main.sh` - Instalação via script oficial
- `commands/setup/mise/main.sh` - Download de binário por arquitetura
- `commands/setup/uv/main.sh` - Exemplo simples e limpo

---

## Documentação

Todo comando setup deve ter sua documentação completa em `docs/reference/commands/setup/`.

### Estrutura de Documentação

```text
docs/reference/commands/setup/
├── index.md           # Índice de comandos setup (atualizar)
├── .pages             # Configuração de navegação (atualizar)
└── nome-ferramenta.md # Documentação do comando
```

### Criando a Documentação

Ao implementar um novo comando, você deve:

1. **Criar o arquivo de documentação**: `docs/reference/commands/setup/nome-ferramenta.md`
2. **Atualizar o índice**: Adicionar link no `docs/reference/commands/setup/index.md`
3. **Atualizar navegação**: Adicionar entrada no `docs/reference/commands/setup/.pages`

### Estrutura do Arquivo de Documentação

O arquivo de documentação deve seguir este template:

**`docs/reference/commands/setup/nome-ferramenta.md`:**

```markdown
# Nome da Ferramenta

Breve descrição do que a ferramenta faz.

## Instalação

susa setup nome-ferramenta

## Opções

- `-h, --help` - Mostra ajuda
- `--update` - Atualiza para versão mais recente
- `--uninstall` - Desinstala a ferramenta
- `-v, --verbose` - Saída detalhada
- `-q, --quiet` - Saída mínima

## O que é instalado

- Descrição dos componentes instalados
- Localização dos arquivos
- Configurações aplicadas

## Pós-instalação

Passos necessários após a instalação (se aplicável).

## Uso Básico

Comandos úteis para começar a usar a ferramenta.

## Sistemas Operacionais

- Linux (Ubuntu, Debian, Fedora, etc.)
- macOS

## Referências

- [Site Oficial](https://exemplo.com)
- [Documentação](https://docs.exemplo.com)
- [Repositório GitHub](https://github.com/user/repo)
```

### Exemplo de Atualização do index.md

Adicione uma linha no arquivo `docs/reference/commands/setup/index.md`:

```markdown
- [Nome da Ferramenta](nome-ferramenta.md) - Breve descrição
```

### Exemplo de Atualização do .pages

Adicione uma entrada no arquivo `docs/reference/commands/setup/.pages`:

```yaml
nav:
  - index.md
  - ...
  - nome-ferramenta.md
  - ...
```

---

## Checklist de Implementação

Ao criar um novo comando setup, certifique-se de:

- [ ] Criar `command.json` com todas as variáveis necessárias
- [ ] Definir `sudo: true|false` corretamente
- [ ] Listar sistemas operacionais suportados em `os:`
- [ ] Implementar `show_help()` completo
- [ ] Implementar `get_latest_tool_version()` com fallback
- [ ] Implementar `get_tool_version()`
- [ ] Implementar `check_existing_installation()`
- [ ] Implementar `install_tool()`, `update_tool()`, `uninstall_tool()`
- [ ] Implementar funções específicas por SO (`_linux`, `_macos`)
- [ ] Usar `mark_installed()` após instalação bem-sucedida
- [ ] Usar `mark_uninstalled()` após desinstalação
- [ ] Adicionar suporte a `-v/--verbose` e `-q/--quiet`
- [ ] Testar em Linux e macOS (se suportados)
- [ ] Adicionar mensagens de pós-instalação
- [ ] Documentar próximos passos no help
- [ ] Criar arquivo de documentação em `docs/reference/commands/setup/`
- [ ] Atualizar `docs/reference/commands/setup/index.md`
- [ ] Atualizar `docs/reference/commands/setup/.pages`

---

## Referências

- [Biblioteca installations.sh](../../core/lib/internal/installations.sh)
- [Exemplos de comandos](../../commands/setup/)
- [Guia de adição de comandos](adding-commands.md)
- [Documentação de bibliotecas](../../reference/libraries/)

---

**Nota**: Este documento descreve os padrões atuais. Para sugestões de melhorias ou novos padrões, abra uma issue no repositório.
