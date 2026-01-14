# plugin.sh

Funções para gerenciamento de plugins.

## Funções

### `ensure_git_installed()`

Verifica se git está instalado.

**Retorno:**

- `0` - git disponível
- `1` - git não encontrado

```bash
ensure_git_installed || {
    echo "Git é necessário"
    exit 1
}
```

### `has_github_ssh_access()`

Verifica se usuário tem acesso SSH ao GitHub configurado.

**Retorno:**

- `0` - SSH configurado e funcional
- `1` - SSH não disponível

**Verificações:**

1. Checa se existem chaves SSH (`~/.ssh/id_rsa` ou `~/.ssh/id_ed25519`)
2. Testa conexão com `git@github.com` (timeout 3 segundos)

```bash
if has_github_ssh_access; then
    echo "SSH configurado, usando git@github.com"
else
    echo "SSH não disponível, usando HTTPS"
fi
```

### `has_gitlab_ssh_access()`

Verifica se usuário tem acesso SSH ao GitLab configurado.

```bash
if has_gitlab_ssh_access; then
    echo "SSH GitLab disponível"
fi
```

### `has_bitbucket_ssh_access()`

Verifica se usuário tem acesso SSH ao Bitbucket configurado.

```bash
if has_bitbucket_ssh_access; then
    echo "SSH Bitbucket disponível"
fi
```

### `detect_git_provider()`

Detecta provedor Git de uma URL.

**Parâmetros:**

- `$1` - URL do repositório

**Retorno:**

- `github` - GitHub
- `gitlab` - GitLab
- `bitbucket` - Bitbucket
- `unknown` - Provedor desconhecido

```bash
provider=$(detect_git_provider "https://gitlab.com/user/repo.git")
echo "$provider"  # gitlab
```

### `validate_repo_access()`

Valida se repositório está acessível antes de clonar.

**Parâmetros:**

- `$1` - URL do repositório

**Retorno:**

- `0` - Repositório acessível
- `1` - Sem acesso ou repo não existe

```bash
if validate_repo_access "https://github.com/user/repo.git"; then
    echo "Repositório acessível"
else
    echo "Sem acesso ao repositório"
    exit 1
fi
```

### `detect_plugin_version()`

Detecta a versão de um plugin no diretório.

**Lógica:**

1. Verifica `version.txt`
2. Se não existe, verifica `VERSION`
3. Se não existe, retorna "1.0.0"

```bash
version=$(detect_plugin_version "/opt/susa/plugins/myplugin")
echo "Versão: $version"
```

### `count_plugin_commands()`

Conta quantos comandos um plugin possui.

```bash
count=$(count_plugin_commands "/opt/susa/plugins/myplugin")
echo "Plugin tem $count comandos"
```

### `clone_plugin()`

Clona plugin de um repositório Git e remove pasta .git.

**Parâmetros:**

- `$1` - URL do repositório
- `$2` - Diretório de destino

```bash
if clone_plugin "https://github.com/user/plugin.git" "/opt/susa/plugins/plugin"; then
    echo "Plugin clonado com sucesso"
fi
```

### `normalize_git_url()`

Converte formato `user/repo` para URL completa. Suporta GitHub, GitLab e Bitbucket.

**Parâmetros:**

- `$1` - URL ou formato `user/repo`
- `$2` - Force SSH (opcional, padrão: false)
- `$3` - Provider (opcional, padrão: github). Valores: `github`, `gitlab`, `bitbucket`

**Comportamento:**

- Se `user/repo`: converte para SSH (se disponível ou forçado) ou HTTPS
- Detecta automaticamente SSH para cada provedor
- Se URL completa HTTPS + force SSH: converte para SSH
- Caso contrário: retorna URL inalterada

```bash
# GitHub (padrão)
url=$(normalize_git_url "user/repo")
echo "$url"  # git@github.com:user/repo.git (se SSH disponível)

# GitLab
url=$(normalize_git_url "user/repo" "false" "gitlab")
echo "$url"  # https://gitlab.com/user/repo.git

# Bitbucket com SSH forçado
url=$(normalize_git_url "user/repo" "true" "bitbucket")
echo "$url"  # git@bitbucket.org:user/repo.git

# Converter HTTPS para SSH
url=$(normalize_git_url "https://gitlab.com/user/repo.git" "true")
echo "$url"  # git@gitlab.com:user/repo.git
```

### `extract_plugin_name()`

Extrai nome do plugin da URL.

```bash
name=$(extract_plugin_name "https://github.com/user/awesome-plugin.git")
echo "$name"  # awesome-plugin
```

## Exemplo Completo

```bash
#!/bin/bash
source "$LIB_DIR/plugin.sh"
source "$LIB_DIR/logger.sh"

# Parse argumentos
use_ssh="false"
if [ "$2" = "--ssh" ]; then
    use_ssh="true"
fi

# Garante git instalado
ensure_git_installed || exit 1

# Normaliza URL (com detecção/forçar SSH)
url=$(normalize_git_url "$1" "$use_ssh")
name=$(extract_plugin_name "$url")

log_info "Instalando plugin: $name"
log_debug "URL: $url"

# Valida acesso ao repositório
if ! validate_repo_access "$url"; then
    log_error "Não foi possível acessar o repositório"
    echo ""
    echo "Possíveis causas:"
    echo "  • Repositório não existe"
    echo "  • Repositório privado sem acesso"
    echo "  • Credenciais não configuradas"
    exit 1
fi

    log_success "Plugin $name v$version instalado!"
    log_info "Total de comandos: $count"
else
    log_error "Falha ao clonar plugin"
    exit 1
fi
```

## Boas Práticas

1. **Sempre normalize URLs** antes de clonar usando `normalize_git_url()`
2. **Verifique git instalado** antes de usar com `ensure_git_installed()`
3. **Valide acesso ao repo** antes de clonar com `validate_repo_access()`
4. **Detecte SSH automaticamente** usando `has_github_ssh_access()` para melhor UX
5. **Ofereça opção `--ssh`** para usuários forçarem autenticação SSH
6. **Valide estrutura do plugin** após clonar contando comandos
7. **Remova `.git`** após clone para economizar espaço
8. **Forneça feedback claro** em caso de falha de acesso (mensagens úteis)

## Repositórios Privados

### Detecção Automática

A biblioteca detecta automaticamente se SSH está configurado:

```bash
# Usuário com SSH configurado
url=$(normalize_git_url "org/private-plugin")
# Retorna: git@github.com:org/private-plugin.git

# Usuário sem SSH
url=$(normalize_git_url "org/private-plugin")
# Retorna: https://github.com/org/private-plugin.git
```

### Validação de Acesso

Sempre valide antes de clonar para evitar falhas tardias:

```bash
if ! validate_repo_access "$url"; then
    # Mensagens de erro específicas aqui
    exit 1
fi

# Agora pode clonar com segurança
clone_plugin "$url" "$dest"
```
