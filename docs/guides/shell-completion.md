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
# Para Zsh
rm -f ~/.zcompdump*  # Limpa cache (recomendado)
source ~/.zshrc

# Para Bash
source ~/.bashrc

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

### 3. **Filtragem por Sistema Operacional** 🆕

O completion **filtra automaticamente** comandos baseado no OS:

**Processo:**

1. Detecta o OS atual (`linux` ou `mac`)
2. Para cada comando, verifica o arquivo `config.yaml`
3. Lê o campo `os: ["linux", "mac"]`
4. Oculta comandos incompatíveis com o OS atual

**Exemplo prático:**

```yaml
# commands/setup/iterm/config.yaml
os: ["mac"]  # Apenas macOS
```

```yaml
# commands/setup/tilix/config.yaml
os: ["linux"]  # Apenas Linux
```

**Resultado:**

```bash
# No Linux
susa setup <TAB>
# ✅ Mostra: tilix, docker, podman, mise...
# ❌ Oculta: iterm (exclusivo Mac)

# No macOS
susa setup <TAB>
# ✅ Mostra: iterm, docker, podman, mise...
# ❌ Oculta: tilix (exclusivo Linux)
```

### 4. **Sugestões Inteligentes**

- Remove duplicatas automaticamente
- Ordena alfabeticamente
- Funciona em múltiplos níveis de subcategorias
- Filtra comandos por compatibilidade de OS

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

### Comandos incompatíveis aparecem no completion

**Sintoma:** Comandos específicos de outros sistemas operacionais aparecem (ex: iTerm no Linux, Tilix no macOS)

**Causa:** Completion instalado de versão antiga que não suporta filtragem por OS

**Solução:** Reinstale o completion:

```bash
susa self completion --uninstall
susa self completion --install
# Para Zsh, limpe o cache
rm -f ~/.zcompdump*
exec $SHELL
```

**Verificação:** No Linux, `susa setup <TAB>` NÃO deve mostrar `iterm`. No macOS, NÃO deve mostrar `tilix`.

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
2. Detecta o sistema operacional atual (Linux ou macOS)
3. Lista diretórios em `commands/` e `plugins/`
4. Para cada comando, verifica compatibilidade de OS:
   - Lê `config.yaml` do comando
   - Verifica campo `os: [...]` (suporta formatos inline e multi-linha)
   - Filtra comandos incompatíveis

    **Formatos suportados de `os` em config.yaml:**

    ```yaml
    # Formato inline (compacto)
    os: ["mac"]
    os: ["linux", "mac"]

    # Formato multi-linha (legível)
    os:
    - mac
    - linux
    ```

    **⚠️ Nota importante:** Comandos sem `config.yaml` são sempre exibidos no completion, independente do sistema operacional. Isso é intencional para permitir comandos multiplataforma simples.

5. Filtra apenas diretórios (ignora arquivos como `config.yaml`)
6. Remove duplicatas
7. Retorna sugestões ordenadas e compatíveis com o SO atual

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

### Preciso reinstalar após atualizar o Susa CLI?

**Sim, recomendado!** Se a versão incluir melhorias no completion (como a filtragem por OS), reinstale para obter as atualizações:

```bash
susa self completion --uninstall
susa self completion --install
# Limpar cache do Zsh (se aplicável)
rm -f ~/.zcompdump* 2>/dev/null || true
exec $SHELL
```

**⚠️ Importante:** Versões antigas do completion podem não filtrar corretamente comandos por SO. Se você vê comandos incompatíveis (ex: iTerm no Linux), reinstale o completion.

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
susa self completion --uninstall
susa self completion --install
source ~/.zshrc  # ou ~/.bashrc
```

### Como verificar se o filtro de OS está funcionando?

**No Linux:**

```bash
susa setup <TAB>
# ✅ Deve mostrar: docker, podman, tilix, mise, poetry, uv...
# ❌ NÃO deve mostrar: iterm (exclusivo macOS)
```

**No macOS:**

```bash
susa setup <TAB>
# ✅ Deve mostrar: docker, podman, iterm, mise, poetry, uv...
# ❌ NÃO deve mostrar: tilix (exclusivo Linux)
```

Se comandos incompatíveis aparecerem, reinstale o completion.

---

**Dica:** O completion é especialmente útil quando você tem muitos comandos e subcategorias. Use TAB frequentemente para descobrir o que está disponível! 🚀
