# Context API

Sistema de contexto em memória para compartilhar dados durante a execução de comandos.

## O que faz?

A biblioteca de contexto provê um armazenamento chave-valor em memória otimizado para compartilhar informações durante a execução de um comando. Os dados são automaticamente limpos após o comando terminar.

Internamente usa o sistema de cache nomeado (`context` cache) para máxima performance - todas as operações são feitas em memória e persistidas apenas quando necessário.

## Como usar

```bash
# Carregar biblioteca
source "$LIB_DIR/internal/cache.sh"
source "$LIB_DIR/internal/context.sh"

# Inicializar contexto (início do comando)
context_init

# Armazenar dados
context_set "software" "docker"
context_set "version" "24.0.5"
context_set "install_path" "/usr/bin/docker"

# Ler dados
local software=$(context_get "software")
local version=$(context_get "version")

# Verificar existência
if context_has "version"; then
    echo "Versão definida: $(context_get "version")"
fi

# Listar todas as chaves
context_keys

# Contar itens
local total=$(context_count)
echo "Total de itens no contexto: $total"

# Limpar contexto (final do comando)
context_clear
```

## Funções Disponíveis

### Inicialização e Limpeza

| Função | Descrição |
|--------|-----------|
| `context_init()` | Inicializa o contexto (limpa se existir) |
| `context_clear()` | Limpa todo o contexto |

### Manipulação de Dados

| Função | Descrição |
|--------|-----------|
| `context_set "chave" "valor"` | Define um valor |
| `context_get "chave"` | Obtém um valor (retorna vazio se não existir) |
| `context_has "chave"` | Verifica se chave existe (retorna 0/1) |
| `context_remove "chave"` | Remove uma chave |

### Consultas

| Função | Descrição |
|--------|-----------|
| `context_get_all()` | Retorna todo o contexto como JSON |
| `context_keys()` | Lista todas as chaves (uma por linha) |
| `context_count()` | Conta quantas chaves existem |

### Utilitários

| Função | Descrição |
|--------|-----------|
| `context_save()` | Salva contexto em disco (útil para debug) |

## Exemplos Práticos

### Exemplo 1: Compartilhar dados entre funções

```bash
#!/bin/bash
source "$LIB_DIR/internal/cache.sh"
source "$LIB_DIR/internal/context.sh"

check_dependencies() {
    local missing=()

    for dep in docker docker-compose; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        context_set "missing_deps" "${missing[*]}"
        return 1
    fi

    return 0
}

show_missing_deps() {
    if context_has "missing_deps"; then
        local deps=$(context_get "missing_deps")
        log_error "Dependências faltando: $deps"
    fi
}

main() {
    context_init

    if ! check_dependencies; then
        show_missing_deps
        context_clear
        exit 1
    fi

    # Resto da lógica...

    context_clear
}

main "$@"
```

### Exemplo 2: Armazenar progresso de instalação

```bash
#!/bin/bash
source "$LIB_DIR/internal/cache.sh"
source "$LIB_DIR/internal/context.sh"

download_software() {
    context_set "step" "download"
    context_set "download_url" "https://..."
    # Lógica de download...
    context_set "download_path" "/tmp/software.tar.gz"
}

extract_software() {
    context_set "step" "extract"
    local download_path=$(context_get "download_path")
    # Lógica de extração...
    context_set "install_dir" "/opt/software"
}

configure_software() {
    context_set "step" "configure"
    local install_dir=$(context_get "install_dir")
    # Lógica de configuração...
}

handle_error() {
    local current_step=$(context_get "step")
    log_error "Erro durante: $current_step"

    # Debug: salvar contexto em disco
    context_save
    log_debug "Contexto salvo para análise"
}

main() {
    context_init

    trap handle_error ERR

    download_software
    extract_software
    configure_software

    log_success "Instalação concluída!"
    context_clear
}

main "$@"
```

### Exemplo 3: Validação de pré-requisitos

```bash
#!/bin/bash
source "$LIB_DIR/internal/cache.sh"
source "$LIB_DIR/internal/context.sh"

validate_system() {
    # Verificar OS
    if [ "$OS_TYPE" = "linux" ]; then
        context_set "os_compatible" "true"
    else
        context_set "os_compatible" "false"
        context_set "error" "Sistema operacional não suportado"
        return 1
    fi

    # Verificar arquitetura
    if [ "$OS_ARCH" = "x86_64" ]; then
        context_set "arch_compatible" "true"
    else
        context_set "arch_compatible" "false"
        context_set "error" "Arquitetura não suportada"
        return 1
    fi

    # Verificar espaço em disco
    local available=$(df / | awk 'NR==2 {print $4}')
    context_set "disk_space" "$available"

    if [ "$available" -lt 1048576 ]; then  # 1GB em KB
        context_set "error" "Espaço em disco insuficiente"
        return 1
    fi

    return 0
}

show_validation_report() {
    echo "Relatório de Validação:"
    echo "  OS compatível: $(context_get "os_compatible")"
    echo "  Arquitetura compatível: $(context_get "arch_compatible")"
    echo "  Espaço disponível: $(context_get "disk_space") KB"

    if context_has "error"; then
        echo "  Erro: $(context_get "error")"
    fi
}

main() {
    context_init

    if validate_system; then
        log_success "Sistema validado com sucesso"
    else
        show_validation_report
        context_clear
        exit 1
    fi

    # Continuar com instalação...

    context_clear
}

main "$@"
```

## Performance

O sistema de contexto é otimizado para performance:

- ✅ **Operações em memória:** Usa arrays associativos do Bash
- ✅ **Zero I/O:** Apenas lê/escreve disco quando explicitamente solicitado
- ✅ **Isolado por comando:** Cada execução tem seu próprio contexto
- ✅ **Limpeza automática:** Não deixa arquivos residuais

## Comparação com Alternativas

| Abordagem | Pros | Contras |
|-----------|------|---------|
| **Variáveis globais** | Simples | Poluição do namespace |
| **Arquivos temporários** | Persistente | Lento, requer limpeza manual |
| **Context API** ✓ | Rápido, limpo, estruturado | Requer inicialização |

## Boas Práticas

### ✅ Fazer

```bash
# Sempre inicializar no início
context_init

# Verificar existência antes de usar
if context_has "key"; then
    value=$(context_get "key")
fi

# Sempre limpar no final
context_clear
```

### ❌ Evitar

```bash
# Não usar sem inicializar
context_set "key" "value"  # Funciona, mas não é idiomático

# Não esquecer de limpar
# ... código ...
# (faltou context_clear)

# Não armazenar dados sensíveis por muito tempo
context_set "password" "secret123"  # Limpe logo após usar
```

## Debug

Se precisar inspecionar o contexto durante desenvolvimento:

```bash
# Mostrar todo o contexto
context_get_all | jq .

# Listar todas as chaves
context_keys

# Salvar para análise posterior
context_save
cat "${XDG_RUNTIME_DIR:-/tmp}/susa-$USER/context.cache"
```

## Veja também

- [Cache API](cache.md) - Sistema de cache subjacente
- [Internal Libraries](index.md) - Outras bibliotecas internas
