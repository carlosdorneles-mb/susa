# Como Adicionar Novos Comandos

Este guia mostra como adicionar novos comandos ao Susa CLI de forma dinâmica.

> **💡 Dica:** Para criar estruturas hierárquicas com subcategorias e múltiplos níveis, veja [Sistema de Categorias e Subcategorias Aninhadas](subcategories.md).

## 📋 Estrutura de um Comando

Cada comando deve seguir esta estrutura hierárquica:

```text
commands/
  <categoria>/
    config.yaml           # Configuração da categoria
    <comando>/
      config.yaml         # Configuração do comando
      main.sh             # Script principal executável
```

**Exemplo real:**

```text
commands/
  setup/
    config.yaml
    asdf/
      config.yaml
      main.sh
    docker/
      config.yaml
      main.sh
```

> **💡 Nota:** Categorias podem conter comandos diretos OU subcategorias. Para criar hierarquias com subcategorias aninhadas, veja [Sistema de Subcategorias](subcategories.md).

## ➕ Passos para Adicionar um Comando

### 1. Criar a Estrutura de Diretórios

```bash
# Criar categoria (se não existir)
mkdir -p commands/<categoria>/<comando>
```

**Exemplo:**

```bash
mkdir -p commands/setup/vscode
```

### 2. Configurar a Categoria

Crie ou edite `commands/<categoria>/config.yaml`:

```yaml
name: "Setup"
description: "Instalar e configurar ferramentas"
```

### 3. Configurar o Comando

Crie `commands/<categoria>/<comando>/config.yaml`:

```yaml
name: "Nome Amigável"
description: "Descrição clara e objetiva do comando"
script: "main.sh"
sudo: false
os: ["linux", "mac"]
```

**Exemplo completo:**

```yaml
name: "VS Code"
description: "Instala Visual Studio Code"
script: "main.sh"
sudo: false
os: ["linux", "mac"]
```

**Campos disponíveis:**

- `name`: Nome amigável exibido ao usuário
- `description`: Descrição breve do comando
- `script`: Nome do arquivo executável (geralmente `main.sh`)
- `sudo`: Se requer privilégios de administrador (`true`/`false`). Quando `true`, o comando exibe o indicador `[sudo]` na listagem
- `os`: Sistemas suportados (`["linux"]`, `["mac"]`, `["linux", "mac"]`)

### 4. Criar o Script Principal

Crie `commands/<categoria>/<comando>/main.sh`:

```bash
#!/bin/bash
set -euo pipefail

setup_command_env

# Help function
show_help() {
    show_description
    echo ""
    show_usage
    echo ""
    echo -e "${LIGHT_GREEN}O que é:${NC}"
    echo "  Descrição detalhada da ferramenta ou funcionalidade"
    echo ""
    echo -e "${LIGHT_GREEN}Opções:${NC}"
    echo "  -h, --help        Mostra esta mensagem de ajuda"
    echo "  -u, --uninstall   Remove a instalação"
    echo ""
    echo -e "${LIGHT_GREEN}Exemplos:${NC}"
    echo "  susa <categoria> <comando>              # Instala"
    echo "  susa <categoria> <comando> --uninstall  # Remove"
    echo ""
}

# Main installation function
install() {
    log_info "Instalando..."

    # Seu código de instalação aqui

    log_success "Instalado com sucesso!"
}

# Uninstall function
uninstall() {
    log_info "Removendo..."

    # Seu código de remoção aqui

    log_success "Removido com sucesso!"
}

# Parse arguments
UNINSTALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        --uninstall|-u)
            UNINSTALL=true
            shift
            ;;
        *)
            log_error "Opção desconhecida: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Execute main logic
if [ "$UNINSTALL" = true ]; then
    uninstall
else
    install
fi
```

### 5. Tornar o Script Executável

```bash
chmod +x commands/<categoria>/<comando>/main.sh
```

### 6. Testar o Comando

```bash
# Listar comandos da categoria
susa <categoria>

# Executar o comando
susa <categoria> <comando>

# Exibir ajuda
susa <categoria> <comando> --help
```

**Exemplo:**

```bash
susa setup              # Lista todos os comandos de setup
susa setup vscode       # Instala o VS Code
susa setup vscode -h    # Mostra ajuda do comando
```

## 📚 Bibliotecas Disponíveis

Para detalhes completos de todas as bibliotecas, veja [Referência de Bibliotecas](../reference/libraries/index.md).

## 🎯 Boas Práticas

1. **Sempre use `setup_command_env`**: Primeira linha após `set -euo pipefail`
2. **Funções de log**: Use `log_*` em vez de `echo` para mensagens
3. **Função de ajuda**: Sempre implemente `show_help()` com `show_description` e `show_usage`
4. **Tratamento de erros**: Use `set -euo pipefail` no início
5. **Parse de argumentos**: Use `while` + `case` para processar opções
6. **Validação**: Verifique se dependências estão instaladas antes de usar
7. **Cores com reset**: Sempre termine mensagens coloridas com `${NC}`

## 🔍 Descoberta Automática

O Susa CLI descobre comandos **automaticamente**:

- Não há registro central de comandos
- O CLI varre o diretório `commands/` em tempo de execução
- Cada `config.yaml` é lido dinamicamente
- Plugins funcionam da mesma forma em `plugins/`

> **💡 Para entender como o sistema diferencia comandos e subcategorias**, veja [Diferença entre Comandos e Subcategorias](subcategories.md#diferenca-entre-comandos-e-subcategorias).

## 🧪 Testando Localmente

```bash
# Testar descoberta de comandos
susa

# Testar categoria específica
susa setup

# Executar comando
susa setup vscode

# Testar com debug
DEBUG=true susa setup vscode

# Ver ajuda
susa setup vscode --help
```

## 📖 Exemplo Completo

Veja o comando [setup asdf](../reference/commands/setup/asdf.md) como referência completa de implementação.

## 🔗 Guias Relacionados

- **[Sistema de Categorias e Subcategorias Aninhadas](subcategories.md)** - Para criar estruturas hierárquicas com múltiplos níveis
- **[Referência de Bibliotecas](../reference/libraries/index.md)** - Bibliotecas disponíveis para usar em seus scripts
