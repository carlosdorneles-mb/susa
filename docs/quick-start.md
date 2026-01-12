# Quick Start

## 🚀 Instalação Rápida

### Instalação com um comando (Recomendado)

A forma mais rápida de instalar o Susa CLI é usando o instalador remoto:

```bash
# macOS e Linux
curl -LsSf https://raw.githubusercontent.com/cdorneles/scripts/main/cli/install-remote.sh | sh
```

Este comando irá:

- ✅ Detectar seu sistema operacional automaticamente
- ✅ Instalar dependências necessárias (git)
- ✅ Clonar o repositório
- ✅ Executar a instalação
- ✅ Configurar o PATH automaticamente

---

### Instalação Manual

Se preferir instalar manualmente:

```bash
# 1. Clone o repositório
git clone https://github.com/cdorneles/scripts.git
cd scripts/cli

# 2. Execute o instalador
./install.sh
```

---

### Verificar Instalação

Após a instalação, verifique se funcionou:

```bash
susa --version
susa --help
```

---

## 📖 Uso Básico

### 1. Estrutura Básica

```text
commands/
  {categoria}/           # Categoria principal
    config.yaml          # Descrição da categoria
    {comando}/           # Comando executável
      config.yaml        # Com campo 'script'
      main.sh            # Script executável
    {subcategoria}/      # Subcategoria navegável
      config.yaml        # Sem campo 'script'
      {comando}/         # Comando da subcategoria
        config.yaml      # Com campo 'script'
        main.sh
```

### 2. Regras Simples

**⚠️ IMPORTANTE:** O sistema verifica a **existência do script** para diferenciar comandos de subcategorias!

| Tipo | Tem config.yaml? | Tem campo 'script'? | Tem arquivo script? | Comportamento |
| ---- | ---------------- | ------------------- | ------------------- | ------------- |
| **Categoria** | ✅ Sim | ❌ Não | ❌ Não | Navegável |
| **Subcategoria** | ✅ Sim | ❌ Não | ❌ Não | Navegável |
| **Comando** | ✅ Sim | ✅ Sim | ✅ Sim | Executável |

**Como funciona a detecção?**

1. Sistema lê o `config.yaml` do diretório
2. Verifica se tem campo `script:` definido
3. Verifica se o arquivo do script existe
4. **Se tem script e arquivo existe** → É um **comando executável**
5. **Se não tem script ou arquivo não existe** → É uma **subcategoria navegável**

**Vantagens:**

- ✅ Mais intuitivo: "tem script = é executável"
- ✅ Consistente: todos usam `config.yaml`
- ✅ Simples: comandos PRECISAM de script, subcategorias não

### 3. Criar Comando Simples

```bash
# 1. Criar estrutura
mkdir -p commands/install/meu-comando

# 2. Config (COM campo 'script')
cat > commands/install/meu-comando/config.yaml << EOF
name: "Meu Comando"
description: "Descrição curta"
script: "main.sh"      # ← Campo obrigatório para comandos
sudo: false
EOF

# 3. Script
cat > commands/install/meu-comando/main.sh << 'EOF'
#!/bin/bash
echo "Hello World!"
EOF

# 4. Permissões
chmod +x commands/install/meu-comando/main.sh

# 5. Usar
./susa setup meu-comando
```

### 4. Criar Subcategoria com Comandos

```bash
# 1. Estrutura
mkdir -p commands/tools/python/{cmd1,cmd2}

# 2. Config da subcategoria (SEM campo 'script')
cat > commands/tools/python/config.yaml << EOF
name: "Python"
description: "Ferramentas Python"
# Sem campo 'script' = subcategoria navegável
EOF

# 3. Primeiro comando (COM campo 'script')
cat > commands/tools/python/cmd1/config.yaml << EOF
name: "Comando 1"
description: "Primeiro comando"
script: "main.sh"      # ← Campo indica que é executável
sudo: false
EOF

echo '#!/bin/bash' > commands/tools/python/cmd1/main.sh
echo 'echo "Comando 1"' >> commands/tools/python/cmd1/main.sh
chmod +x commands/tools/python/cmd1/main.sh

# 4. Segundo comando
cat > commands/tools/python/cmd2/config.yaml << EOF
name: "Comando 2"
description: "Segundo comando"
script: "main.sh"
sudo: false
EOF

echo '#!/bin/bash' > commands/tools/python/cmd2/main.sh
echo 'echo "Comando 2"' >> commands/tools/python/cmd2/main.sh
chmod +x commands/tools/python/cmd2/main.sh

# 5. Usar
./susa tools python        # Lista cmd1 e cmd2
./susa tools python cmd1   # Executa cmd1
./susa tools python cmd2   # Executa cmd2
```

## 📋 Campos config.yaml

Para Comandos (Executáveis)

```yaml
name: "Nome do Comando"
description: "Descrição"
script: "main.sh"          # ← OBRIGATÓRIO para comandos
sudo: false                # Opcional: requer sudo?
os: ["linux", "mac"]      # Opcional: sistemas compatíveis
group: "Nome do Grupo"    # Opcional: agrupamento visual
```

### Para Subcategorias (Navegáveis)

```yaml
name: "Nome da Subcategoria"
description: "Descrição"
# SEM campo 'script' = subcategoria navegável
```

## 🎯 Navegação Rápida

```bash
./susa                           # Lista categorias principais
./susa {categoria}              # Lista subcategorias e comandos
./susa {categoria} {subcategoria}  # Lista comandos da subcategoria
./susa {categoria} {comando}    # Executa comando
./susa {categoria} {subcategoria} {comando}  # Executa em subcategoria
```

## 💡 Dicas Importantes

1. **Todos os itens têm `config.yaml`** (categorias, subcategorias e comandos)
2. **Campo `script:` indica que é executável**
3. **Sem campo `script:` = subcategoria navegável**
4. **Script deve existir e ter permissão de execução**
5. **Não esqueça `chmod +x` no script**
6. **Teste com `./susa` após criar**

## ❓ FAQ

**P: Como o sistema diferencia comando de subcategoria?**
R: Verifica se tem campo `script:` no config.yaml E se o arquivo do script existe. Se sim = comando, senão = subcategoria.

**P: Posso ter uma subcategoria sem config.yaml?**
R: Tecnicamente sim, mas ela aparecerá sem nome e descrição. Recomendado sempre criar config.yaml.

**P: O que acontece se eu definir `script:` mas não criar o arquivo?**
R: Será tratado como subcategoria (script não existe = não é executável).

**P: Posso usar outro nome além de main.sh?**
R: Sim! Defina em `script: "meu-script.sh"` e crie o arquivo com esse nome
