# Setup Bruno

Instala o Bruno, um cliente de API open-source rápido e amigável para Git que armazena coleções diretamente no sistema de arquivos.

## O que é Bruno?

Bruno é um cliente de API moderno que revoluciona a forma como você interage com APIs ao adotar uma abordagem **offline-first** e **Git-friendly**:

- **Offline-First**: Funciona completamente offline, sem necessidade de conta ou sincronização em nuvem
- **Git Native**: Armazena coleções como arquivos de texto em pastas do sistema
- **Linguagem Bru**: Formato de marcação próprio para salvar requisições
- **Open Source**: Código aberto e gratuito para sempre
- **Leve e Rápido**: Interface rápida e responsiva
- **Colaboração via Git**: Use Git para controle de versão e trabalho em equipe
- **Suporte Multi-Protocolo**: REST, GraphQL, gRPC e WebSocket

**Diferencial principal:**

Ao contrário de Postman e Insomnia, Bruno não armazena suas coleções em nuvem. Tudo fica no seu sistema de arquivos, permitindo usar Git para versionamento e compartilhamento sem depender de servidores externos.

**Exemplo de arquivo .bru:**

```bru
meta {
  name: Get User
  type: http
  seq: 1
}

get {
  url: {{base_url}}/api/users/{{user_id}}
}

headers {
  Authorization: Bearer {{token}}
  Content-Type: application/json
}

vars:pre-request {
  user_id: 123
}

script:post-response {
  if (res.status === 200) {
    bru.setEnvVar("user_name", res.body.name);
  }
}

tests {
  test("Status should be 200", function() {
    expect(res.status).to.equal(200);
  });

  test("User should have email", function() {
    expect(res.body.email).to.be.a('string');
  });
}
```

## Como usar

### Instalar

```bash
susa setup bruno
```

O comando vai:

**No macOS:**

- Verificar se o Homebrew está instalado
- Instalar o Bruno via `brew install --cask bruno`
- Configurar o aplicativo no sistema

**No Linux:**

- Buscar a versão mais recente no GitHub
- Baixar o pacote .deb apropriado (amd64 ou arm64)
- Instalar via apt-get ou dpkg
- Criar entrada no menu de aplicativos

Depois de instalar, você pode abrir o Bruno:

```bash
bruno                # Linux
open -a Bruno        # macOS
```

Ou através do menu de aplicativos.

### Atualizar

```bash
susa setup bruno --upgrade
```

Atualiza o Bruno para a versão mais recente disponível. O comando usa:

- **macOS**: `brew upgrade --cask bruno`
- **Linux**: Baixa e reinstala a versão mais recente do GitHub

Todas as suas coleções e configurações serão preservadas, pois ficam armazenadas em pastas separadas.

### Desinstalar

```bash
susa setup bruno --uninstall
```

Remove o Bruno do sistema. O comando vai:

1. Remover o aplicativo
2. Remover entrada do menu (Linux)
3. Suas coleções permanecerão intactas nas pastas onde foram criadas

**Nota:** Como as coleções ficam em pastas do sistema de arquivos (não dentro do app), você não perde nada ao desinstalar.

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda detalhada |
| `-u, --upgrade` | Atualiza o Bruno para a versão mais recente |
| `--uninstall` | Remove o Bruno do sistema |
| `-v, --verbose` | Habilita saída detalhada para depuração |
| `-q, --quiet` | Minimiza a saída, desabilita mensagens de depuração |

## Requisitos

- **macOS**: Homebrew instalado
- **Linux**: Sistema com suporte a pacotes .deb (Ubuntu, Debian, etc.)

## Recursos Principais

### 1. Coleções no Sistema de Arquivos

Crie uma coleção em qualquer pasta:

```bash
# Estrutura de uma coleção Bruno
my-api-collection/
├── bruno.json              # Configuração da coleção
├── environments/
│   ├── local.bru
│   ├── staging.bru
│   └── production.bru
└── requests/
    ├── users/
    │   ├── get-user.bru
    │   ├── create-user.bru
    │   └── update-user.bru
    └── auth/
        └── login.bru
```

### 2. Controle de Versão com Git

```bash
# Initialize repository
cd my-api-collection
git init
git add .
git commit -m "Initial API collection"

# Collaborate
git push origin main

# Team member pulls and uses
git clone <repo>
# Open collection in Bruno
```

### 3. Variáveis de Ambiente

**Arquivo: `environments/local.bru`**

```bru
vars {
  base_url: http://localhost:3000
  api_key: dev_key_123
  user_id: 1
}
```

**Arquivo: `environments/production.bru`**

```bru
vars {
  base_url: https://api.production.com
  api_key: {{env.API_KEY}}
  user_id: {{env.USER_ID}}
}
```

Variáveis de ambiente ficam versionadas junto com as requisições!

### 4. Scripts e Testes

Bruno suporta JavaScript para scripts pre-request e post-response:

```bru
meta {
  name: Create User
  type: http
}

post {
  url: {{base_url}}/api/users
}

body:json {
  {
    "name": "João Silva",
    "email": "joao@example.com"
  }
}

script:pre-request {
  // Generate timestamp
  const timestamp = Date.now();
  bru.setVar("timestamp", timestamp);

  // Set auth header
  const token = bru.getEnvVar("token");
  req.setHeader("Authorization", `Bearer ${token}`);
}

script:post-response {
  // Save user ID for next requests
  if (res.status === 201) {
    const userId = res.body.id;
    bru.setEnvVar("created_user_id", userId);
    console.log(`User created with ID: ${userId}`);
  }
}

tests {
  test("Should return 201", function() {
    expect(res.status).to.equal(201);
  });

  test("Should return user ID", function() {
    expect(res.body.id).to.be.a('number');
  });

  test("Email should match", function() {
    expect(res.body.email).to.equal('joao@example.com');
  });
}
```

### 5. GraphQL Support

```bru
meta {
  name: Get User Query
  type: graphql
}

post {
  url: {{base_url}}/graphql
}

body:graphql {
  query GetUser($id: ID!) {
    user(id: $id) {
      id
      name
      email
      posts {
        title
        content
      }
    }
  }
}

body:graphql:vars {
  {
    "id": "{{user_id}}"
  }
}

tests {
  test("Should return user", function() {
    expect(res.body.data.user).to.not.be.null;
  });
}
```

### 6. Documentação Embutida

Adicione descrição e documentação direto nas requisições:

```bru
meta {
  name: User Authentication
  type: http
  seq: 1
}

docs {
  # User Authentication

  Autentica um usuário e retorna um token JWT.

  ## Parâmetros
  - **email**: Email do usuário
  - **password**: Senha do usuário

  ## Resposta
  ```json
  {
    "token": "eyJhbGc...",
    "user": {
      "id": 1,
      "name": "João",
      "email": "joao@example.com"
    }
  }
  ```

  ## Notas
  - Token válido por 24 horas
  - Use o token no header Authorization
}

post {
  url: {{base_url}}/auth/login
}

body:json {
  {
    "email": "joao@example.com",
    "password": "senha123"
  }
}
```

## Comparação: Bruno vs Postman

| Recurso | Bruno | Postman |
|---------|-------|---------|
| **Armazenamento** | Sistema de arquivos | Nuvem + Cache local |
| **Colaboração** | Via Git | Via Postman Cloud |
| **Preço** | Gratuito e Open Source | Freemium (limites no free) |
| **Offline** | ✅ Completamente | ⚠️ Limitado sem sincronização |
| **Controle de Versão** | ✅ Git nativo | ⚠️ Via Postman (limitado) |
| **Formato** | Texto (.bru) | JSON proprietário |
| **Tamanho** | ~150MB | ~400MB |
| **Velocidade** | ⚡ Muito rápida | Regular |
| **Conta obrigatória** | ❌ Não | ✅ Sim (para colaboração) |

## Fluxo de Trabalho Recomendado

### Desenvolvimento Individual

```bash
# 1. Crie uma coleção em qualquer pasta
mkdir ~/projects/my-api
cd ~/projects/my-api

# 2. Abra o Bruno e crie uma coleção nesta pasta
bruno

# 3. Crie requisições normalmente

# 4. Versionamento opcional
git init
git add .
git commit -m "Initial collection"
```

### Colaboração em Equipe

```bash
# 1. Mantenha coleções no repositório do projeto
my-project/
├── src/
├── tests/
├── bruno-collections/    # ← Coleções Bruno aqui
│   ├── bruno.json
│   ├── environments/
│   └── requests/
└── README.md

# 2. Todos os devs clonando o repo têm acesso
git clone <repo>
cd my-project

# 3. Abra a coleção no Bruno
bruno bruno-collections/

# 4. Mudanças são versionadas como código
git add bruno-collections/
git commit -m "Add new endpoints"
git push
```

### CI/CD Integration

Bruno inclui CLI para automação:

```bash
# Install Bruno CLI
npm install -g @usebruno/cli

# Run collection
bru run bruno-collections/ --env production

# Run specific folder
bru run bruno-collections/requests/users --env staging

# Export results
bru run bruno-collections/ --env production --output results.json
```

## Atalhos Úteis

| Atalho | Ação |
|--------|------|
| `Ctrl/Cmd + N` | Nova requisição |
| `Ctrl/Cmd + S` | Salvar requisição |
| `Ctrl/Cmd + Enter` | Enviar requisição |
| `Ctrl/Cmd + E` | Gerenciar ambientes |
| `Ctrl/Cmd + T` | Nova aba |
| `Ctrl/Cmd + W` | Fechar aba |
| `Ctrl/Cmd + P` | Busca rápida |
| `Ctrl/Cmd + B` | Toggle sidebar |

## Migração do Postman

Para migrar coleções do Postman para Bruno:

```bash
# 1. Exporte coleção do Postman (formato Collection v2.1)

# 2. No Bruno, vá em:
#    File → Import Collection → Postman Collection

# 3. Selecione o arquivo .json exportado

# 4. Coleção será convertida para formato .bru
```

**Nota:** Scripts e testes podem precisar de pequenos ajustes na sintaxe.

## Solução de Problemas

### Linux: Bruno não abre

```bash
# Verifique instalação
which bruno
bruno --version

# Se não encontrado, reinstale
susa setup bruno --upgrade
```

### macOS: "Bruno" não pode ser aberto

```bash
# Remova quarentena do macOS
xattr -d com.apple.quarantine /Applications/Bruno.app

# Ou reinstale via Homebrew
brew reinstall --cask bruno
```

### Coleções não aparecem

- Certifique-se que a pasta contém arquivo `bruno.json`
- Abra a pasta correta no Bruno
- Verifique permissões de leitura/escrita

### Erros em scripts

- Bruno usa JavaScript moderno
- Algumas APIs do Postman podem ter nomes diferentes
- Consulte documentação: https://docs.usebruno.com/scripting/

## Links Úteis

- **Site oficial**: https://www.usebruno.com/
- **GitHub**: https://github.com/usebruno/bruno
- **Documentação**: https://docs.usebruno.com/
- **Discord**: https://discord.com/invite/KgcZUncpjq
- **Exemplos**: https://github.com/usebruno/bruno/tree/main/examples

## Diferenças Importantes

### Por que escolher Bruno?

✅ **Escolha Bruno se você:**

- Quer controle total sobre seus dados
- Prefere trabalhar offline
- Usa Git para tudo
- Valoriza open source
- Quer algo rápido e leve
- Não quer depender de serviços cloud

⚠️ **Use Postman se você:**

- Precisa de recursos enterprise (mock servers avançados, monitoring)
- Trabalha em equipe grande com necessidade de workspaces complexos
- Já tem fluxo estabelecido no Postman
- Precisa de integrações específicas do ecossistema Postman

## Variáveis de Ambiente do Comando

O comando usa as seguintes variáveis que podem ser customizadas:

```bash
BRUNO_HOMEBREW_CASK="bruno"
BRUNO_GITHUB_REPO="usebruno/bruno"
BRUNO_INSTALL_DIR="/opt/bruno"
BRUNO_DESKTOP_FILE="/usr/share/applications/bruno.desktop"
BRUNO_BIN_LINK="/usr/local/bin/bruno"
```

Para customizar, edite o arquivo `command.json` no diretório `commands/setup/bruno/` antes da instalação.

## Conclusão

Bruno representa uma nova geração de clientes de API que prioriza:

- ✅ Privacidade e controle local
- ✅ Simplicidade e velocidade
- ✅ Colaboração via Git
- ✅ Open source e gratuito

Ideal para desenvolvedores que valorizam ferramentas simples, rápidas e que se integram naturalmente ao fluxo de trabalho moderno baseado em Git.
