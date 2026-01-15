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

### Plugins Git

1. Verifica se o plugin existe
2. Mostra quantos comandos serão removidos
3. Solicita confirmação
4. Remove o diretório do plugin
5. Remove o registro do plugin do sistema
6. Atualiza o arquivo susa.lock

### Plugins Dev (Modo Desenvolvimento)

1. Verifica se o plugin existe no registry
2. Mostra modo desenvolvimento e caminho local
3. Mostra quantos comandos serão removidos
4. Solicita confirmação
5. Remove apenas o registro do sistema (não remove arquivos locais)
6. Atualiza o arquivo susa.lock

**Importante:** Plugins dev não têm seus arquivos removidos, apenas o registro no sistema.

## Processo de remoção

### Plugin Git

```text
⚠ Atenção: Você está prestes a remover o plugin 'backup-tools'

Comandos que serão removidos: 4

Deseja continuar? (s/N): s
ℹ Removendo plugin 'backup-tools'...
✓ Plugin 'backup-tools' removido com sucesso!
ℹ Atualizando arquivo susa.lock...

💡 Execute 'susa --help' para ver as categorias atualizadas
```

### Plugin Dev (Modo Desenvolvimento)

```text
⚠ Atenção: Você está prestes a remover o plugin 'meu-plugin'

Modo: desenvolvimento
Local do plugin: /home/usuario/projetos/meu-plugin

Comandos que serão removidos: 3

Deseja continuar? (s/N): s
ℹ Removendo plugin 'meu-plugin'...
✓ Plugin 'meu-plugin' removido com sucesso!
ℹ Atualizando arquivo susa.lock...

💡 Execute 'susa --help' para ver as categorias atualizadas
```

**Nota:** Os arquivos do plugin dev permanecem no diretório local.

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

## Diferenças entre Plugin Git e Dev

### Plugin Git

- ❌ **Remove diretório completo** de `~/.susa/plugins/nome-plugin`
- ❌ **Remove registro** do sistema
- 🔄 **Atualiza** susa.lock
- ⚠️ **Permanente** - Precisa reinstalar do Git

### Plugin Dev

- ✅ **Mantém arquivos** no diretório local
- ❌ **Remove apenas registro** do sistema
- 🔄 **Atualiza** susa.lock
- 🔄 **Reversível** - Pode reinstalar com `susa self plugin add .`

## Atenção

⚠️ Para **plugins Git**, a remoção é **permanente**. Se precisar do plugin novamente, será necessário reinstalá-lo usando `susa self plugin add`.

✅ Para **plugins dev**, os arquivos permanecem no diretório local. Você pode reinstalar a qualquer momento:

```bash
cd ~/projetos/meu-plugin
susa self plugin add .
```

## Veja também

- [susa self plugin list](list.md) - Ver plugins instalados
- [susa self plugin add](add.md) - Reinstalar um plugin
- [susa self plugin update](update.md) - Atualizar plugin sem remover
