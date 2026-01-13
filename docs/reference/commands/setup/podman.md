# Setup Podman

Instala o Podman, um motor de container open-source para desenvolvimento, gerenciamento e execução de containers OCI. É uma alternativa daemon-less e rootless ao Docker.

## O que é Podman?

Podman é uma ferramenta para gerenciar containers, similar ao Docker, mas com algumas vantagens importantes:

- **Sem daemon**: Não precisa de um serviço rodando em background
- **Rootless**: Pode executar containers sem privilégios de root
- **Compatível com Docker**: Usa os mesmos comandos e imagens
- **Mais seguro**: Melhor isolamento e segurança

**Por exemplo:**

```bash
# No Docker você faz:
docker run hello-world

# No Podman é idêntico:
podman run hello-world
```

## Como usar

### Instalar

```bash
susa setup podman
```

O comando vai:

- **Linux**: Baixar o binário mais recente do GitHub e instalar em `~/.local/bin`
- **macOS**: Instalar via Homebrew e configurar máquina virtual
- **Ambos**: Instalar `podman-compose` automaticamente

Depois de instalar, reinicie o terminal ou execute:

```bash
source ~/.bashrc   # Para Bash
source ~/.zshrc    # Para Zsh
```

### Desinstalar

```bash
susa setup podman --uninstall
```

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda detalhada |
| `-u, --uninstall` | Remove o Podman do sistema |

## Guia Rápido de Uso

### Comandos Básicos

**1. Verificar instalação**

```bash
podman --version
```

**2. Executar seu primeiro container**

```bash
podman run hello-world
```

**3. Listar imagens disponíveis**

```bash
podman images
```

**4. Listar containers em execução**

```bash
podman ps
```

**5. Listar todos os containers (incluindo parados)**

```bash
podman ps -a
```

### Trabalhando com Containers

**Executar um container Ubuntu interativo**

```bash
podman run -it ubuntu bash
```

**Executar um servidor web Nginx**

```bash
podman run -d -p 8080:80 --name meu-nginx nginx
```

Acesse: http://localhost:8080

**Parar um container**

```bash
podman stop meu-nginx
```

**Remover um container**

```bash
podman rm meu-nginx
```

### Trabalhando com Imagens

**Baixar uma imagem**

```bash
podman pull nginx:latest
```

**Listar imagens locais**

```bash
podman images
```

**Remover uma imagem**

```bash
podman rmi nginx:latest
```

**Construir uma imagem a partir de um Dockerfile**

```bash
podman build -t minha-app .
```

### Usando Podman Compose

O `podman-compose` permite gerenciar aplicações multi-container usando arquivos YAML, compatível com Docker Compose.

**Exemplo de docker-compose.yml:**

```yaml
version: '3'
services:
  web:
    image: nginx
    ports:
      - "8080:80"
  db:
    image: postgres
    environment:
      POSTGRES_PASSWORD: senha123
```

**Comandos:**

```bash
# Iniciar todos os serviços
podman-compose up -d

# Ver status dos serviços
podman-compose ps

# Ver logs
podman-compose logs

# Parar todos os serviços
podman-compose down
```

## Vantagens do Podman

### 1. Sem Daemon (Daemonless)

- Docker precisa do daemon `dockerd` rodando
- Podman executa containers diretamente, sem processo intermediário
- Menos consumo de recursos

### 2. Rootless por Padrão

```bash
# Podman pode executar containers sem sudo
podman run nginx

# Docker geralmente precisa de sudo ou adicionar usuário ao grupo docker
sudo docker run nginx
```

### 3. Compatibilidade

```bash
# Se você já usa Docker, pode criar um alias:
alias docker=podman

# Agora todos os comandos Docker funcionam!
docker run hello-world
docker ps
docker images
```

### 4. Pods (similar ao Kubernetes)

```bash
# Criar um pod (grupo de containers)
podman pod create --name meu-pod

# Adicionar containers ao pod
podman run -d --pod meu-pod nginx
podman run -d --pod meu-pod redis
```

## Diferenças do Docker

| Característica | Docker | Podman |
|----------------|--------|--------|
| Daemon | Sim (dockerd) | Não |
| Privilégios root | Geralmente necessário | Opcional (rootless) |
| Pods | Não (apenas containers) | Sim |
| Compatibilidade | Padrão de mercado | Compatível com Docker |
| systemd | Integração básica | Integração nativa |

## Troubleshooting

### Problema: Comando não encontrado após instalação

**Linux:**

```bash
# Adicione ao PATH manualmente
export PATH="$HOME/.local/bin:$PATH"

# Ou reinicie o terminal
```

**macOS:**

```bash
# Inicie a máquina virtual
podman machine start
```

### Problema: Permissões ao executar containers

```bash
# Configure namespaces de usuário (Linux)
echo "$USER:100000:65536" | sudo tee /etc/subuid
echo "$USER:100000:65536" | sudo tee /etc/subgid
```

### Problema: Porta já em uso

```bash
# Verifique o que está usando a porta
sudo lsof -i :8080

# Use outra porta
podman run -p 8081:80 nginx
```

## Recursos Adicionais

- [Documentação Oficial](https://docs.podman.io/)
- [GitHub do Podman](https://github.com/containers/podman)
- [Podman vs Docker](https://docs.podman.io/en/latest/Introduction.html)
- [Tutoriais](https://github.com/containers/podman/blob/main/docs/tutorials/README.md)

## Exemplos Práticos

### Aplicação Node.js

```bash
# Criar Dockerfile
cat > Dockerfile << EOF
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF

# Construir imagem
podman build -t minha-app:latest .

# Executar
podman run -d -p 3000:3000 --name app minha-app:latest
```

### Banco de Dados PostgreSQL

```bash
# Criar volume para persistência
podman volume create pgdata

# Executar PostgreSQL
podman run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=senha123 \
  -e POSTGRES_DB=meudb \
  -v pgdata:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:15

# Conectar ao banco
podman exec -it postgres psql -U postgres -d meudb
```

### Redis Cache

```bash
# Executar Redis
podman run -d \
  --name redis \
  -p 6379:6379 \
  redis:alpine

# Testar conexão
podman exec -it redis redis-cli ping
```

## Migração do Docker para Podman

Se você já usa Docker, migrar é simples:

```bash
# 1. Instalar Podman
susa setup podman

# 2. Criar alias (opcional)
echo "alias docker=podman" >> ~/.bashrc
source ~/.bashrc

# 3. Usar normalmente
docker run hello-world
docker ps
docker-compose up -d  # Use podman-compose
```

**Diferenças a considerar:**

- `docker-compose` → `podman-compose`
- Alguns plugins do Docker não funcionam
- Networking pode ter pequenas diferenças
- Volumes são gerenciados de forma diferente

## Comandos Úteis

```bash
# Limpar containers parados
podman container prune

# Limpar imagens não utilizadas
podman image prune

# Limpar tudo (cuidado!)
podman system prune -a

# Ver uso de espaço
podman system df

# Inspecionar container
podman inspect <container-id>

# Ver logs em tempo real
podman logs -f <container-name>

# Copiar arquivos do/para container
podman cp arquivo.txt <container>:/path/
podman cp <container>:/path/arquivo.txt .

# Executar comando em container rodando
podman exec -it <container> bash
```

## Requisitos de Sistema

### Linux

- Kernel Linux 3.10+
- systemd (opcional, mas recomendado)
- Namespaces de usuário habilitados

### macOS

- macOS 11.0 (Big Sur) ou superior
- Homebrew instalado
- Máquina virtual será criada automaticamente

## Notas Importantes

- **Linux**: Instalação via binário estático, sem necessidade de repositórios
- **macOS**: Requer máquina virtual (criada automaticamente)
- **Rootless**: Por padrão, não precisa de sudo
- **Compose**: Instalado automaticamente (apt/dnf/yum ou pip)
- **Atualizações**: Execute novamente `susa setup podman` para atualizar

## Suporte

Se encontrar problemas:

1. Verifique os logs com `DEBUG=1 susa setup podman`
2. Consulte a [documentação oficial](https://docs.podman.io/)
3. Visite o [GitHub do Podman](https://github.com/containers/podman/issues)
4. Use `susa setup podman --help` para mais informações
