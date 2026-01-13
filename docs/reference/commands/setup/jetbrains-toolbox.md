# JetBrains Toolbox

Instala e configura o JetBrains Toolbox, gerenciador oficial para todas as IDEs da JetBrains.

## O que é JetBrains Toolbox?

JetBrains Toolbox é um aplicativo que facilita o gerenciamento de todas as IDEs da JetBrains a partir de uma única interface. Permite instalar, atualizar e gerenciar múltiplas versões das IDEs, além de gerenciar projetos e configurações.

### IDEs Suportadas

- **IntelliJ IDEA** - Java, Kotlin, Scala, Groovy
- **PyCharm** - Python
- **WebStorm** - JavaScript, TypeScript
- **PhpStorm** - PHP
- **RubyMine** - Ruby
- **GoLand** - Go
- **CLion** - C, C++
- **Rider** - .NET, Unity
- **DataGrip** - Banco de dados
- **AppCode** - iOS, macOS
- **RustRover** - Rust
- **Aqua** - Testes de automação

### Características Principais

- **Instalação Simplificada**: Instale qualquer IDE com um clique
- **Gerenciamento de Versões**: Mantenha múltiplas versões lado a lado
- **Atualizações Automáticas**: Mantenha suas IDEs sempre atualizadas
- **Rollback Fácil**: Volte para versões anteriores quando necessário
- **Gerenciamento de Projetos**: Acesso rápido aos seus projetos recentes
- **Configurações Compartilhadas**: Sincronize configurações entre IDEs
- **Shell Scripts**: Abra projetos pela linha de comando

## Uso

```bash
susa setup jetbrains-toolbox [opções]
```

### Opções

| Opção | Descrição |
|---|---|
| `-h, --help` | Mostra mensagem de ajuda |
| `-u, --uninstall` | Desinstala o JetBrains Toolbox |
| `--update` | Atualiza para a versão mais recente |
| `-v, --verbose` | Modo detalhado com logs de debug |
| `-q, --quiet` | Modo silencioso |

## Guia Rápido

### Instalação

```bash
# Instalar JetBrains Toolbox
susa setup jetbrains-toolbox

# Instalar com logs detalhados
susa setup jetbrains-toolbox -v
```

O Toolbox será iniciado automaticamente após a instalação.

### Primeira Configuração

1. **Faça Login**: Use sua conta JetBrains para acessar licenças
2. **Configure Preferências**: Defina diretório de instalação das IDEs
3. **Instale IDEs**: Escolha as IDEs que deseja usar

### Atualização

```bash
# Atualizar JetBrains Toolbox
susa setup jetbrains-toolbox --update

# Atualizar com logs detalhados
susa setup jetbrains-toolbox --update -v
```

### Desinstalação

```bash
# Desinstalar JetBrains Toolbox
susa setup jetbrains-toolbox --uninstall

# A desinstalação irá perguntar se deseja:
# 1. Confirmar remoção do Toolbox
# 2. Remover IDEs instaladas e suas configurações
```

## Usando o JetBrains Toolbox

### Instalando IDEs

1. Abra o JetBrains Toolbox
2. Navegue até a IDE desejada
3. Clique em "Install" ou selecione uma versão específica
4. Aguarde a instalação completar

### Gerenciando Versões

```bash
# O Toolbox permite:
- Instalar múltiplas versões da mesma IDE
- Usar versões EAP (Early Access Program)
- Fazer rollback para versões anteriores
- Atualizar automaticamente ou manualmente
```

### Configurações

#### Diretório de Instalação

Por padrão, as IDEs são instaladas em:

- **Linux**: `~/.local/share/JetBrains/Toolbox/apps/`
- **macOS**: `~/Library/Application Support/JetBrains/Toolbox/apps/`

Você pode alterar nas configurações do Toolbox.

#### Shell Scripts

Habilite shell scripts para abrir projetos pela linha de comando:

```bash
# Após habilitar nas configurações
idea ~/meu-projeto      # IntelliJ IDEA
pycharm ~/meu-projeto   # PyCharm
webstorm ~/meu-projeto  # WebStorm
```

### Atalhos do Teclado

Dentro do Toolbox:

- `Ctrl/Cmd + O` - Abrir projeto
- `Ctrl/Cmd + ,` - Configurações
- `Ctrl/Cmd + R` - Atualizar lista de IDEs

## Recursos Avançados

### Atualizações Automáticas

Configure atualizações automáticas:

1. Abra configurações do Toolbox
2. Vá para "Tools"
3. Configure "Update all tools automatically"
4. Escolha "Stable only" ou incluir "EAP versions"

### Gerenciamento de Projetos

O Toolbox mantém histórico dos projetos recentes:

```bash
# Recursos:
- Busca rápida de projetos
- Abrir projeto com IDE específica
- Gerenciar múltiplos projetos simultaneamente
- Favoritar projetos importantes
```

### Múltiplas Versões

Mantenha diferentes versões para diferentes projetos:

```bash
# Exemplo:
- IntelliJ IDEA 2024.1 - Projetos legados
- IntelliJ IDEA 2024.3 - Projetos novos
- IntelliJ IDEA EAP - Testes de novas features
```

### Configurações Compartilhadas

Sincronize configurações entre IDEs:

1. Habilite "Settings Sync" em uma IDE
2. Faça login com conta JetBrains
3. Suas configurações serão sincronizadas automaticamente
4. Use em múltiplos computadores

## Integração com Terminal

### Comandos Shell

Após habilitar shell scripts:

```bash
# IntelliJ IDEA
idea .                    # Abre diretório atual
idea /path/to/project     # Abre projeto específico
idea diff file1 file2     # Comparar arquivos

# PyCharm
pycharm .
pycharm /path/to/project

# WebStorm
webstorm .
webstorm /path/to/project

# Outros
goland .
phpstorm .
rider .
clion .
```

### Adicionar ao PATH

Se os comandos não funcionarem, adicione ao PATH:

**Linux/macOS:**

```bash
# Adicionar ao ~/.bashrc ou ~/.zshrc
export PATH="$HOME/.local/share/JetBrains/Toolbox/scripts:$PATH"

# macOS alternativo
export PATH="$HOME/Library/Application Support/JetBrains/Toolbox/scripts:$PATH"
```

## Licenciamento

### Tipos de Licença

- **Free Versions**: Community editions (IntelliJ IDEA, PyCharm)
- **Trial**: 30 dias de avaliação das versões Ultimate
- **Individual**: Licença pessoal
- **Organization**: Licença empresarial
- **Educational**: Gratuita para estudantes e professores

### Ativar Licença

1. Abra qualquer IDE
2. Vá para "Help → Register"
3. Escolha método de ativação:
   - JetBrains Account
   - Activation code
   - License server

### Educational License

Estudantes e professores podem obter licenças gratuitas:

1. Acesse https://www.jetbrains.com/community/education/
2. Cadastre-se com email educacional
3. Confirme seu status de estudante/professor
4. Ative usando JetBrains Account

## Plugins e Extensões

### Instalar Plugins

Cada IDE tem seu próprio marketplace:

1. Abra a IDE
2. Vá para "Settings → Plugins"
3. Busque e instale plugins
4. Reinicie a IDE se necessário

### Plugins Populares

- **GitHub Copilot** - Assistente de código com IA
- **GitToolBox** - Funcionalidades extras do Git
- **Rainbow Brackets** - Colorir parênteses
- **Key Promoter X** - Aprender atalhos
- **SonarLint** - Análise de código
- **Docker** - Integração com Docker
- **Database Tools** - Gerenciamento de bancos

## Troubleshooting

### Toolbox não Inicia (Linux)

```bash
# Verificar se está em execução
ps aux | grep jetbrains-toolbox

# Verificar logs
cat ~/.local/share/JetBrains/Toolbox/logs/toolbox.log

# Reiniciar Toolbox
pkill jetbrains-toolbox
jetbrains-toolbox
```

### Toolbox não Inicia (macOS)

```bash
# Verificar logs
cat ~/Library/Logs/JetBrains/Toolbox/toolbox.log

# Reiniciar Toolbox
osascript -e 'quit app "JetBrains Toolbox"'
open -a "JetBrains Toolbox"
```

### IDE não Aparece

```bash
# Atualizar lista de ferramentas
1. Abra o Toolbox
2. Clique no ícone de engrenagem
3. Clique em "Reload tools list"
```

### Problemas de Permissão (Linux)

```bash
# Corrigir permissões
chmod +x ~/.local/bin/jetbrains-toolbox

# Verificar PATH
echo $PATH | grep .local/bin
```

### Erro ao Baixar IDE

```bash
# Verificar conexão
curl -I https://download.jetbrains.com/

# Limpar cache
rm -rf ~/.cache/JetBrains/Toolbox/

# Tentar novamente
```

### IDE não Abre

```bash
# Verificar instalação
ls -la ~/.local/share/JetBrains/Toolbox/apps/

# Reinstalar IDE específica
1. No Toolbox, clique nos 3 pontos da IDE
2. Selecione "Uninstall"
3. Instale novamente
```

### Consumo Excessivo de Memória

```bash
# Ajustar configurações de memória da IDE
1. Help → Edit Custom VM Options
2. Ajustar valores:
   -Xms512m          # Memória inicial
   -Xmx2048m         # Memória máxima
   -XX:ReservedCodeCacheSize=512m
```

## Comparação com Outras Ferramentas

### JetBrains Toolbox vs Snap

| Aspecto | JetBrains Toolbox | Snap |
|---|---|---|
| Gerenciamento | Interface gráfica | Linha de comando |
| Múltiplas versões | ✅ Sim | ❌ Limitado |
| Atualizações | Automáticas opcionais | Automáticas forçadas |
| Rollback | ✅ Fácil | ⚠️ Limitado |
| Projetos recentes | ✅ Sim | ❌ Não |
| Shell scripts | ✅ Sim | ⚠️ Limitado |

### JetBrains Toolbox vs Download Manual

| Aspecto | Toolbox | Manual |
|---|---|---|
| Instalação | Um clique | Vários passos |
| Atualizações | Automáticas | Manual |
| Múltiplas versões | Fácil | Complexo |
| Gerenciamento | Centralizado | Disperso |
| Configurações | Sincronizadas | Manual |

## Melhores Práticas

### Organização de Projetos

```bash
# Estrutura recomendada
~/Projects/
  ├── java/
  │   ├── projeto1/
  │   └── projeto2/
  ├── python/
  │   ├── projeto1/
  │   └── projeto2/
  └── javascript/
      ├── projeto1/
      └── projeto2/
```

### Backup de Configurações

```bash
# Habilite Settings Sync nas IDEs
# Ou faça backup manual dos diretórios:

# Linux
~/.config/JetBrains/
~/.local/share/JetBrains/

# macOS
~/Library/Application Support/JetBrains/
~/Library/Preferences/JetBrains/
```

### Gerenciamento de Espaço

```bash
# Remover versões antigas
1. No Toolbox, vá para Settings → Tools
2. Configure "Keep previous versions" para número desejado
3. IDEs antigas serão removidas automaticamente

# Limpar cache das IDEs
# Em cada IDE: File → Invalidate Caches → Clear and Restart
```

### Atualizações Controladas

```bash
# Para ambientes de produção
1. Desabilite atualizações automáticas
2. Teste novas versões em ambiente separado
3. Atualize quando estável
4. Mantenha versão anterior como fallback
```

## Recursos Adicionais

### Documentação Oficial

- [JetBrains Toolbox](https://www.jetbrains.com/toolbox-app/)
- [Toolbox Help](https://www.jetbrains.com/help/toolbox-app/)
- [IDEs Overview](https://www.jetbrains.com/products/)

### Comunidade

- [JetBrains Blog](https://blog.jetbrains.com/)
- [JetBrains Community](https://www.jetbrains.com/community/)
- [Stack Overflow - JetBrains](https://stackoverflow.com/questions/tagged/jetbrains)
- [Reddit r/JetBrains](https://www.reddit.com/r/JetBrains/)

### Aprendizado

- [JetBrains Academy](https://www.jetbrains.com/academy/)
- [IntelliJ IDEA Guide](https://www.jetbrains.com/idea/guide/)
- [PyCharm Guide](https://www.jetbrains.com/pycharm/guide/)
- [WebStorm Guide](https://www.jetbrains.com/webstorm/guide/)

### Suporte

- [Support Center](https://www.jetbrains.com/support/)
- [Issue Tracker](https://youtrack.jetbrains.com/)
- [Forums](https://intellij-support.jetbrains.com/hc/en-us/community/topics)

## Veja Também

- [ASDF](asdf.md) - Gerenciador de versões de linguagens
- [Mise](mise.md) - Alternativa moderna ao ASDF
- [Poetry](poetry.md) - Gerenciador de dependências Python
- [Docker](docker.md) - Containers para desenvolvimento
