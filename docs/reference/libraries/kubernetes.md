# kubernetes.sh

Funções auxiliares para trabalhar com Kubernetes (kubectl).

## Funções

### `check_kubectl_installed()`

Verifica se kubectl está instalado.

**Parâmetros:**

- `exit_on_error` (opcional) - Se passado, sai do script com erro se kubectl não estiver instalado

**Retorno:**

- `0` - kubectl disponível
- `1` - kubectl não encontrado

```bash
# Apenas verifica
if check_kubectl_installed; then
    echo "kubectl disponível"
fi

# Força instalação ou sai
check_kubectl_installed "exit_on_error"
```

### `check_namespace_exists()`

Verifica se um namespace Kubernetes existe.

**Parâmetros:**

- `$1` - Nome do namespace
- `exit_on_error` (opcional) - Se passado, sai do script com erro se namespace não existir

```bash
# Apenas verifica
if check_namespace_exists "production"; then
    echo "Namespace production existe"
fi

# Força existência ou sai
check_namespace_exists "production" "exit_on_error"
```

### `get_current_context()`

Retorna o contexto atual do kubectl.

```bash
context=$(get_current_context)
echo "Contexto atual: $context"
```

### `print_current_context()`

Imprime o contexto atual formatado no console.

```bash
print_current_context
# Output: O contexto atual do kubectl é: minikube
```

## Exemplo Completo

```bash
#!/bin/bash
source "$LIB_DIR/kubernetes.sh"
source "$LIB_DIR/logger.sh"

# Garante kubectl instalado
check_kubectl_installed "exit_on_error"

# Mostra contexto atual
print_current_context

# Valida namespace
namespace="${1:-default}"
check_namespace_exists "$namespace" "exit_on_error"

log_success "Namespace $namespace está acessível"

# Lista pods
log_info "Pods no namespace $namespace:"
kubectl get pods -n "$namespace"
```

## Boas Práticas

1. Sempre verifique kubectl antes de comandos k8s
2. Valide namespace antes de operações
3. Mostre contexto atual para evitar erros
