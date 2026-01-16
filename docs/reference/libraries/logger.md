# logger.sh

Sistema de logs com níveis diferentes, timestamps automáticos e suporte a modo silencioso.

## Visão Geral

A biblioteca `logger.sh` fornece funções padronizadas para logging com:

- 🎨 Cores automáticas por nível de severidade
- ⏰ Timestamps automáticos
- 🔇 Modo silencioso (`SILENT`)
- 🐛 Modo debug (`DEBUG`)
- 📋 Formatação consistente

## Funções de Logging

### `log_output()`

Exibe mensagem formatada personalizada (suporta cores).

```bash
log_output "${GREEN}✓${NC} Operação concluída"
# Output: ✓ Operação concluída (em verde)
```

**Quando usar:** Para outputs customizados onde você controla totalmente a formatação.

### `log_message()`

Log genérico sem cor específica.

```bash
log_message "Mensagem informativa"
# Output: [MESSAGE] 2026-01-13 14:30:45 - Mensagem informativa
```

**Quando usar:** Para mensagens neutras sem semântica específica.

### `log_info()`

Log de informação (ciano/azul).

```bash
log_info "Iniciando processo de instalação..."
# Output: [INFO] 2026-01-13 14:30:45 - Iniciando processo de instalação...
```

**Quando usar:** Para informar progresso, etapas ou estados do processo.

### `log_success()`

Log de sucesso (verde).

```bash
log_success "Instalação concluída com sucesso!"
# Output: [SUCCESS] 2026-01-13 14:30:45 - Instalação concluída com sucesso!
```

**Quando usar:** Para confirmar operações bem-sucedidas ou conclusões.

### `log_warning()`

Log de aviso (amarelo).

```bash
log_warning "Arquivo de configuração não encontrado, usando padrões"
# Output: [WARNING] 2026-01-13 14:30:45 - Arquivo de configuração não encontrado, usando padrões
```

**Quando usar:** Para situações não-ideais mas não-críticas que merecem atenção.

### `log_error()`

Log de erro (vermelho, escreve para `stderr`).

```bash
log_error "Falha ao conectar ao servidor"
# Output (stderr): [ERROR] 2026-01-13 14:30:45 - Falha ao conectar ao servidor
```

**Quando usar:** Para erros que impedem o funcionamento normal. Use antes de `exit 1`.

### `log_debug()`

Log de debug (cinza, só exibe se `DEBUG=true`).

```bash
export DEBUG=true
log_debug "Variável X = $X, PATH = $PATH"
# Output: [DEBUG] 2026-01-13 14:30:45 - Variável X = 42, PATH = /usr/bin:/bin
```

**Quando usar:** Para informações de desenvolvimento, valores de variáveis, troubleshooting.

## Variáveis de Ambiente

### `DEBUG`

Controla a exibição de mensagens de debug.

| Valor | Efeito |
|-------|--------|
| `true`, `1`, `on`, `yes` | Ativa logs de debug |
| `false`, `0`, `off`, `no` | Desativa logs de debug (padrão) |

**Exemplos:**

```bash
# Ativar para uma única execução
DEBUG=true ./meu-script.sh

# Ativar para a sessão
export DEBUG=true
./meu-script.sh

# Ativar via flag --verbose no comando
susa setup asdf --verbose  # Internamente seta DEBUG=true
```

### `SILENT`

Suprime todos os logs (útil para scripts silenciosos ou automação).

| Valor | Efeito |
|-------|--------|
| `true`, `1`, `on`, `yes` | Silencia todos os logs |
| `false`, `0`, `off`, `no` | Logs normais (padrão) |

**Exemplos:**

```bash
# Execução silenciosa
SILENT=true ./meu-script.sh

# Via flag --quiet no comando
susa setup asdf --quiet  # Internamente seta SILENT=true
```

## Funções Auxiliares

### `strtobool()`

Converte string para booleano (usado internamente).

```bash
if strtobool "${DEBUG:-false}"; then
    echo "Debug está ativo"
fi
```

**Valores aceitos:**

- Verdadeiro: `true`, `1`, `on`, `yes`
- Falso: `false`, `0`, `off`, `no`

## Exemplos de Uso

### Básico

```bash
#!/bin/bash
source "$LIB_DIR/logger.sh"

log_info "Verificando dependências..."

if command -v docker &>/dev/null; then
    log_success "Docker encontrado"
else
    log_error "Docker não está instalado"
    exit 1
fi

log_warning "Usando configuração padrão"
```

### Com Debug

```bash
#!/bin/bash
source "$LIB_DIR/logger.sh"

export DEBUG=true

log_info "Iniciando instalação..."
log_debug "Diretório de instalação: $INSTALL_DIR"
log_debug "Sistema operacional: $(uname -s)"

install_package
log_success "Instalação concluída"
```

### Função com Logs Estruturados

```bash
#!/bin/bash
source "$LIB_DIR/logger.sh"

instalar_ferramenta() {
    local nome=$1
    local versao=$2

    log_info "Instalando $nome $versao..."
    log_debug "Verificando dependências..."

    if ! verificar_dependencias; then
        log_error "Dependências não satisfeitas"
        return 1
    fi

    log_debug "Baixando pacote..."
    if ! baixar_pacote "$nome" "$versao"; then
        log_error "Falha ao baixar $nome"
        return 1
    fi

    log_debug "Instalando binário..."
    instalar_binario

    log_success "$nome $versao instalado com sucesso!"
}

# Uso
instalar_ferramenta "podman" "v5.0.0"
```

### Tratamento de Erros

```bash
#!/bin/bash
source "$LIB_DIR/logger.sh"

processar_arquivo() {
    local arquivo=$1

    if [ ! -f "$arquivo" ]; then
        log_error "Arquivo não encontrado: $arquivo"
        return 1
    fi

    log_info "Processando $arquivo..."

    if ! validar_conteudo "$arquivo"; then
        log_error "Conteúdo inválido em $arquivo"
        return 1
    fi

    log_success "Arquivo processado com sucesso"
}

# Com verificação de erro
if ! processar_arquivo "command.json"; then
    log_error "Falha no processamento, abortando"
    exit 1
fi
```

### Modo Silencioso (Automação)

```bash
#!/bin/bash
source "$LIB_DIR/logger.sh"

# Para scripts em CI/CD ou automação
if [ -n "$CI" ]; then
    export SILENT=true
fi

# Estes logs não aparecerão se SILENT=true
log_info "Executando testes..."
log_success "Todos os testes passaram"

# Mas você ainda pode capturar retornos
resultado=$(executar_comando 2>&1)
exit_code=$?

if [ $exit_code -ne 0 ]; then
    # Logs de erro aparecem mesmo em SILENT
    log_error "Comando falhou: $resultado"
    exit 1
fi
```

## Boas Práticas

### 1. Escolha o Nível Apropriado

| Situação | Função | Exemplo |
|----------|---------|---------|
| Progresso normal | `log_info` | "Baixando arquivo..." |
| Operação concluída | `log_success` | "Instalação completa!" |
| Situação não-ideal | `log_warning` | "Config não encontrada, usando padrões" |
| Erro que impede execução | `log_error` | "Falha ao conectar ao servidor" |
| Informações técnicas | `log_debug` | "PID=1234, MEM=128MB" |

### 2. Use log_error Antes de Sair

```bash
# ✓ Bom - informa o erro antes de sair
if [ ! -f "$CONFIG_FILE" ]; then
    log_error "Arquivo de configuração não encontrado: $CONFIG_FILE"
    exit 1
fi

# ✗ Ruim - sai sem informar
[ ! -f "$CONFIG_FILE" ] && exit 1
```

### 3. Combine com Verificações de Erro

```bash
# ✓ Bom - verifica e loga
if ! comando_critico; then
    log_error "Comando crítico falhou"
    return 1
fi

# ✓ Bom - captura output para debug
output=$(comando 2>&1)
if [ $? -ne 0 ]; then
    log_error "Comando falhou"
    log_debug "Output: $output"
    return 1
fi
```

### 4. Use Debug Generosamente

```bash
#!/bin/bash

# Não tenha medo de adicionar muitos log_debug
# Eles só aparecem quando DEBUG=true

log_debug "Iniciando função instalar()"
log_debug "Parâmetros: nome=$1, versao=$2"
log_debug "Diretório atual: $(pwd)"

local download_url="https://example.com/package.tar.gz"
log_debug "URL de download: $download_url"

if baixar_arquivo "$download_url"; then
    log_debug "Download concluído com sucesso"
else
    log_error "Falha no download"
    return 1
fi
```

### 5. Estruture Logs para Troubleshooting

```bash
#!/bin/bash

processar_item() {
    local item=$1
    log_info "Processando: $item"

    log_debug "=== Início do processamento de $item ==="
    log_debug "Timestamp: $(date +%s)"
    log_debug "Working dir: $(pwd)"

    # ... processamento ...

    log_debug "=== Fim do processamento de $item ==="
}
```

### 6. Forneça Contexto nas Mensagens

```bash
# ✗ Ruim - pouco contexto
log_error "Falha na conexão"

# ✓ Bom - contexto claro
log_error "Falha ao conectar ao servidor MySQL em localhost:3306"

# ✓ Melhor ainda - com detalhes
log_error "Falha ao conectar ao servidor MySQL em localhost:3306"
log_debug "Erro: Connection refused (errno: 111)"
log_debug "Tentativas: 3, Timeout: 5s"
```

### 7. Respeite o Modo Silencioso

```bash
# ✓ Bom - usa funções de log (respeitam SILENT)
log_info "Processando..."

# ✗ Ruim - echo direto (ignora SILENT)
echo "Processando..."

# ✓ Bom - output customizado que respeita SILENT
log_output "Resultado: ${GREEN}OK${NC}"
```

## Hierarquia de Logs

```text
DEBUG    → Apenas desenvolvimento/troubleshooting
INFO     → Progresso e estados normais
SUCCESS  → Confirmações importantes
WARNING  → Atenção não-crítica
ERROR    → Falhas que impedem execução
```

**Regra geral:** Em produção sem flags especiais, usuário só vê INFO, SUCCESS, WARNING e ERROR.

## Integração com Comandos

Os comandos do `susa` já suportam controle de logging:

```bash
# Normal - INFO, SUCCESS, WARNING, ERROR
susa setup asdf

# Verbose - Adiciona DEBUG
susa setup asdf --verbose

# Quiet - Silencia tudo exceto erros críticos
susa setup asdf --quiet
```
