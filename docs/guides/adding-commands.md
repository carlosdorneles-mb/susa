# Como Adicionar Novos Comandos

Este guia mostra como adicionar novos comandos ao CLI de forma dinâmica.

## 📋 Estrutura de um Comando

Cada comando deve seguir esta estrutura:

```text
commands/
  <categoria>/
    <comando>/
      main.sh        # Script principal do comando
      config.yml     # (opcional) Configurações específicas
      README.md      # (opcional) Documentação do comando
```

## ➕ Passos para Adicionar um Comando

### 1. Criar o Diretório

```bash
mkdir -p commands/<categoria>/<nome-comando>
```

**Exemplo:**

```bash
mkdir -p commands/install/vscode
```

### 2. Criar o Script Principal

Crie o arquivo `main.sh` dentro do diretório:

```bash
#!/bin/bash

# ============================================================
# Nome do Comando
# ============================================================

CLI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

meu_comando() {
    log_info "Executando meu comando..."
    
    # Seu código aqui
    
    log_success "Comando executado com sucesso!"
}

# Executa o comando
meu_comando "$@"
```

### 3. Tornar o Script Executável

```bash
chmod +x commands/<categoria>/<nome-comando>/main.sh
```

### 4. Registrar no cli.yml

Adicione o comando no arquivo `commands/cli.yml`:

```yaml
categories:
  <categoria>:
    name: "Nome da Categoria"
    description: "Descrição da categoria"
    commands:
      - id: <nome-comando>
        order: 40
        name: "Nome Amigável"
        description: "Descrição do comando"
        script: "main.sh"
```

**Exemplo completo:**

```yaml
categories:
  install:
    name: "Install"
    description: "Instalar software (Ubuntu)"
    commands:
      - id: vscode
        order: 40
        name: "VS Code"
        description: "Instala Visual Studio Code"
        script: "main.sh"
```

### 5. Testar o Comando

```bash
# Listar comandos da categoria
./susa setup

# Executar o comando
./susa setup vscode
```

## 📚 Funções Disponíveis

Seus scripts têm acesso a todas as funções das bibliotecas em `lib/`:

### Logger

```bash
log_info "Mensagem informativa"
log_success "Operação bem-sucedida"
log_warning "Aviso importante"
log_error "Erro encontrado"
```

### Colors

```bash
echo -e "${GREEN}Texto verde${NC}"
echo -e "${CYAN}Texto ciano${NC}"
echo -e "${RED}Texto vermelho${NC}"
```

### OS Detection

```bash
detect_os  # Detecta o sistema operacional
```

### Utils

```bash
ensure_curl_installed  # Garante que curl está instalado
```

## 🎯 Boas Práticas

1. **Use log functions**: Sempre use `log_info`, `log_success`, etc.
2. **Valide entradas**: Verifique os parâmetros recebidos
3. **Tratamento de erros**: Use `set -e` ou verifique códigos de retorno
4. **Documentação**: Adicione comentários explicativos
5. **Parâmetros**: Aceite parâmetros via `"$@"`

## 🔄 Ordem de Execução

O campo `order` no `cli.yml` define a ordem de exibição dos comandos:

- Números menores aparecem primeiro
- Use incrementos de 10 (10, 20, 30...) para facilitar inserções futuras
