#!/bin/bash

# --- Kubernets Helper Functions --- #

# Checks if kubectl is installed. Prints an error and exits if not found and "exit_on_error" is passed as an argument.
# Usage:
#   check_kubectl_installed "exit_on_error"
check_kubectl_installed() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl não está instalado. Por favor, instale o kubectl seguindo as instruções em: https://kubernetes.io/docs/tasks/tools/install-kubectl/"
        if [ "$1" == "exit_on_error" ]; then
            exit 1
        fi
        return 1
    fi
    return 0
}

# Checks if a given Kubernetes namespace exists. Exits with error if not found and "exit_on_error" is passed as the second argument.
# Usage:
#   check_namespace_exists "namespace_name" "exit_on_error"
check_namespace_exists() {
    local namespace=$1
    check_kubectl_installed "exit_on_error"

    if ! kubectl get namespace "$namespace" &> /dev/null; then
        if [ "$2" == "exit_on_error" ]; then
            log_error "O ambiente $namespace não existe. Verifique o nome do ambiente."
            exit 1
        fi
        return 1
    fi
    return 0
}

# Returns the current kubectl context name.
# Usage:
#   get_current_context
# Example:
#   context=$(get_current_context)
#   echo "$context"
get_current_context() {
    check_kubectl_installed "exit_on_error"
    kubectl config current-context
}

# Prints the current kubectl context to the console.
# Usage:
#   print_current_context
print_current_context() {
    local context
    context=$(get_current_context)
    if [ $? -eq 0 ]; then
        echo -e "O contexto atual do kubectl é: ${BOLD}$context${NC}"
    else
        log_error "Não foi possível obter o contexto atual do kubectl."
    fi
}