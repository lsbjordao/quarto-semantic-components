# Quarto Semantic Components

Extensão Quarto/Pandoc com componentes semânticos reutilizáveis para **HTML, PDF e DOCX**. A estrutura principal permanece no AST do Pandoc; o HTML acrescenta apresentação rica, enquanto formatos não HTML preservam listas, links e conteúdo textual.

## Inspiração

Algumas ideias de ergonomia e sintaxe vieram do framework [Vocs](https://vocs.dev/), em especial dos componentes de Markdown como **Steps** e **File Tree**. A implementação aqui é própria e adaptada ao ecossistema Quarto/Pandoc, com foco adicional em renderização multiplataforma, metadata de projeto e degradação segura para PDF/DOCX.

## Componentes

- `steps`: sequência numerada;
- `steps type="dots"`: steps com bolinhas vazadas por padrão e ampla personalização;
- `circle-list`: lista ordenada com números circulados;
- `git-tree`: histórico Git com lanes, branches e merges em SVG no HTML;
- `file-tree`: árvore de arquivos com aninhamento profundo, links, tooltips, ícones e pastas expansíveis/colapsáveis em HTML;
- `badge`: badge inline com presets de projeto e personalização por instância.

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

A precedência é:

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
      type: success
      appearance: solid
      icon: "✓"

    - key: experimental
      label: Experimental
      type: info
      appearance: outline
      icon: "⚗"

  steps:
    dot-color: "#8c959f"
    dot-size: "0.72rem"
    line-color: "#9aa0a6"
    line-width: "1.5px"

  file-tree:
    icons: devicon
    expanded: true

  git-tree:
    line-color: "#9aa0a6"
    line-width: "2px"
    node-size: "0.68rem"
    lane-gap: "0.82rem"
```

Também são aceitos os namespaces `semantic-components:` e `extensions.semantic-components`.

## Badges

O shortcode público é apenas **`badge`**:

```markdown
{{< badge "Beta" >}}
{{< badge "Estável" type="success" icon="✓" >}}
{{< badge stable >}}
{{< badge "Release estável" key="stable" >}}
```

A forma AST-native usa a mesma palavra:

```markdown
[AST-native]{.badge key="stable" appearance="outline" size="md"}
```

A classe pública `.badge` é convertida internamente pela extensão para uma classe privada, evitando depender do estilo `.badge` do Bootstrap.

### Compatibilidade com `mcanouil/quarto-badge`

O projeto [`mcanouil/quarto-badge`](https://github.com/mcanouil/quarto-badge) também registra um shortcode chamado `badge`. Portanto, um projeto deve **escolher qual extensão será responsável por `{{< badge ... >}}`**; não é recomendado carregar as duas extensões de badge simultaneamente.

A proposta deste projeto é oferecer personalização livre por instância, além de presets definidos no projeto:

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

## Steps

Os exemplos usam `##` como padrão. O filtro considera o primeiro nível de heading encontrado dentro do componente, então outros níveis continuam válidos.

### Numerado

```markdown
:::steps
## Primeiro passo
Conteúdo.

## Segundo passo
Conteúdo.

## Terceiro passo
Conteúdo.

## Quarto passo
Conteúdo.
:::
```

### Bolinhas vazadas por padrão

```markdown
::: {.steps type="dots"}
## Extrair
Conteúdo.

## Validar
Conteúdo.

## Transformar
Conteúdo.

## Publicar
Conteúdo.
:::
```

`dot-color` controla o contorno. O preenchimento só aparece se `dot-fill` for definido.

```markdown
::: {.steps type="dots"
  dot-color="#8c959f"
  dot-size="0.78rem"
  line-color="#9aa0a6"
  line-width="1.5px"}

## Extrair {dot-color="#2563eb"}
Conteúdo.

## Deduplicar {dot-color="#f59e0b" dot-size="0.95rem"}
Conteúdo.

## Revisar {dot-color="#8b5cf6"}
Conteúdo.

## Publicar {dot-color="#16a34a"}
Conteúdo.
:::
```

Defaults e overrides disponíveis: `dot-color`, `dot-fill`, `dot-size`, `dot-border-width`, `line-color` e `line-width`.

Aliases: `marker-color`, `marker-fill`, `marker-size`, `marker-border-width`, `connector-color` e `connector-width`.

## Circle list

```markdown
:::circle-list
1. Item um
2. Item dois
3. Item três
4. Item quatro
:::
```

## Git tree

Branches são escritos como listas aninhadas. No HTML, a extensão lineariza o histórico e desenha lanes, nós, branch-outs e merges em SVG.

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

```yaml
extensions:
  file-tree:
    icons: devicon
    expanded: true
```

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

Para `.qmd`, `_quarto.yml` e `quarto.yml`, o provider padrão usa o símbolo oficial do Quarto servido pelo próprio site.

### Pastas expansíveis e colapsáveis no HTML

Pastas com filhos são interativas em HTML. Elas ficam abertas por padrão para preservar o comportamento tradicional do componente. Clique no chevron ou no nome da pasta para abrir/fechar; o controle também é acessível por teclado através do botão do chevron.

O estado padrão do projeto pode ser definido no `_quarto.yml`:

```yaml
extensions:
  file-tree:
    expanded: false
```

Também é possível definir o estado de uma árvore inteira:

```markdown
::: {.file-tree expanded="false"}
- +src
  - app.ts
  - styles.css
- +docs
  - index.qmd
:::
```

Ou sobrescrever diretórios individualmente usando atributos Pandoc:

```markdown
:::file-tree
- [+src]{expanded="false"}
  - +components
    - Button.ts
    - Card.ts
  - app.ts
- [+docs]{open="true"}
  - index.qmd
- [+data]{collapsed="true"}
  - raw.csv
:::
```

Aliases aceitos: `expanded`/`open` e `collapsed`. Em PDF e DOCX a árvore continua sempre estruturalmente expandida e legível; a interação existe apenas em HTML.

Se uma pasta também for um link, clicar no link continua navegando. O chevron e o restante da linha controlam a expansão.

### Texto normal ou inline code

A extensão preserva a sintaxe escolhida pelo autor:

```markdown
:::file-tree
- analysis.R texto normal
- `pipeline.py` inline code
- [app.ts](https://github.com/lsbjordao/quarto-semantic-components) link normal
- [`steps.lua`](https://github.com/lsbjordao/quarto-semantic-components/blob/main/_extensions/semantic-components/steps.lua) link + inline code
:::
```

### Tooltip opcional

`tooltip=` e `info=` adicionam um ícone de informação em HTML:

```markdown
:::file-tree
- [analysis.R]{tooltip="Script principal de análise em R"}
- [`pipeline.py`]{info="Pipeline de ingestão e validação"}
:::
```

### Ícones customizados

```markdown
- `pipeline.py`{icon="devicon:python"}
- `analysis.R`{icon="simple-icons:r"}
- `species.csv`{icon="leaf"}
- `golden.parquet`{icon="★"}
- `special.dat`{icon="assets/special.svg"}
```

## Formatos

- **HTML**: apresentação completa, ícones, badges, tooltips, árvores colapsáveis, conectores e Git tree em SVG;
- **PDF**: conteúdo estrutural e links são preservados; decoração HTML degrada com segurança;
- **DOCX**: listas, links e texto permanecem editáveis.

## Exemplos

`index.qmd` contém a galeria completa e o `_quarto.yml` da raiz demonstra defaults de projeto.

```bash
quarto preview index.qmd
```
