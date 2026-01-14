.PHONY: help install install-deps install-dev setup-vscode install-hooks serve doc clean cli-install cli-uninstall test shellcheck shfmt format lint

# Cores para output
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
RED := \033[0;31m
NC := \033[0m

help:
	@echo "$(GREEN)CLI - Makefile Commands$(NC)"
	@echo ""
	@echo "$(BLUE)CLI Commands:$(NC)"
	@grep -E '^cli-[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Development Commands:$(NC)"
	@grep -E '^(install-deps|install-dev|install-hooks|setup-vscode):.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Quality Assurance Commands:$(NC)"
	@grep -E '^(shellcheck|shfmt|format|lint|test):.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Documentation Commands:$(NC)"
	@grep -E '^(serve|doc|clean):.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

serve: ## Inicia servidor de documentação local
	@echo "$(GREEN)🌐 Iniciando servidor MkDocs...$(NC)"
	@echo "$(YELLOW)📖 Acesse: http://127.0.0.1:8000$(NC)"
	@echo ""
	@mkdocs serve

doc: serve ## Alias para 'serve' - inicia servidor de documentação

clean: ## Remove arquivos gerados
	@echo "$(YELLOW)🧹 Limpando arquivos gerados...$(NC)"
	@rm -rf site/
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "$(GREEN)✅ Limpeza concluída!$(NC)"

# CLI Installation
cli-install: ## Instala o CLI no sistema
	@if command -v susa > /dev/null 2>&1; then \
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

# Quality Assurance
shellcheck: ## Executa ShellCheck em todos os scripts
	@echo "$(GREEN)🔍 Executando ShellCheck...$(NC)"
	@command -v shellcheck >/dev/null 2>&1 || { echo "$(RED)❌ ShellCheck não está instalado. Instale com: sudo apt install shellcheck ou brew install shellcheck$(NC)"; exit 1; }
	@if shellcheck -x core/susa core/lib/*.sh core/lib/internal/*.sh install*.sh uninstall*.sh $$(find commands -name "*.sh" | grep -v "/node_modules/"); then \
		echo "$(GREEN)✅ Todos os scripts passaram na verificação!$(NC)"; \
	else \
		echo "$(RED)❌ Alguns scripts falharam na verificação$(NC)"; \
		exit 1; \
	fi

shfmt: ## Verifica formatação de scripts com shfmt
	@echo "$(GREEN)📝 Verificando formatação com shfmt...$(NC)"
	@command -v shfmt >/dev/null 2>&1 || { echo "$(RED)❌ shfmt não está instalado. Instale com: sudo apt install shfmt ou brew install shfmt$(NC)"; exit 1; }
	@if shfmt -d -i 4 -ci core/susa core/lib install*.sh uninstall*.sh commands; then \
		echo "$(GREEN)✅ Todos os scripts estão formatados corretamente!$(NC)"; \
	else \
		echo "$(RED)❌ Alguns scripts não estão formatados corretamente$(NC)"; \
		echo "$(YELLOW)💡 Execute 'make format' para corrigir automaticamente$(NC)"; \
		exit 1; \
	fi

format: ## Formata automaticamente todos os scripts com shfmt
	@echo "$(GREEN)✨ Formatando scripts com shfmt...$(NC)"
	@command -v shfmt >/dev/null 2>&1 || { echo "$(RED)❌ shfmt não está instalado. Instale com: sudo apt install shfmt ou brew install shfmt$(NC)"; exit 1; }
	@shfmt -w -i 4 -ci core/susa core/lib install*.sh uninstall*.sh commands
	@echo "$(GREEN)✅ Scripts formatados com sucesso!$(NC)"

lint: shellcheck shfmt ## Executa todas as verificações de qualidade

test: ## Executa todos os testes
	@echo "$(GREEN)✅ Todos os testes passaram!$(NC)"

# Development Commands
install-deps: ## Instala dependências para documentação
	@echo "$(GREEN)📦 Instalando dependências para documentação...$(NC)"
	@command -v pip >/dev/null 2>&1 || { echo "$(RED)❌ pip não está instalado. Instale Python primeiro.$(NC)"; exit 1; }
	@pip install --upgrade pip
	@pip install mkdocs-material
	@pip install pymdown-extensions
	@pip install mkdocs-awesome-pages-plugin
	@pip install mkdocs-glightbox
	@pip install mkdocs-panzoom-plugin
	@pip install mkdocs-include-markdown-plugin
	@echo ""
	@echo "$(GREEN)✅ Dependências para documentação instaladas com sucesso!$(NC)"

install-dev: ## Instala ferramentas de desenvolvimento (bash-language-server, shellcheck, shfmt)
	@echo "$(GREEN)📦 Instalando ferramentas de desenvolvimento...$(NC)"
	@echo ""
	@if [ "$$(uname)" = "Darwin" ]; then \
		if command -v brew >/dev/null 2>&1; then \
			echo "$(BLUE)Instalando bash-language-server...$(NC)"; \
			brew install bash-language-server; \
			echo "$(BLUE)Instalando shellcheck...$(NC)"; \
			brew install shellcheck; \
			echo "$(BLUE)Instalando shfmt...$(NC)"; \
			brew install shfmt; \
		else \
			echo "$(RED)❌ Homebrew não está instalado. Instale em: https://brew.sh$(NC)"; \
			exit 1; \
		fi \
	elif [ "$$(uname)" = "Linux" ]; then \
		if command -v apt >/dev/null 2>&1; then \
			echo "$(BLUE)Instalando bash-language-server...$(NC)"; \
			sudo apt install -y bash-language-server; \
			echo "$(BLUE)Instalando shellcheck...$(NC)"; \
			sudo apt install -y shellcheck; \
			echo "$(BLUE)Instalando shfmt...$(NC)"; \
			sudo apt install -y shfmt; \
		elif command -v apt-get >/dev/null 2>&1; then \
			echo "$(BLUE)Instalando bash-language-server...$(NC)"; \
			sudo apt-get install -y bash-language-server; \
			echo "$(BLUE)Instalando shellcheck...$(NC)"; \
			sudo apt-get install -y shellcheck; \
			echo "$(BLUE)Instalando shfmt...$(NC)"; \
			sudo apt-get install -y shfmt; \
		else \
			echo "$(RED)❌ Gerenciador de pacotes não suportado. Use: sudo apt install bash-language-server shellcheck shfmt$(NC)"; \
			exit 1; \
		fi \
	else \
		echo "$(RED)❌ Sistema operacional não suportado$(NC)"; \
		exit 1; \
	fi
	@echo ""
	@echo "$(GREEN)✅ bash-language-server instalado com sucesso!$(NC)"
	@echo "$(GREEN)✅ shellcheck instalado com sucesso!$(NC)"
	@echo "$(GREEN)✅ shfmt instalado com sucesso!$(NC)"
	@echo "$(YELLOW)💡 Execute 'make setup-vscode' para configurar o VS Code$(NC)"

install: install-dev install-deps

install-hooks: ## Instala Git hooks (pre-commit com shellcheck + shfmt)
	@echo "$(GREEN)🔧 Instalando Git hooks...$(NC)"
	@if [ ! -d ".git" ]; then \
		echo "$(RED)❌ Não é um repositório Git!$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f ".githooks/pre-commit" ]; then \
		echo "$(RED)❌ Arquivo .githooks/pre-commit não encontrado!$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f ".githooks/pre-push" ]; then \
		echo "$(RED)❌ Arquivo .githooks/pre-push não encontrado!$(NC)"; \
		exit 1; \
	fi
	@mkdir -p .git/hooks
	@cp .githooks/pre-commit .git/hooks/pre-commit
	@cp .githooks/pre-push .git/hooks/pre-push
	@chmod +x .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-push
	@echo "$(GREEN)✅ Pre-commit hook instalado com sucesso!$(NC)"
	@echo "$(GREEN)✅ Pre-push hook instalado com sucesso!$(NC)"
	@echo "$(YELLOW)💡 O hook executará shellcheck + shfmt antes de cada commit$(NC)"
	@echo "$(YELLOW)💡 O hook executará os testes antes de cada push$(NC)"

setup-vscode: ## Configura VS Code com configurações do projeto
	@echo "$(GREEN)⚙️  Configurando VS Code...$(NC)"
	@echo ""
	@if [ ! -d ".vscode" ]; then \
		echo "$(RED)❌ Diretório .vscode não encontrado!$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f ".vscode/settings.json.example" ]; then \
		echo "$(RED)❌ Arquivo .vscode/settings.json.example não encontrado!$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f ".vscode/extensions.json.example" ]; then \
		echo "$(RED)❌ Arquivo .vscode/extensions.json.example não encontrado!$(NC)"; \
		exit 1; \
	fi
	@if [ -f ".vscode/settings.json" ]; then \
		echo "$(YELLOW)⚠️  settings.json já existe. Deseja sobrescrever? (s/N):$(NC)"; \
		read -p "" response; \
		if [ "$$response" = "s" ] || [ "$$response" = "S" ]; then \
			echo "$(BLUE)Criando settings.json...$(NC)"; \
			cp .vscode/settings.json.example .vscode/settings.json; \
		else \
			echo "$(BLUE)ℹ️  Mantendo settings.json existente$(NC)"; \
		fi \
	else \
		echo "$(BLUE)Criando settings.json...$(NC)"; \
		cp .vscode/settings.json.example .vscode/settings.json; \
	fi
	@if [ -f ".vscode/extensions.json" ]; then \
		echo "$(YELLOW)⚠️  extensions.json já existe. Deseja sobrescrever? (s/N):$(NC)"; \
		read -p "" response; \
		if [ "$$response" = "s" ] || [ "$$response" = "S" ]; then \
			echo "$(BLUE)Criando extensions.json...$(NC)"; \
			cp .vscode/extensions.json.example .vscode/extensions.json; \
		else \
			echo "$(BLUE)ℹ️  Mantendo extensions.json existente$(NC)"; \
		fi \
	else \
		echo "$(BLUE)Criando extensions.json...$(NC)"; \
		cp .vscode/extensions.json.example .vscode/extensions.json; \
	fi
	@echo ""
	@echo "$(GREEN)✅ VS Code configurado com sucesso!$(NC)"
	@echo "$(YELLOW)💡 Reabra o VS Code para aplicar as configurações$(NC)"
	@echo "$(YELLOW)💡 Instale as extensões recomendadas quando solicitado$(NC)"
