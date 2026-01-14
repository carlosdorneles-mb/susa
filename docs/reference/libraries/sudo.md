# sudo.sh

Funções para gerenciamento de privilégios de superusuário.

## Funções

### `check_sudo()`

Verifica se o script está sendo executado como root.

**Retorno:**

- `0` - Executando como root
- `1` - Não está executando como root (imprime aviso)

**Uso:**

```bash
if check_sudo; then
    echo "Executando como root"
else
    echo "Sem privilégios de root"
fi
```

### `required_sudo()`

Garante privilégios sudo ou sai com erro.

**Comportamento:**

- Se já é root: não faz nada
- Se não é root: pede senha sudo
- Se falhar: sai com exit 1

**Uso:**

```bash
#!/bin/bash
source "$LIB_DIR/sudo.sh"

# Garante que temos sudo antes de continuar
required_sudo

# Aqui já temos sudo garantido
apt-get update
apt-get install package
```

## Exemplo Completo

```bash
#!/bin/bash
source "$LIB_DIR/sudo.sh"
source "$LIB_DIR/logger.sh"

# Verifica se precisa de sudo
if ! check_sudo; then
    log_warning "Este comando requer privilégios sudo"
    required_sudo
fi

log_info "Atualizando sistema..."
apt-get update

log_success "Sistema atualizado!"
```

## Boas Práticas

1. Use no início de comandos que modificam o sistema
2. Combine com campo `sudo: true` no config.yaml
3. Informe o usuário antes de pedir sudo
