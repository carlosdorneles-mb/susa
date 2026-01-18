# Início Rápido

## 🚀 Instalação

A forma mais rápida de instalar o Susa CLI é usando o instalador remoto.

### Linux and macOS

Use este comando com `curl` para baixar o script e executá-lo:

```bash
curl -LsSf https://raw.githubusercontent.com/duducp/susa/main/install-remote.sh | bash
```

Se o seu sistema não tiver curl, você pode usar `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/duducp/susa/main/install-remote.sh | bash
```

Solicite uma versão específica incluindo-a no URL:

```bash
curl -LsSf https://raw.githubusercontent.com/duducp/susa/1.0.0/install-remote.sh | bash
```

Este comando irá:

- ✅ Detectar seu sistema operacional automaticamente
- ✅ Verificar e instalar dependências necessárias (git, jq)
- ✅ Clonar o repositório
- ✅ Executar a instalação
- ✅ Configurar o PATH automaticamente
- ✅ Detectar e configurar todos os shells disponíveis (Bash e Zsh)

### 📦 Dependências

O SUSA CLI requer algumas dependências para funcionar:

| Dependência | Versão Mínima | Motivo | Instalação |
|-------------|---------------|--------|------------|
| **Bash** | 4.0+ | Arrays associativos para cache | `brew install bash` (macOS) |
| **jq** | 1.5+ | Processamento de JSON | `brew install jq` ou `apt install jq` |

**Verificação Automática:**

Na primeira execução, o SUSA CLI verifica automaticamente se todas as dependências estão instaladas:

```bash
$ susa --version

Dependências faltando

✗ jq
  Motivo: jq é necessário para processar arquivos JSON (cache, configurações, plugins)
  Comando: sudo apt install -y jq

Deseja instalar as dependências agora? (s/n)
```

Se você responder **'s'** (sim), as dependências serão instaladas automaticamente. Se responder **'n'** (não), será exibido o comando de instalação manual.

**Pular verificação (CI/CD):**

Para ambientes automatizados onde as dependências já estão garantidas:

```bash
export SUSA_SKIP_DEPS_CHECK=1
susa --version
```

### ⚠️ Importante: Shells Suportados

O Susa CLI suporta **Bash** e **Zsh**. Durante a instalação, o script detectará e configurará automaticamente todos os shells disponíveis no seu sistema.

#### Se você usa apenas Bash

Nenhuma ação adicional necessária! ✅

#### Se você planeja usar Zsh no futuro

Se você instalar o Zsh após a instalação do Susa CLI, será necessário configurá-lo manualmente:

```bash
# 1. Instalar Zsh primeiro
# Ubuntu/Debian:
sudo apt install zsh

# Fedora/RHEL:
sudo dnf install zsh

# Arch Linux:
sudo pacman -S zsh

# macOS (já vem instalado por padrão)

# 2. Adicionar o PATH do .local no ~/.zshrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc

# 3. Configurar o autocompletar do Susa CLI para Zsh
susa self completion zsh --install

# 4. Recarregar o shell
source ~/.zshrc
```

#### Mudar o shell padrão para Zsh

Se quiser usar Zsh como shell padrão:

```bash
# Verificar se Zsh está instalado
which zsh

# Mudar para Zsh como shell padrão
chsh -s $(which zsh)

# Fazer logout e login novamente para aplicar
```

### Verificar Instalação

Após a instalação, verifique se funcionou:

```bash
susa --version
susa --help
```

### Desinstalação

Para remover o Susa CLI utilizando o `curl`:

```bash
curl -LsSf https://raw.githubusercontent.com/duducp/susa/main/uninstall-remote.sh | bash
```

Se o seu sistema não tiver curl, você pode usar `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/duducp/susa/main/uninstall-remote.sh | bash
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
cat > commands/demo/category.json << EOF
{
  "name": "Demo",
  "description": "Comandos de demonstração"
}
EOF

# Configuração do comando
cat > commands/demo/hello/command.json << EOF
{
  "name": "Hello World",
  "description": "Comando de exemplo",
  "entrypoint": "main.sh",
  "sudo": false,
  "os": ["linux", "mac"]
}
EOF

# Script do comando
cat > commands/demo/hello/main.sh << 'EOF'
#!/bin/bash
set -euo pipefail


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
3. **Use as funções auxiliares do CLI**:
4. **Funções de log**: Use `log_*` em vez de `echo`
5. **Teste com DEBUG**: `DEBUG=true susa comando` para ver logs detalhados

---

## ❓ Ajuda

Se tiver problemas:

- Veja a documentação completa nos guias
- Use `susa self info` para ver informações da instalação
- Execute com `DEBUG=true` para ver logs detalhados
- Verifique os exemplos em `commands/setup/asdf/`
