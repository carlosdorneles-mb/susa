# Self Plugin Add

Instala um plugin a partir de um repositório Git, adicionando novos comandos ao Susa CLI.

## Como usar

### Usando URL completa

```bash
susa self plugin add https://github.com/usuario/susa-plugin-name
susa self plugin add git@github.com:organizacao/plugin-privado.git
```

### Usando formato user/repo

```bash
# Público
susa self plugin add usuario/susa-plugin-name

# Privado (detecta SSH automaticamente)
susa self plugin add organizacao/plugin-privado

# Privado (força SSH)
susa self plugin add organizacao/plugin-privado --ssh
```

## O que acontece?

1. Verifica se o plugin já está instalado
2. Valida acesso ao repositório
3. Clona o repositório Git do plugin
4. Registra o plugin no sistema
5. Torna os comandos do plugin disponíveis imediatamente

## Opções

| Opção | O que faz |
|-------|-----------|
| `--ssh` | Força uso de SSH (recomendado para repos privados) |
| `-h, --help` | Mostra ajuda |

## Requisitos

- Git instalado no sistema
- Conexão com a internet
- Plugin deve seguir a estrutura do Susa CLI

## Estrutura esperada do plugin

```text
susa-plugin-name/
├── commands/
│   └── categoria/
│       ├── config.yaml
│       └── main.sh
```

## Exemplo de uso

```bash
# Instalar plugin de backup
susa self plugin add usuario/susa-backup-tools

# Após instalação, os comandos ficam disponíveis
susa backup criar
susa backup restaurar
```

## Se o plugin já estiver instalado

O comando mostra informações do plugin existente e sugere ações:

```text
⚠ Plugin 'backup-tools' já está instalado

  Versão atual: 1.2.0
  Instalado em: 2026-01-10 14:30:00

Opções disponíveis:
  • Atualizar plugin:  susa self plugin update backup-tools
  • Remover plugin:    susa self plugin remove backup-tools
  • Listar plugins:    susa self plugin list
```

## Repositórios Privados

### Autenticação SSH (Recomendada)

O sistema detecta automaticamente se você tem SSH configurado e usa quando disponível:

```bash
# 1. Configure sua chave SSH
ssh-keygen -t ed25519 -C "seu-email@example.com"
cat ~/.ssh/id_ed25519.pub

# 2. Adicione no GitHub: Settings → SSH and GPG keys

# 3. Instale o plugin (detecta SSH automaticamente)
susa self plugin add organizacao/plugin-privado
```

### Forçar SSH

Use `--ssh` para garantir uso de SSH:

```bash
susa self plugin add organizacao/plugin-privado --ssh
```

### Autenticação HTTPS

Configure credential helper para repositórios HTTPS:

```bash
git config --global credential.helper store
susa self plugin add https://github.com/org/plugin-privado.git
```

### Mensagens de Erro

Se não tiver acesso, o comando mostra ajuda:

```text
[ERROR] Não foi possível acessar o repositório

Possíveis causas:
  • Repositório não existe
  • Repositório é privado e você não tem acesso
  • Credenciais Git não configuradas

Para repositórios privados:
  • Use --ssh e configure chave SSH no GitHub/GitLab
  • Configure credential helper: git config --global credential.helper store
```

## Veja também

- [susa self plugin list](list.md) - Listar plugins instalados
- [susa self plugin update](update.md) - Atualizar um plugin
- [susa self plugin remove](remove.md) - Remover um plugin
- [Visão Geral de Plugins](../../../../plugins/overview.md) - Entenda o sistema de plugins
- [Arquitetura de Plugins](../../../../plugins/architecture.md) - Como funcionam os plugins
