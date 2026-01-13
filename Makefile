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
	@pip install mkdocs-material
	@pip install pymdown-extensions
	@pip install mkdocs-awesome-pages-plugin
	@pip install mkdocs-glightbox
	@pip install mkdocs-panzoom-plugin
	@pip install mkdocs-include-markdown-plugin

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
	@if command -v susa &> /dev/null; then \
		echo "$(YELLOW)⚠️  SUSA já está instalado$(NC)"; \
		read -p "Deseja reinstalar? (s/N): " response; \
		if [ "$$response" = "s" ] || [ "$$response" = "S" ]; then \
			echo "$(GREEN)🚀 Reinstalando CLI...$(NC)"; \
			./install.sh; \
		else \
			echo "$(BLUE)ℹ️  Instalação cancelada$(NC)"; \
		fi \
	else \
		echo "$(GREEN)🚀 Instalando CLI...$(NC)"; \
		./install.sh; \
	fi

cli-uninstall: ## Remove o CLI do sistema
	@echo "$(YELLOW)🗑️  Desinstalando CLI...$(NC)"
	@./uninstall.sh

# Development
new-command: ## Cria um novo comando
	@read -p "Categoria do comando (ex: setup, utils): " category; \
	read -p "ID do comando (ex: tilix, cleanup): " id; \
	./create_command.sh "$$category" "$$id"
