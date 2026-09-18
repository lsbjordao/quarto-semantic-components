# Quarto Semantic Components

Quarto/Pandoc extension with reusable semantic components for **HTML, PDF, and DOCX**. The core structure stays in the Pandoc AST; HTML adds richer presentation, while non-HTML formats preserve lists, links, and textual content.

## Inspiration

Some ergonomics and syntax ideas came from the [Vocs](https://vocs.dev/) framework, especially Markdown components such as **Steps** and **File Tree**. The implementation here is original and adapted to the Quarto/Pandoc ecosystem, with additional focus on cross-format rendering, project metadata, and safe degradation to PDF/DOCX.

## Components

- `steps`: numbered sequence;
- `steps type="dots"`: steps with hollow dots by default and extensive customization;
- `circle-list`: ordered list with circled numbers;
- `git-tree`: Git commit graph (DAG) with branches, merges, tags, `HEAD`, and TB/BT directions;
- `file-tree`: file tree with deep nesting, links, info, icons, and collapsible folders in HTML;
- `badge`: inline badge with project presets and per-instance customization;
- `article`: semantic container based on the HTML `<article>` element, with border, optional side accent, and collapse/expand in HTML.

## Installation

```bash
quarto add lsbjordao/quarto-semantic-components
```

In the document or `_quarto.yml`:

```yaml
filters:
  - semantic-components
```

## Defaults in `_quarto.yml`

Precedence is:

```text
_quarto.yml / _metadata.yml
        ↓
component preset
        ↓
component attributes
        ↓
individual item attributes
```

Example:

```yaml
extensions:
  badge:
    - key: stable
      label: Stable
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
    indent: "1.8rem"

  git-tree:
    direction: TB
    line-color: "#9aa0a6"
    line-width: "2px"
    node-size: "0.68rem"
    lane-gap: "0.82rem"
    row-height: "36px"
    content-gap: "0.55rem"

  article:
    radius: "0.75rem"
    padding: "1rem 1.1rem"
    accent: none
```

The `semantic-components:` and `extensions.semantic-components` namespaces are also accepted.

## Badges

The only public shortcode is **`badge`**:

```markdown
{{< badge "Beta" >}}
{{< badge "Stable" type="success" icon="✓" >}}
{{< badge stable >}}
{{< badge "Stable release" key="stable" >}}
```

The AST-native form uses the same word:

```markdown
[AST-native]{.badge key="stable" appearance="outline" size="md"}
```

The public `.badge` class is converted internally by the extension to a private class, avoiding dependence on Bootstrap's `.badge` styling.

### Compatibility with `mcanouil/quarto-badge`

The [`mcanouil/quarto-badge`](https://github.com/mcanouil/quarto-badge) project also registers a shortcode named `badge`. A project should therefore **choose which extension is responsible for `{{< badge ... >}}`**; loading both badge extensions at the same time is not recommended.

## Steps

Examples use `##` by default. The filter detects the first heading level found inside the component, so other heading levels remain valid.

### Numbered

In numbered mode, the edge is also continuous from center to center and passes behind the circles. The inside of each marker uses the theme surface to hide the line. `line-color`, `line-width`, and `surface-color` work for both numbered and dot steps.

```markdown
:::steps
## Primeiro passo
Content.

## Second step
Content.

## Third step
Content.

## Fourth step
Content.
:::
```

### Hollow dots by default

```markdown
::: {.steps type="dots"}
## Extract
Content.

## Validate
Content.

## Transform
Content.

## Publish
Content.
:::
```

`dot-color` controls the outline. Without `dot-fill`, the node center uses the theme surface color to mask the continuous edge; `dot-fill` applies an explicit fill.

```markdown
::: {.steps type="dots"
  dot-color="#8c959f"
  dot-size="0.78rem"
  line-color="#9aa0a6"
  line-width="1.5px"}

## Extract {dot-color="#2563eb"}
Content.

## Deduplicate {dot-color="#f59e0b" dot-size="0.95rem"}
Content.

## Review {dot-color="#8b5cf6"}
Content.

## Publish {dot-color="#16a34a"}
Content.
:::
```

Defaults and overrides: `dot-color`, `dot-fill`, `dot-size`, `dot-border-width`, `line-color`, `line-width`, and `surface-color`. In dot steps, the edge is continuous from node center to node center and passes behind the dots; the center uses the theme surface to hide the line. For custom backgrounds, use `surface-color=`. `dot-fill="transparent"` and `dot-fill="none"` are also interpreted as the surface, preventing the edge from showing through the node.

### Timeline example with `steps type="dots"`

There is no separate `timeline` component. A vertical timeline is a natural use case for dot steps:

```markdown
::: {.steps type="dots" line-color="#9aa0a6" line-width="2px"}

## [2024]{.badge type="success" appearance="outline" size="xs"} Prototype {dot-color="#16a34a"}
First implementation of the component.

## [2025]{.badge type="info" appearance="outline" size="xs"} Beta {dot-color="#2563eb"}
Validation and visual refinement.

## [2026-06]{.badge type="warning" appearance="outline" size="xs"} Release candidate {dot-color="#f59e0b"}
API freeze for final testing.

## [2026-09]{.badge type="success" appearance="solid" size="xs"} Release {dot-color="#16a34a"}
Stable version released.

:::
```

This keeps `steps` as a reusable primitive instead of creating another component with the same geometry.

For more general flows and diagrams, the extension does not create its own `pipeline`: Quarto already provides integration with Mermaid and other diagramming tools.


## Circle list

```markdown
:::circle-list
1. Item one
2. Item two
3. Item three
4. Item four
:::
```

## Git tree: a commit graph, not just a visual tree

Git is modeled as a **commit DAG**. In `git-tree`:

- each dot represents a commit;
- each edge connects a parent commit to a child commit;
- a branch split always starts at a commit;
- a merge always ends at a commit;
- the tag/branch and description start immediately after the corresponding node, forming a staircase aligned with the lane hierarchy;
- `tag=` and `head=true` can attach additional references to the commit.

### Simple syntax

```markdown
:::git-tree
- `main` initial commit
- `main` base architecture
  - `feature/icons` creates branch
  - `feature/icons` adds Devicon
    - `docs/icons` documents providers
    - `docs/icons` adds examples
  - `feature/icons` merge docs/icons
  - `feature/icons` adds links
- `main` merge feature/icons
:::
```

The extension infers parents as follows:

- same depth → next commit on the same lane;
- increased depth → branch created from the immediately preceding commit;
- return to a shallower depth → the next commit on the parent lane is treated as a merge commit;
- return across multiple levels at once → the commit receives multiple parents.

`lane-gap` controls the distance between lanes, and `content-gap` controls the space between the node and the tag/description.

### TB or BT direction

```markdown
::: {.git-tree direction="TB"}
...
:::
```

`TB` (`top → bottom`) shows the oldest commit at the top. `BT` (`bottom → top`) keeps the same DAG and only reverses vertical reading:

```markdown
::: {.git-tree direction="BT"}
...
:::
```

### Explicit DAG: ids and parents

```markdown
:::git-tree
- `main`{#c1} initial commit
- `main`{#c2 parent="c1"} base architecture
  - `feature/badges`{#c3 parent="c2"} creates badge
  - `feature/badges`{#c4 parent="c3"} visual customization
    - `test/badges`{#c5 parent="c4"} covers variants
    - `test/badges`{#c6 parent="c5"} covers links
  - `feature/badges`{#c7 parents="c4,c6"} merge test/badges
- `main`{#c8 parents="c2,c7" tag="v0.10.9" head="true"} merge feature/badges
:::
```

`parents=` takes precedence over automatic inference. `parents="none"` explicitly creates a root commit.

## File tree

### Deep nesting and automatic icons

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

Available providers: `devicon`, `simple-icons`, `builtin`, and `none`.

`schema.sql` automatically receives the classic database cylinder icon in the builtin fallback.

### Horizontal indentation per level

`indent` controls the horizontal distance added at each nested level:

```markdown
::: {.file-tree indent="1rem"}
- +src
  - +components
    - Button.ts
  - app.ts
- +database
  - schema.sql
:::
```

It can also be defined at the project level:

```yaml
extensions:
  file-tree:
    indent: "1.8rem"
```

Accepted aliases: `level-indent`, `indent-size`, and `child-indent`.

For `.qmd`, `_quarto.yml`, and `quarto.yml`, the default provider uses Quarto's official symbol served from the Quarto website.

### Expandable folders in HTML

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

Aliases: `expanded`, `open`, and `collapsed`.

### Plain text, links, and info

```markdown
:::file-tree
- analysis.R plain text
- `pipeline.py` inline code
- [app.ts](https://github.com/lsbjordao/quarto-semantic-components) regular link
- [`steps.lua`](https://github.com/lsbjordao/quarto-semantic-components/blob/main/_extensions/semantic-components/steps.lua) link + inline code
- [analysis.R]{info="Main R analysis script"}
:::
```

## Article

`article` is the generic block for a self-contained unit of content. In HTML, the extension emits a real `<article>` element. Internal Markdown headings are preserved visually and semantically with `role="heading"`/`aria-level`, without generating `<section>` elements that escape the box. The default behavior is simply a subtle rounded border:

```markdown
:::article
## Technical note
Self-contained content with normal **Markdown**.
:::
```

### Optional left accent

The generic article has no side accent. To add a left accent with rounded ends, use `accent="left"`:

```markdown
::: {.article accent="left" accent-color="warning"}
## Attention
The side accent is only an optional presentation of the same `article`.
:::
```

`accent-color=` accepts any CSS color or a predefined semantic name. Presets: `note`/`info`, `warning`, `danger`/`caution`, `success`/`tip`, and `important`. These names use Quarto callout color variables, with Bootstrap as a fallback.

Accent parameters: `accent`, `accent-color`, and `accent-width`. `left-border="true"` is an alias for `accent="left"`.

### Collapse and expand

The same `article` can be collapsible in HTML:

```markdown
::: {.article
  collapsible="true"
  summary="Technical details"
  expanded="false"}

Content initially collapsed.

:::
```

Internally, HTML keeps `<article>` as the outer element and uses a native `<details>` inside it. This makes the control work without JavaScript and keeps it keyboard-accessible.

`expanded=`, `expand=`, and `open=` are equivalent. `collapsed=` uses the inverse logic. If any of these states is provided, `collapsible` is inferred automatically. In PDF/DOCX, the content is always rendered in full.

Accent and collapse can be combined:

```markdown
::: {.article
  accent="left"
  accent-color="note"
  collapsible="true"
  summary="Methodology"
  expanded="true"}

Methodology content.

:::
```

### Example: changelog

A changelog does not need its own component; it is simply one possible use of an `article`:

```markdown
:::article

## 0.10.9 — 2026-09-17

### Added
- Optional left accent in `article`.
- Collapse/expand nativo.

### Changed
- All generic blocks converged on `article`.

### Removed
- `aside`.

:::
```

In addition to the options above, `article` accepts `border-color`, `radius`, `padding`, `background`, and `shadow`.


## Formats

- **HTML**: full presentation, icons, badges, info, interactive file tree, Git DAG in SVG, and the semantic `<article>` element;
- **PDF**: structural content and links are preserved; interactive components degrade safely;
- **DOCX**: lists, headings, links, and text remain editable.

## Examples

`index.qmd` contains the complete gallery, and the root `_quarto.yml` demonstrates project defaults.

```bash
quarto preview index.qmd
```
