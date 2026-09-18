# Quarto Semantic Components

Extensão Quarto/Pandoc com componentes semânticos reutilizáveis para **HTML, PDF e DOCX**. A estrutura principal permanece no AST do Pandoc; o HTML acrescenta apresentação rica, enquanto formatos não HTML preservam listas, links e conteúdo textual.

## Inspiração

Algumas ideias de ergonomia e sintaxe vieram do framework [Vocs](https://vocs.dev/), em especial dos componentes de Markdown como **Steps** e **File Tree**. A implementação aqui é própria e adaptada ao ecossistema Quarto/Pandoc, com foco adicional em renderização multiplataforma, metadata de projeto e degradação segura para PDF/DOCX.

## Componentes

- `steps`: sequência numerada;
- `steps type="dots"`: steps com bolinhas vazadas por padrão e ampla personalização;
- `circle-list`: lista ordenada com números circulados;
- `git-tree`: grafo de commits Git (DAG) com branches, merges, tags, `HEAD` e direções TB/BT;
- `file-tree`: árvore de arquivos com aninhamento profundo, links, tooltips, ícones e pastas colapsáveis em HTML;
- `badge`: badge inline com presets de projeto e personalização por instância;
- `aside`: bloco semântico lateral baseado no elemento HTML `<aside>`, com variantes visuais;
- `article`: contêiner semântico baseado no elemento HTML `<article>`, neutro e reutilizável.

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

  steps:
    dot-color: "#8c959f"
    dot-size: "0.72rem"
    line-color: "#9aa0a6"
    line-width: "1.5px"

  file-tree:
    icons: devicon
    expanded: true

  git-tree:
    direction: TB
    line-color: "#9aa0a6"
    line-width: "2px"
    node-size: "0.68rem"
    lane-gap: "0.82rem"
    row-height: "36px"
    content-gap: "0.55rem"

  aside:
    variant: default

  article:
    radius: "0.75rem"
    padding: "1rem 1.1rem"
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

Defaults e overrides: `dot-color`, `dot-fill`, `dot-size`, `dot-border-width`, `line-color` e `line-width`.

## Circle list

```markdown
:::circle-list
1. Item um
2. Item dois
3. Item três
4. Item quatro
:::
```

## Git tree: um grafo de commits, não apenas uma árvore visual

O Git é modelado como um **DAG de commits**. No `git-tree`:

- cada bolinha representa um commit;
- cada aresta conecta um commit pai a um commit filho;
- uma bifurcação sempre começa em um commit;
- um merge sempre termina em um commit;
- a tag/branch e a descrição começam logo após o nó correspondente, formando uma escadinha coerente com a lane;
- `tag=` e `head=true` podem anexar referências adicionais ao commit.

### Sintaxe simples

```markdown
:::git-tree
- `main` initial commit
- `main` arquitetura base
  - `feature/icons` cria branch
  - `feature/icons` adiciona Devicon
    - `docs/icons` documenta providers
    - `docs/icons` adiciona exemplos
  - `feature/icons` merge docs/icons
  - `feature/icons` adiciona links
- `main` merge feature/icons
:::
```

A extensão infere os parents da seguinte forma:

- mesma profundidade → próximo commit da mesma lane;
- aumento de profundidade → branch criado a partir do commit imediatamente anterior;
- retorno a uma profundidade menor → o próximo commit da lane pai é tratado como merge commit;
- retorno de vários níveis de uma vez → o commit recebe múltiplos parents.

`lane-gap` controla a distância entre lanes e `content-gap` controla o espaço entre o nó e a tag/descrição.

### Direção TB ou BT

```markdown
::: {.git-tree direction="TB"}
...
:::
```

`TB` (`top → bottom`) mostra o commit mais antigo no topo. `BT` (`bottom → top`) mantém o mesmo DAG, invertendo apenas a leitura vertical:

```markdown
::: {.git-tree direction="BT"}
...
:::
```

### DAG explícito: ids e parents

```markdown
:::git-tree
- `main`{#c1} initial commit
- `main`{#c2 parent="c1"} arquitetura base
  - `feature/badges`{#c3 parent="c2"} cria badge
  - `feature/badges`{#c4 parent="c3"} customização visual
    - `test/badges`{#c5 parent="c4"} cobre variantes
    - `test/badges`{#c6 parent="c5"} cobre links
  - `feature/badges`{#c7 parents="c4,c6"} merge test/badges
- `main`{#c8 parents="c2,c7" tag="v0.9.0" head="true"} merge feature/badges
:::
```

`parents=` prevalece sobre a inferência automática. `parents="none"` cria explicitamente um root commit.

## File tree

### Aninhamento profundo e ícones automáticos

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

### Pastas expansíveis em HTML

```yaml
extensions:
  file-tree:
    expanded: true
```

```markdown
::: {.file-tree expanded="false"}
- [+src]{expanded="true"}
  - app.ts
  - styles.css
- [+docs]{collapsed="true"}
  - index.qmd
:::
```

Aliases: `expanded`, `open` e `collapsed`.

### Texto normal, links e tooltip

```markdown
:::file-tree
- analysis.R texto normal
- `pipeline.py` inline code
- [app.ts](https://github.com/lsbjordao/quarto-semantic-components) link normal
- [`steps.lua`](https://github.com/lsbjordao/quarto-semantic-components/blob/main/_extensions/semantic-components/steps.lua) link + inline code
- [analysis.R]{tooltip="Script principal de análise em R"}
:::
```

## Timeline com `steps type="dots"`

Não há um componente `timeline` separado. Uma timeline vertical é um caso natural de uso dos próprios steps com bolinhas:

```markdown
::: {.steps type="dots" line-color="#9aa0a6" line-width="2px"}

## 2024 — Protótipo {dot-color="#16a34a"}
Primeira implementação do componente.

## 2025 — Beta {dot-color="#2563eb"}
Validação e refinamento visual.

## 2026-06 — Release candidate {dot-color="#f59e0b"}
Congelamento da API para testes finais.

## 2026-09 — Release {dot-color="#16a34a"}
Versão estável publicada.

:::
```

Isso mantém `steps` como primitive reutilizável em vez de criar outro componente com a mesma geometria.

Para fluxos e diagramas mais gerais, a extensão não cria um `pipeline` próprio: o Quarto já oferece integração com Mermaid e outras ferramentas de diagramas.

## Aside

`aside` é um bloco semântico genérico. Em HTML, ele é emitido como um elemento real `<aside>`; em PDF/DOCX, o conteúdo permanece como um bloco estrutural legível.

```markdown
::: {.aside variant="note" title="Nota"}
Conteúdo complementar ao fluxo principal do documento.
:::

::: {.aside variant="warning" title="Atenção"}
Este conteúdo merece destaque, mas continua sendo semanticamente um aside.
:::
```

Variantes: `default`, `note`, `warning`, `danger` e `success`.

O default pode ser definido no projeto:

```yaml
extensions:
  aside:
    variant: default
```

## Article

`article` é um contêiner agnóstico para uma unidade de conteúdo autocontida. Em HTML, ele é emitido como um elemento real `<article>` com borda arredondada por padrão.

```markdown
:::article

## 0.9.0 — 2026-09-17

### Added
- `aside`
- `article`

### Changed
- Timeline demonstrada com `steps type="dots"`.
- Fluxos gerais ficam a cargo de Mermaid/Quarto.

### Removed
- `timeline`
- `pipeline`
- `details`
- `changelog`

:::
```

O exemplo acima é um changelog, mas `article` não conhece nenhuma semântica específica de changelog. Ele pode conter posts, releases, notas técnicas, resumos, especificações ou qualquer outra unidade autocontida.

Defaults disponíveis: `border-color`, `radius`, `padding`, `background` e `shadow`.


## Formatos

- **HTML**: apresentação completa, ícones, badges, tooltips, file tree interativo, Git DAG em SVG e elementos semânticos `<aside>`/`<article>`;
- **PDF**: conteúdo estrutural e links são preservados; componentes interativos degradam com segurança;
- **DOCX**: listas, headings, links e texto permanecem editáveis.

## Exemplos

`index.qmd` contém a galeria completa e o `_quarto.yml` da raiz demonstra defaults de projeto.

```bash
quarto preview index.qmd
```
