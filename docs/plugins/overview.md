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
├── categoria1/
│   ├── config.yaml
│   ├── comando1/
│   │   ├── config.yaml
│   │   └── main.sh
│   └── subcategoria/
│       ├── config.yaml
│       └── comando2/
│           ├── config.yaml
│           └── main.sh
└── categoria2/
    ├── config.yaml
    └── ...
```

## 🚀 Comandos de Gerenciamento

### Listar Plugins

```bash
susa self plugin list
```

Mostra todos os plugins instalados com:
- Origem (URL Git ou local)
- Versão
- Número de comandos
- Categorias
- Data de instalação

### Instalar Plugin

```bash
# De URL completa
susa self plugin install https://github.com/user/cli-plugin-name

# Atalho GitHub
susa self plugin install user/cli-plugin-name
```

### Atualizar Plugin

```bash
susa self plugin update plugin-name
```

Atualiza o plugin para a versão mais recente do repositório Git.

### Remover Plugin

```bash
susa self plugin remove plugin-name
```

Remove completamente o plugin e suas entradas do registro.

## 🏗️ Criando um Plugin

### 1. Estrutura Básica

```bash
mkdir -p meu-plugin/deploy/{staging,production}

# Categoria
cat > meu-plugin/deploy/config.yaml << EOF
name: "Deploy"
description: "Ferramentas de deployment"
EOF

# Comando
cat > meu-plugin/deploy/staging/config.yaml << EOF
name: "Staging"
description: "Deploy para staging"
script: "main.sh"
EOF

cat > meu-plugin/deploy/staging/main.sh << 'EOF'
#!/bin/bash
echo "🚀 Deploying to staging..."
# Seu código aqui
EOF

chmod +x meu-plugin/deploy/staging/main.sh
```

### 2. Adicionar Versão

```bash
echo "1.0.0" > meu-plugin/version.txt
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

### 4. Instalar Localmente para Teste

```bash
# Copie para o diretório de plugins
cp -r meu-plugin cli/plugins/

# Adicione ao registro manualmente
# Ou use o comando install apontando para o diretório local
```

## 🔧 Funcionalidades de Plugins

### Subcategorias Aninhadas

Plugins suportam a mesma estrutura hierárquica que comandos built-in:

```text
meu-plugin/
  deploy/
    config.yaml
    staging/
      config.yaml
      main.sh
    aws/                 # Subcategoria
      config.yaml
      ec2/               # Comando em subcategoria
        config.yaml
        main.sh
```

### Acesso via CLI

```bash
susa deploy              # Lista staging + aws
susa deploy staging      # Executa deploy staging
susa deploy aws          # Lista comandos AWS
susa deploy aws ec2      # Executa deploy EC2
```

## 📝 Boas Práticas

1. **Versionamento** - Sempre mantenha `version.txt` atualizado
2. **Documentação** - Adicione README.md ao plugin
3. **Naming** - Use nomes descritivos e sem espaços
4. **Testes** - Teste localmente antes de publicar
5. **Compatibilidade** - Use campo `os:` se específico de plataforma

## 🔗 Próximos Passos

- [Arquitetura de Plugins](architecture.md) - Detalhes técnicos
- [Exemplos de Plugins](https://github.com/carlosdorneles-mb/cli-plugins) - Repositório de exemplos
