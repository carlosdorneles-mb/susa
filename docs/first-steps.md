# Primeiros Passos

Guia rápido para começar a usar o CLI.

## Instalação

### Requisitos

- Bash 4.0 ou superior
- Git
- yq (instalado automaticamente se necessário)

### Instalação via Script

```bash
git clone https://github.com/cdorneles/cli.git
cd cli
./install.sh
```

O instalador:

1. ✅ Valida o sistema
2. ✅ Cria link simbólico em `~/.local/bin/cli`
3. ✅ Configura permissões
4. ✅ Verifica dependências

### Instalação Manual

```bash
# Clone o repositório
git clone https://github.com/cdorneles/cli.git

# Crie o link simbólico
ln -s $(pwd)/cli/cli ~/.local/bin/cli

# Torne executável
chmod +x ~/.local/bin/cli

# Adicione ao PATH se necessário
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Verificação

Confirme que a instalação funcionou:

```bash
# Ver versão
susa --version

# Ver ajuda
susa --help

# Listar comandos
susa
```

## Primeiro Uso

### Explorar Comandos

```bash
# Ver menu principal
susa

# Navegar em categorias
susa setup
susa self

# Acessar subcategorias
susa self plugin
```

### Instalar Software

```bash
# Instalar ASDF
susa setup asdf

# Ver comandos disponíveis em setup
susa setup help
```

### Gerenciar Plugins

```bash
# Listar plugins instalados
susa self plugin list

# Instalar um plugin
susa self plugin install https://github.com/user/cli-plugin-name

# Ver versão
susa self version
```

## Configuração

### Arquivo Global (cli.yaml)

Configuração estrutural do CLI:

```yaml
command: "cli"
name: "CLI"
description: "CLI para gerenciar instalações e atualizações de software"
version: "1.0.0"

commands_dir: "commands"
plugins_dir: "plugins"
```

### Configurações de Usuário (config/settings.conf)

Personalize comportamentos:

```bash
# Diretório padrão para backups
BACKUP_DIR="$HOME/backups"
```

## Desinstalação

```bash
cd cli
./uninstall.sh
```

## Próximos Passos

- [Sistema de Subcategorias](guides/subcategories.md)
- [Criar seus próprios comandos](guides/adding-commands.md)
- [Instalar plugins](plugins/overview.md)
