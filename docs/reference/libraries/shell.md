# shell.sh

Funções para detectar e configurar o shell do usuário.

## Funções

### `detect_shell_type()`

Detecta o tipo de shell do usuário.

**Retorno:**

- `zsh` - Se o shell atual é zsh
- `bash` - Se o shell atual é bash
- `fish` - Se o shell atual é fish
- `unknown` - Shell não reconhecido

**Lógica de detecção:**

1. Verifica variável `$SHELL`
2. Fallback para variáveis de ambiente específicas (`$ZSH_VERSION`, `$BASH_VERSION`)

**Uso:**

```bash
shell=$(detect_shell_type)

case "$shell" in
    zsh)
        echo "Usando Zsh"
        ;;
    bash)
        echo "Usando Bash"
        ;;
    *)
        echo "Shell desconhecido"
        ;;
esac
```

### `detect_shell_config()`

Detecta qual arquivo de configuração do shell usar (.zshrc, .bashrc, etc.).

**Retorno:**

- `$HOME/.zshrc` - Se o shell atual é zsh
- `$HOME/.bashrc` - Se o shell atual é bash
- `$HOME/.profile` - Fallback padrão

**Lógica de detecção:**

1. Verifica variável `$SHELL`
2. Se zsh e `.zshrc` existe → retorna `.zshrc`
3. Se bash e `.bashrc` existe → retorna `.bashrc`
4. Se `.zshrc` existe → retorna `.zshrc`
5. Se `.bashrc` existe → retorna `.bashrc`
6. Caso contrário → retorna `.profile`

**Uso:**

```bash
source "$LIB_DIR/shell.sh"

shell_config=$(detect_shell_config)
echo "export PATH=\"\$PATH:/opt/susa/bin\"" >> "$shell_config"

echo "Configuração adicionada em: $shell_config"
```

## Exemplo Completo

```bash
#!/bin/bash
source "$LIB_DIR/shell.sh"
source "$LIB_DIR/logger.sh"

# Adiciona PATH ao shell config
shell_config=$(detect_shell_config)
cli_path="/opt/susa/bin"

if ! grep -q "$cli_path" "$shell_config"; then
    echo "export PATH=\"\$PATH:$cli_path\"" >> "$shell_config"
    log_success "PATH adicionado a $shell_config"
    log_info "Execute: source $shell_config"
else
    log_info "PATH já configurado em $shell_config"
fi
```

## Boas Práticas

1. Use para configurar PATH e aliases
2. Sempre verifique se a configuração já existe
3. Informe o usuário para recarregar o shell
