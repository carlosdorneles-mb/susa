# Sistema de Categorias e Subcategorias Aninhadas

## 📋 Visão Geral

O CLI suporta uma estrutura hierárquica de categorias e subcategorias baseada em diretórios, permitindo organizar comandos em múltiplos níveis de profundidade.

> **📖 Pré-requisito:** Este guia assume que você já conhece os conceitos básicos de estrutura de comandos, `config.yaml` e criação de scripts. Se não, veja primeiro [Como Adicionar Novos Comandos](adding-commands.md).

## 🏗️ Estrutura de Diretórios

### Diferença entre Comandos e Subcategorias

**🔑 Regra Fundamental:** A existência do **script executável** determina o comportamento!

O sistema verifica:

1. Se o diretório tem `config.yaml`
2. Se o `config.yaml` tem o campo `script:` definido
3. Se o arquivo do script existe

**Resultado:**

- **Tem `script:` E arquivo existe** → É um **comando executável**
  - Sistema executa o script
  - Aparece na seção "Commands"

- **Não tem `script:` OU arquivo não existe** → É uma **subcategoria navegável**
  - Sistema permite navegar (listar sub-itens)
  - Aparece na seção "Subcategories"

### Todos usam config.yaml

Tanto comandos quanto subcategorias têm `config.yaml`, mas com campos diferentes:

| Tipo | Campos no config.yaml |
| ---- | --------------------- |
| **Comando** | `name`, `description`, `script` (obrigatório), `sudo`, `os` |
| **Subcategoria** | `name`, `description` (sem campo `script`) |

> **ℹ️ Para detalhes completos sobre campos do config.yaml, veja [Configuração de Comandos](adding-commands.md#3-configurar-o-comando).**

**Vantagens dessa abordagem:**

- ✅ Mais intuitivo: "tem script = é executável"
- ✅ Mais consistente: todos usam o mesmo tipo de arquivo
- ✅ Mais lógico: comandos PRECISAM de script, subcategorias não

### Estrutura Exemplo

```text
commands/
  setup/                            # Categoria principal
    config.yaml                     # name, description (sem script)
    asdf/                           # Comando direto
      config.yaml                   # category, id, name, description, script, sudo, os
      main.sh                       # Script executável
    python/                         # Subcategoria
      config.yaml                   # name, description (sem script)
      pip/                          # Comando
        config.yaml                 # category, id, name, description, script
        main.sh
      poetry/                       # Comando
        config.yaml
        main.sh
      tools/                        # Sub-subcategoria (nível 3)
        config.yaml                 # name, description (sem script)
        venv/                       # Comando nível 3
          config.yaml               # category, id, name, description, script
          main.sh
    nodejs/                         # Subcategoria
      config.yaml                   # name, description (sem script)
      npm/                          # Comando
        config.yaml                 # category, id, name, description, script
        main.sh
```

## 🎯 Navegação

### Comandos de Navegação

```bash
# Listar categorias principais
susa

# Listar subcategorias e comandos de uma categoria
susa setup

# Navegar para uma subcategoria
susa setup python

# Navegar para sub-subcategoria (nível 3)
susa setup python tools

# Executar comando direto
susa setup asdf

# Executar comando em subcategoria
susa setup python pip

# Executar comando em sub-subcategoria
susa setup python tools venv
```

## 📝 Arquivos de Configuração

### Arquivo Único: config.yaml

Todos os itens (categorias, subcategorias e comandos) usam `config.yaml`.
A diferença está nos **campos definidos**.

### 1. Categoria/Subcategoria (Navegável)

Usado para itens que contêm outros itens.

```yaml
name: "Python"
description: "Ferramentas Python"
# SEM campo 'script' = navegável
```

**Localização:** `commands/{categoria}/config.yaml` ou `commands/{categoria}/{subcategoria}/config.yaml`

### 2. Comando (Executável)

Configuração completa de um comando executável.

```yaml
name: "Pip"
description: "Instala gerenciador de pacotes Python (pip)"
script: "main.sh"        # ← Este campo indica que é executável
sudo: false              # true = exibe indicador [sudo] na listagem
os: ["linux", "mac"]
```

**Localização:** `commands/{categoria}/.../{comando}/config.yaml`

**Importante:** O arquivo definido em `script:` DEVE existir e ter permissão de execução.

## ✨ Campos de Configuração

> **📖 Referência completa:** Veja [Configuração de Comandos](adding-commands.md#3-configurar-o-comando) para detalhes sobre todos os campos disponíveis.

### Resumo Rápido

**Para Comandos (Executáveis):**

- Devem ter o campo `script:` apontando para um arquivo executável
- Exemplo: `script: "main.sh"`

**Para Subcategorias (Navegáveis):**

- NÃO devem ter o campo `script`
- Apenas `name` e `description`

### Lista de Categoria com Subcategorias

```text
Instalar software (Ubuntu)

Usage: susa setup <command> [options]

Subcategories:
  nodejs          Ferramentas Node.js
  python          Ferramentas Python

Commands:
  asdf            Instala ASDF Version Manager
```

### Lista de Subcategoria

```text
Ferramentas Python

Usage: susa setup/python <command> [options]

Subcategories:
  tools           Ferramentas Python Avançadas

Commands:
  pip             Instala gerenciador de pacotes Python (pip)
  poetry          Instala Poetry (gerenciador de dependências Python)
```

## 🚀 Como Adicionar Comandos em Hierarquias

> **📖 Para criar comandos simples**, veja [Como Adicionar Novos Comandos](adding-commands.md). Esta seção foca em **estruturas hierárquicas** com subcategorias.

### 1. Comando em Categoria Existente

> Veja [guia básico](adding-commands.md#passos-para-adicionar-um-comando) para detalhes.

**Resumo:**

```bash
mkdir -p commands/setup/comando-novo
# Criar config.yaml e main.sh conforme guia básico
```

### 2. Comando em Nova Subcategoria

A diferença principal: criar um `config.yaml` **sem** campo `script` para a subcategoria.

```bash
# Criar estrutura
mkdir -p commands/install/nova-categoria/comando-xyz

# Criar configuração da subcategoria (SEM campo 'script')
cat > commands/install/nova-categoria/config.yaml << EOF
name: "Nova Categoria"
description: "Descrição da nova categoria"
# Sem campo 'script' = subcategoria navegável
EOF

# Criar configuração do comando (COM campo 'script')
cat > commands/install/nova-categoria/comando-xyz/config.yaml << EOF
name: "Comando XYZ"
description: "Descrição do comando XYZ"
script: "main.sh"       # ← Indica que é executável
sudo: false
EOF

# Criar script
cat > commands/install/nova-categoria/comando-xyz/main.sh << 'EOF'
#!/bin/bash
echo "Executando XYZ!"
EOF

# Tornar executável
chmod +x commands/setup/nova-categoria/comando-xyz/main.sh
```

**Uso:** `./susa setup nova-categoria comando-xyz`

### 3. Comando em Sub-Subcategoria (3 níveis)

```bash
# Criar estrutura completa
mkdir -p commands/install/categoria/subcategoria/comando

# Criar config.yaml para cada nível navegável
cat > commands/install/categoria/config.yaml << EOF
name: "Categoria"
description: "Nível 1"
EOF

cat > commands/install/categoria/subcategoria/config.yaml << EOF
name: "Subcategoria"
description: "Nível 2"
EOF

# Criar comando executável (COM campo 'script')
cat > commands/install/categoria/subcategoria/comando/config.yaml << EOF
name: "Comando"
description: "Comando no nível 3"
script: "main.sh"       # ← Indica que é executável
sudo: false
EOF

cat > commands/install/categoria/subcategoria/comando/main.sh << 'EOF'
#!/bin/bash
echo "Comando profundo!"
EOF

chmod +x commands/setup/categoria/subcategoria/comando/main.sh
```

**Uso:** `./susa setup categoria subcategoria comando`

## 🔍 Descoberta Automática

O sistema descobre automaticamente:

- ✅ Todas as categorias em `commands/`
- ✅ Todas as subcategorias (diretórios sem `config.yaml`)
- ✅ Todos os comandos (diretórios com `config.yaml`)
- ✅ Múltiplos níveis de aninhamento
- ✅ Comandos em plugins externos

**Não é necessário registrar manualmente** categorias ou comandos em arquivos centrais.

## 📦 Plugins

Plugins também suportam a mesma estrutura hierárquica com subcategorias aninhadas:

```text
plugins/
  dev-tools/                    # Plugin
    deploy/                     # Categoria
      config.yaml               # name, description (sem script)
      staging/                  # Comando
        config.yaml             # name, description, script
        main.sh
      production/               # Comando
        config.yaml
        main.sh
      aws/                      # Subcategoria
        config.yaml             # name, description (sem script)
        ec2/                    # Comando
          config.yaml           # name, description, script
          main.sh
        lambda/                 # Comando
          config.yaml
          main.sh
    test/                       # Categoria
      config.yaml
      unit/                     # Comando
        config.yaml
        main.sh
      integration/              # Comando
        config.yaml
        main.sh
```

### Navegação em Plugins

```bash
# Listar categorias do plugin
./susa deploy                    # Mostra: staging, production, aws (subcategoria)

# Navegar para subcategoria
./susa deploy aws                # Mostra: ec2, lambda

# Executar comando em subcategoria
./susa deploy aws ec2            # Executa deploy EC2

# Outro exemplo
./susa test                      # Mostra: unit, integration
./susa test unit                 # Executa testes unitários
```

### Usando Plugin Run com Subcategorias

Ao usar `susa self plugin run` para executar plugins em desenvolvimento, use barra `/` para indicar subcategorias:

```bash
# Plugin instalado (navegação normal)
susa deploy aws ec2

# Plugin em desenvolvimento (usar barra /)
cd ~/dev-tools
susa self plugin run dev-tools deploy/aws ec2

# Múltiplos níveis
susa self plugin run dev-tools infra/k8s/deploy production
```

**Por que barra `/`?**

- No modo run, você passa `<plugin> <categoria> <comando>`
- Para subcategorias, a categoria vira `categoria/subcategoria`
- Sistema converte automaticamente para navegação em diretórios

Veja [Self Plugin Run](../reference/commands/self/plugins/run.md) para mais detalhes sobre o comando run.

### Importante sobre Plugins

✅ Plugins funcionam **exatamente** como `commands/`:

- Mesma lógica de detecção (script = comando, sem script = subcategoria)
- Mesma estrutura de config.yaml
- Mesma navegação multinível
- Mesma descoberta automática

**Diferenças:**

- Diretório: `plugins/{nome-plugin}/` ao invés de `commands/`
- Comandos de plugins exibem o indicador **`[plugin]`** na listagem

**Exemplo de listagem com plugins:**

```text
Commands:
  asdf           Instala ASDF Version Manager
  staging        Deploy para staging [plugin]
  production     Deploy produção (requer sudo) [plugin] [sudo]
```

## ⚙️ Filtros de Sistema Operacional e Sudo

> **📖 Referência completa:** Veja [Configuração de Comandos](adding-commands.md#3-configurar-o-comando) para detalhes sobre os campos `os` e `sudo`.

**Resumo:**

- Use o campo `os: ["linux", "mac"]` para restringir sistemas
- Use `sudo: true` para comandos que requerem privilégios elevados
  - Comandos com `sudo: true` exibem o indicador **`[sudo]`** na listagem

**Exemplo de exibição:**

```text
Commands:
  docker          Instala Docker CE [sudo]
  asdf            Instala ASDF Version Manager
  podman          Instala Podman
```

## 📊 Agrupamento de Comandos

Comandos podem ser agrupados para melhor organização:

```yaml
# commands/install/tool1/config.yaml
group: "Development Tools"

# commands/install/tool2/config.yaml
group: "Development Tools"
```

**Exibição:**

```text
Commands:
  standalone-cmd  Comando sem grupo

 Development Tools
  tool1           Primeira ferramenta
  tool2           Segunda ferramenta
```

## 🎯 Boas Práticas

### Nomenclatura

- **Diretórios:** Use kebab-case: `install-python`, `backup-tools`
- **Nomes (config):** Use formato legível: `"Install Python"`, `"Backup Tools"`
- **Scripts:** Sempre `main.sh` (ou o nome definido em `script:`)

### Organização

1. **Categorias principais** → Grandes áreas funcionais (`install`, `daily`, `backup`)
2. **Subcategorias** → Agrupamento lógico (`python`, `nodejs`, `docker`)
3. **Comandos** → Ações específicas (`pip`, `poetry`, `npm`)

### Hierarquia Recomendada

```text
✅ Boa hierarquia:
commands/install/python/pip
commands/install/python/poetry
commands/install/nodejs/npm

❌ Hierarquia excessiva:
commands/tools/dev/lang/python/pkg/pip
(muito profunda, evite mais de 3 níveis)
```

## 🐛 Troubleshooting

### Comando não aparece na listagem

 1:** Falta campo `script:` no `config.yaml`

**Solução:** Adicionar o campo script

```yaml
script: "main.sh"
```

**Causa 2:** Arquivo do script não existe ou não tem o nome correto

**Solução:** Verificar se o arquivo existe e corresponde ao nome em `script:`

```bash
ls -la commands/categoria/comando/main.sh
```

**Causa 3:** Incompatível com o sistema operacional atual

**Solução:** Verificar campo `os:` no config.yaml

### Subcategoria aparece como comando (não consigo navegar)

**Causa:** Config.yaml tem campo `script:` definido e o arquivo existe

**Explicação:** O sistema identifica como comando executável pela presença do script.

**Soluç 1:** Script não está executável

**Solução:**

```bash
chmod +x commands/path/to/command/main.sh
```

**Causa 2:** Nome do script no config.yaml não corresponde ao arquivo

**Solução:** Verificar se `script:` aponta para o arquivo correto

**Causa 3:** Script não existe

**Solução:** Criar o arquivo do script

### Descrição não aparece

**Causa:** Falta campo `description:` no config.yaml

**Solução:** Adicionar descrição

```yaml
name: "Nome"
description: "Descrição aqui"
```

### Descrição da subcategoria não aparece

**Causa:** Falta `config.yaml` ou está sem campos obrigatórios

**Solução:** Criar `config.yaml` com `name` e `description` (SEM campo `script`)

```yaml
name: "Nome da Subcategoria"
description: "Descrição aqui"
```

## 📚 Exemplos Completos

> **📖 Para exemplos de comandos simples**, veja [Exemplo Completo](adding-commands.md#exemplo-completo) no guia básico.

### Exemplo: Hierarquia com Subcategorias (Foco deste guia)

```bash
# Estrutura
mkdir -p commands/backup/{local,cloud}/{full,incremental}

# Subcategoria: backup/local (SEM campo 'script')
cat > commands/backup/local/config.yaml << EOF
name: "Local"
description: "Backups locais"
EOF

# Comando: backup/local/full (COM campo 'script')
cat > commands/backup/local/full/config.yaml << EOF
name: "Full Backup"
description: "Backup completo local"
script: "main.sh"
sudo: false
EOF

cat > commands/backup/local/full/main.sh << 'EOF'
#!/bin/bash
echo "Executando backup completo local..."
tar -czf /tmp/backup-$(date +%Y%m%d).tar.gz /home/$USER/Documents
echo "✅ Backup concluído!"
EOF

chmod +x commands/backup/local/full/main.sh
```

**Uso:**

- `./susa backup` → Lista `local` e `cloud` como subcategorias
- `./susa backup local` → Lista `full` e `incremental` como comandos
- `./susa backup local full` → Executa o backup

### Exemplo 3: Plugin com Subcategorias Aninhadas

```bash
# Estrutura completa para plugin dev-tools
mkdir -p plugins/dev-tools/deploy/{staging,production,aws/{ec2,lambda}}
mkdir -p plugins/dev-tools/test/{unit,integration}

# Categoria: deploy (SEM script)
cat > plugins/dev-tools/deploy/config.yaml << EOF
name: "Deploy"
description: "Ferramentas de deployment"
EOF

# Comando: deploy/staging
cat > plugins/dev-tools/deploy/staging/config.yaml << EOF
name: "Staging"
description: "Deploy para ambiente de staging"
script: "main.sh"
EOF

cat > plugins/dev-tools/deploy/staging/main.sh << 'EOF'
#!/bin/bash
echo "🚀 Deploy para Staging..."
echo "✅ Deploy concluído!"
EOF

# Subcategoria: deploy/aws (SEM script)
cat > plugins/dev-tools/deploy/aws/config.yaml << EOF
name: "AWS"
description: "Deploy para serviços AWS"
EOF

# Comando em subcategoria: deploy/aws/ec2
cat > plugins/dev-tools/deploy/aws/ec2/config.yaml << EOF
name: "EC2"
description: "Deploy para instâncias EC2"
script: "main.sh"
EOF

cat > plugins/dev-tools/deploy/aws/ec2/main.sh << 'EOF'
#!/bin/bash
echo "☁️ Deploy para AWS EC2..."
echo "✅ Deploy EC2 concluído!"
EOF

# Tornar scripts executáveis
chmod +x plugins/dev-tools/deploy/staging/main.sh
chmod +x plugins/dev-tools/deploy/aws/ec2/main.sh
```

**Uso:**

- `./susa deploy` → Lista `staging`, `production`, `aws` (subcategoria)
- `./susa deploy staging` → Executa deploy staging
- `./susa deploy aws` → Lista `ec2`, `lambda`
- `./susa deploy aws ec2` → Executa deploy EC2

## 🔗 Guias Relacionados

- **[Como Adicionar Novos Comandos](adding-commands.md)** - Guia fundamental para criar comandos simples
- **[Referência de Bibliotecas](../reference/libraries/index.md)** - Bibliotecas disponíveis para usar em seus scripts
- **[Plugins](../plugins/overview.md)** - Sistema de plugins que suporta a mesma estrutura hierárquica
