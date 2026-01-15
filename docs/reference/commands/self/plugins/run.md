# Self Plugin Run

Executa um plugin instalado ou em modo de desenvolvimento, sem necessidade de instalação permanente.

Ideal para **testar plugins durante desenvolvimento** ou executar comandos de plugins instalados de forma direta.

## Como usar

### Execução Básica

```bash
# Executar comando de plugin instalado
susa self plugin run meu-plugin text hello

# Passar argumentos para o comando
susa self plugin run meu-plugin text hello --name World

# Executar comando em subcategoria (use barra /)
susa self plugin run meu-plugin database/admin migrate
```

### Modo Desenvolvimento (Dev Mode)

Execute plugins diretamente do diretório de desenvolvimento sem instalá-los:

```bash
# Modo automático (com cleanup)
cd ~/meu-plugin
susa self plugin run meu-plugin text comando

# O plugin é automaticamente:
# 1. Adicionado ao registry temporariamente
# 2. Executado
# 3. Removido do registry após execução
```

### Modo Manual (Preparar/Executar/Limpar)

Para testes mais elaborados onde você precisa executar múltiplos comandos:

```bash
# 1. Preparar plugin dev (adicionar ao registry)
cd ~/meu-plugin
susa self plugin run --prepare meu-plugin text comando

# 2. Executar comandos normalmente (múltiplas vezes)
susa text comando
susa text outro-comando
susa text mais-um-comando

# 3. Limpar plugin dev (remover do registry)
susa self plugin run --cleanup meu-plugin text comando
```

### Separador de Argumentos

Use `--` para separar opções do comando `run` de argumentos do plugin:

```bash
# --help vai para o plugin (não para o comando run)
susa self plugin run meu-plugin text hello -- --help

# -v e --format vão para o plugin
susa self plugin run meu-plugin text hello -- -v --format json

# Múltiplos argumentos após o separador
susa self plugin run meu-plugin text hello -- --verbose --dry-run --output file.txt
```

## O que acontece?

### Fluxo de Execução

1. **Verifica lock**: Busca comando no `susa.lock` (plugins instalados)
2. **Modo dev**: Se não encontrar, tenta adicionar do diretório atual
   - Plugin marcado como `dev: true` no registry
   - Campo `source` aponta para diretório atual
3. **Atualiza lock**: Regenera lock incluindo comandos do plugin dev
4. **Executa**: Executa o comando do plugin
5. **Cleanup**: Remove plugin dev automaticamente (modo execute) ou mantém até `--cleanup` (modo prepare)

## Opções

### `-h, --help`

Exibe ajuda do comando run.

```bash
susa self plugin run --help
```

### `-v, --verbose`

Ativa modo verbose para debug do comando run (não do plugin).

```bash
susa self plugin run -v meu-plugin text hello
```

Para passar verbose ao plugin, use o separador:

```bash
susa self plugin run meu-plugin text hello -- -v
```

### `--prepare`

Apenas prepara o plugin dev (adiciona ao registry/lock) sem executar. Útil para testar múltiplos comandos sem reinstalar a cada vez.

```bash
cd ~/meu-plugin
susa self plugin run --prepare meu-plugin text comando

# Agora pode executar normalmente
susa text comando
susa text outro-comando
```

### `--cleanup`

Remove o plugin dev do registry/lock após testes com `--prepare`.

```bash
susa self plugin run --cleanup meu-plugin text comando
```

Use após terminar os testes com `--prepare`.

### `--`

Separador entre opções do run e argumentos do plugin. Necessário quando argumentos do plugin conflitam com opções do run (`--help`, `-v`, etc.).

```bash
# Sem separador: --help é capturado pelo run
susa self plugin run --help meu-plugin text hello

# Com separador: --help vai para o plugin
susa self plugin run meu-plugin text hello -- --help

# Múltiplos argumentos
susa self plugin run meu-plugin text hello -- -v --format json --output file.txt
```

## Argumentos

### `plugin-name`

Nome do plugin a ser executado.

```bash
susa self plugin run susa-plugin-tools text hello
```

### `category`

Categoria do comando no plugin.

Para subcategorias, use barra `/`:

```bash
# Categoria simples
susa self plugin run tools database backup

# Subcategoria
susa self plugin run tools database/admin migrate

# Múltiplos níveis
susa self plugin run tools infra/k8s/deploy production
```

### `command`

Nome do comando a ser executado.

### `[args...]`

Argumentos adicionais para o comando do plugin.

## Estrutura Esperada

O plugin deve seguir a estrutura padrão:

```text
meu-plugin/
├── version.txt           # Versão do plugin
├── categoria1/
│   ├── config.yaml       # Config da categoria
│   ├── comando1/
│   │   ├── config.yaml   # Config do comando
│   │   └── main.sh       # Script do comando
│   └── subcategoria/     # Subcategorias opcionais
│       ├── config.yaml
│       └── comando2/
│           ├── config.yaml
│           └── main.sh
└── categoria2/
    └── ...
```

## Exemplos

### Desenvolvimento Rápido

```bash
# Testar comando durante desenvolvimento
cd ~/susa-plugin-tools
susa self plugin run susa-plugin-tools database backup
```

### Testes Múltiplos

```bash
# Preparar plugin
cd ~/susa-plugin-tools
susa self plugin run --prepare susa-plugin-tools database backup

# Executar vários comandos
susa database backup --full
susa database restore backup.sql
susa database migrate

# Limpar
susa self plugin run --cleanup susa-plugin-tools database backup
```

Teste Rápido (Modo Automático)

```bash
cd ~/susa-plugin-tools
susa self plugin run susa-plugin-tools database backup
# Plugin adicionado → executado → removido automaticamente
```

### Testes Múltiplos (Modo Manual)

```bash
cd ~/susa-plugin-tools
susa self plugin run --prepare susa-plugin-tools database backup

susa database backup --full
susa database restore backup.sql
susa database migrate

susa self plugin run --cleanup susa-plugin-tools database backup
```

### Com Subcategorias e Separador

```bash
# Subcategoria: tools/infra/k8s/deploy/
susa self plugin run tools infra/k8s/deploy production

# Separador para passar --help ao plugin
susa self plugin run tools text hello -- --help -vmostra execução interna)
susa self plugin run meu-plugin text cmd -- -v

# Ambos
susa self plugin run -v meu-plugin text cmd -- -v
```

### Debug com Verbose

```bash
# Verbose do run (mostra busca e preparação)
susa self plugin run -v meu-plugin text cmd

# Verbose do plugin (usa separador --)
susa self plugin run meu-plugin text cmd -- -v
```

### CI/CD Testing

```bash
git clone https://github.com/user/plugin.git
cd plugin
susa self plugin run plugin-name text test-command
```

### Testes Integrados

```bash
cd ~/plugin
susa self plugin run --prepare plugin text cmd
./run-integration-tests.sh

Plugins em modo dev são **temporários** no modo execute:

```bash
# Adicionado e removido automaticamente
cd ~/plugin
susa self plugin run plugin text cmd
# Lock fica limpo após execução
```

Para manter entre execuções, use `--prepare`.

## Troubleshooting

### "Comando não encontrado no lock"

**Causa**: Estrutura do plugin incorreta ou config.yaml inválido.

**Solução**:

```bash
# Verificar estrutura
cd ~/plugin
tree
 Importantes

- **Plugins dev são temporários**: No modo execute, são removidos automaticamente. Use `--prepare` para manter entre execuções
- **Campo `source`**: Plugins dev usam diretório atual, instalados usam `$CLI_DIR/plugins/nome-plugin`
- **Exit code**: O exit code do script do plugin é propagado para o shell

## Veja também

- [Plugin Add](add.md) - Instalar plugins permanentemente
- [Plugin List](list.md) - Listar plugins instalados
- [Plugin Remove](remove.md) - Remover plugins
- [Visão Geral de Plugins](../../../../plugins/overview.md) - Entenda o sistema
- [Arquitetura de Plugins](../../../../plugins/architecture.md) - Como funcionam
Use o separador `--` quando opções forem capturadas pelo run:

```bash
susa self plugin run plugin text cmd -- -v --help
