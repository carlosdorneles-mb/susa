# 📚 Susa CLI - Documentação

> Documentação oficial do Susa CLI, gerada com [MkDocs](https://www.mkdocs.org/) e tema [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/).

## 🚀 Início Rápido

### Pré-requisitos

- Python 3.8+
- pip (gerenciador de pacotes Python)

### Instalação do Ambiente

```bash
# Instalar ambiente de documentação
make install
```

Este comando irá:
- ✅ Criar ambiente virtual Python
- ✅ Instalar MkDocs e tema Material
- ✅ Instalar todas as extensões necessárias
- ✅ Preparar o ambiente para desenvolvimento

### Comandos Principais

```bash
# 📖 Visualizar documentação localmente (com auto-reload)
make serve
# ou
make docs

# 🔨 Gerar build estático
make build

# 🚀 Deploy para GitHub Pages
make deploy

# 🧹 Limpar arquivos gerados
make clean

# ❓ Ver todos os comandos disponíveis
make help
```

### Preview em Tempo Real

Ao executar `make serve`, o servidor local inicia em http://127.0.0.1:8000 e atualiza automaticamente sempre que você edita os arquivos markdown.

```bash
make serve
# INFO     -  Building documentation...
# INFO     -  Serving on http://127.0.0.1:8000
```

Acesse no navegador e comece a editar! 🎉

---

## 📁 Estrutura da Documentação

```text
docs/
├── index.md                    # 🏠 Página inicial
├── quick-start.md             # ⚡ Guia de início rápido
├── first-steps.md             # 👣 Primeiros passos
│
├── guides/                    # 📖 Guias detalhados
│   ├── features.md           # Funcionalidades principais
│   ├── configuration.md      # Configuração do CLI
│   ├── adding-commands.md    # Como adicionar comandos
│   ├── subcategories.md      # Sistema de subcategorias
│   └── shell-completion.md   # Configurar autocompletar
│
├── plugins/                   # 🔌 Sistema de plugins
│   ├── overview.md           # Visão geral
│   └── architecture.md       # Arquitetura dos plugins
│
├── reference/                 # 📚 Referências técnicas
│   └── libraries.md          # Documentação das bibliotecas
│
└── about/                     # ℹ️ Sobre o projeto
    ├── contributing.md       # Como contribuir
    └── license.md            # Licença MIT
```

---

## ✍️ Editando a Documentação

### Fluxo de Trabalho

1. **Edite** arquivos `.md` no diretório `docs/`
2. **Visualize** as mudanças no navegador (auto-reload)
3. **Commit** suas alterações
4. **Push** para GitHub (deploy automático via Actions)

### Sintaxe Suportada

A documentação suporta Markdown estendido com recursos avançados:

#### Code Blocks com Syntax Highlighting

````markdown
```bash
# Instalar Docker
susa setup docker install

# Verificar versão
docker --version
```

```python
def hello():
    print("Hello, Susa!")
```
````

#### Admonitions (Caixas de Aviso)

```markdown
!!! note "Nota Importante"
    Esta é uma admonição do tipo nota.

!!! warning "Atenção"
    Cuidado com este comando!

!!! tip "Dica"
    Use `susa --help` para ver todos os comandos.

!!! danger "Perigo"
    Esta operação não pode ser desfeita.
```

#### Tabelas

```markdown
| Comando | Descrição | Requer Sudo |
|---------|-----------|-------------|
| `setup docker` | Instala Docker | ✅ |
| `self version` | Mostra versão | ❌ |
```

#### Listas de Tarefas

```markdown
- [x] Tarefa concluída
- [ ] Tarefa pendente
- [ ] Outra tarefa
```

#### Tabs

````markdown
=== "Linux"
    ```bash
    sudo apt-get install package
    ```

=== "macOS"
    ```bash
    brew install package
    ```
````

#### Emojis

Use emojis diretamente: 🎉 🚀 ✨ 💡 ⚠️ 🔧

---

## 🚢 Deploy & Publicação

### Deploy Automático (Recomendado)

O deploy é **totalmente automático** via GitHub Actions:

1. 📝 Edite a documentação
2. 💾 Faça commit e push para `main`
3. 🤖 GitHub Actions executa automaticamente
4. ✅ Documentação atualizada em ~2-3 minutos
5. 🌐 Disponível em: https://carlosdorneles-mb.github.io/susa

**Não é necessário executar `make deploy` manualmente!**

### Deploy Manual (Opcional)

Se preferir fazer deploy manual:

```bash
make deploy
```

Isso irá:
- Construir a documentação
- Fazer push para o branch `gh-pages`
- Publicar no GitHub Pages

---

## 🔧 Configuração

### Arquivo `mkdocs.yml`

O arquivo `mkdocs.yml` na raiz do projeto controla toda a configuração:

```yaml
site_name: Susa CLI               # Nome do site
site_url: https://...             # URL do site

theme:
  name: material                  # Tema Material
  palette:
    primary: indigo               # Cor primária
    accent: indigo                # Cor de destaque
  features:                       # Features habilitadas
    - navigation.tabs
    - navigation.sections
    - search.suggest

nav:                              # Estrutura de navegação
  - Home: index.md
  - Guias:
      - guides/features.md

plugins:                          # Plugins MkDocs
  - search                        # Busca integrada
  - git-revision-date-localized   # Datas de modificação

markdown_extensions:              # Extensões Markdown
  - admonition                    # Caixas de aviso
  - pymdownx.highlight            # Syntax highlighting
  - pymdownx.tabbed               # Tabs
  - pymdownx.emoji                # Emojis
```

### Personalização do Tema

#### Mudar Cores

Edite `mkdocs.yml`:

```yaml
theme:
  palette:
    # Modo claro
    - scheme: default
      primary: teal
      accent: amber
      toggle:
        icon: material/brightness-7
        name: Mudar para modo escuro
    
    # Modo escuro
    - scheme: slate
      primary: teal
      accent: amber
      toggle:
        icon: material/brightness-4
        name: Mudar para modo claro
```

#### Ativar/Desativar Features

```yaml
theme:
  features:
    - navigation.instant          # Loading instantâneo
    - navigation.tracking         # Rastreamento de scroll
    - navigation.tabs            # Navegação em tabs
    - navigation.sections        # Seções expansíveis
    - navigation.top             # Botão "voltar ao topo"
    - search.suggest             # Sugestões de busca
    - search.highlight           # Destaque nos resultados
    - content.code.copy          # Botão copiar em code blocks
```

---

## 📝 Adicionar Nova Página

### Passo a Passo

1. **Crie o arquivo** `.md` no diretório apropriado:

```bash
touch docs/guides/minha-nova-pagina.md
```

2. **Escreva o conteúdo**:

```markdown
# Minha Nova Página

## Introdução

Conteúdo da página...

## Exemplo

```bash
susa comando exemplo
```
```

3. **Adicione à navegação** em `mkdocs.yml`:

```yaml
nav:
  - Home: index.md
  - Guias:
      - features.md
      - Minha Nova Página: guides/minha-nova-pagina.md  # ← Adicione aqui
```

4. **Visualize e verifique**:

```bash
make serve
```

5. **Commit e push**:

```bash
git add docs/guides/minha-nova-pagina.md mkdocs.yml
git commit -m "docs: adicionar página sobre X"
git push
```

---

## 🔍 Sistema de Busca

A busca está **habilitada por padrão** e indexa automaticamente:

- ✅ Todos os títulos e subtítulos
- ✅ Conteúdo completo de todas as páginas
- ✅ Code blocks e exemplos
- ✅ Metadados das páginas

### Melhorar a Busca

Para melhorar os resultados:

```yaml
plugins:
  - search:
      lang: 
        - pt
        - en
      separator: '[\s\-\.]+'
```

---

## 🐛 Solução de Problemas

### Port Já em Uso

Se a porta 8000 já estiver em uso:

```bash
# Opção 1: Usar outra porta
mkdocs serve -a 127.0.0.1:8001

# Opção 2: Editar Makefile
# Altere a linha do comando serve
```

### Build Falha

```bash
# Limpar e reconstruir
make clean
make build

# Se persistir, verificar sintaxe
make build --strict
```

### Erros de Importação Python

```bash
# Remover e reinstalar ambiente
rm -rf venv/
make install
```

### Problemas com Cache

```bash
# Limpar cache do MkDocs
rm -rf site/
rm -rf .cache/
make build
```

### Verificar Integridade

```bash
# Build com verificação estrita
mkdocs build --strict

# Isso irá falhar se houver:
# - Links quebrados
# - Arquivos referenciados inexistentes
# - Erros de sintaxe
```

---

## 🎨 Dicas de Estilo

### Estrutura de Documento

```markdown
# Título Principal (apenas 1 por página)

> Descrição breve opcional

## Seção Principal

Introdução da seção...

### Subseção

Conteúdo...

#### Sub-subseção (evite ir muito fundo)
```

### Uso de Emojis

Use emojis para destacar seções:

- 🚀 Início rápido, instalação
- 📖 Guias, tutoriais
- 🔧 Configuração
- 💡 Dicas, sugestões
- ⚠️ Avisos, cuidados
- ✅ Sucesso, confirmação
- ❌ Erro, falha
- 🔌 Plugins, extensões
- 📦 Pacotes, dependências

### Links Internos

```markdown
<!-- Link para outra página -->
Veja o [guia de features](guides/features.md)

<!-- Link para seção específica -->
Confira a [instalação](quick-start.md#instalação)

<!-- Link absoluto (evite) -->
[Página](https://example.com/page)
```

### Notas de Rodapé

```markdown
Texto com referência[^1].

[^1]: Nota de rodapé detalhada.
```

---

## 📚 Recursos Úteis

### Documentação Oficial

- 📖 [MkDocs Documentation](https://www.mkdocs.org/)
- 🎨 [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)
- 🔧 [Material Setup](https://squidfunk.github.io/mkdocs-material/setup/)
- 📝 [Material Reference](https://squidfunk.github.io/mkdocs-material/reference/)

### Guias e Tutoriais

- 📘 [Markdown Guide](https://www.markdownguide.org/)
- 🎯 [Material Extensions](https://squidfunk.github.io/mkdocs-material/reference/admonitions/)
- 🌈 [Color Palette](https://squidfunk.github.io/mkdocs-material/setup/changing-the-colors/)

### Exemplos

- 🔍 [FastAPI Docs](https://fastapi.tiangolo.com/) - Exemplo de ótima documentação
- 🐍 [Python Docs](https://docs.python.org/) - Documentação técnica clara

---

## 🤝 Contribuindo

Quer melhorar a documentação? Ótimo!

1. 🍴 Fork o repositório
2. 🌿 Crie uma branch (`git checkout -b docs/melhoria`)
3. ✍️ Faça suas alterações
4. 👀 Visualize localmente (`make serve`)
5. 💾 Commit suas mudanças (`git commit -m 'docs: melhorar página X'`)
6. 📤 Push para o GitHub (`git push origin docs/melhoria`)
7. 🔀 Abra um Pull Request

Veja mais detalhes em [Contributing](about/contributing.md).

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja [LICENSE](about/license.md) para mais detalhes.
