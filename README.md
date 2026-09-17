# Quarto Semantic Components

Extensão Quarto/Pandoc com componentes semânticos reutilizáveis para HTML, PDF e DOCX. A estrutura principal permanece no AST do Pandoc; o HTML acrescenta apresentação rica, enquanto formatos não HTML preservam listas, links e conteúdo textual.

## Inspiração

Algumas ideias de ergonomia e sintaxe vieram do framework [Vocs](https://vocs.dev/), em especial dos componentes de Markdown como **Steps** e **File Tree**. A implementação aqui é própria e adaptada ao ecossistema Quarto/Pandoc, com foco adicional em renderização multiplataforma, metadata de projeto e degradação para PDF/DOCX.

## Componentes

- `steps`: sequência numerada inspirada no padrão de documentação do Vocs;
- `steps type="dots"`: bolinhas com cor, tamanho, cor da linha e espessura configuráveis globalmente e por etapa;
- `circle-list`: lista ordenada com números circulados;
- `git-tree`: histórico Git com lanes e merges renderizados em SVG no HTML, sem ASCII art;
- `file-tree`: árvore de arquivos com aninhamento profundo, links e providers de ícones;
- `badge`: badge inline altamente customizável e compatível com presets de projeto.

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

Os componentes podem receber defaults e presets no metadata compartilhado do projeto. A precedência é:

```text
_quarto.yml / _metadata.yml
        ↓
preset do componente
        ↓
atributos do componente
        ↓
atributos do item individual
```

Exemplo:

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

Também são aceitos os namespaces `semantic-components:` e `extensions.semantic-components`.

## Badges

O shortcode público é **`badge`**:

```markdown
{{< badge "Beta" >}}
{{< badge "Estável" type="success" icon="✓" >}}
{{< badge stable >}}
{{< badge "Release estável" key="stable" >}}
```

### Compatibilidade com `mcanouil/quarto-badge`

O projeto [`mcanouil/quarto-badge`](https://github.com/mcanouil/quarto-badge) também registra um shortcode chamado `badge`. Por isso, um projeto deve **escolher qual extensão será responsável por `{{< badge ... >}}`**; não é recomendado carregar as duas extensões de badge simultaneamente.

A proposta deste projeto é oferecer personalização livre por instância, além de presets de projeto:

```markdown
{{< badge "Custom"
  bg="#111827"
  fg="#fff"
  border="#60a5fa"
  border-width="2px"
  radius="0.35rem"
  padding="0.2em 0.7em"
  shadow="0 2px 8px rgb(0 0 0 / .16)" >}}
```

Opções incluem `type`/`variant`, `size`, `shape`, `appearance`, `icon`, `icon-position`, `href`, `title`, `fg`, `bg`, `colour`/`color`, `border`, `border-width`, `radius`, `padding`, `weight`, `font-size`, `letter-spacing`, `shadow`, `uppercase`, `font="mono"` e `class`/`classes`.

Internamente as classes CSS continuam prefixadas como `.semantic-badge` para não colidir com a classe `.badge` do Bootstrap/Quarto.

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

Branches são escritos como listas aninhadas. No HTML, a extensão lineariza o histórico e desenha **lanes, nós, branch-outs e merges em SVG**, o que evita os ganchos e sobreposições produzidos por pseudo-elementos CSS em árvores muito aninhadas.

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

Em PDF/DOCX a estrutura continua sendo uma lista semântica legível.

Defaults disponíveis no `_quarto.yml`: `line-color`, `line-width`, `node-size`, `lane-gap` e `node-bg`.

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
      - +r
        - analysis.R
  - +docs
    - report.qmd
  - _quarto.yml
:::
```

Providers disponíveis: `devicon`, `simple-icons`, `builtin` e `none`.

### Ícone oficial do Quarto

Devicon não fornece atualmente um glifo próprio do Quarto. Para arquivos `.qmd`, `_quarto.yml` e `quarto.yml`, o provider padrão usa o **símbolo oficial do Quarto** servido pelo próprio site em `https://quarto.org/favicon.png`. Esse é o mark circular azul usado como favicon oficial; o recurso `quarto.png`, por outro lado, é o wordmark horizontal completo.

Se `icons="simple-icons"` for escolhido explicitamente, o provider Simple Icons continua sendo respeitado.

### Ícones customizados

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

- **HTML**: apresentação completa, ícones, conectores, SVG do Git tree e badges ricos;
- **PDF**: conteúdo estrutural e links são preservados; decoração HTML degrada com segurança;
- **DOCX**: listas, links e texto permanecem editáveis.

## Exemplos

`index.qmd` contém a galeria de componentes e o `_quarto.yml` da raiz demonstra defaults de projeto. Cada exemplo mostra primeiro o código gerador e depois o output.

```bash
quarto preview index.qmd
```
