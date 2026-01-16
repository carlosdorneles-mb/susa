# 📚 Referência de Bibliotecas

Esta seção documenta todas as bibliotecas disponíveis em `lib/` e suas funções públicas.

## Visão Geral

O Susa CLI fornece um conjunto robusto de bibliotecas reutilizáveis que facilitam o desenvolvimento de comandos. As bibliotecas estão organizadas em duas categorias:

- **Bibliotecas Públicas** (`core/lib/*.sh`): Disponíveis para uso em comandos de usuário
- **Bibliotecas Internas** (`core/lib/internal/*.sh`): Usadas apenas pelo core do sistema

## Bibliotecas Públicas

Estas bibliotecas podem ser importadas e usadas livremente em comandos personalizados e plugins.

### Interface e Output

#### [color.sh](color.md)

Constantes de cores e estilos para formatação de texto no terminal. Define variáveis como `RED`, `GREEN`, `BOLD`, `NC` para estilização de mensagens.

#### [logger.sh](logger.md)

Sistema de logs estruturado com níveis diferentes (info, success, warning, error, debug) e timestamps automáticos. Essencial para feedback consistente ao usuário.

### Sistema e Ambiente

#### [os.sh](os.md)

Detecção de sistema operacional e distribuições Linux. Fornece a variável `OS_TYPE` e a função `get_simple_os()` para comandos multiplataforma.

#### [shell.sh](shell.md)

Detecção e configuração de shells (bash, zsh, fish). Identifica o shell do usuário e seus arquivos de configuração para instalação automática.

#### [sudo.sh](sudo.md)

Gerenciamento de privilégios de superusuário. Verifica e solicita permissões sudo quando necessário para comandos que requerem elevação.

### Utilitários

#### [string.sh](string.md)

Manipulação de strings e arrays. Inclui funções para conversão de case, limpeza de espaços e parsing de listas separadas por vírgula.

#### [dependencies.sh](dependencies.md)

Gerenciamento automático de dependências externas. Auto-instala ferramentas como `curl`, `jq` e `fzf` quando necessário.

#### [kubernetes.sh](kubernetes.md)

Funções auxiliares para trabalhar com Kubernetes. Valida instalação do `kubectl`, verifica namespaces e contextos.

#### [github.sh](github.md)

Gerenciamento de releases do GitHub. Baixa releases com verificação de checksum, detecta sistema/arquitetura e automatiza instalação de binários de projetos hospedados no GitHub.

### CLI Core

#### [cli.sh](cli.md)

Funções específicas do framework CLI. Fornece `show_usage()`, `show_description()` e `build_command_path()` para padronização de comandos.

## Bibliotecas Internas

Estas bibliotecas são usadas internamente pelo core do Susa CLI. Não devem ser importadas diretamente em comandos de usuário.

#### [json.sh](json.md)

Parser JSON interno usando jq. Funções auxiliares para leitura e manipulação de arquivos JSON. Usado internamente por config.sh, lock.sh e registry.sh.

#### [cache.sh](cache.md)

Sistema de cache em memória para acelerar o carregamento do CLI. Mantém uma cópia pré-processada do `susa.lock` em memória e disco, eliminando a necessidade de múltiplas chamadas ao jq durante a execução.

#### [args.sh](args.md)

Parsing consistente de argumentos de linha de comando. Valida argumentos obrigatórios, processa flags e elimina código duplicado.

#### [completion.sh](completion.md)

Gerenciamento de autocompletar (tab completion) para Bash e Zsh. Verifica instalação, status e carregamento de scripts de completion.

#### [config.sh](config.md)

Parser JSON completo para configurações. Descobre categorias, comandos e lê metadados dos arquivos de configuração (command.json e category.json). Inclui funções de versão do CLI.

#### [git.sh](git.md)

Operações Git para gerenciamento de plugins. Valida acesso a repositórios, clona e atualiza plugins, detecta provedores Git (GitHub, GitLab, Bitbucket).

#### [plugin.sh](plugin.md)

Gerenciamento de metadados de plugins externos. Detecta versões, conta comandos e normaliza URLs de plugins Git.

#### [registry.sh](registry.md)

Gerenciamento do arquivo `registry.json` de plugins. Adiciona, remove e lista plugins instalados com versionamento.

#### [installations.sh](installations.md)

Rastreamento de instalações de software no arquivo `susa.lock`. Registra versões, timestamps e sincroniza estado entre sistema e lock file.

## Dependências Entre Bibliotecas

```text
BIBLIOTECAS PÚBLICAS:

cli.sh
├── color.sh
└── internal/config.sh

logger.sh
└── color.sh

dependencies.sh
└── logger.sh
    └── color.sh

shell.sh
(sem dependências)

string.sh
(sem dependências)

os.sh
(sem dependências)

sudo.sh
└── color.sh

kubernetes.sh
└── color.sh

BIBLIOTECAS INTERNAS:

internal/config.sh
├── internal/registry.sh
├── internal/json.sh
└── internal/cache.sh

internal/cache.sh
└── logger.sh (opcional)
    └── color.sh

internal/args.sh
└── logger.sh
    └── color.sh

internal/completion.sh
└── shell.sh

internal/plugin.sh
├── internal/git.sh
└── internal/registry.sh

internal/git.sh
└── logger.sh

internal/registry.sh
└── internal/json.sh

internal/lock.sh
├── internal/json.sh
└── internal/cache.sh

internal/installations.sh
├── internal/json.sh
├── logger.sh
└── os.sh

internal/json.sh
(sem dependências - requer jq)
```

**Nota:** Sempre faça `source` das dependências antes de usar uma biblioteca.

## Padrão de Uso

### Estrutura Típica de um Comando

```bash
#!/bin/bash
set -euo pipefail

# Setup environment

# Importa bibliotecas necessárias
source "$LIB_DIR/logger.sh"
source "$LIB_DIR/color.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/internal/args.sh"
source "$LIB_DIR/internal/installations.sh"  # Para rastreamento

# Help function
show_help() {
    echo "Uso: susa comando [opções]"
    echo "Descrição do comando"
}

# Parse argumentos
parse_simple_help_only "$@"

# Lógica do comando
log_info "Iniciando..."

simple_os=$(get_simple_os)

case "$simple_os" in
    mac)
        log_info "Instalando para macOS..."
        ;;
    linux)
        log_info "Instalando para Linux..."
        ;;
esac

# Registrar instalação
if command -v software &>/dev/null; then
    version=$(software --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    _mark_installed_software_in_lock "software" "$version"
    log_success "Concluído!"
fi
```

## Boas Práticas

1. **Sempre use `set -euo pipefail`** no início dos scripts para tratamento robusto de erros
2. **Importe apenas o necessário** para reduzir overhead e melhorar performance
3. **Use `log_*` ao invés de `echo`** para mensagens consistentes com níveis e timestamps
4. **Detecte SO antes de comandos específicos** usando `get_simple_os()` para compatibilidade
5. **Valide dependências cedo** com `ensure_*_installed` antes de usar ferramentas externas
6. **Use cores para destacar** informações importantes e melhorar UX
7. **Teste compatibilidade de SO** com `is_command_compatible()` antes de executar
8. **Use jq para JSON** ao invés de awk/grep para parsing confiável
9. **Sempre termine cores com `${NC}`** para evitar poluição de estilo no terminal

## Recursos Adicionais

- [Guia de Adicionar Comandos](../../guides/adding-commands.md) - Como criar comandos usando as bibliotecas
- [Sistema de Plugins](../../plugins/overview.md) - Como plugins reutilizam bibliotecas
- [Guia de Subcategorias](../../guides/subcategories.md) - Navegação hierárquica de comandos
- [Funcionalidades](../../guides/features.md) - Visão geral completa do sistema
