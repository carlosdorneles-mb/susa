# Self Plugin Remove

Remove um plugin instalado, excluindo todos os seus comandos do sistema.

## Como usar

```bash
susa self plugin remove <nome-do-plugin>
```

## Exemplo

```bash
susa self plugin remove backup-tools
```

## O que acontece?

1. Verifica se o plugin existe
2. Mostra quantos comandos serão removidos
3. Solicita confirmação
4. Remove o diretório do plugin
5. Remove o registro do plugin do sistema

## Processo de remoção

```text
⚠ Atenção: Você está prestes a remover o plugin 'backup-tools'

Comandos que serão removidos: 4

Deseja continuar? (s/N): s

ℹ Removendo plugin 'backup-tools'...

✓ Plugin 'backup-tools' removido com sucesso!
```

## Confirmação obrigatória

O comando **sempre** solicita confirmação antes de remover o plugin. Para cancelar, pressione `N` ou `Enter`.

## Se o plugin não existir

```text
✗ Plugin 'nome-invalido' não encontrado

Use susa self plugin list para ver plugins instalados
```

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda |

## Atenção

⚠️ A remoção é **permanente**. Se precisar do plugin novamente, será necessário reinstalá-lo usando `susa self plugin add`.

## Veja também

- [susa self plugin list](list.md) - Ver plugins instalados
- [susa self plugin add](add.md) - Reinstalar um plugin
- [susa self plugin update](update.md) - Atualizar plugin sem remover
