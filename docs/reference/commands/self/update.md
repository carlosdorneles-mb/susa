# Self Update

Atualiza o Susa CLI para a versão mais recente disponível no repositório.

## Como funciona?

O comando:

1. Verifica se há uma versão mais recente disponível
2. Baixa a nova versão do repositório Git
3. **Preserva** seus plugins instalados e configurações
4. Atualiza os arquivos do sistema
5. Remove arquivos temporários automaticamente

## Como usar

```bash
susa self update
```

### Com logs de debug

```bash
DEBUG=true susa self update
```

## O que é preservado?

Durante a atualização, **não são perdidos**:

- ✅ Plugins instalados
- ✅ Registry de plugins (`plugins/registry.yaml`)
- ✅ Configurações personalizadas

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda |

## Variáveis de ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `CLI_REPO_URL` | URL do repositório | `github.com/duducp/susa` |
| `CLI_REPO_BRANCH` | Branch a usar | `main` |
| `DEBUG` | Ativa logs de debug | `false` |

## Exemplo com variáveis

```bash
# Usar branch de desenvolvimento
CLI_REPO_BRANCH=dev susa self update

# Repositório customizado
CLI_REPO_URL=https://github.com/usuario/fork.git susa self update
```

## Veja também

- [susa self version](version.md) - Verificar versão atual
- [susa self info](info.md) - Ver detalhes da instalação
