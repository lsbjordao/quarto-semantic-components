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
    dot-size: "0.72rem"
    line-width: "1.5px"

  file-tree:
    icons: devicon
    expanded: true
    indent: "1.8rem"

  git-tree:
    direction: TB
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

## Theme-aware colors

Color options support a common fallback rule:

```text
property-light / property-dark
            ↓
      property
            ↓
automatic theme default
```

The unsuffixed property applies to **both** themes. A suffixed property overrides it only for the corresponding color mode.

```markdown
::: {.steps
  line-color="#6b7280"
  line-color-dark="#adb5bd"}
...
:::
```

In this example, the light theme uses `line-color`, while the dark theme uses `line-color-dark`.

You can also define both theme values explicitly:

```markdown
::: {.steps
  surface-color-light="#f3f4f6"
  surface-color-dark="#2b3035"
  line-color-light="#6b7280"
  line-color-dark="#adb5bd"}
...
:::
```

Supported theme-aware color properties:

| Component | Properties |
|---|---|
| `steps` | `surface-color`, `line-color`, `dot-color`, `dot-fill` |
| `git-tree` | `line-color`, `node-bg` |
| `article` | `border-color`, `background`, `accent-color` |
| `badge` | `fg`, `bg`, `border` |

Each property also accepts `-light` and `-dark`, for example `accent-color-light` and `accent-color-dark`.

If no explicit color is supplied, the automatic theme-aware default is preserved.

## Badges

The only public shortcode is **`badge`**:

```markdown
{{< badge "Beta" >}}
{{< badge "Stable" type="success" icon="✓" >}}
{{< badge stable >}}
{{< badge "Stable release" key="stable" >}}
```

Theme-specific custom colors are also supported:

```markdown
{{< badge "Adaptive"
  fg-light="#1f2937" bg-light="#e5e7eb" border-light="#9ca3af"
  fg-dark="#f9fafb" bg-dark="#374151" border-dark="#6b7280" >}}
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

In numbered mode, the edge is continuous from center to center and passes behind the circles. The inside of each marker uses the theme surface to hide the line.

```markdown
:::steps
## First step
Content.

## Second step
Content.

## Third step
Content.

## Fourth step
Content.
:::
```

For a custom surface, prefer theme-specific colors when contrast needs to differ between light and dark modes:

```markdown
::: {.steps
  surface-color-light="#f3f4f6"
  surface-color-dark="#2b3035"
  line-color-light="#6b7280"
  line-color-dark="#adb5bd"}

## Prepare
Content.

## Import
Content.

## Validate
Content.

## Export
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

Theme suffixes can also be used per heading:

```markdown
::: {.steps type="dots"}
## Extract {dot-color-light="#2563eb" dot-color-dark="#60a5fa"}
Content.

## Review {dot-color-light="#d97706" dot-color-dark="#fbbf24"}
Content.
:::
```

Defaults and overrides: `dot-color`, `dot-fill`, `dot-size`, `dot-border-width`, `line-color`, `line-width`, and `surface-color`. `dot-fill="transparent"` and `dot-fill="none"` are interpreted as the current surface, preventing the connector from showing through the node.

### Timeline example with `steps type="dots"`

There is no separate `timeline` component. A vertical timeline is a natural use case for dot steps:

```markdown
::: {.steps type="dots" line-width="2px"}

## [2024]{.badge type="success" appearance="outline" size="xs"} Prototype
First implementation of the component.

## [2025]{.badge type="info" appearance="outline" size="xs"} Beta
Validation and visual refinement.

## [2026-06]{.badge type="warning" appearance="outline" size="xs"} Release candidate
API freeze for final testing.

## [2026-09]{.badge type="success" appearance="solid" size="xs"} Release
Stable version released.

:::
```

This keeps `steps` as a reusable primitive instead of creating another component with the same geometry.

For more general flows and diagrams, the extension does not create its own `pipeline`: Quarto already provides integration with Mermaid and other diagramming tools.

## Circled Ordered List

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

`TB` (`top → bottom`) shows the oldest commit at the top. `BT` (`bottom → top`) keeps the same DAG and only reverses vertical reading.

Theme-specific graph colors are supported:

```markdown
::: {.git-tree
  line-color-light="#6b7280"
  line-color-dark="#adb5bd"
  node-bg-light="#ffffff"
  node-bg-dark="#212529"}
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
- `main`{#c8 parents="c2,c7" tag="v0.11.0" head="true"} merge feature/badges
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
    - +database
      - schema.sql
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

`article` is the generic block for a self-contained unit of content. In HTML, the extension emits a real `<article>` element. The default behavior is a subtle rounded border.

```markdown
:::article
## Technical note
Self-contained content with normal **Markdown**.
:::
```

### Optional left accent

```markdown
::: {.article accent="left" accent-color="warning"}
## Attention
The side accent is an optional presentation of the same `article`.
:::
```

`accent-color=` accepts any CSS color or a semantic name: `note`/`info`, `warning`, `danger`/`caution`, `success`/`tip`, and `important`.

Theme-specific article colors are also supported:

```markdown
::: {.article
  accent="left"
  accent-color-light="#7c3aed"
  accent-color-dark="#c4b5fd"
  border-color-light="#d1d5db"
  border-color-dark="#4b5563"
  background-light="#fafafa"
  background-dark="#1f2937"}
...
:::
```

### Collapse and expand

```markdown
::: {.article
  collapsible="true"
  summary="Technical details"
  expanded="false"}

Content initially collapsed.

:::
```

Internally, HTML keeps `<article>` as the outer element and uses a native `<details>` inside it. This works without JavaScript and remains keyboard-accessible.

`expanded=`, `expand=`, and `open=` are equivalent. `collapsed=` uses the inverse logic. In PDF/DOCX, the content is always rendered in full.

In addition to the options above, `article` accepts `border-color`, `radius`, `padding`, `background`, and `shadow`.

## Formats

- **HTML**: full presentation, light/dark color overrides, icons, badges, info, interactive file tree, Git DAG in SVG, and the semantic `<article>` element;
- **PDF**: structural content and links are preserved; interactive components degrade safely;
- **DOCX**: lists, headings, links, and text remain editable.

## Examples

`index.qmd` contains the complete gallery, and the root `_quarto.yml` demonstrates project defaults.

```bash
quarto preview index.qmd
```
