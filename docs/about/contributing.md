# Contribuindo

Obrigado pelo interesse em contribuir para o projeto CLI! 🎉

## 🤝 Como Contribuir

### Reportar Bugs

Encontrou um bug? Abra uma [issue](https://github.com/carlosdorneles-mb/susa/issues) com:

- Descrição clara do problema
- Passos para reproduzir
- Comportamento esperado vs atual
- Versão do CLI (`cli --version`)
- Sistema operacional

### Sugerir Melhorias

Tem uma ideia? Compartilhe abrindo uma issue com:

- Descrição da funcionalidade
- Caso de uso
- Exemplos de como seria usado

### Pull Requests

1. **Fork** o repositório
2. **Clone** seu fork
3. **Crie** um branch: `git checkout -b feature/minha-feature`
4. **Implemente** suas mudanças
5. **Teste** suas alterações
6. **Commit**: `git commit -m "feat: adiciona nova funcionalidade"`
7. **Push**: `git push origin feature/minha-feature`
8. **Abra** um Pull Request

## 📝 Padrões de Código

### Shell Script

- Use `#!/bin/bash` em todos os scripts
- Ative modo strict: `set -euo pipefail`
- Use 4 espaços para indentação
- Nomeie variáveis em `snake_case`
- Nomeie funções em `snake_case`
- Adicione comentários explicativos

### Commits

Siga o padrão [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - Nova funcionalidade
- `fix:` - Correção de bug
- `docs:` - Mudanças na documentação
- `refactor:` - Refatoração de código
- `test:` - Adição/modificação de testes
- `chore:` - Tarefas de manutenção

Exemplos:

```text
feat: adiciona comando de backup automático
fix: corrige detecção de SO em macOS
docs: atualiza guia de instalação
refactor: simplifica parsing YAML com yq
```

## 🧪 Testes

Antes de submeter PR:

```bash
# Teste o comando principal
./susa --help

# Teste comandos específicos
./susa self version
./susa self plugin list

# Teste em subcategorias
./susa setup
```

## 📚 Documentação

- Atualize `docs/` se adicionar funcionalidades
- Adicione exemplos de uso
- Atualize o CHANGELOG se relevante
- Mantenha README.md sincronizado

## 🔄 Processo de Review

1. Maintainer revisa o PR
2. Feedback e discussão
3. Ajustes se necessários
4. Aprovação e merge
5. Atualização do changelog

## 📦 Criando Plugins

Para contribuir com plugins:

1. Crie um repositório separado
2. Siga a [estrutura de plugins](../plugins/overview.md)
3. Documente bem o plugin
4. Submeta para a lista de plugins da comunidade

## 💬 Dúvidas?

- Abra uma [Discussion](https://github.com/carlosdorneles-mb/susa/discussions)
- Pergunte nas issues existentes
- Consulte a documentação completa

## 🎯 Áreas para Contribuir

- 🐛 Correção de bugs
- 📝 Melhorias na documentação
- ✨ Novas funcionalidades
- 🧪 Adicionar testes
- 🎨 Melhorias na UI/UX
- 🔌 Criar plugins
- 🌍 Traduções

Obrigado por contribuir! 🚀
