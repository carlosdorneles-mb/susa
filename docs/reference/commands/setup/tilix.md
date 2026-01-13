# Setup Tilix

Instala o Tilix, um emulador de terminal avançado para Linux usando GTK+ 3, com suporte a tiles (painéis lado a lado), notificações, transparência e temas personalizáveis.

## O que é Tilix?

Tilix (anteriormente Terminix) é um emulador de terminal moderno para Linux que oferece recursos poderosos para usuários avançados e desenvolvedores:

- **Tiles**: Divida a janela em múltiplos painéis lado a lado ou empilhados
- **Notificações**: Receba alertas quando comandos longos terminam
- **Transparência**: Configure fundo transparente ou imagens de fundo
- **Drag & Drop**: Arraste arquivos diretamente para o terminal
- **Hyperlinks**: URLs e caminhos de arquivos clicáveis
- **Temas**: Suporte a esquemas de cores personalizados

**Por exemplo:**

```bash
# Trabalhe com múltiplas views ao mesmo tempo:
# ┌─────────────┬─────────────┐
# │  Servidor   │   Logs      │
# │             │             │
# ├─────────────┼─────────────┤
# │  Editor     │   Tests     │
# │             │             │
# └─────────────┴─────────────┘
```

## Como usar

### Instalar

```bash
susa setup tilix
```

O comando vai:

- Detectar seu gerenciador de pacotes (apt, dnf, pacman, etc.)
- Atualizar a lista de pacotes
- Instalar o Tilix via gerenciador de pacotes
- Configurar integração VTE (se disponível)

Depois de instalar, você encontrará o Tilix no menu de aplicativos. Para configurá-lo como terminal padrão:

```bash
sudo update-alternatives --config x-terminal-emulator
```

### Atualizar

```bash
susa setup tilix --update
```

Atualiza o Tilix para a versão mais recente disponível nos repositórios do seu sistema. Todas as suas configurações e preferências serão preservadas.

### Desinstalar

```bash
susa setup tilix --uninstall
```

Remove o Tilix do sistema. Você terá a opção de também remover as configurações e preferências salvas em `~/.config/tilix`.

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda detalhada |
| `--update` | Atualiza o Tilix para a versão mais recente |
| `-u, --uninstall` | Remove o Tilix do sistema |
| `-v, --verbose` | Habilita saída detalhada para depuração |
| `-q, --quiet` | Minimiza a saída, desabilita mensagens de depuração |

## Guia Rápido de Uso

### Atalhos Essenciais

**Gerenciamento de Tiles**

```
Ctrl+Alt+T     - Novo terminal em tile
Ctrl+Alt+D     - Dividir horizontalmente
Ctrl+Alt+R     - Dividir verticalmente
Alt+Setas      - Navegar entre tiles
Ctrl+Alt+W     - Fechar tile atual
```

**Navegação e Busca**

```
Ctrl+Shift+F   - Buscar no terminal
Ctrl+Shift+C   - Copiar
Ctrl+Shift+V   - Colar
Ctrl+Shift+H   - Ver histórico
Ctrl+L         - Limpar tela
```

**Sessões e Abas**

```
Ctrl+Shift+T   - Nova aba
Ctrl+Shift+W   - Fechar aba
Ctrl+PgUp/PgDn - Alternar entre abas
Ctrl+Shift+N   - Nova janela
```

**Zoom e Visualização**

```
Ctrl++         - Aumentar fonte
Ctrl+-         - Diminuir fonte
Ctrl+0         - Reset zoom
F11            - Tela cheia
```

### Configuração Inicial

**1. Acessar Preferências**

```bash
# Via menu
Tilix → Preferences

# Ou pressione
Ctrl+,
```

**2. Configurar Perfil Padrão**

```
Preferences → Profiles → Default
• Command: Usar shell de login
• Colors: Escolher esquema de cores
• Text: Configurar fonte (recomendado: Monospace 11)
```

**3. Habilitar VTE Integration**

Adicione ao seu `~/.bashrc` ou `~/.zshrc`:

```bash
# Para Tilix VTE integration
if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
    source /etc/profile.d/vte.sh
fi
```

Depois execute:

```bash
source ~/.bashrc  # ou ~/.zshrc
```

## Recursos Avançados

### 1. Layouts Personalizados

Salve seu layout de tiles favorito:

```
1. Organize seus tiles como preferir
2. Tilix → Save Layout
3. Nome: "desenvolvimento"
4. Para carregar: Tilix → Load Layout → desenvolvimento
```

### 2. Notificações

Configure alertas quando comandos demorados terminam:

```
Preferences → Advanced
• Enable: "Show notifications when commands complete"
• Threshold: 30 segundos (customizável)
```

Exemplo de uso:

```bash
# Comando longo
npm run build
# Você será notificado quando terminar!
```

### 3. Badges (Emblemas)

Mostre informações na barra de título:

```
Preferences → Profiles → Default → Advanced
• Badge text: ${userName}@${hostName}:${columns}x${rows}
```

Variáveis disponíveis:
- `${userName}` - Nome do usuário
- `${hostName}` - Nome do host
- `${columns}` - Colunas do terminal
- `${rows}` - Linhas do terminal
- `${profileName}` - Nome do perfil

### 4. Triggers (Gatilhos)

Execute ações automáticas baseadas em padrões:

```
Preferences → Profiles → Default → Advanced → Triggers

Exemplo: Destacar erros
• Pattern: ERROR|FATAL|FAIL
• Action: Highlight Text
• Color: Vermelho
```

### 5. Hyperlinks Automáticos

Configure reconhecimento de padrões:

```
Preferences → Advanced → URL
• Auto-detect: URLs, file paths, email addresses
• Custom regex patterns para casos específicos
```

### 6. Sessões Nomeadas

Salve e restaure grupos de trabalho:

```bash
# Salvar sessão atual
Tilix → Save Session → "projeto-web"

# Restaurar depois
Tilix → Load Session → "projeto-web"
```

## Esquemas de Cores Populares

### Temas Built-in

O Tilix vem com vários temas pré-instalados:

- **Solarized Dark/Light** - Esquema equilibrado e suave
- **Monokai** - Colorido e vibrante
- **Dracula** - Dark theme popular
- **Gruvbox** - Warm dark theme
- **One Dark** - Inspirado no Atom

### Importar Temas Customizados

```bash
# 1. Baixar arquivo .json do tema
# 2. Copiar para o diretório de esquemas
mkdir -p ~/.config/tilix/schemes
cp meu-tema.json ~/.config/tilix/schemes/

# 3. Reiniciar Tilix
# 4. Preferences → Profiles → Colors → Color scheme
```

### Criar Seu Próprio Tema

```bash
# Exportar tema atual como base
tilix --export-scheme > meu-tema.json

# Editar cores no JSON
# Importar de volta
```

## Integração com Shell

### Bash

Adicione ao `~/.bashrc`:

```bash
# Tilix VTE integration
if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
    source /etc/profile.d/vte.sh
fi

# Definir título da janela
if [ "$TILIX_ID" ]; then
    function set-title() {
        echo -ne "\033]0;$1\007"
    }
fi

# Mostrar comando atual no título
trap 'echo -ne "\033]0;${BASH_COMMAND}\007"' DEBUG
```

### Zsh

Adicione ao `~/.zshrc`:

```bash
# Tilix VTE integration
if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
    source /etc/profile.d/vte.sh
fi

# Título dinâmico
precmd() {
    print -Pn "\e]0;%n@%m: %~\a"
}

preexec() {
    print -Pn "\e]0;%n@%m: $1\a"
}
```

## Comparação com Outros Terminais

| Recurso | Tilix | Terminator | GNOME Terminal | Kitty |
|---------|-------|------------|----------------|-------|
| **Tiles nativos** | ✅ Sim | ✅ Sim | ❌ Não | ✅ Sim |
| **Drag & Drop** | ✅ Sim | ❌ Não | ❌ Não | ✅ Sim |
| **Notificações** | ✅ Sim | ❌ Não | ❌ Não | ✅ Sim |
| **Transparência** | ✅ Sim | ✅ Sim | ✅ Sim | ✅ Sim |
| **GPU Acceleration** | ❌ Não | ❌ Não | ✅ Sim (VTE4) | ✅ Sim |
| **Quake mode** | ✅ Sim | ❌ Não | ❌ Não | ❌ Não |
| **Interface** | GTK+ 3 | GTK+ | GTK+ | OpenGL |

## Configurações Recomendadas

### Performance

```
Preferences → Advanced
• Disable: "Use overlay scrollbar"
• Enable: "Optimize rendering"
• Scrollback lines: 10000 (ou menos para melhor performance)
```

### Aparência

```
Preferences → Appearance
• Theme variant: Dark (ou Light)
• Window style: Normal (ou Disable CSD para janela tradicional)
• Terminal title: Show when single (economiza espaço)

Preferences → Profiles → Default → Text
• Font: Fira Code Mono 11 (ou sua preferência)
• Enable: "Custom font"
• Anti-aliasing: Greyscale
```

### Comportamento

```
Preferences → Advanced → Session
• When terminal commands set title: Replace title
• Run command as login shell: Enabled

Preferences → Advanced → Terminal
• Rewrap on resize: Enabled
• Show unsafe paste dialog: Enabled (segurança)
```

## Quake Mode

Configure um terminal dropdown estilo Quake:

```
Preferences → Quake
1. Enable "Enable quake mode"
2. Shortcut: F12 (ou sua preferência)
3. Height: 50% (metade da tela)
4. Position: Top
5. Enable: "Hide on focus loss"
```

Agora pressione F12 para mostrar/esconder o terminal!

## Troubleshooting

### Terminal não abre após instalação

```bash
# Verificar instalação
which tilix
tilix --version

# Verificar logs
journalctl -xe | grep tilix

# Reinstalar
susa setup tilix --update
```

### VTE integration não funciona

```bash
# Verificar se existe o arquivo
ls -la /etc/profile.d/vte.sh

# Se não existir, criar manualmente
sudo ln -s /etc/profile.d/vte-*.sh /etc/profile.d/vte.sh

# Recarregar shell
source ~/.bashrc
```

### Fontes não aparecem corretamente

```bash
# Instalar fontes recomendadas
sudo apt install fonts-firacode fonts-hack-ttf

# Recarregar cache de fontes
fc-cache -fv

# Reiniciar Tilix
```

### Performance lenta com transparência

```
Preferences → Profiles → Default → Colors
• Disable: "Use transparent background"
• Ou reduzir: Transparency level para 90%

Preferences → Advanced
• Disable: "Use transparency"
```

### Configurações não salvam

```bash
# Verificar permissões
ls -la ~/.config/tilix

# Corrigir se necessário
chmod 755 ~/.config/tilix
chmod 644 ~/.config/tilix/tilix.conf

# Reset configurações (se necessário)
dconf reset -f /com/gexperts/Tilix/
```

## Compatibilidade

- **Sistema Operacional**: Linux (Distribuições baseadas em Debian, Red Hat, Arch, etc.)
- **Desktop Environment**: Funciona em GNOME, KDE, XFCE, i3, e outros
- **Dependências**: GTK+ 3.18 ou superior, VTE 0.46 ou superior
- **Instalação**: Via gerenciador de pacotes do sistema

## Gerenciadores de Pacotes Suportados

| Distribuição | Gerenciador | Comando usado |
|--------------|-------------|---------------|
| **Ubuntu/Debian** | apt | `sudo apt-get install tilix` |
| **Fedora** | dnf | `sudo dnf install tilix` |
| **CentOS/RHEL** | yum | `sudo yum install tilix` |
| **Arch Linux** | pacman | `sudo pacman -S tilix` |
| **openSUSE** | zypper | `sudo zypper install tilix` |

## Links Úteis

- [Site Oficial](https://gnunn1.github.io/tilix-web/)
- [GitHub Repository](https://github.com/gnunn1/tilix)
- [Documentação](https://gnunn1.github.io/tilix-web/manual/)
- [Wiki](https://github.com/gnunn1/tilix/wiki)
- [Color Schemes](https://github.com/storm119/Tilix-Themes)
- [Issue Tracker](https://github.com/gnunn1/tilix/issues)

## Próximos Passos

Depois de instalar o Tilix:

1. ✅ Configure VTE integration no shell
2. ✅ Escolha seu esquema de cores favorito
3. ✅ Configure atalhos personalizados
4. ✅ Experimente criar layouts salvos
5. ✅ Habilite Quake mode
6. ✅ Configure triggers para alertas
7. ✅ Explore os recursos de notificação

---

**Dica**: Tilix é altamente personalizável através do dconf-editor. Explore `com.gexperts.Tilix` para opções avançadas! 🎨
