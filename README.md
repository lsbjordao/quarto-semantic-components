# Quarto Semantic Components

Extensão Quarto/Pandoc com componentes semânticos reutilizáveis para HTML, PDF e DOCX. A estrutura principal permanece no AST do Pandoc; o HTML acrescenta apresentação rica, enquanto formatos não HTML preservam listas, links e conteúdo textual.

## Componentes

- `steps`: sequência numerada inspirada no Vocs;
- `steps type="dots"`: bolinhas com cor, tamanho, cor da linha e espessura configuráveis globalmente e por etapa;
- `circle-list`: lista ordenada com números circulados;
- `git-tree`: histórico Git com branches aninhados e conectores CSS, sem ASCII art;
- `file-tree`: árvore de arquivos com aninhamento profundo, links e providers de ícones;
- `semantic-badge`: badge inline altamente customizável e compatível com presets de projeto.

## Instalação

```bash
quarto add lsbjordao/quarto-semantic-components
```

No documento ou `_quarto.yml`:

```yaml
filters:
  - semantic-components
```

## Defaults no `_quarto.yml`

A partir da versão **0.5.0**, os componentes podem receber defaults e presets no metadata compartilhado do projeto. A precedência é:

```text
_quarto.yml / _metadata.yml
        ↓
atributos do componente
        ↓
atributos do item individual
```

Isto permite definir um design system uma vez e sobrescrever apenas exceções.

### Sintaxe compacta `extensions:`

```yaml
extensions:
  badge:
    - key: stable
      label: Estável
      colour: springgreen
      fg: "#102a18"
      appearance: solid

    - key: experimental
      label: Experimental
      class: bg-info
      appearance: solid

  steps:
    dot-color: "#8c959f"
    dot-size: "0.72rem"
    line-color: "#d0d7de"
    line-width: "1.5px"

  file-tree:
    icons: devicon

  git-tree:
    line-color: "#9aa0a6"
    line-width: "2px"
    node-size: "0.68rem"
    lane-gap: "0.82rem"
```

O repositório inclui um `_quarto.yml` funcional usando exatamente esse padrão.

### Namespace explícito

Em projetos que já usam `extensions:` para outras convenções, a mesma configuração pode ser colocada em `semantic-components:`:

```yaml
semantic-components:
  badge:
    defaults:
      shape: pill
      size: sm
    presets:
      - key: stable
        colour: springgreen

  steps:
    dot-size: "0.8rem"
    line-width: "2px"
```

Também é aceito `extensions.semantic-components`.

## Badges

O projeto [`mcanouil/quarto-badge`](https://github.com/mcanouil/quarto-badge) trabalha com badges configurados por chave/valor. Esta extensão usa o nome **`semantic-badge`** para coexistir com ele e acrescenta personalização livre por instância.

### Presets do projeto

Com este `_quarto.yml`:

```yaml
extensions:
  badge:
    - key: stable
      label: Estável
      colour: springgreen
      fg: "#102a18"
      appearance: solid

    - key: experimental
      class: bg-info
      appearance: solid
```

basta escrever:

```markdown
{{< semantic-badge stable >}}
{{< semantic-badge experimental >}}
```

Também é possível usar a aparência do preset com outro texto:

```markdown
{{< semantic-badge "Release estável" key="stable" >}}
```

`colour`/`color` é um alias conveniente para `bg`. Valores explícitos no shortcode sempre vencem o preset e os defaults.

### Personalização por instância

```markdown
{{< semantic-badge "Estável" type="success" icon="✓" >}}
{{< semantic-badge "Custom"
  bg="#111827" fg="#fff"
  border="#60a5fa" border-width="2px"
  radius="0.35rem" padding="0.2em 0.7em"
  shadow="0 2px 8px rgb(0 0 0 / .16)" >}}
```

Opções incluem `type`/`variant`, `size`, `shape`, `appearance`, `icon`, `icon-position`, `href`, `title`, `fg`, `bg`, `colour`/`color`, `border`, `border-width`, `radius`, `padding`, `weight`, `font-size`, `letter-spacing`, `shadow`, `uppercase`, `font="mono"` e `class`/`classes`.

Também existe a forma AST-native:

```markdown
[Beta]{.semantic-badge key="experimental" appearance="outline"}
```

## Steps

Os exemplos usam `##` como padrão. O filtro considera o primeiro nível de heading encontrado dentro do componente, portanto outros níveis continuam válidos.

### Numerado

```markdown
:::steps
## Primeiro passo
Conteúdo.

## Segundo passo
Conteúdo.
:::
```

### Bolinhas com defaults do projeto

Se `_quarto.yml` já contém os defaults, o documento pode ser simples:

```markdown
::: {.steps type="dots"}
## Extrair
Conteúdo.

## Validar
Conteúdo.

## Publicar
Conteúdo.
:::
```

### Override no bloco e por etapa

```markdown
::: {.steps type="dots"
  dot-color="#8c959f"
  dot-size="0.72rem"
  line-color="#d0d7de"
  line-width="1.5px"}

## Extrair {dot-color="#2563eb" dot-size="0.62rem"}
Conteúdo.

## Deduplicar {dot-color="#f59e0b" dot-size="1.1rem" line-width="3px"}
Conteúdo.

## Publicar {dot-color="#2da44e" dot-size="0.85rem"}
Conteúdo.
:::
```

Aliases disponíveis: `marker-color`, `marker-size`, `connector-color` e `connector-width`.

## Circle list

```markdown
:::circle-list
1. Item um
2. Item dois
3. Item três
:::
```

## Git tree

Branches são listas aninhadas. O grafo HTML é desenhado por CSS com linhas, curvas e nós circulares, sem caracteres ASCII.

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
:::
```

Defaults disponíveis no `_quarto.yml`: `line-color`, `line-width`, `node-size`, `lane-gap`, `row-indent` e `node-bg`. Os mesmos atributos podem ser usados diretamente em `::: {.git-tree ...}` para sobrescrever o projeto.

## File tree

### Aninhamento profundo e ícones automáticos

O provider padrão pode ser definido uma vez no `_quarto.yml`:

```yaml
extensions:
  file-tree:
    icons: devicon
```

Depois:

```markdown
:::file-tree
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
          - +components
            - chart.ts
            - table.ts
          - app.ts
  - +data
    - +processed
      - +gold
        - occurrences.parquet
:::
```

Providers disponíveis: `devicon`, `simple-icons`, `builtin` e `none`.

Um item pode sobrescrever o provider ou ícone:

```markdown
- `pipeline.py`{icon="devicon:python"}
- `analysis.R`{icon="simple-icons:r"}
- `species.csv`{icon="leaf"}
- `golden.parquet`{icon="★"}
- `special.dat`{icon="assets/special.svg"}
```

### Arquivos como links

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

- **HTML**: apresentação completa, ícones, conectores e badges ricos;
- **PDF**: conteúdo estrutural e links são preservados; decoração HTML degrada com segurança;
- **DOCX**: listas, links e texto permanecem editáveis.

## Exemplos

`index.qmd` contém a galeria de componentes e o `_quarto.yml` da raiz demonstra defaults de projeto.

```bash
quarto preview index.qmd
```
