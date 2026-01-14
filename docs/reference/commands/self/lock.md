# susa self lock

Atualiza o arquivo `susa.lock` com os comandos e categorias disponíveis.

## Descrição

O comando `susa self lock` varre os diretórios `commands/` e `plugins/` para descobrir todas as categorias, subcategorias e comandos disponíveis, gerando um arquivo de cache (`susa.lock`) que acelera a inicialização do CLI.

**Importante**: O arquivo `susa.lock` é **obrigatório** para o funcionamento do CLI. Na primeira execução, ele é gerado automaticamente.

## Benefícios

- **Performance**: Inicialização ~38% mais rápida
- **Automático**: Gerado na primeira execução e atualizado ao gerenciar plugins
- **Obrigatório**: O CLI requer este arquivo para funcionar

## Uso

```bash
susa self lock
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

Execute `susa self lock` manualmente apenas quando:

- Adicionar novos comandos diretamente no diretório `commands/`
- Modificar a estrutura de categorias/subcategorias
- O arquivo foi corrompido

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
```

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

Quando usando `susa self plugin run` sem `--prepare`, o plugin dev:

- É adicionado ao lock temporariamente com `dev: true`
- Tem `source` apontando para diretório atual
- É automaticamente removido após execução

Veja [Self Plugin Run](../plugins/run.md) para detalhes.

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
