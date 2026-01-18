# Self

Comandos para gerenciamento e manutenção do próprio Susa CLI.

## O que é?

A categoria `self` reúne todos os comandos relacionados à **gestão interna** do Susa CLI, como:

- Verificar informações e versões
- Atualizar o sistema
- Configurar funcionalidades (autocompletar)
- Gerenciar plugins externos

## Comandos Disponíveis

### [Completion](completion.md)

Configura o autocompletar (tab completion) para seu shell.

```bash
susa self completion bash --install
susa self completion zsh --install
```

### [Info](info.md)

Exibe informações detalhadas sobre a instalação da CLI.

```bash
susa self info
```

### [Lock](lock.md)

Atualiza o arquivo `susa.lock` para acelerar a inicialização do CLI (~38% mais rápido).

```bash
susa self lock
```

### [Cache](cache.md)

Gerencia o sistema de cache do CLI para melhorar a performance.

```bash
susa self cache list                # Lista todos os caches
susa self cache list --detailed     # Informações detalhadas
susa self cache clear lock          # Limpa cache específico
susa self cache clear --all         # Limpa todos os caches
```

### [Version](version.md)

Mostra a versão atual do Susa CLI.

```bash
susa self version
susa self version --number
```

### [Update](update.md)

Atualiza o Susa CLI para a versão mais recente.

```bash
susa self update
```

### [Plugins](plugins/index.md)

Gerencia plugins externos que estendem as funcionalidades do Susa CLI.

```bash
susa self plugin add usuario/plugin-name
susa self plugin list
susa self plugin update nome-plugin
susa self plugin remove nome-plugin
```

## Referência Rápida

| Comando | Descrição |
|---------|-----------|
| `completion` | Configura autocompletar no shell |
| `info` | Informações da instalação |
| `lock` | Atualiza cache de comandos (susa.lock) |
| `cache` | Gerencia o sistema de cache do CLI |
| `version` | Versão atual do CLI |
| `update` | Atualiza o Susa CLI |
| `plugin add` | Instala novo plugin |
| `plugin list` | Lista plugins instalados |
| `plugin update` | Atualiza plugin |
| `plugin remove` | Remove plugin |

## Veja também

- [Guia de Configuração](../../../guides/configuration.md) - Personalize o Susa CLI
- [Guia de Shell Completion](../../../guides/shell-completion.md) - Mais sobre autocompletar
- [Visão Geral de Plugins](../../../plugins/overview.md) - Entenda o sistema de plugins
- [Arquitetura de Plugins](../../../plugins/architecture.md) - Como funcionam os plugins
