# Setup Flameshot

Instala o Flameshot, uma ferramenta poderosa e simples de captura de tela com recursos de anotação, edição e compartilhamento.

## O que é Flameshot?

Flameshot é uma ferramenta de captura de tela open-source com recursos avançados de edição e anotação:

- **Captura Interativa**: Selecione área específica da tela com feedback visual
- **Editor Integrado**: Ferramentas de desenho e anotação embutidas
- **Multiplataforma**: Linux e macOS
- **Leve e Rápido**: Interface responsiva com baixo uso de recursos
- **Atalhos Customizáveis**: Configure teclas de atalho personalizadas
- **Upload Direto**: Envie screenshots para Imgur automaticamente
- **Multi-Monitor**: Suporte completo para múltiplos monitores

**Ferramentas de edição disponíveis:**

- Setas, linhas e formas geométricas
- Texto com fontes customizáveis
- Marcador e caneta
- Desfoque e pixelização
- Contador numerado
- Seletor de cores
- Desfazer/Refazer ilimitado

## Como usar

### Instalar

```bash
susa setup flameshot
```

O comando vai:

**No macOS:**

- Verificar se o Homebrew está instalado
- Instalar o Flameshot via `brew install flameshot`
- Configurar o comando `flameshot` no PATH

**No Linux:**

- Detectar distribuição automaticamente
- **Debian/Ubuntu**: Instalar via apt-get
- **Fedora/RHEL**: Instalar via dnf/yum
- **Arch**: Instalar via pacman

Depois de instalar, você pode usar:

```bash
flameshot gui            # Modo interativo (recomendado)
flameshot full           # Captura tela inteira
flameshot screen         # Captura tela específica
flameshot launcher       # Abre menu de opções
```

### Atualizar

```bash
susa setup flameshot --upgrade
```

Atualiza o Flameshot para a versão mais recente disponível nos repositórios.

### Desinstalar

```bash
susa setup flameshot --uninstall
```

Remove o Flameshot do sistema completamente.

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda detalhada |
| `-u, --upgrade` | Atualiza o Flameshot para a versão mais recente |
| `--uninstall` | Remove o Flameshot do sistema |
| `-v, --verbose` | Habilita saída detalhada para depuração |
| `-q, --quiet` | Minimiza a saída, desabilita mensagens de depuração |

## Requisitos

- **macOS**: Homebrew instalado
- **Linux**: Sistema com apt-get, dnf/yum ou pacman

## Uso Básico

### Captura Interativa (Recomendado)

```bash
# Abre interface de seleção de área
flameshot gui

# Com delay de 2 segundos
flameshot gui -d 2000

# Salva diretamente em arquivo
flameshot gui -p ~/Pictures/screenshots/

# Copia para clipboard
flameshot gui -c
```

### Captura Completa

```bash
# Captura toda a tela e salva
flameshot full -p ~/Pictures/

# Captura e copia para clipboard
flameshot full -c

# Captura com delay de 2 segundos
flameshot full -d 2000
```

### Captura de Tela Específica

```bash
# Captura monitor 0
flameshot screen -n 0 -p ~/Pictures/

# Captura monitor 1
flameshot screen -n 1 -p ~/Pictures/
```

## Configuração

### Configurar Atalho de Teclado (Linux)

#### GNOME / Ubuntu

```bash
# 1. Abra Settings
gnome-control-center

# 2. Vá para Keyboard → Keyboard Shortcuts → Custom Shortcuts

# 3. Adicione novo atalho:
#    Nome: Flameshot
#    Comando: flameshot gui
#    Atalho: Print (tecla Print Screen)
```

#### KDE Plasma

```bash
# 1. Abra System Settings
systemsettings5

# 2. Vá para Shortcuts → Custom Shortcuts

# 3. Adicione:
#    Action: flameshot gui
#    Trigger: Print
```

#### i3 / Sway

Adicione ao arquivo de configuração (~/.config/i3/config ou ~/.config/sway/config):

```bash
# Flameshot shortcuts
bindsym Print exec flameshot gui
bindsym Shift+Print exec flameshot full -p ~/Pictures/screenshots/
bindsym Ctrl+Print exec flameshot screen
```

### Configurar Atalho (macOS)

```bash
# 1. Abra System Preferences → Keyboard → Shortcuts

# 2. Selecione "App Shortcuts" e clique em "+"

# 3. Configure:
#    Application: All Applications
#    Menu Title: (deixe vazio)
#    Keyboard Shortcut: Cmd+Shift+5 (ou outra combinação)

# 4. Configure comando via Automator ou BetterTouchTool
```

Ou use via linha de comando:

```bash
# Adicione ao ~/.zshrc ou ~/.bashrc
alias screenshot='flameshot gui'
```

### Arquivo de Configuração

Flameshot salva configurações em:

- **Linux**: `~/.config/flameshot/flameshot.ini`
- **macOS**: `~/Library/Preferences/flameshot/flameshot.ini`

Exemplo de configuração:

```ini
[General]
disabledTrayIcon=false
showStartupLaunchMessage=false
drawColor=#ff0000
drawThickness=2

[Shortcuts]
TYPE_ARROW=A
TYPE_CIRCLE=C
TYPE_COPY=Ctrl+C
TYPE_DRAWER=D
TYPE_EXIT=Esc
TYPE_MARKER=M
TYPE_MOVESELECTION=Ctrl+M
TYPE_REDO=Ctrl+Shift+Z
TYPE_SAVE=Ctrl+S
TYPE_SELECTION=S
TYPE_TEXT=T
TYPE_UNDO=Ctrl+Z
```

## Recursos Avançados

### Ferramentas de Anotação

Durante a captura interativa, use as seguintes teclas:

| Tecla | Ferramenta |
|-------|-----------|
| `S` | Seleção retangular |
| `A` | Seta |
| `L` | Linha |
| `D` | Caneta/Desenho |
| `R` | Retângulo |
| `C` | Círculo |
| `T` | Texto |
| `M` | Marcador |
| `B` | Desfoque |
| `P` | Pixelização |
| `N` | Contador numerado |
| `U` | Upload para Imgur |
| `Ctrl+C` | Copiar para clipboard |
| `Ctrl+S` | Salvar arquivo |
| `Ctrl+Z` | Desfazer |
| `Ctrl+Shift+Z` | Refazer |
| `Esc` | Cancelar |

### Upload para Imgur

```bash
# Configurar chave API do Imgur (opcional)
flameshot config

# Captura e faz upload automático
flameshot gui
# Pressione 'U' após editar
```

### Integração com Script

```bash
#!/bin/bash

# Captura screenshot e retorna caminho do arquivo
screenshot=$(flameshot gui -r)

# Processa imagem
if [ -n "$screenshot" ]; then
    echo "Screenshot salva em: $screenshot"
    # Faz algo com a imagem
    convert "$screenshot" -resize 50% "$screenshot"
fi
```

### Captura com Nome Personalizado

```bash
#!/bin/bash

# Gera nome com timestamp
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
filename="screenshot_${timestamp}.png"

# Captura e salva
flameshot gui -p ~/Pictures/screenshots/ -f "$filename"
```

### Modo Daemon

Execute Flameshot em background:

```bash
# Inicia daemon
flameshot &

# Agora pode usar atalhos globais configurados
```

Adicione ao arquivo de inicialização:

```bash
# ~/.config/autostart/flameshot.desktop (Linux)
[Desktop Entry]
Name=Flameshot
Exec=flameshot
Terminal=false
Type=Application
Icon=flameshot
```

## Comparação com Outras Ferramentas

| Recurso | Flameshot | GNOME Screenshot | Spectacle | macOS Screenshot |
|---------|-----------|------------------|-----------|------------------|
| **Editor Integrado** | ✅ Completo | ❌ Não | ⚠️ Básico | ⚠️ Básico |
| **Anotações** | ✅ Muitas | ❌ Não | ⚠️ Limitado | ⚠️ Limitado |
| **Upload Imgur** | ✅ Sim | ❌ Não | ❌ Não | ❌ Não |
| **Atalhos Personalizáveis** | ✅ Sim | ⚠️ Limitado | ✅ Sim | ⚠️ Limitado |
| **Multi-Monitor** | ✅ Sim | ✅ Sim | ✅ Sim | ✅ Sim |
| **Desfoque/Pixelização** | ✅ Sim | ❌ Não | ❌ Não | ❌ Não |
| **Open Source** | ✅ Sim | ✅ Sim | ✅ Sim | ❌ Não |
| **Plataformas** | Linux, macOS | Linux | Linux | macOS |

## Dicas e Truques

### 1. Screenshots Programadas

```bash
# Captura após 5 segundos (útil para menus)
flameshot gui -d 5000
```

### 2. Captura de Janela Específica

```bash
# Use wmctrl para obter ID da janela
wmctrl -l

# Captura janela específica
flameshot gui -w <window-id>
```

### 3. Qualidade e Formato

Por padrão, Flameshot salva em PNG. Configure no arquivo ini:

```ini
[General]
saveAsFileExtension=jpg
```

### 4. Tema Escuro

```bash
# Ativa tema escuro (Linux)
export QT_QPA_PLATFORMTHEME=qt5ct
flameshot gui
```

### 5. Desabilitar Sons

```ini
[General]
startupLaunchMessage=false
checkForUpdates=false
```

## Solução de Problemas

### Linux: Flameshot não captura tela corretamente

```bash
# Problema com Wayland
# Solução: Use XWayland ou configure permissões

# Para GNOME Wayland, instale extensão
gnome-extensions install screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com
```

### Linux: Atalho não funciona

```bash
# Verifique se flameshot está no PATH
which flameshot

# Teste comando manualmente
flameshot gui

# Reconfigure atalho usando caminho completo
/usr/bin/flameshot gui
```

### macOS: Permissões de Screen Recording

```bash
# 1. Abra System Preferences
# 2. Security & Privacy → Privacy → Screen Recording
# 3. Adicione flameshot e marque checkbox
# 4. Reinicie o aplicativo
```

### macOS: Flameshot não abre

```bash
# Verifique quarentena
xattr -d com.apple.quarantine $(which flameshot)

# Reinstale
brew reinstall flameshot
```

### Captura fica preta

```bash
# Problema com drivers gráficos
# Tente modo de compatibilidade

flameshot gui --raw
```

## Integração com Outras Ferramentas

### Com ImageMagick

```bash
# Captura e converte para diferentes formatos
flameshot full -c | convert - -quality 90 output.jpg
```

### Com OCR (Tesseract)

```bash
#!/bin/bash
# Captura e extrai texto

tempfile=$(mktemp --suffix=.png)
flameshot gui -r > "$tempfile"
tesseract "$tempfile" - | xclip -selection clipboard
rm "$tempfile"
```

### Com Dropbox/Cloud

```bash
#!/bin/bash
# Captura e salva no Dropbox

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
flameshot gui -p ~/Dropbox/Screenshots/ -f "screenshot_${timestamp}.png"
```

## Variáveis de Ambiente do Comando

O comando usa as seguintes variáveis que podem ser customizadas:

```bash
FLAMESHOT_HOMEBREW_FORMULA="flameshot"
FLAMESHOT_GITHUB_REPO="flameshot-org/flameshot"
```

Para customizar, edite o arquivo `command.json` no diretório `commands/setup/flameshot/` antes da instalação.

## Links Úteis

- **Site oficial**: https://flameshot.org/
- **GitHub**: https://github.com/flameshot-org/flameshot
- **Documentação**: https://flameshot.org/docs/
- **Relatórios de bugs**: https://github.com/flameshot-org/flameshot/issues

## Conclusão

Flameshot é a ferramenta ideal para quem precisa de:

- ✅ Capturas de tela frequentes
- ✅ Anotações e edições rápidas
- ✅ Compartilhamento ágil
- ✅ Workflow produtivo
- ✅ Solução open-source e gratuita

Perfeita para desenvolvedores, designers, suporte técnico, documentação e qualquer trabalho que exija comunicação visual eficiente.
