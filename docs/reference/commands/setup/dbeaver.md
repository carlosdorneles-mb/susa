# Setup DBeaver

Instala o DBeaver Community, uma ferramenta universal de gerenciamento de banco de dados, gratuita e open-source, com suporte a mais de 80 tipos diferentes de bancos de dados.

## O que é DBeaver?

DBeaver é uma ferramenta profissional de gerenciamento de banco de dados que oferece interface intuitiva e recursos avançados para trabalhar com diversos sistemas de banco de dados:

- **Suporte Universal**: MySQL, PostgreSQL, SQLite, Oracle, SQL Server, DB2, Sybase, MS Access, Teradata, Firebird, Apache Hive, Phoenix, Presto e mais de 80 tipos
- **Editor SQL Avançado**: Syntax highlighting, autocompletar, formatação automática e validação
- **Navegador de Schema**: Explore estrutura de databases, tabelas, views, procedures
- **Editor ER Diagram**: Visualize relacionamentos entre tabelas
- **Transferência de Dados**: Migre dados entre diferentes bancos de dados
- **Geração de Dados Mock**: Crie dados de teste automaticamente

**Por exemplo:**

```sql
-- Editor SQL com syntax highlighting e autocompletar
SELECT
    u.id,
    u.name,
    u.email,
    COUNT(o.id) AS total_orders,
    SUM(o.total) AS revenue
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.status = 'active'
GROUP BY u.id, u.name, u.email
HAVING COUNT(o.id) > 0
ORDER BY revenue DESC;
```

## Como usar

### Instalar

```bash
susa setup dbeaver
```

O comando vai:

**No macOS:**

- Verificar se o Homebrew está instalado
- Instalar o DBeaver Community via `brew install --cask dbeaver-community`
- Configurar o comando `dbeaver` no PATH

**No Linux:**

- Detectar sua distribuição (Debian/Ubuntu, RHEL/Fedora, Arch)
- Adicionar a chave GPG oficial do DBeaver
- Configurar o repositório apropriado
- Instalar via gerenciador de pacotes nativo
- Configurar o comando `dbeaver`

Depois de instalar, você pode abrir o DBeaver:

```bash
dbeaver              # Abre o DBeaver
```

### Atualizar

```bash
susa setup dbeaver --update
```

Atualiza o DBeaver para a versão mais recente disponível. O comando usa:

- **macOS**: `brew upgrade --cask dbeaver-community`
- **Debian/Ubuntu**: `apt-get install --only-upgrade dbeaver-ce`
- **RHEL/Fedora**: `dnf upgrade dbeaver-ce`
- **Arch**: `yay -Syu dbeaver`

Todas as suas conexões, favoritos e configurações serão preservados.

### Desinstalar

```bash
susa setup dbeaver --uninstall
```

Remove o DBeaver do sistema. O comando vai:

1. Remover o binário e pacote
2. Remover repositórios configurados
3. Suas configurações e conexões permanecerão em:
   - `~/.local/share/DBeaverData` (Linux)
   - `~/Library/DBeaverData` (macOS)

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda detalhada |
| `--update` | Atualiza o DBeaver para a versão mais recente |
| `--uninstall` | Remove o DBeaver do sistema |
| `-v, --verbose` | Habilita saída detalhada para depuração |
| `-q, --quiet` | Minimiza a saída, desabilita mensagens de depuração |

## Guia Rápido de Uso

### Primeira conexão

1. Abra o DBeaver
2. Clique em **Database** → **New Database Connection**
3. Selecione o tipo de banco de dados (MySQL, PostgreSQL, etc.)
4. Configure os parâmetros de conexão:
   - **Host**: localhost ou IP do servidor
   - **Port**: porta padrão do banco
   - **Database**: nome do database
   - **Username** e **Password**: credenciais de acesso
5. Clique em **Test Connection** para validar
6. Clique em **Finish** para salvar

### Principais recursos

#### 1. Editor SQL

Execute queries com recursos avançados:

```sql
-- Autocompletar tabelas e colunas
SELECT * FROM users WHERE |  -- Ctrl+Space mostra sugestões

-- Formatação automática
SELECT id,name,email FROM users WHERE status='active';
-- Ctrl+Shift+F formata para:
SELECT
    id,
    name,
    email
FROM users
WHERE status = 'active';

-- Executar query
-- F9: Executa query atual ou selecionada
-- Ctrl+Enter: Executa script completo
-- Alt+X: Executa atual e mostra em nova tab
```

#### 2. Navegador de Schema

Explore a estrutura do banco:

```
📁 localhost:3306
  └── 📁 Databases
      └── 📁 my_database
          ├── 📁 Tables
          │   ├── 📄 users (id, name, email)
          │   ├── 📄 orders (id, user_id, total)
          │   └── 📄 products (id, name, price)
          ├── 📁 Views
          ├── 📁 Procedures
          └── 📁 Functions
```

**Ações rápidas:**
- **F4**: Abre editor de dados da tabela
- **Ctrl+]**: Gera código SQL
- **Ctrl+Alt+Shift+D**: Abre ER Diagram
- **Right-click** → **Generate SQL** → Gera DDL, SELECT, INSERT, etc.

#### 3. Editor de Dados

Edite dados diretamente na grid:

```bash
# Abrir tabela
Duplo clique na tabela → Tab "Data"

# Editar registro
Duplo clique na célula → Digite → Enter

# Adicionar registro
Ctrl+Alt+A → Preencha campos → Ctrl+S para salvar

# Deletar registro
Selecione linha → Delete → Ctrl+S para confirmar

# Filtros rápidos
Click no header da coluna → "Filter" → Digite valor
```

#### 4. ER Diagram

Visualize relacionamentos:

```bash
# Gerar diagrama
Right-click no database → "View Diagram"

# Adicionar tabelas
Arraste tabelas da lista lateral para o diagrama

# Exportar
File → Export → Image (PNG, SVG, PDF)
```

### Atalhos de teclado

#### Navegação

| Atalho | Ação |
|--------|------|
| `Ctrl+N` | Nova conexão SQL |
| `Ctrl+Shift+N` | Nova conexão de banco |
| `F4` | Abrir editor de dados |
| `Ctrl+]` | Gerar SQL |
| `Alt+Left/Right` | Navegar histórico |
| `Ctrl+F7` | Próxima aba |

#### Editor SQL

| Atalho | Ação |
|--------|------|
| `F9` | Executar query atual/selecionada |
| `Ctrl+Enter` | Executar script completo |
| `Alt+X` | Executar e mostrar em nova tab |
| `Ctrl+Shift+F` | Formatar SQL |
| `Ctrl+Space` | Autocompletar |
| `Ctrl+/` | Comentar/descomentar linha |
| `Ctrl+Shift+E` | Explicar plano de execução |

#### Dados

| Atalho | Ação |
|--------|------|
| `Ctrl+F` | Buscar na grid |
| `Ctrl+Alt+A` | Adicionar novo registro |
| `Delete` | Deletar registro selecionado |
| `Ctrl+S` | Salvar alterações |
| `Ctrl+Z` | Desfazer alterações |
| `F2` | Editar célula |

### Configurações úteis

#### Tema escuro

```
Window → Preferences → User Interface → Appearance
└── Theme: Dark
```

#### Autocompletar

```
Window → Preferences → Editors → SQL Editor → Code Completion
├── ☑ Enable auto activation
├── Auto activation delay: 500ms
└── ☑ Insert best match automatically
```

#### Formatação SQL

```
Window → Preferences → Editors → SQL Editor → Formatting
├── Keyword case: UPPER
├── Identifier case: lower
└── ☑ Format SQL on save
```

#### Conexões seguras

```
Connection settings → Driver properties
└── useSSL: true
└── requireSSL: true
└── verifyServerCertificate: true
```

## Conectando a diferentes bancos

### MySQL/MariaDB

```bash
# Configuração básica
Host: localhost
Port: 3306
Database: mydb
Username: root
Password: ****

# Parâmetros extras (Driver properties)
useSSL: false
allowPublicKeyRetrieval: true
serverTimezone: UTC
```

### PostgreSQL

```bash
# Configuração básica
Host: localhost
Port: 5432
Database: mydb
Username: postgres
Password: ****

# Parâmetros extras
ssl: require
sslmode: require
```

### SQLite

```bash
# Não requer servidor
Path: /path/to/database.db
```

### SQL Server

```bash
# Configuração básica
Host: localhost
Port: 1433
Database: mydb
Authentication: SQL Server
Username: sa
Password: ****

# Windows Authentication
Authentication: Windows
```

### Oracle

```bash
# Configuração básica
Host: localhost
Port: 1521
Database (SID): ORCL
Username: system
Password: ****

# Ou usando Service Name
Service name: XEPDB1
```

### MongoDB

```bash
# Configuração básica
Host: localhost
Port: 27017
Database: mydb
Authentication database: admin
Username: root
Password: ****
```

## Recursos Avançados

### 1. Transferência de dados

Migre dados entre diferentes bancos:

```bash
# Exportar dados
Right-click na tabela → Export Data
└── Escolha formato: SQL, CSV, JSON, XML
└── Configure opções
└── Execute

# Importar dados
Right-click na tabela → Import Data
└── Escolha arquivo e formato
└── Mapeie colunas
└── Execute
```

### 2. Geração de dados mock

Crie dados de teste:

```bash
# Abrir gerador
Right-click na tabela → Generate SQL → Generate Mock Data

# Configure
Rows to generate: 1000
├── id: AUTO_INCREMENT
├── name: FIRST_NAME + LAST_NAME
├── email: EMAIL
├── created_at: DATE_BETWEEN('2020-01-01', '2024-12-31')
└── status: RANDOM(['active', 'inactive', 'pending'])

# Execute
Generate SQL → Run
```

### 3. Scripts e tasks

Execute scripts agendados:

```bash
# Criar task
Database → Database Tasks → Create Task
├── Task name: Backup diário
├── Type: SQL Script
├── Script: /path/to/backup.sql
└── Schedule: Daily at 02:00

# Monitorar tasks
Database → Database Tasks → Task Manager
```

### 4. Bookmarks

Salve queries favoritas:

```sql
-- No editor SQL, escreva query útil
SELECT * FROM users WHERE status = 'active' ORDER BY created_at DESC;

-- Salve como bookmark
Right-click no editor → Bookmarks → Add Bookmark
Name: Usuários ativos recentes
Folder: Users Queries
```

### 5. Schema Compare

Compare estruturas de bancos:

```bash
# Abrir comparador
Database → Compare → Schema

# Selecione databases
Source: production_db
Target: development_db

# Execute comparação
Compare → Mostra diferenças em:
├── Tabelas
├── Colunas
├── Índices
├── Constraints
└── Procedures

# Gerar script de sincronização
Generate Script → Aplica mudanças
```

## Extensões e Plugins

### Office formats

Exporte dados para Excel:

```bash
Help → Install New Software
└── Search: "office"
└── Install: DBeaver Office extension

# Uso
Right-click na tabela → Export Data → XLSX
```

### Git integration

Versionamento de scripts SQL:

```bash
Window → Preferences → DBeaver → Git
└── ☑ Enable Git integration
└── Repository path: /path/to/repo

# Scripts são salvos em:
.dbeaver/
└── sql-scripts/
    └── connection-name/
        └── your-script.sql
```

## Troubleshooting

### Erro de conexão

```bash
# Verificar se banco está rodando
# MySQL
sudo systemctl status mysql

# PostgreSQL
sudo systemctl status postgresql

# Verificar firewall
sudo ufw status
sudo ufw allow 3306/tcp  # MySQL
sudo ufw allow 5432/tcp  # PostgreSQL

# Testar conexão manual
mysql -h localhost -u root -p
psql -h localhost -U postgres
```

### Driver JDBC não encontrado

```bash
# DBeaver baixa drivers automaticamente na primeira conexão
# Se falhar, baixe manualmente:

Database → Driver Manager → Select driver → Download/Update
```

### Performance lenta com grandes resultsets

```bash
# Limitar resultados
Window → Preferences → Editors → SQL Editor → SQL Execute
└── Resultset max rows: 1000

# Ou use LIMIT na query
SELECT * FROM large_table LIMIT 1000;
```

### Erro de memória (OutOfMemoryError)

```bash
# Aumentar heap size
# Edite: dbeaver.ini (Linux) ou DBeaver.app/Contents/Eclipse/dbeaver.ini (macOS)

-Xms128m
-Xmx2048m  # Aumente este valor
```

## Dicas de Produtividade

### 1. Templates SQL

Crie templates reutilizáveis:

```sql
-- Window → Preferences → Editors → SQL Editor → Templates
-- Adicione:

-- Template: sel
SELECT ${columns}
FROM ${table}
WHERE ${condition}
ORDER BY ${order};

-- Template: upd
UPDATE ${table}
SET ${column} = ${value}
WHERE ${condition};

-- Uso: Digite "sel" + Ctrl+Space
```

### 2. Múltiplas conexões

Trabalhe com vários bancos simultaneamente:

```bash
# Abra múltiplos editores SQL
Ctrl+N (várias vezes)

# Alterne rapidamente
Alt+PageUp/PageDown

# Ou use abas
Ctrl+Tab
```

### 3. Scripts compartilhados

Compartilhe queries com a equipe:

```bash
# Salve em projeto
File → New → SQL Project
└── Name: Team Queries

# Organize por pasta
├── Migrations/
├── Reports/
├── Analytics/
└── Maintenance/

# Compartilhe via Git
Project → Team → Share Project
```

### 4. Exportação automática

Agende exportações:

```bash
# Crie script de exportação
File → New → SQL Script → Export Script

-- export_users.sql
\set ON_ERROR_STOP on
\copy (SELECT * FROM users WHERE created_at > CURRENT_DATE - 7)
TO '/tmp/users_weekly.csv' WITH CSV HEADER;

# Agende via cron
0 0 * * 0 dbeaver-cli -sql /path/to/export_users.sql
```

## Recursos e Links

- **Site oficial**: [https://dbeaver.io](https://dbeaver.io)
- **Documentação**: [https://dbeaver.com/docs/](https://dbeaver.com/docs/)
- **GitHub**: [https://github.com/dbeaver/dbeaver](https://github.com/dbeaver/dbeaver)
- **Fórum**: [https://github.com/dbeaver/dbeaver/discussions](https://github.com/dbeaver/dbeaver/discussions)
- **Wiki**: [https://github.com/dbeaver/dbeaver/wiki](https://github.com/dbeaver/dbeaver/wiki)

## Comparação com outras ferramentas

| Recurso | DBeaver | pgAdmin | MySQL Workbench | DataGrip |
|---------|---------|---------|-----------------|----------|
| Suporte multi-DB | ✅ 80+ | ❌ PostgreSQL | ❌ MySQL | ✅ Vários |
| Gratuito | ✅ | ✅ | ✅ | ❌ Pago |
| Open Source | ✅ | ✅ | ✅ | ❌ |
| ER Diagram | ✅ | ✅ | ✅ | ✅ |
| Mock data | ✅ | ❌ | ❌ | ✅ |
| Schema compare | ✅ | ❌ | ✅ | ✅ |
| NoSQL support | ✅ | ❌ | ❌ | ✅ |
| Cloud DB | ✅ | ✅ | ✅ | ✅ |

## Exemplos Práticos

### Análise de performance

```sql
-- Ver queries lentas (MySQL)
SELECT
    query_time,
    lock_time,
    rows_sent,
    rows_examined,
    sql_text
FROM mysql.slow_log
WHERE query_time > 1
ORDER BY query_time DESC
LIMIT 20;

-- Analisar plano de execução
EXPLAIN ANALYZE
SELECT u.*, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id;

-- Ver índices não utilizados (PostgreSQL)
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans
FROM pg_stat_user_indexes
WHERE idx_scan = 0
AND indexname NOT LIKE 'pg_%';
```

### Backup e restore

```sql
-- Backup (exportar)
Right-click no database → Tools → Backup/Restore → Backup
├── Format: Custom
├── Compression: 9
└── File: /backup/mydb_20240116.backup

-- Restore (importar)
Right-click no database → Tools → Backup/Restore → Restore
└── File: /backup/mydb_20240116.backup
```

### Migração entre bancos

```bash
# Exemplo: MySQL → PostgreSQL

# 1. Exportar schema
Right-click MySQL database → Generate SQL → DDL
└── Save as mysql_schema.sql

# 2. Converter DDL para PostgreSQL
# Edite manualmente ou use ferramentas como pgloader

# 3. Exportar dados
Right-click MySQL tables → Export Data → CSV
├── Format: CSV
├── Headers: Yes
└── Encoding: UTF-8

# 4. Importar no PostgreSQL
Right-click PostgreSQL tables → Import Data → CSV
└── Map columns → Execute
```

### Análise de dados

```sql
-- Dashboard de métricas
-- Salve como bookmark "Daily Metrics"

-- Total de usuários por status
SELECT status, COUNT(*) as total
FROM users
GROUP BY status;

-- Vendas por dia (último mês)
SELECT
    DATE(created_at) as date,
    COUNT(*) as orders,
    SUM(total) as revenue
FROM orders
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Top 10 produtos mais vendidos
SELECT
    p.name,
    COUNT(oi.id) as quantity_sold,
    SUM(oi.price * oi.quantity) as revenue
FROM products p
JOIN order_items oi ON p.id = oi.product_id
GROUP BY p.id, p.name
ORDER BY quantity_sold DESC
LIMIT 10;
```

## Variáveis de Ambiente

O comando usa as seguintes variáveis configuráveis:

| Variável | Valor Padrão | Descrição |
|----------|--------------|-----------|
| `DBEAVER_HOMEBREW_CASK` | `dbeaver-community` | Nome do cask no Homebrew (macOS) |
| `DBEAVER_APT_KEY_URL` | `https://dbeaver.io/debs/dbeaver.gpg.key` | URL da chave GPG para repositório APT |
| `DBEAVER_APT_REPO` | `https://dbeaver.io/debs/dbeaver-ce` | URL do repositório APT (Debian/Ubuntu) |
| `DBEAVER_GITHUB_REPO` | `dbeaver/dbeaver` | Repositório GitHub para releases |
| `DBEAVER_PACKAGE_NAME` | `dbeaver-ce` | Nome do pacote em distribuições Linux |

Para personalizar, edite o arquivo `/commands/setup/dbeaver/command.json`.
