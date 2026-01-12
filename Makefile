.PHONY: help install serve build deploy clean cli-install cli-uninstall test

# Cores para output
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m

help:
	@echo "$(GREEN)CLI - Makefile Commands$(NC)"
	@echo ""
	@echo "$(BLUE)CLI Commands:$(NC)"
	@grep -E '^cli-[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Documentation Commands:$(NC)"
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v '^cli-' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

install: ## Instala dependências para documentação
	@pip install --upgrade pip
	@pip install mkdocs mkdocs-material pymdown-extensions

serve doc: ## Inicia servidor de documentação local
	@echo "$(GREEN)🌐 Iniciando servidor MkDocs...$(NC)"
	@echo "$(YELLOW)📖 Acesse: http://127.0.0.1:8000$(NC)"
	@echo ""
	@mkdocs serve

clean: ## Remove arquivos gerados
	@echo "$(YELLOW)🧹 Limpando arquivos gerados...$(NC)"
	@rm -rf site/
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "$(GREEN)✅ Limpeza concluída!$(NC)"

# CLI Installation
cli-install: ## Instala o CLI no sistema
	@echo "$(GREEN)🚀 Instalando CLI...$(NC)"
	@./install.sh

cli-uninstall: ## Remove o CLI do sistema
	@echo "$(YELLOW)🗑️  Desinstalando CLI...$(NC)"
	@./uninstall.sh
