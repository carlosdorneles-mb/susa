# Sistema de Categorias e Subcategorias Aninhadas

## 📋 Visão Geral

O CLI suporta uma estrutura hierárquica de categorias e subcategorias baseada em diretórios, permitindo organizar comandos em múltiplos níveis de profundidade.

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
| **Comando** | `name`, `description`, `script` (obrigatório), `sudo`, `os`, `group` |
| **Subcategoria** | `name`, `description` (sem campo `script`) |

**Vantagens dessa abordagem:**

- ✅ Mais intuitivo: "tem script = é executável"
- ✅ Mais consistente: todos usam o mesmo tipo de arquivo
- ✅ Mais lógico: comandos PRECISAM de script, subcategorias não

### Estrutura Exemplo

```text
commands/
  install/                          # Categoria principal
    config.yaml                     # name, description (sem script)
    asdf/                           # Comando direto
      config.yaml                   # name, description, script, sudo, os
      main.sh                       # Script executável
    python/                         # Subcategoria
      config.yaml                   # name, description (sem script)
      pip/                          # Comando
        config.yaml                 # name, description, script
        main.sh
      poetry/                       # Comando
        config.yaml
        main.sh
      tools/                        # Sub-subcategoria (nível 3)
        config.yaml                 # name, description (sem script)
        venv/                       # Comando nível 3
          config.yaml               # name, description, script
          main.sh
    nodejs/                         # Subcategoria
      config.yaml                   # name, description (sem script)
      npm/                          # Comando
        config.yaml                 # name, description, script
        main.sh
```

## 🎯 Navegação

### Comandos de Navegação

```bash
# Listar categorias principais
./cli

# Listar subcategorias e comandos de uma categoria
./susa setup

# Navegar para uma subcategoria
./susa setup python

# Navegar para sub-subcategoria (nível 3)
./susa setup python tools

# Executar comando direto
./susa setup asdf

# Executar comando em subcategoria
./susa setup python pip

# Executar comando em sub-subcategoria
./susa setup python tools venv
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
sudo: false
os: ["linux", "mac"]
group: "Package Managers"  # Opcional
```

**Localização:** `commands/{categoria}/.../{comando}/config.yaml`

**Importante:** O arquivo definido em `script:` DEVE existir e ter permissão de execução.

## ✨ Campos de Configuração

### Para Comandos (Executáveis)

| Campo | Tipo | Obrigatório | Descrição |
| ----- | ---- | ----------- | --------- |
| `name` | string | ✅ | Nome exibido do comando |
| `description` | string | ✅ | Descrição curta |
| `script` | string | ✅ | Nome do arquivo do script (ex: "main.sh") |
| `sudo` | boolean | ❌ | Requer permissões de superusuário (padrão: false) |
| `os` | array | ❌ | Sistemas compatíveis: `["linux", "mac"]` |
| `group` | string | ❌ | Agrupa comandos relacionados na listagem |

### Para Subcategorias (Navegáveis)

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `name` | string | ✅ | Nome exibido da subcategoria |
| `description` | string | ✅ | Descrição curta |

**Nota:** Subcategorias NÃO devem ter o campo `script`.

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

## 🚀 Como Adicionar Novos Comandos

### 1. Comando em Categoria Existente

```bash
# Criar diretório do comando
mkdir -p commands/install/comando-novo

# Criar configuração
cat > commands/install/comando-novo/config.yaml << EOF
name: "Comando Novo"
description: "Descrição do comando"
script: "main.sh"
sudo: false
os: ["linux"]
EOF

# Criar script
cat > commands/install/comando-novo/main.sh << 'EOF'
#!/bin/bash
echo "Executando comando novo!"
EOF

# Tornar executável
chmod +x commands/setup/comando-novo/main.sh
```

**Uso:** `./susa setup comando-novo`

### 2. Comando em Nova Subcategoria

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

### Importante sobre Plugins

✅ Plugins funcionam **exatamente** como `commands/`:

- Mesma lógica de detecção (script = comando, sem script = subcategoria)
- Mesma estrutura de config.yaml
- Mesma navegação multinível
- Mesma descoberta automática

A única diferença é o diretório: `plugins/{nome-plugin}/` ao invés de `commands/`.

## ⚙️ Filtros de Sistema Operacional

Comandos podem ser restritos a sistemas operacionais específicos:

```yaml
# Apenas Linux
os: ["linux"]

# Apenas macOS
os: ["mac"]

# Ambos
os: ["linux", "mac"]

# Todos (omitir campo ou deixar vazio)
os: []
```

Comandos incompatíveis são automaticamente ocultados na listagem.

## 🔐 Comandos com Sudo

Comandos que requerem privilégios de superusuário:

```yaml
sudo: true
```

Exibem um indicador `[sudo]` na listagem e validam permissões antes da execução.

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

### Exemplo 1: Ferramenta de Instalação Simples

```bash
mkdir -p commands/install/docker

cat > commands/install/docker/config.yaml << EOF
name: "Docker"
description: "Instala Docker CE"
script: "main.sh"
sudo: true
os: ["linux"]
EOF

cat > commands/install/docker/main.sh << 'EOF'
#!/bin/bash
echo "📦 Instalando Docker CE..."
apt-get update
apt-get install -y docker.io
systemctl start docker
systemctl enable docker
echo "✅ Docker instalado!"
EOF

chmod +x commands/install/docker/main.sh
```

**Uso:**

- `./susa setup` → Lista docker entre as opções
- `./susa setup docker` → Instala o Docker

### Exemplo 2: Categoria com Subcategorias

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
