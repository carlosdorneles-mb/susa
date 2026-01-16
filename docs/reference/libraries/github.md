# github.sh

Biblioteca para gerenciamento de releases do GitHub com suporte a download, verificação de integridade e instalação automática.

## Visão Geral

A biblioteca `github.sh` fornece funções reutilizáveis para:

- Obter informações de releases do GitHub
- Baixar releases com retry automático
- Verificar integridade com checksums (SHA256, SHA512, MD5)
- Detectar sistema operacional e arquitetura
- Extrair e instalar binários automaticamente

## Importação

```bash
source "$LIB_DIR/github.sh"
```

## Funções

### github_get_latest_version

Obtém a tag da última release de um repositório GitHub.

```bash
github_get_latest_version "owner/repo"
```

**Parâmetros:**

- `repo` - Repositório no formato `owner/repo`

**Retorna:**

- Tag da última release (ex: `v1.2.3`)
- Código 1 em caso de erro

**Exemplo:**

```bash
version=$(github_get_latest_version "jdx/mise")
echo "Última versão: $version"
```

**Variáveis de Ambiente:**

- `GITHUB_API_MAX_TIME` - Timeout máximo em segundos (padrão: 10)
- `GITHUB_API_CONNECT_TIMEOUT` - Timeout de conexão (padrão: 5)

---

### github_detect_os_arch

Detecta o sistema operacional e arquitetura atual.

```bash
github_detect_os_arch [formato]
```

**Parâmetros:**
- `formato` - Formato do nome do OS (opcional):
  - `standard` (padrão): Linux=`linux`, macOS=`macos`
  - `darwin-macos`: Linux=`linux`, macOS=`darwin`
  - `linux-gnu`: Linux=`linux-gnu`, macOS=`macos`

**Retorna:**
- String no formato `os_name:arch` (ex: `linux:x64`)
- Código 1 se sistema não suportado

**Arquiteturas Suportadas:**
- `x64` (x86_64)
- `arm64` (aarch64, arm64)
- `armv7` (armv7l)
- `x86` (i686)

**Exemplo:**
```bash
os_arch=$(github_detect_os_arch)
os_name="${os_arch%:*}"
arch="${os_arch#*:}"
echo "OS: $os_name, Arquitetura: $arch"
```

---

### github_build_download_url

Constrói URL de download para um release específico.

```bash
github_build_download_url "owner/repo" "version" "os_name" "arch" "file_pattern"
```

**Parâmetros:**
- `repo` - Repositório no formato `owner/repo`
- `version` - Tag da versão (com ou sem prefixo `v`)
- `os_name` - Nome do sistema operacional
- `arch` - Arquitetura
- `file_pattern` - Padrão do nome do arquivo com placeholders:
  - `{version}` - Versão sem prefixo `v`
  - `{os}` - Sistema operacional
  - `{arch}` - Arquitetura

**Retorna:**
- URL completa do download

**Exemplo:**
```bash
url=$(github_build_download_url \
    "jdx/mise" \
    "v2024.1.0" \
    "linux" \
    "x64" \
    "mise-{version}-{os}-{arch}.tar.gz")
echo "$url"
# https://github.com/jdx/mise/releases/download/v2024.1.0/mise-2024.1.0-linux-x64.tar.gz
```

---

### github_download_release

Baixa um arquivo de release do GitHub.

```bash
github_download_release "url" "output_file" [description]
```

**Parâmetros:**
- `url` - URL completa do arquivo
- `output_file` - Caminho onde salvar o arquivo
- `description` - Descrição para logs (opcional, padrão: "arquivo")

**Retorna:**
- Código 0 em sucesso
- Código 1 em erro

**Características:**
- Barra de progresso visual
- Timeout de 300 segundos
- 3 tentativas com delay de 2 segundos
- Cria diretórios automaticamente

**Exemplo:**
```bash
if github_download_release \
    "https://github.com/jdx/mise/releases/download/v2024.1.0/mise.tar.gz" \
    "/tmp/mise.tar.gz" \
    "Mise"; then
    echo "Download concluído!"
fi
```

---

### github_verify_checksum

Verifica a integridade de um arquivo usando checksum.

```bash
github_verify_checksum "file" "checksum_source" [algorithm]
```

**Parâmetros:**
- `file` - Caminho do arquivo a verificar
- `checksum_source` - Hash esperado ou caminho do arquivo de checksum
- `algorithm` - Algoritmo (opcional, padrão: `sha256`)
  - `sha256`
  - `sha512`
  - `md5`

**Retorna:**
- Código 0 se checksum válido
- Código 1 se inválido

**Comportamento:**
- Se o comando de hash não estiver disponível, retorna 0 com warning
- Se `checksum_source` for um arquivo, procura o hash correspondente
- Comparação case-insensitive

**Exemplo:**
```bash
# Com hash direto
github_verify_checksum \
    "/tmp/file.tar.gz" \
    "abc123def456..." \
    "sha256"

# Com arquivo de checksum
github_verify_checksum \
    "/tmp/file.tar.gz" \
    "/tmp/checksums.txt" \
    "sha256"
```

---

### github_download_and_verify

Baixa um arquivo e verifica seu checksum.

```bash
github_download_and_verify "download_url" "checksum_url" "output_file" [algorithm] [description]
```

**Parâmetros:**
- `download_url` - URL do arquivo principal
- `checksum_url` - URL do arquivo de checksum (ou "none" para pular)
- `output_file` - Caminho de destino
- `algorithm` - Algoritmo de hash (opcional, padrão: `sha256`)
- `description` - Descrição para logs (opcional)

**Retorna:**
- Código 0 em sucesso
- Código 1 em erro ou checksum inválido

**Comportamento:**
- Se `checksum_url` for vazio ou "none", pula verificação
- Se download do checksum falhar, continua sem verificação
- Remove arquivos em caso de falha na verificação

**Exemplo:**
```bash
github_download_and_verify \
    "https://github.com/owner/repo/releases/download/v1.0/file.tar.gz" \
    "https://github.com/owner/repo/releases/download/v1.0/file.tar.gz.sha256" \
    "/tmp/file.tar.gz" \
    "sha256" \
    "My Tool"
```

---

### github_extract_tarball

Extrai um arquivo tar.gz.

```bash
github_extract_tarball "tar_file" [extract_dir]
```

**Parâmetros:**
- `tar_file` - Caminho do arquivo .tar.gz
- `extract_dir` - Diretório de destino (opcional, padrão: `/tmp/github-extract-$$`)

**Retorna:**
- Caminho do diretório de extração
- Código 1 em erro

**Exemplo:**
```bash
extracted=$(github_extract_tarball "/tmp/tool.tar.gz" "/tmp/tool-extract")
echo "Extraído em: $extracted"
```

---

### github_install_binary

Instala um binário de um diretório extraído.

```bash
github_install_binary "extracted_dir" "binary_name" "install_dir"
```

**Parâmetros:**
- `extracted_dir` - Diretório com arquivos extraídos
- `binary_name` - Nome do binário a procurar
- `install_dir` - Diretório de instalação

**Retorna:**
- Caminho completo do binário instalado
- Código 1 em erro

**Comportamento:**
- Procura o binário recursivamente
- Move para diretório de instalação
- Define permissões de execução
- Remove arquivos temporários

**Exemplo:**
```bash
binary_path=$(github_install_binary \
    "/tmp/extracted" \
    "mise" \
    "$HOME/.local/bin")
echo "Instalado em: $binary_path"
```

---

### github_install_release

Função completa: baixa, verifica e instala um release do GitHub.

```bash
github_install_release "owner/repo" "version" "binary_name" "install_dir" "file_pattern" [checksum_pattern] [algorithm]
```

**Parâmetros:**
- `repo` - Repositório no formato `owner/repo`
- `version` - Tag da versão
- `binary_name` - Nome do binário a instalar
- `install_dir` - Diretório de instalação
- `file_pattern` - Padrão do arquivo (com placeholders)
- `checksum_pattern` - Padrão do arquivo de checksum (opcional)
- `algorithm` - Algoritmo de hash (opcional, padrão: `sha256`)

**Retorna:**
- Caminho do binário instalado
- Código 1 em erro

**Processo:**
1. Detecta sistema operacional e arquitetura
2. Constrói URLs de download
3. Baixa e verifica checksum (se disponível)
4. Extrai arquivo
5. Instala binário
6. Remove arquivos temporários

**Exemplo:**
```bash
# Instalação completa com verificação
github_install_release \
    "jdx/mise" \
    "v2024.1.0" \
    "mise" \
    "$HOME/.local/bin" \
    "mise-{version}-{os}-{arch}.tar.gz" \
    "mise-{version}-{os}-{arch}.tar.gz.sha256" \
    "sha256"

# Instalação sem verificação
github_install_release \
    "owner/tool" \
    "v1.0.0" \
    "tool" \
    "$HOME/.local/bin" \
    "tool-{version}-{os}-{arch}.tar.gz"
```

## Dependências

- `curl` - Download de arquivos
- `tar` - Extração de arquivos
- `sha256sum` ou `shasum` - Verificação de checksums (opcional)
- `logger.sh` - Logs estruturados

## Exemplos de Uso

Veja [github-examples.md](github-examples.md) para exemplos práticos detalhados.

## Tratamento de Erros

Todas as funções:
- Retornam código 0 em sucesso, 1 em erro
- Geram logs informativos usando `log_*` functions
- Limpam arquivos temporários em caso de erro

## Veja Também

- [Guia de Adicionar Comandos](../../guides/adding-commands.md)
- [logger.sh](logger.md) - Sistema de logs
- [os.sh](os.md) - Detecção de sistema operacional
