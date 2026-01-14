# Shell Completion (Autocompletar)

O Susa CLI oferece suporte completo a autocompletar (tab completion) para os shells **Bash**, **Zsh** e **Fish**, permitindo que você complete comandos, categorias e subcategorias pressionando a tecla **TAB**.

---

## 🎯 O que é Shell Completion?

Shell completion é um recurso que permite autocompletar comandos ao pressionar TAB. Com ele você pode:

- ✅ Listar todas as categorias disponíveis: `susa <TAB>`
- ✅ Listar comandos de uma categoria: `susa setup <TAB>`
- ✅ Navegar por subcategorias: `susa setup python <TAB>`
- ✅ Descobrir comandos de plugins instalados automaticamente

---

## 🚀 Instalação

### Instalação Automática

O completion detecta seu shell automaticamente e instala a configuração necessária:

```bash
susa self completion --install
```

Depois, recarregue seu shell:

```bash
source ~/.zshrc    # Para Zsh
source ~/.bashrc   # Para Bash
# Para Fish não é necessário recarregar, o completion é carregado automaticamente
```

### Instalação para Shell Específico

Se preferir especificar o shell:

```bash
# Para Bash
susa self completion bash --install

# Para Zsh
susa self completion zsh --install

# Para Fish
susa self completion fish --install
```

---

## 📚 Como Usar

### Listar Categorias

Pressione TAB após digitar `susa`:

```bash
susa <TAB><TAB>

# Resultado:
self    setup
```

### Listar Comandos de uma Categoria

```bash
susa setup <TAB>

# Resultado (exemplo):
asdf    docker    nodejs    python
```

### Navegar Subcategorias

```bash
susa setup python <TAB>

# Resultado (se houver subcategorias):
pip    tools    venv
```

### Autocompletar Parcial

Digite parte do nome e pressione TAB:

```bash
susa se<TAB>

# Completa automaticamente para:
susa self
```

---

## 🔧 Comandos Disponíveis

### Instalar Completion

```bash
# Detecção automática do shell
susa self completion --install

# Shell específico
susa self completion bash --install
susa self completion zsh --install
susa self completion fish --install
```

### Visualizar Script de Completion

Para ver o script gerado sem instalar:

```bash
# Bash
susa self completion bash --print

# Zsh
susa self completion zsh --print

# Fish
susa self completion fish --print
```

### Desinstalar Completion

Remove os scripts de completion instalados:

```bash
susa self completion --uninstall
```

---

## 🎨 Como Funciona

O completion funciona de forma **dinâmica**, lendo a estrutura de diretórios em tempo real:

### 1. **Detecção de Comandos Nativos**

Lista diretórios em `commands/`:

```text
commands/
  setup/         → Categoria
    asdf/        → Comando
    docker/      → Comando
  self/          → Categoria
    completion/  → Comando
    version/     → Comando
```

### 2. **Detecção de Plugins**

Lista também comandos de plugins instalados:

```text
plugins/
  meu-plugin/
    deploy/      → Categoria do plugin
      app/       → Comando do plugin
```

### 3. **Sugestões Inteligentes**

- Remove duplicatas automaticamente
- Ordena alfabeticamente
- Funciona em múltiplos níveis de subcategorias

---

## 🛠️ Solução de Problemas

### Completion não funciona após instalação

**Solução:** Recarregue o shell ou reinicie o terminal

```bash
# Zsh
source ~/.zshrc

# Bash
source ~/.bashrc
```

### TAB não mostra sugestões

**Verifique se o arquivo foi criado:**

```bash
# Bash
ls -l ~/.local/share/bash-completion/completions/susa

# Zsh
ls -l ~/.local/share/zsh/site-functions/_susa
```

**Se não existir, reinstale:**

```bash
susa self completion --install
```

### Erro "command not found: susa"

O completion precisa que o comando `susa` esteja no PATH. Verifique:

```bash
which susa
```

Se não encontrar, certifique-se de que `~/.local/bin` está no PATH:

```bash
echo $PATH | grep ".local/bin"
```

---

## 📋 Shells Suportados

| Shell | Status | Comando |
| ----- | ------ | ------- |
| **Bash** | ✅ Suportado | `susa self completion bash --install` |
| **Zsh** | ✅ Suportado | `susa self completion zsh --install` |

---

## 🔍 Detalhes Técnicos

### Localização dos Arquivos

**Bash:**

```text
~/.local/share/bash-completion/completions/susa
```

**Zsh:**

```text
~/.local/share/zsh/site-functions/_susa
```

### Carregamento Automático

**Bash:**

- Carrega automaticamente de `~/.local/share/bash-completion/completions/`
- Não precisa adicionar nada no `.bashrc` manualmente

**Zsh:**

- O instalador adiciona o diretório ao `fpath` no `.zshrc`:

  ```bash
  fpath=(~/.local/share/zsh/site-functions $fpath)
  autoload -Uz compinit && compinit
  ```

### Completion Dinâmico

O script de completion:

1. Detecta onde o Susa CLI está instalado
2. Lista diretórios em `commands/` e `plugins/`
3. Filtra apenas diretórios (ignora arquivos como `config.yaml`)
4. Remove duplicatas
5. Retorna sugestões ordenadas

---

## 💡 Exemplos Práticos

### Descobrir Comandos Disponíveis

```bash
# Listar todas as categorias
susa <TAB><TAB>

# Ver comandos de setup
susa setup <TAB>

# Navegar em subcategorias
susa setup python tools <TAB>
```

### Completar Rapidamente

```bash
# Digite parte e pressione TAB
susa se<TAB>         → susa self
susa self ve<TAB>    → susa self version
susa self co<TAB>    → susa self completion
```

### Descobrir Comandos de Plugins

```bash
# Após instalar um plugin, ele aparece automaticamente
susa self plugin add user/plugin-repo

# O completion detecta novos comandos
susa <TAB>  # Mostra categorias do plugin também
```

---

## 📚 Recursos Relacionados

- [Adicionar Comandos](adding-commands.md) - Como criar novos comandos
- [Sistema de Plugins](../plugins/overview.md) - Instalar plugins
- [Configuração](configuration.md) - Configurar o Susa CLI
- [Funcionalidades](features.md) - Visão geral completa

---

## ❓ FAQ

### Preciso reinstalar o completion após adicionar um comando?

**Não!** O completion é dinâmico e detecta novos comandos automaticamente.

### O completion funciona com plugins?

**Sim!** O completion detecta automaticamente comandos de plugins instalados.

### Posso ter completion em múltiplos shells?

**Sim!** Você pode instalar para bash e zsh simultaneamente:

```bash
susa self completion bash --install
susa self completion zsh --install
```

### Como atualizar o completion?

Reinstale para atualizar:

```bash
susa self completion --install
source ~/.zshrc  # ou ~/.bashrc
```

---

**Dica:** O completion é especialmente útil quando você tem muitos comandos e subcategorias. Use TAB frequentemente para descobrir o que está disponível! 🚀
