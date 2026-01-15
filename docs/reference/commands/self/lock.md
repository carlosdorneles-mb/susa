# susa self lock

Atualiza o arquivo `susa.lock` com os comandos e categorias disponíveis.

## Descrição

O comando `susa self lock` varre os diretórios `commands/` e `plugins/` para descobrir todas as categorias, subcategorias e comandos disponíveis, gerando um arquivo de cache (`susa.lock`) que acelera a inicialização do CLI.

**Importante**: O arquivo `susa.lock` é **obrigatório** para o funcionamento do CLI. Na primeira execução, ele é gerado automaticamente.

## Benefícios

- **Performance**: Inicialização ~38% mais rápida
- **Automático**: Gerado na primeira execução e atualizado ao gerenciar plugins
- **Obrigatório**: O CLI requer este arquivo para funcionar
- **Rastreamento**: Mantém registro de instalações de software via `setup` commands

## Uso

```bash
# Regenera o arquivo de lock
susa self lock

# Regenera e sincroniza instalações do sistema
susa self lock --sync
```

## Opções

### `--sync`

Sincroniza o estado das instalações entre o sistema e o lock file:

- **Adiciona**: Detecta aplicações instaladas no sistema e registra no lock file
- **Remove**: Detecta aplicações desinstaladas e atualiza o lock file
- **Bidirecional**: Mantém o lock sempre alinhado com o estado real do sistema

**Casos de uso**:

- Após instalar software manualmente (fora do `susa setup`)
- Após desinstalar software diretamente do sistema
- Para auditar instalações gerenciadas pelo Susa CLI

### `-v, --verbose`

Habilita saída detalhada com mensagens de debug. Útil para diagnóstico e desenvolvimento.

```bash
susa self lock --sync --verbose
# Mostra cada verificação realizada
```

### `-q, --quiet`

Minimiza a saída, desabilitando mensagens de debug. Útil para uso em scripts.

```bash
susa self lock --quiet
# Mostra apenas mensagens essenciais
```

## Exemplos

```bash
# Regenera o lock file
susa self lock

# Regenera e sincroniza instalações
susa self lock --sync

# Sincroniza com saída detalhada
susa self lock --sync --verbose

# Sincroniza silenciosamente
susa self lock --sync --quiet
```

### Exemplo de Saída com `--sync`

### Exemplo de Saída com `--sync`

**Com mudanças detectadas:**
$ susa self lock --sync
[INFO] Gerando arquivo susa.lock...
[SUCCESS] Arquivo susa.lock gerado com sucesso!

[INFO] Sincronizando instalações...
[SUCCESS] Sincronizado: docker (29.1.4)
[SUCCESS] Sincronizado: podman (5.7.1)
[WARNING] Removido do lock: fake-app (não está mais instalado)

[SUCCESS] 2 software(s) adicionado(s) ao lock file.
[SUCCESS] 1 software(s) removido(s) do lock file.
```

**Sem alterações detectadas:**

```bash
$ susa self lock --sync
[INFO] Gerando arquivo susa.lock...
[SUCCESS] Arquivo susa.lock gerado com sucesso!

[INFO] Sincronizando instalações...

[INFO] Nenhuma alteração encontrada.
```

## Geração Automática

O arquivo `susa.lock` é gerado automaticamente em duas situações:

## Geração Automática

O arquivo `susa.lock` é gerado automaticamente em duas situações:

### 1. Primeira Execução

Se o arquivo não existir, o CLI o gera automaticamente:

```bash
$ susa --version
[INFO] Primeira execução detectada. Configurando o Susa CLI...
[INFO] Gerando arquivo de cache para otimizar o desempenho...

[SUCCESS] Configuração concluída! O CLI está pronto para uso.

Susa CLI (versão 1.0.0)
```

### 2. Gerenciamento de Plugins

- Ao instalar um plugin (`susa self plugin add`)
- Ao remover um plugin (`susa self plugin remove`)
- Ao atualizar um plugin (`susa self plugin update`)

## Quando Executar Manualmente

Execute `susa self lock` manualmente quando:

- Adicionar novos comandos diretamente no diretório `commands/`
- Modificar a estrutura de categorias/subcategorias
- O arquivo foi corrompido

Execute `susa self lock --sync` quando:

- Instalar/desinstalar software manualmente (fora do `susa setup`)
- Quiser auditar o estado das instalações no sistema
- Suspeitar de inconsistências entre o lock e o sistema

## Estrutura do Arquivo

O arquivo `susa.lock` é um arquivo YAML com a seguinte estrutura:

```yaml
version: "1.0.0"
generated_at: "2026-01-13T17:13:49Z"

categories:
  - name: "self"
    description: "Gerencia as configurações do Susa CLI"
    source: "commands"
  - name: "setup"
    description: "Instalação e atualização de softwares"
    source: "commands"

commands:
  - category: "self"
    name: "lock"
    description: "Atualiza o arquivo susa.lock"
  - category: "setup"
    name: "docker"
    description: "Instala Docker"
    os: ["linux", "mac"]
    sudo: "true"
    group: "containers"
  - category: "deploy"
    name: "staging"
    description: "Deploy para staging"
    plugin:
      name: "backup-tools"
      source: "/home/user/.config/susa/plugins/backup-tools"
      dev: false

# Seção de instalações (gerenciada automaticamente)
installations:
  - name: docker
    installed: true
    version: 29.1.4
    installed_at: "2026-01-14T15:27:36Z"
  - name: podman
    installed: true
    version: 5.7.1
    installed_at: "2026-01-14T15:27:36Z"
  - name: mise
    installed: true
    version: 2026.1.1
    installed_at: "2026-01-14T15:27:36Z"
```

### Seção `installations`

A seção `installations` rastreia automaticamente o software instalado via comandos `susa setup`:

- **`name`**: Nome do software (corresponde ao comando setup)
- **`installed`**: Booleano indicando se está instalado
- **`version`**: Versão instalada (detectada automaticamente)
- **`installed_at`**: Timestamp ISO 8601 da instalação
- **`updated_at`**: Timestamp da última atualização (quando aplicável)

Esta seção é gerenciada automaticamente:

- Atualizada ao executar `susa setup <software>`
- Atualizada ao executar `susa setup <software> --update`
- Atualizada ao executar `susa setup <software> --uninstall`
- Sincronizada ao executar `susa self lock --sync`

## Impacto na Performance

Benchmark médio em um CLI com 10 comandos:

- **Com susa.lock**: 0.508s
- **Sem susa.lock**: 0.823s
- **Ganho**: 38% mais rápido

## Campo Source em Plugins

Para comandos de plugins, o lock inclui o campo `plugin.source` que indica o caminho do plugin:

- **Plugins instalados**: `$CLI_DIR/plugins/nome-plugin`
- **Plugins dev**: Diretório atual durante desenvolvimento

Esse campo permite ao sistema resolver corretamente os paths dos scripts mesmo quando plugins estão em desenvolvimento.

## Plugins em Modo Dev

Plugins instalados localmente (modo dev) são automaticamente incluídos no lock com `dev: true` e `source` apontando para o diretório local.

## Observações

- O arquivo `susa.lock` não deve ser editado manualmente
- O arquivo pode ser versionado no Git
- **Obrigatório**: O CLI requer este arquivo para funcionar
- Se deletado, será recriado automaticamente na próxima execução
- Campo `source` é essencial para resolução de paths de plugins

## Ver Também

- [susa self plugin add](plugins/add.md) - Instala plugins
- [susa self plugin remove](plugins/remove.md) - Remove plugins
- [susa self plugin update](plugins/update.md) - Atualiza plugins
