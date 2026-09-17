# Quarto Semantic Components

Extensão Quarto/Pandoc com componentes semânticos reutilizáveis para HTML, PDF e DOCX. A estrutura principal é mantida no AST do Pandoc; o HTML acrescenta a apresentação visual, enquanto formatos não HTML preservam listas, links e conteúdo textual.

## Componentes

- `steps`: sequência numerada inspirada no Vocs;
- `steps type="dots"`: sequência com bolinhas, com `dot-color` e `line-color` customizáveis;
- `circle-list`: lista ordenada com números circulados;
- `git-tree`: histórico Git com branches aninhados e conectores CSS, sem caracteres ASCII;
- `file-tree`: árvore de arquivos com aninhamento profundo, links e providers de ícones;
- `semantic-badge`: badge inline altamente customizável e com nome próprio para coexistir com `mcanouil/quarto-badge`.

## Instalação

```bash
quarto add lsbjordao/quarto-semantic-components
```

No documento ou `_quarto.yml`:

```yaml
filters:
  - semantic-components
```

## Badges: complementar ao `quarto-badge`

O projeto [`mcanouil/quarto-badge`](https://github.com/mcanouil/quarto-badge) define tipos de badge na configuração e os reutiliza por chave/valor. Esta extensão não usa o shortcode `badge`: usa **`semantic-badge`** e prioriza customização por instância.

```markdown
{{< semantic-badge "Estável" type="success" icon="✓" >}}
{{< semantic-badge "v0.4.0" type="accent" appearance="solid" size="md" >}}
{{< semantic-badge "Custom" bg="#111827" fg="#fff" border="#60a5fa" border-width="2px" radius="0.35rem" padding="0.2em 0.7em" shadow="0 2px 8px rgb(0 0 0 / .16)" >}}
```

Opções incluem `type`/`variant`, `size`, `shape`, `appearance`, `icon`, `icon-position`, `href`, `title`, `fg`, `bg`, `border`, `border-width`, `radius`, `padding`, `weight`, `font-size`, `letter-spacing`, `shadow`, `uppercase` e `font="mono"`.

Também existe a forma AST-native:

```markdown
[Beta]{.semantic-badge variant="info" appearance="outline"}
```

## Steps

```markdown
:::steps
### Primeiro passo
Conteúdo.

### Segundo passo
Conteúdo.
:::
```

### Bolinhas e cores

```markdown
::: {.steps type="dots" dot-color="#2da44e" line-color="#8c959f"}
### Extrair
Conteúdo.

### Validar
Conteúdo.

### Publicar
Conteúdo.
:::
```

`dot-color` controla a bolinha; `line-color` controla o conector vertical.

## Circle list

```markdown
:::circle-list
1. Item um
2. Item dois
3. Item três
:::
```

## Git tree

Branches são listas aninhadas. O grafo HTML é desenhado por CSS com linhas, curvas e nós circulares — não por caracteres ASCII.

```markdown
:::git-tree
- `main` initial commit
- `main` arquitetura base
  - `feature/icons` cria branch
  - `feature/icons` adiciona Devicon
    - `docs/icons` documenta providers
    - `docs/icons` adiciona exemplos
  - `feature/icons` adiciona links
- `main` merge feature/icons
- `main` release v0.4.0
:::
```

## File tree

### Aninhamento profundo e ícones automáticos

O provider padrão é **Devicon**, com logos reais de linguagens/ferramentas como R, Python, JavaScript e TypeScript.

```markdown
::: {.file-tree icons="devicon"}
- +project
  - +src
    - +pipelines
      - +python
        - pipeline.py
        - validate.py
      - +r
        - analysis.R
        - report.Rmd
      - +web
        - +src
          - app.ts
          - chart.js
          - styles.css
  - +data
    - +processed
      - +gold
        - occurrences.parquet
:::
```

### Providers de ícones

Escolha no bloco:

```markdown
::: {.file-tree icons="devicon"}
...
:::
```

Valores disponíveis:

- `devicon` — padrão, logos coloridos de linguagens/ferramentas;
- `simple-icons` — Simple Icons;
- `builtin` — ícones locais e monocromáticos;
- `none` — sem ícones.

Um item pode sobrescrever o provider:

```markdown
- `pipeline.py`{icon="devicon:python"}
- `analysis.R`{icon="simple-icons:r"}
- `species.csv`{icon="leaf"}
- `golden.parquet`{icon="★"}
- `special.dat`{icon="assets/special.svg"}
```

### Arquivos como links

Links Markdown são preservados. O destino é escolhido pelo autor:

```markdown
:::file-tree
- +_extensions
  - +semantic-components
    - [`steps.lua`](https://github.com/lsbjordao/quarto-semantic-components/blob/main/_extensions/semantic-components/steps.lua) steps
    - [`file-tree.lua`](https://github.com/lsbjordao/quarto-semantic-components/blob/main/_extensions/semantic-components/file-tree.lua) file tree
    - [`git-tree.lua`](https://github.com/lsbjordao/quarto-semantic-components/blob/main/_extensions/semantic-components/git-tree.lua) git tree
:::
```

## Formatos

- **HTML**: apresentação completa, Devicon/Simple Icons, conectores e badges ricos;
- **PDF**: conteúdo estrutural e links são preservados; decoração HTML degrada com segurança;
- **DOCX**: listas, links e texto permanecem editáveis; badges usam conteúdo inline e podem receber o estilo `Semantic Badge`.

## Exemplos

`index.qmd` contém uma galeria completa. Cada exemplo mostra primeiro o código gerador e depois o output. O YAML também mantém `execute: echo: true` para documentos que incluam células executáveis.

```bash
quarto preview index.qmd
```
