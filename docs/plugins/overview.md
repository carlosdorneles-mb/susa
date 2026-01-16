# Visão Geral do Sistema de Plugins

O CLI suporta plugins externos que podem adicionar novas funcionalidades sem modificar o código principal.

## 🎯 O que são Plugins?

Plugins são **pacotes externos** que adicionam:

- ✅ Novas categorias de comandos
- ✅ Comandos específicos para ferramentas
- ✅ Subcategorias aninhadas
- ✅ Funcionalidades personalizadas

## 📦 Estrutura de um Plugin

```text
meu-plugin/
├── plugin.json           # Metadados do plugin (obrigatório)
├── categoria1/
│   ├── category.json
│   ├── comando1/
│   │   ├── command.json
│   │   └── main.sh
│   └── subcategoria/
│       ├── category.json
│       └── comando2/
│           ├── command.json
│           └── main.sh
└── categoria2/
    ├── category.json
    └── ...
```

### Arquivo plugin.json

**⚠️ OBRIGATÓRIO**: Todo plugin deve ter um arquivo `plugin.json` na raiz com as seguintes informações:

```json
{
  "name": "meu-plugin",
  "version": "1.0.0",
  "description": "Descrição do que o plugin faz",
  "directory": "src"
}
```

Campos:

- **name**: Nome do plugin (⚠️ obrigatório)
- **version**: Versão no formato semver (⚠️ obrigatório)
- **description**: Descrição do plugin (opcional)
- **directory**: Subdiretório onde os comandos estão (opcional, útil se comandos estão em `src/`)

**Nota**: Plugins sem `plugin.json` válido não poderão ser instalados.

Para mais detalhes sobre a estrutura de plugins, veja [Arquitetura de Plugins](architecture.md).

## 🚀 Comandos de Gerenciamento

Veja nas [referências](../reference/commands/self/plugins/index.md) todos os comandos disponíveis.

### Modo Desenvolvimento

Durante o desenvolvimento, instale o plugin localmente:

```bash
cd ~/meu-plugin
susa self plugin add .

# Testar comandos
susa deploy staging

# Fazer alterações no código e testar novamente
# Mudanças são refletidas automaticamente!
susa deploy production
```

Plugins instalados localmente (modo dev) refletem alterações automaticamente - não é necessário reinstalar.

## 🏗️ Criando um Plugin

> **💡 Exemplo completo:** Veja o [susa-plugin-hello-world](https://github.com/duducp/susa-plugin-hello-world) como referência de implementação.

### 1. Criar plugin.json (OBRIGATÓRIO)

Todo plugin deve começar com o arquivo `plugin.json` na raiz:

```bash
mkdir meu-plugin
cat > meu-plugin/plugin.json << 'EOF'
{
  "name": "meu-plugin",
  "version": "1.0.0",
  "description": "Ferramentas de deployment"
}
EOF
```

### 2. Estrutura de Comandos

```bash
mkdir -p meu-plugin/deploy/{staging,production}

# Categoria
cat > meu-plugin/deploy/category.json << EOF
name: "Deploy"
description: "Ferramentas de deployment"
EOF

# Comando
cat > meu-plugin/deploy/staging/command.json << EOF
name: "Staging"
description: "Deploy para staging"
entrypoint: "main.sh"
envs:
  STAGING_URL: "https://staging.example.com"
  STAGING_TIMEOUT: "60"
EOF

cat > meu-plugin/deploy/staging/main.sh << 'EOF'
#!/bin/bash

# Variáveis automaticamente disponíveis
url="${STAGING_URL:-https://default-staging.com}"
timeout="${STAGING_TIMEOUT:-30}"

echo "🚀 Deploying to staging ($url)..."
# Seu código aqui
EOF

chmod +x meu-plugin/deploy/staging/main.sh
```

### 3. Publicar no GitHub

```bash
cd meu-plugin
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/user/meu-plugin.git
git push -u origin main
```

### 4. Testar Localmente

```bash
# Modo desenvolvimento (mudanças refletem automaticamente)
susa self plugin add ./meu-plugin

# Ou do diretório do plugin
cd meu-plugin
susa self plugin add .

# Testar comandos
susa deploy staging
```

## 🔧 Funcionalidades de Plugins

### Subcategorias Aninhadas

Plugins suportam a mesma estrutura hierárquica que comandos built-in:

```text
meu-plugin/
  deploy/
    category.json
    staging/
      command.json
      main.sh
    aws/                 # Subcategoria
      category.json
      ec2/               # Comando em subcategoria
        command.json
        main.sh
```

### Acesso via CLI

```bash
susa deploy              # Lista staging + aws
susa deploy staging      # Executa deploy staging
susa deploy aws          # Lista comandos AWS
susa deploy aws ec2      # Executa deploy EC2
```

### Indicador Visual

Comandos de plugins são identificados com o indicador **`[plugin]`** na listagem:

```text
Commands:
  asdf            Instala ASDF Version Manager
  staging         Deploy para staging [plugin]
  production      Deploy para produção [plugin]
```

Se o comando também requer `sudo`, ambos os indicadores aparecem:

```text
Commands:
  docker        Instala Docker CE [sudo]
  deploy-prod   Deploy produção com privilégios elevados [plugin] [sudo]
```

### Categorias com Entrypoint (Feature Avançada)

Assim como categorias built-in, categorias de plugins podem ter um `entrypoint` que permite aceitar parâmetros diretamente:

**Estrutura:**

```text
meu-plugin/
  demo/
    category.json        # ← Com campo entrypoint
    main.sh              # ← Script da categoria
    hello/
      command.json
      main.sh
    info/
      command.json
      main.sh
```

**demo/category.json:**

```json
{
  "name": "Demo",
  "description": "Comandos de demonstração",
  "entrypoint": "main.sh"
}
```

**demo/main.sh:**

```bash
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source "$LIB_DIR/logger.sh"
source "$LIB_DIR/color.sh"

# Exibida ao listar comandos da categoria
show_complement_help() {
    echo ""
    log_output "${LIGHT_GREEN}Opções da categoria:${NC}"
    log_output "  -h, --help       Mostra ajuda"
    log_output "  --list           Lista comandos disponíveis"
    log_output "  --about          Sobre o plugin"
}

list_demo_commands() {
    local lock_file="$CLI_DIR/susa.lock"
    jq -r '.commands[]? | select(.category == "demo") |
           "\(.name)\t\(.description)"' "$lock_file"
}

main() {
    case "${1:-}" in
        --list) list_demo_commands; exit 0 ;;
        --about) echo "Sobre o plugin..."; exit 0 ;;
        *) log_error "Opção desconhecida: $1"; exit 1 ;;
    esac
}

# IMPORTANTE: Permite controle de execução
if [ "${SUSA_SKIP_MAIN:-}" != "1" ]; then
    main "$@"
fi
```

**Uso:**

```bash
# Lista comandos + mostra help complementar
susa demo

# Executa opção da categoria
susa demo --list
susa demo --about

# Executa comando específico normalmente
susa demo hello
```

**Quando usar:**

- ✅ Operações em massa (--upgrade-all, --list-all)
- ✅ Ações que afetam toda a categoria
- ✅ Help complementar com informações extras
- ❌ Comandos individuais (use comandos normais)

> **📖 Referência completa:** Veja [Categorias com Parâmetros](../guides/subcategories.md#categorias-com-parametros-feature-avancada) para detalhes sobre implementação.

## 📝 Boas Práticas

1. **plugin.json** - ⚠️ Obrigatório! Sempre inclua com `name` e `version`
2. **Versionamento** - Use semver no campo `version` do plugin.json (ex: 1.0.0, 1.2.3)
3. **Documentação** - Adicione README.md ao plugin
4. **Naming** - Use nomes descritivos e sem espaços
5. **Testes** - Teste localmente antes de publicar
6. **Compatibilidade** - Use campo `os:` se específico de plataforma
7. **Variáveis de Ambiente** - Use `envs:` no command.json para configurações
   - Sempre forneça fallback no script: `${VAR:-default}`
   - Use prefixos únicos: `MYPLUGIN_*`
   - Documente no README quais envs estão disponíveis

## 🔗 Próximos Passos

- [Arquitetura de Plugins](architecture.md) - Detalhes técnicos
- [Plugin Hello World](https://github.com/duducp/susa-plugin-hello-world) - Exemplo completo de plugin
