# Self Completion

Configura o autocompletar (tab completion) para o shell, permitindo sugestões automáticas de comandos.

## O que é?

O autocompletar permite que você pressione a tecla `Tab` para o Susa CLI sugerir comandos, categorias e subcategorias automaticamente. Isso acelera o uso da ferramenta e evita erros de digitação.

## Como usar

### Instalar no Bash

```bash
susa self completion bash --install
```

### Instalar no Zsh

```bash
susa self completion zsh --install
```

### Instalar no Fish

```bash
susa self completion fish --install
```

### Remover autocompletar

```bash
susa self completion --uninstall
```

### Apenas visualizar o script

```bash
susa self completion bash --print
susa self completion fish --print
```

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda |
| `-i, --install` | Instala o completion no shell |
| `--uninstall` | Remove o completion do shell |
| `-p, --print` | Apenas imprime o script |

## Após a instalação

Reinicie o terminal ou execute:

```bash
# Para Bash
source ~/.bashrc

# Para Zsh
source ~/.zshrc

# Para Fish
# Não é necessário recarregar, o completion é carregado automaticamente
```

## Shells suportados

- ✅ Bash
- ✅ Zsh
- ✅ Fish

## Filtragem Inteligente por OS

O completion filtra automaticamente comandos baseado no sistema operacional:

- **No Linux:** Mostra apenas comandos compatíveis com Linux
- **No Mac:** Mostra apenas comandos compatíveis com macOS

### Exemplo

```bash
# No Linux
susa setup <TAB>
# Mostra: tilix (e outros comandos Linux)
# Oculta: iterm (exclusivo Mac)

# No Mac
susa setup <TAB>
# Mostra: iterm (e outros comandos Mac)
# Oculta: tilix (exclusivo Linux)
```

**Como funciona:**

1. O completion verifica o arquivo `command.json` de cada comando
2. Lê o campo `os: ["linux", "mac"]`
3. Filtra comandos incompatíveis com o OS atual
4. Exibe apenas sugestões relevantes

## Veja também

- [susa self info](info.md) - Ver informações da instalação
- [Guia de Shell Completion](../../../guides/shell-completion.md) - Mais detalhes
