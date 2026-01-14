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
| `-u, --uninstall` | Remove o completion do shell |
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

## Veja também

- [susa self info](info.md) - Ver informações da instalação
- [Guia de Shell Completion](../../../guides/shell-completion.md) - Mais detalhes
