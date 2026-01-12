# 📚 Documentação do Projeto

Documentação gerada com [MkDocs](https://www.mkdocs.org/) e tema [Material](https://squidfunk.github.io/mkdocs-material/).

## 🚀 Quick Start

### Instalação

```bash
make install
```

Isso irá:

- Criar ambiente virtual Python
- Instalar MkDocs e dependências
- Preparar o ambiente para desenvolvimento

### Desenvolvimento Local

```bash
# Iniciar servidor local (http://127.0.0.1:8000)
make serve
# ou
make docs
# ou
make doc

# Build estático
make build

# Deploy para GitHub Pages
make deploy

# Limpar arquivos gerados
make clean
```

### Ver Comandos Disponíveis

```bash
make help
```

### Preview em Tempo Real

O servidor local (`make serve`) atualiza automaticamente quando você edita os arquivos markdown.

## 📁 Estrutura

```text
docs/
├── index.md                  # Página inicial
├── quick-start.md           # Guia rápido
├── first-steps.md           # Primeiros passos
├── guides/                  # Guias detalhados
│   ├── subcategories.md
│   ├── adding-commands.md
│   └── features.md
├── plugins/                 # Sistema de plugins
│   ├── overview.md
│   └── architecture.md
├── reference/               # Referências
│   └── changelog-v2.md
└── about/                   # Sobre o projeto
    ├── contributing.md
    └── license.md
```

## ✍️ Editando Documentação

1. Edite arquivos `.md` no diretório `docs/`
2. Verifique no navegador (auto-reload)
3. Commit suas mudanças

### Sintaxe Markdown

A documentação suporta:

- ✅ Markdown padrão
- ✅ Code blocks com syntax highlighting
- ✅ Admonitions (caixas de nota, aviso, etc)
- ✅ Tabelas
- ✅ Listas de tarefas
- ✅ Tabs
- ✅ Emojis

Exemplos:

````markdown
```bash
# Code block com highlight
susa setup docker
```

!!! note "Nota"
    Isto é uma admonição

| Coluna 1 | Coluna 2 |
|----------|----------|
| Valor 1  | Valor 2  |
````

## 🚢 Deploy

### GitHub Pages (Automático)

O deploy é automático via GitHub Actions quando você faz push para `main`:

1. Edite documentação
2. Commit e push
3. GitHub Actions roda automaticamente
4. Documentação atualizada em poucos minutos

### Deploy Manual

```bash
make deploy
```

## 🔧 Configuração

### mkdocs.yml

Arquivo principal de configuração:

- `site_name`: Nome do site
- `theme`: Configuração do tema Material
- `nav`: Estrutura de navegação
- `plugins`: Plugins habilitados
- `markdown_extensions`: Extensões markdown

### Tema Material

Veja [documentação completa](https://squidfunk.github.io/mkdocs-material/) para personalização avançada.

## 📝 Adicionar Nova Página

1. Crie arquivo `.md` em `docs/`
2. Adicione à navegação em `mkdocs.yml`:

```yaml
nav:
  - Home: index.md
  - Nova Página: minha-pagina.md
```

3. Build e verifique

## 🔍 Busca

A busca está habilitada por padrão e indexa todo o conteúdo automaticamente.

## 🎨 Customização

### Cores

Edite `mkdocs.yml`:

```yaml
theme:
  palette:
    primary: indigo  # Cor primária
    accent: indigo   # Cor de destaque
```

### Features

Ative/desative features em `mkdocs.yml`:

```yaml
theme:
  features:
    - navigation.tabs
    - navigation.sections
    - search.suggest
```

## 🐛 Troubleshooting

### Ver comandos disponíveis

```bash
make help
```

### Port já em uso

Edite o Makefile ou rode diretamente:

```bash
source venv/bin/activate
mkdocs serve -a 127.0.0.1:8001
```

### Build falha

```bash
make clean
make build
```

### Reinstalar ambiente

```bash
make clean
make install
```

## 📖 Recursos

- [MkDocs Documentation](https://www.mkdocs.org/)
- [Material Theme](https://squidfunk.github.io/mkdocs-material/)
- [Markdown Guide](https://www.markdownguide.org/)
