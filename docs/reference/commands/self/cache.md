# susa self cache

Gerencia o sistema de cache do CLI para melhorar a performance.

## Uso

```bash
susa self cache <comando>
```

## Comandos Disponíveis

### list

Lista todos os caches disponíveis no sistema.

```bash
susa self cache list [--detailed]
```

**Opções:**

- `-d, --detailed` - Mostra informações detalhadas de cada cache
- `-h, --help` - Mostra a mensagem de ajuda

**Modo Resumido (padrão):**

Exibe uma tabela compacta com:

- Nome do cache
- Tamanho do arquivo
- Número de chaves armazenadas
- Status

**Modo Detalhado (--detailed):**

Exibe informações completas de cada cache:

- Localização do arquivo
- Tamanho em disco
- Data da última modificação
- Número de chaves armazenadas

**Exemplos:**

```bash
# Listagem resumida
$ susa self cache list
[INFO] Caches Disponíveis:

Nome          Tamanho      Chaves    Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
lock          8KB          9         ✓

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: 1 cache(s) • 8KB

Localização: /run/user/1002/susa-user

# Listagem detalhada
$ susa self cache list --detailed
[INFO] Caches Disponíveis:

Cache: lock
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Localização:
  Arquivo: /run/user/1002/susa-user/lock.cache

Status:
  Existe:      ✓ Sim
  Tamanho:     12K
  Modificado:  2026-01-18 09:55:47 -0300
  Chaves:      9

Localização do diretório: /run/user/1002/susa-user
```

### clear

Remove um cache específico ou todos os caches.

```bash
susa self cache clear <cache-name>
susa self cache clear --all
```

**Argumentos:**

- `<cache-name>` - Nome do cache a limpar (ex: lock)
- `--all` - Limpa todos os caches

**Quando usar:**

- Para liberar espaço em memória
- Quando um cache está corrompido ou causando problemas
- Para forçar uma recriação completa

**Exemplos:**

```bash
# Limpar cache específico
$ susa self cache clear lock
[INFO] Limpando cache 'lock'...
[SUCCESS] ✓ Cache 'lock' removido com sucesso!

# Limpar todos os caches
$ susa self cache clear --all
[INFO] Limpando todos os caches...
[SUCCESS] ✓ 1 cache(s) removido(s) com sucesso!
```

## Descrição

O sistema de cache do SUSA CLI mantém cópias otimizadas de dados em memória para acelerar drasticamente a performance do CLI.

### Cache do Lock

O cache principal é o **lock**, que armazena uma cópia do arquivo `susa.lock`:
- ⚡ Reduz tempo de inicialização em ~75%
- 🔄 Atualizado automaticamente por `susa self lock`
- 💾 Validado automaticamente se está desatualizado

### Como Funciona

1. **Primeira execução**: O CLI lê os dados e cria um cache em disco
2. **Execuções subsequentes**: O CLI carrega o cache pré-processado
3. **Atualização automática**: Se os dados fontes mudarem, o cache é regenerado

### Localização do Cache

Os caches são armazenados em:

**Linux:**
```text
${XDG_RUNTIME_DIR:-/tmp}/susa-$USER/*.cache
```

**macOS:**
```text
${TMPDIR:-$HOME/Library/Caches}/susa/*.cache
```

Características:
- Específico para cada usuário
- Protegido com permissões 600 (acesso apenas pelo usuário)
- Limpo automaticamente em alguns sistemas

## Atualização Automática

O cache do lock é atualizado automaticamente quando:

- O comando `susa self lock` é executado
- Plugins são adicionados/removidos
- O arquivo `susa.lock` é modificado

**Na maioria dos casos, você não precisa executar comandos de cache manualmente.**

## Troubleshooting

### Cache corrompido ou comportamento estranho

```bash
# Limpar cache e regenerar
susa self cache clear lock
susa self lock
```

### Verificar estado dos caches

```bash
# Visão rápida
susa self cache list

# Detalhes completos
susa self cache list --detailed
```

### Liberar espaço

```bash
# Remover todos os caches
susa self cache clear --all
```

## Notas

- O cache é totalmente transparente para o usuário
- Não há necessidade de configuração
- Funciona em Linux e macOS
- Se o cache falhar, o CLI usa automaticamente fallback
- O cache de contexto é interno e gerenciado automaticamente

## Veja Também

- [susa self lock](lock.md) - Regenera o arquivo lock
- [Sistema de Cache](../../libraries/cache.md) - Documentação técnica do sistema de cache
