# Setup Poetry

Instala o Poetry, um gerenciador de dependências e empacotamento para Python que facilita o gerenciamento de bibliotecas, criação de ambientes virtuais e publicação de pacotes.

## O que é Poetry?

Poetry é uma ferramenta moderna para gerenciamento de dependências Python que simplifica o processo de:

- **Gerenciamento de Dependências**: Adicione, remova e atualize pacotes facilmente
- **Ambientes Virtuais**: Criação automática e gerenciamento de virtualenvs
- **Empacotamento**: Build e publicação de pacotes no PyPI
- **Lock Files**: Garantia de builds reproduzíveis com poetry.lock
- **Resolução de Dependências**: Solver inteligente para evitar conflitos

**Por exemplo:**

```python
# pyproject.toml
[tool.poetry]
name = "meu-projeto"
version = "0.1.0"

[tool.poetry.dependencies]
python = "^3.9"
requests = "^2.28.0"
pandas = "^1.5.0"
```

## Como usar

### Instalar

```bash
susa setup poetry
```

O comando vai:

- Baixar o instalador oficial do Poetry
- Instalar o Poetry em `~/.local/share/pypoetry`
- Configurar o PATH no seu shell (bash ou zsh)
- Verificar a instalação

Depois de instalar, reinicie o terminal ou execute:

```bash
source ~/.bashrc  # ou ~/.zshrc
```

### Atualizar

```bash
susa setup poetry --update
```

Atualiza o Poetry para a versão mais recente usando o comando `poetry self update`. Todas as suas configurações serão preservadas.

### Desinstalar

```bash
susa setup poetry --uninstall
```

Remove o Poetry do sistema. Você terá a opção de também remover o cache e configurações salvas em `~/.cache/pypoetry` e `~/.config/pypoetry`.

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda detalhada |
| `--update` | Atualiza o Poetry para a versão mais recente |
| `--uninstall` | Remove o Poetry do sistema |
| `-v, --verbose` | Habilita saída detalhada para depuração |
| `-q, --quiet` | Minimiza a saída, desabilita mensagens de depuração |

## Guia Rápido de Uso

### Comandos Essenciais

**Criar Novo Projeto**

```bash
# Criar projeto do zero
poetry new meu-projeto
cd meu-projeto

# Ou inicializar em diretório existente
poetry init
```

**Gerenciar Dependências**

```bash
# Adicionar dependência
poetry add requests

# Adicionar dependência de desenvolvimento
poetry add --group dev pytest black

# Adicionar com versão específica
poetry add "django>=4.0,<5.0"

# Remover dependência
poetry remove requests
```

**Instalar e Executar**

```bash
# Instalar todas as dependências
poetry install

# Executar scripts no ambiente
poetry run python script.py
poetry run pytest

# Ativar shell no ambiente virtual
poetry shell
```

**Atualizar Dependências**

```bash
# Atualizar todas as dependências
poetry update

# Atualizar dependência específica
poetry update requests

# Ver dependências desatualizadas
poetry show --outdated
```

### Configuração Inicial

**1. Criar um Novo Projeto**

```bash
poetry new meu-projeto
cd meu-projeto
```

Estrutura criada:

```text
meu-projeto/
├── meu_projeto/
│   └── __init__.py
├── tests/
│   └── __init__.py
├── pyproject.toml
└── README.md
```

**2. Configurar pyproject.toml**

```toml
[tool.poetry]
name = "meu-projeto"
version = "0.1.0"
description = "Meu projeto incrível"
authors = ["Seu Nome <email@example.com>"]
readme = "README.md"

[tool.poetry.dependencies]
python = "^3.9"
requests = "^2.28.0"

[tool.poetry.group.dev.dependencies]
pytest = "^7.2.0"
black = "^22.10.0"
flake8 = "^6.0.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

**3. Instalar Dependências**

```bash
poetry install
```

Isso vai:

- Resolver todas as dependências
- Criar/atualizar poetry.lock
- Criar ambiente virtual automaticamente
- Instalar todos os pacotes

## Recursos Avançados

### 1. Grupos de Dependências

Organize dependências por contexto:

```toml
[tool.poetry.dependencies]
python = "^3.9"
requests = "^2.28.0"

[tool.poetry.group.dev.dependencies]
pytest = "^7.2.0"
black = "^22.10.0"

[tool.poetry.group.docs.dependencies]
mkdocs = "^1.4.0"
mkdocs-material = "^9.0.0"
```

Instalar grupos específicos:

```bash
# Instalar apenas dependências principais
poetry install --only main

# Instalar sem grupo dev
poetry install --without dev

# Instalar apenas grupo docs
poetry install --only docs
```

### 2. Scripts Personalizados

Defina scripts customizados no pyproject.toml:

```toml
[tool.poetry.scripts]
start = "meu_projeto.main:main"
test = "pytest"
format = "black ."
```

Execute:

```bash
poetry run start
poetry run test
poetry run format
```

### 3. Ambientes Virtuais

Gerenciar virtualenvs:

```bash
# Ver localização do virtualenv
poetry env info

# Listar virtualenvs
poetry env list

# Remover virtualenv
poetry env remove python3.9

# Usar Python específico
poetry env use python3.11
```

Configurar localização:

```bash
# Criar virtualenv dentro do projeto
poetry config virtualenvs.in-project true

# Ver configurações
poetry config --list
```

### 4. Publicar Pacotes

Prepare e publique no PyPI:

```bash
# Build do pacote
poetry build

# Publicar no PyPI
poetry publish

# Ou tudo de uma vez
poetry publish --build

# Usar repositório de teste
poetry publish -r testpypi
```

Configurar credenciais:

```bash
# Adicionar token do PyPI
poetry config pypi-token.pypi seu-token-aqui

# Adicionar repositório customizado
poetry config repositories.mypypi https://pypi.example.com
```

### 5. Dependency Sources

Usar fontes alternativas:

```toml
[[tool.poetry.source]]
name = "private"
url = "https://pypi.example.com/simple"
priority = "primary"

[[tool.poetry.source]]
name = "pytorch"
url = "https://download.pytorch.org/whl/cpu"
priority = "supplemental"
```

### 6. Lock File

Gerenciar poetry.lock:

```bash
# Atualizar lock sem instalar
poetry lock --no-update

# Verificar se lock está atualizado
poetry check

# Exportar para requirements.txt
poetry export -f requirements.txt --output requirements.txt

# Sem hashes (mais compatível)
poetry export --without-hashes -o requirements.txt
```

## Configurações Recomendadas

### Performance

```bash
# Cache paralelo para instalações mais rápidas
poetry config installer.parallel true

# Limpar cache antigo
poetry cache clear pypi --all
```

### Ambiente Virtual

```bash
# Criar virtualenv dentro do projeto (.venv)
poetry config virtualenvs.in-project true

# Preferir virtualenvs ativos
poetry config virtualenvs.prefer-active-python true

# Path customizado
poetry config virtualenvs.path ~/virtualenvs
```

### Comportamento

```bash
# Não criar virtualenv automaticamente
poetry config virtualenvs.create false

# Usar sistema Python
poetry config virtualenvs.options.system-site-packages true
```

## Integração com IDEs

### VS Code

Configure o Python interpreter:

1. Abra Command Palette (Ctrl+Shift+P)
2. Digite "Python: Select Interpreter"
3. Escolha o virtualenv do Poetry

Ou adicione ao `.vscode/settings.json`:

```json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python"
}
```

### PyCharm

1. Settings → Project → Python Interpreter
2. Add Interpreter → Existing Environment
3. Selecione: `{project}/.venv/bin/python`

Ou use o Poetry plugin:

- Settings → Plugins → Marketplace
- Procure "Poetry"
- Instale e reinicie

## Comparação com Outras Ferramentas

| Recurso | Poetry | pip + venv | Pipenv | PDM |
|---------|--------|------------|--------|-----|
| **Resolução de deps** | ✅ Excelente | ❌ Manual | ✅ Boa | ✅ Excelente |
| **Lock files** | ✅ poetry.lock | ❌ Não | ✅ Pipfile.lock | ✅ pdm.lock |
| **Pyproject.toml** | ✅ Sim | ❌ Não | ❌ Não | ✅ Sim |
| **Build/Publish** | ✅ Nativo | ❌ Precisa setup.py | ❌ Limitado | ✅ Nativo |
| **Performance** | ✅ Boa | ✅ Rápido | ⚠️ Lenta | ✅ Muito boa |
| **Adoção** | ✅ Alta | ✅ Universal | ⚠️ Média | ⚠️ Crescente |

## Workflows Comuns

### Desenvolvimento Local

```bash
# Setup inicial
poetry install

# Adicionar nova feature
poetry add nova-biblioteca

# Testar
poetry run pytest

# Format código
poetry run black .
poetry run flake8

# Commit e push
git add poetry.lock pyproject.toml
git commit -m "Add nova-biblioteca"
```

### CI/CD

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Poetry
        run: curl -sSL https://install.python-poetry.org | python3 -

      - name: Install dependencies
        run: poetry install

      - name: Run tests
        run: poetry run pytest
```

### Deploy

```bash
# Produção
poetry export -f requirements.txt --output requirements.txt --without-hashes
pip install -r requirements.txt

# Ou com Poetry diretamente
poetry install --only main --no-root
```

## Troubleshooting

### Poetry comando não encontrado

```bash
# Verificar instalação
ls -la ~/.local/share/pypoetry

# Adicionar ao PATH manualmente
export PATH="$HOME/.local/share/pypoetry/bin:$PATH"

# Ou reinstalar
susa setup poetry
```

### Dependências não resolvem

```bash
# Limpar cache
poetry cache clear pypi --all

# Atualizar lock
poetry lock --no-update

# Forçar reinstalação
poetry install --sync
```

### Virtualenv não é criado

```bash
# Verificar configuração
poetry config virtualenvs.create

# Habilitar criação
poetry config virtualenvs.create true

# Criar manualmente
poetry env use python3
```

### Conflito de versões

```bash
# Ver árvore de dependências
poetry show --tree

# Identificar conflitos
poetry check

# Atualizar com resolução
poetry update --lock
```

### Performance lenta

```bash
# Habilitar instalação paralela
poetry config installer.parallel true

# Aumentar workers
poetry config installer.max-workers 10

# Limpar cache
poetry cache clear . --all
```

## Compatibilidade

- **Python**: 3.7 ou superior
- **Sistema Operacional**: Linux, macOS, Windows
- **Formato**: Usa pyproject.toml (PEP 518)
- **Instalação**: Script oficial ou via package manager

## Instaladores Alternativos

### Via pip (não recomendado)

```bash
pip install poetry
```

⚠️ Pode causar conflitos com dependências do sistema

### Via pipx (recomendado se não usar susa)

```bash
pipx install poetry
```

### Via Homebrew (macOS)

```bash
brew install poetry
```

## Links Úteis

- [Site Oficial](https://python-poetry.org/)
- [Documentação](https://python-poetry.org/docs/)
- [GitHub Repository](https://github.com/python-poetry/poetry)
- [PyPI Package](https://pypi.org/project/poetry/)
- [Poetry Plugins](https://github.com/topics/poetry-plugin)
- [Issue Tracker](https://github.com/python-poetry/poetry/issues)

## Próximos Passos

Depois de instalar o Poetry:

1. ✅ Crie seu primeiro projeto com `poetry new`
2. ✅ Configure grupos de dependências (main, dev, docs)
3. ✅ Configure scripts personalizados
4. ✅ Integre com seu IDE (VS Code, PyCharm)
5. ✅ Configure CI/CD com Poetry
6. ✅ Explore plugins do Poetry
7. ✅ Aprenda sobre dependency sources

---

**Dica**: Poetry mantém o poetry.lock versionado para garantir builds reproduzíveis em qualquer ambiente! 🔒
