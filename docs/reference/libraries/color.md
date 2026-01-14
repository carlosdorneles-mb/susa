# color.sh

Define constantes de cores para formatação de texto no console.

## Variáveis Disponíveis

### Cores Básicas

| Variável | Cor | Código ANSI |
|----------|-----|-------------|
| `RED` | Vermelho | `\033[0;31m` |
| `GREEN` | Verde | `\033[0;32m` |
| `YELLOW` | Amarelo | `\033[0;33m` |
| `BLUE` | Azul | `\033[0;34m` |
| `MAGENTA` | Magenta | `\033[0;35m` |
| `CYAN` | Ciano | `\033[0;36m` |
| `GRAY` | Cinza | `\033[0;90m` |
| `WHITE` | Branco brilhante | `\033[1;37m` |

### Cores Claras

| Variável | Cor | Código ANSI |
|----------|-----|-------------|
| `LIGHT_RED` | Vermelho claro | `\033[0;91m` |
| `LIGHT_GREEN` | Verde claro | `\033[0;92m` |
| `LIGHT_YELLOW` | Amarelo claro | `\033[0;93m` |
| `LIGHT_BLUE` | Azul claro | `\033[0;94m` |
| `LIGHT_MAGENTA` | Magenta claro | `\033[0;95m` |
| `LIGHT_CYAN` | Ciano claro | `\033[0;96m` |
| `LIGHT_GRAY` | Cinza claro | `\033[2;37m` |

### Estilos

| Variável | Efeito | Código ANSI |
|----------|--------|-------------|
| `BOLD` | Negrito | `\033[1m` |
| `ITALIC` | Itálico | `\033[3m` |
| `UNDERLINE` | Sublinhado | `\033[4m` |
| `DIM` | Escurecido/Opaco | `\033[2m` |

### Reset

| Variável | Função | Código ANSI |
|----------|--------|-------------|
| `NC` | Remove formatação (No Color) | `\033[0m` |
| `RESET` | Remove formatação (alias para NC) | `\033[0m` |

## Exemplo de Uso

### Básico

```bash
#!/bin/bash
source "$LIB_DIR/color.sh"

# Mensagens simples
echo -e "${GREEN}Sucesso!${NC}"
echo -e "${RED}Erro!${NC}"
echo -e "${YELLOW}Aviso!${NC}"
```

### Combinando Estilos

```bash
# Negrito + Cor
echo -e "${BOLD}${GREEN}Instalação concluída!${NC}"

# Múltiplos estilos
echo -e "${BOLD}${UNDERLINE}${RED}Erro crítico!${NC}"

# Texto colorido com contexto
echo -e "${YELLOW}Atenção: ${GRAY}arquivo não encontrado${NC}"
```

### Em Funções

```bash
#!/bin/bash
source "$LIB_DIR/color.sh"

mostrar_status() {
    local status=$1
    local mensagem=$2

    case "$status" in
        sucesso)
            echo -e "${GREEN}✓${NC} $mensagem"
            ;;
        erro)
            echo -e "${RED}✗${NC} $mensagem"
            ;;
        aviso)
            echo -e "${YELLOW}⚠${NC} $mensagem"
            ;;
    esac
}

# Uso
mostrar_status "sucesso" "Arquivo salvo"
mostrar_status "erro" "Falha na conexão"
mostrar_status "aviso" "Versão desatualizada"
```

## Boas Práticas

1. **Sempre termine com reset**: Use `${NC}` ao final de qualquer texto colorido
   ```bash
   echo -e "${GREEN}Sucesso!${NC}"  # ✓ Correto
   echo -e "${GREEN}Sucesso!"        # ✗ Errado
   ```

2. **Combine estilos de forma legível**: Coloque modificadores antes da cor

   ```bash
   echo -e "${BOLD}${GREEN}Texto${NC}"        # ✓ Recomendado
   echo -e "${GREEN}${BOLD}Texto${NC}"        # ✓ Funciona, mas menos claro
   ```

3. **Use cores consistentemente**: Crie uma convenção para seu projeto
   - `GREEN` → Sucesso, confirmação
   - `RED` → Erros, falhas
   - `YELLOW` → Avisos, atenção
   - `CYAN/BLUE` → Informações, comandos
   - `GRAY` → Detalhes secundários, debug

4. **Evite excesso de cores**: Mensagens muito coloridas dificultam a leitura

   ```bash
   # ✓ Bom - destaque pontual
   echo -e "Instalando pacote ${CYAN}nodejs${NC}..."

   # ✗ Ruim - excesso de cores
   echo -e "${GREEN}Instalando${NC} ${YELLOW}pacote${NC} ${CYAN}nodejs${NC}${BLUE}...${NC}"
   ```

5. **Use DIM para informações secundárias**: Ajuda a hierarquizar informações

   ```bash
   echo -e "${GREEN}[OK]${NC} Teste passou ${DIM}(0.23s)${NC}"
   ```

## Referência Rápida

### Paleta Visual

```bash
# Execute este snippet para ver todas as cores
for color in RED GREEN YELLOW BLUE MAGENTA CYAN GRAY WHITE \
             LIGHT_RED LIGHT_GREEN LIGHT_YELLOW LIGHT_BLUE \
             LIGHT_MAGENTA LIGHT_CYAN LIGHT_GRAY; do
    eval "echo -e \"\${$color}$color\${NC}\""
done
```

### Códigos ANSI

Os códigos ANSI seguem o padrão `\033[<código>m`:

- `0` = Reset
- `1` = Negrito
- `2` = Dim
- `3` = Itálico
- `4` = Sublinhado
- `9` = Riscado
- `30-37` = Cores básicas
- `90-97` = Cores claras
