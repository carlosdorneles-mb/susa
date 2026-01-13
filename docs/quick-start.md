# Início Rápido

## 🚀 Instalação

A forma mais rápida de instalar o Susa CLI é usando o instalador remoto.

### Linux and macOS

Use este comando com `curl` para baixar o script e executá-lo:

```bash
curl -LsSf https://raw.githubusercontent.com/carlosdorneles-mb/susa/main/install-remote.sh | bash
```

Se o seu sistema não tiver curl, você pode usar `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/carlosdorneles-mb/susa/main/install-remote.sh | bash
```

Solicite uma versão específica incluindo-a no URL:

```bash
curl -LsSf https://raw.githubusercontent.com/carlosdorneles-mb/susa/1.0.0/install-remote.sh | bash
```

Este comando irá:

- ✅ Detectar seu sistema operacional automaticamente
- ✅ Instalar dependências necessárias (git)
- ✅ Clonar o repositório
- ✅ Executar a instalação
- ✅ Configurar o PATH automaticamente

### Verificar Instalação

Após a instalação, verifique se funcionou:

```bash
susa --version
susa --help
```

### Desinstalação

Para remover o Susa CLI utilizando o `curl`:

```bash
curl -LsSf https://raw.githubusercontent.com/carlosdorneles-mb/susa/main/uninstall-remote.sh | bash
```

Se o seu sistema não tiver curl, você pode usar `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/carlosdorneles-mb/susa/main/uninstall-remote.sh | bash
```

---

## Autocompletar do Shell

Consulte o [Guia de Shell Completion](./guides/shell-completion.md) para detalhes de como instalar.

---

## 📖 Primeiros Passos

### Explorar comandos disponíveis

```bash
# Ver todas as categorias
susa

# Ver comandos de uma categoria
susa setup

# Ver subcategorias e seus comandos
susa self plugin
```

### Executar seu primeiro comando

```bash
# Ver informações do Susa CLI
susa self info

# Ver versão
susa self version

# Instalar ASDF (exemplo)
susa setup asdf
```

### Configurar autocompletar

```bash
# Bash
susa self completion bash --install

# Zsh
susa self completion zsh --install

# Recarregar shell
source ~/.bashrc  # ou ~/.zshrc
```

---

## 🔌 Trabalhando com Plugins

### Instalar um plugin

```bash
# Formato: user/repo
susa self plugin add usuario/meu-plugin

# Ou URL completa
susa self plugin add https://github.com/usuario/meu-plugin
```

### Gerenciar plugins

```bash
# Listar plugins instalados
susa self plugin list

# Atualizar plugin
susa self plugin update nome-plugin

# Remover plugin
susa self plugin remove nome-plugin
```

---

## 🛠️ Criar seu Primeiro Comando

### Estrutura básica

```bash
# Criar diretórios
mkdir -p commands/demo/hello

# Configuração da categoria
cat > commands/demo/config.yaml << EOF
name: "Demo"
description: "Comandos de demonstração"
EOF

# Configuração do comando
cat > commands/demo/hello/config.yaml << EOF
name: "Hello World"
description: "Comando de exemplo"
script: "main.sh"
sudo: false
os: ["linux", "mac"]
EOF

# Script do comando
cat > commands/demo/hello/main.sh << 'EOF'
#!/bin/bash
set -euo pipefail

setup_command_env

show_help() {
    show_description
    echo ""
    show_usage
    echo ""
    echo -e "${LIGHT_GREEN}Exemplo:${NC}"
    echo "  susa demo hello"
}

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Opção desconhecida: $1"
            exit 1
            ;;
    esac
done

log_success "Hello from Susa CLI!"
EOF

# Tornar executável
chmod +x commands/demo/hello/main.sh
```

### Testar o comando

```bash
# Listar categoria
susa demo

# Executar comando
susa demo hello

# Ver ajuda
susa demo hello --help
```

---

## 🎯 Próximos Passos

Agora que você tem o básico, explore mais:

- **[Funcionalidades](guides/features.md)** - Conheça todas as funcionalidades
- **[Adicionar Comandos](guides/adding-commands.md)** - Guia completo para criar comandos
- **[Sistema de Plugins](plugins/overview.md)** - Entenda como funcionam os plugins
- **[Subcategorias](guides/subcategories.md)** - Organize comandos em hierarquia
- **[Configuração](guides/configuration.md)** - Personalize o Susa CLI
- **[Shell Completion](guides/shell-completion.md)** - Configure o autocompletar

---

## 💡 Dicas Importantes

1. **Descoberta automática**: Comandos são descobertos da estrutura de diretórios
2. **Campo `script`**: Determina se é comando (executável) ou categoria (navegável)
3. **Sempre use `setup_command_env`**: Primeira linha após `set -euo pipefail`
4. **Funções de log**: Use `log_*` em vez de `echo`
5. **Teste com DEBUG**: `DEBUG=true susa comando` para ver logs detalhados

---

## ❓ Ajuda

Se tiver problemas:

- Veja a documentação completa nos guias
- Use `susa self info` para ver informações da instalação
- Execute com `DEBUG=true` para ver logs detalhados
- Verifique os exemplos em `commands/setup/asdf/`
