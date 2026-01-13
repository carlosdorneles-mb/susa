# Self Plugin Update

Atualiza um plugin instalado para a versão mais recente disponível no repositório de origem.

Suporta **GitHub**, **GitLab** e **Bitbucket**. O provedor é detectado automaticamente da URL registrada.

## Como usar

```bash
susa self plugin update <nome-do-plugin> [opções]
```

## Exemplos

```bash
# Plugin público
susa self plugin update backup-tools

# Plugin privado (força SSH)
susa self plugin update private-plugin --ssh
```

## Como funciona?

1. Verifica se o plugin existe
2. Busca a URL de origem no registry
3. Valida acesso ao repositório
4. Cria backup da versão atual
5. Clona a nova versão do repositório
6. Substitui os arquivos pelo backup
7. Atualiza o registro no sistema

## Processo de atualização

```text
ℹ Atualizando plugin: backup-tools
  Origem: https://github.com/usuario/susa-backup-tools

Deseja continuar? (s/N): s

ℹ Criando backup...
ℹ Baixando atualização...
ℹ Instalando nova versão...

✓ Plugin 'backup-tools' atualizado com sucesso!
  Versão anterior: 1.2.0
  Nova versão: 1.3.0
  Comandos atualizados: 4
```

## Requisitos

- Plugin deve ter sido instalado via `susa self plugin add`
- Git instalado no sistema
- Conexão com a internet

## Se houver erro na atualização

O backup é **automaticamente restaurado** se algo der errado:

```text
✗ Erro ao atualizar plugin

↺ Restaurando backup da versão anterior...
✓ Plugin restaurado para versão 1.2.0
```

## Plugins que não podem ser atualizados

Plugins instalados **manualmente** (sem Git) não têm origem registrada:

```text
✗ Plugin 'local-plugin' não tem origem registrada ou é local

Apenas plugins instalados via Git podem ser atualizados
```

## Confirmação obrigatória

O comando sempre pede confirmação antes de atualizar. Para cancelar, pressione `N` ou `Enter`.

## Opções

| Opção | O que faz |
|-------|-----------|
| `--ssh` | Força uso de SSH (recomendado para repos privados) |
| `-h, --help` | Mostra ajuda |

## Repositórios Privados

### Validação de Acesso

Antes de atualizar, o comando valida se você ainda tem acesso ao repositório:

```text
[ERROR] Não foi possível acessar o repositório

Possíveis causas:
  • Repositório foi removido ou renomeado
  • Você perdeu acesso ao repositório privado
  • Credenciais Git não estão mais válidas

Soluções:
  • Verifique se o repositório ainda existe
  • Use --ssh se for repositório privado
  • Reconfigure suas credenciais Git
```

### Forçar SSH

Para plugins privados, use `--ssh` para garantir autenticação SSH:

```bash
susa self plugin update organization/private-plugin --ssh
```

### Detecção Automática

O comando detecta automaticamente se você tem SSH configurado e usa quando disponível. A URL do registry é normalizada com base nas suas configurações.

## Veja também

- [susa self plugin list](list.md) - Ver versões dos plugins instalados
- [susa self plugin add](add.md) - Instalar novo plugin (inclui guia SSH)
- [susa self plugin remove](remove.md) - Remover plugin
