# Semantic Blocks for Quarto

Extensão Quarto/Pandoc com componentes semânticos inspirados nas extensões Markdown do Vocs:

- `steps` numerado;
- `steps` com bolinhas;
- `steps` em estilo histórico Git;
- `circle-list` para listas ordenadas com números circulados;
- `file-tree` hierárquico.

A extensão usa um filtro Lua e mantém o conteúdo em AST Pandoc, evitando HTML bruto. O HTML recebe o estilo rico via CSS; PDF/DOCX mantêm fallbacks estruturais legíveis.

## Estrutura

```text
.
├── index.qmd
├── README.md
└── _extensions/
    └── semantic-blocks/
        ├── _extension.yml
        ├── semantic-blocks.lua
        └── semantic-blocks.css
```

## Uso

No YAML:

```yaml
filters:
  - semantic-blocks
```

### Steps numerado

```markdown
:::steps
### Primeiro passo

Conteúdo.

### Segundo passo

Conteúdo.
:::
```

### Steps com bolinhas

```markdown
::: {.steps type="dots"}
### Primeiro

Conteúdo.

### Segundo

Conteúdo.
:::
```

Também funciona com a classe `.steps-dots`.

### Steps no estilo Git

```markdown
::: {.steps type="git"}
### feat: primeira alteração

Descrição.

### fix: corrige problema

Descrição.
:::
```

Também funciona com a classe `.steps-git`.

### Circle list

```markdown
:::circle-list
1. Item um
2. Item dois
3. Item três
:::
```

### File tree

```markdown
:::file-tree
- README.md documentação
- +src código-fonte
  - **main.ts** arquivo em destaque
  - utils.ts utilitários
  - +components
    - Button.ts
:::
```

Regras do `file-tree`:

- `+nome` força o item a ser tratado como diretório;
- um item com filhos é automaticamente tratado como diretório;
- o primeiro token é o nome do arquivo/diretório;
- o restante da linha vira comentário;
- `**arquivo.ext**` destaca o item.

## Renderização

```bash
quarto render index.qmd
```

Para testar outros formatos, troque o YAML de `index.qmd`, por exemplo:

```yaml
format: docx
```

ou:

```yaml
format: pdf
```

## Observação sobre a sintaxe

Pandoc aceita a forma curta `:::steps`, `:::circle-list` e `:::file-tree` como fenced divs com uma classe. Quando atributos adicionais são necessários, use a forma completa, por exemplo:

```markdown
::: {.steps type="git"}
...
:::
```
