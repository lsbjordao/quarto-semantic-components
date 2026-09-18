#!/usr/bin/env python3
from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def update_index() -> None:
    path = Path("index.qmd")
    text = path.read_text(encoding="utf-8")

    text = replace_once(
        text,
        '| `steps` | Procedures, workflows, timelines | Continuous numbered or dot connectors |\n| `circle-list` |',
        '| `steps` | Procedures, workflows, timelines | Continuous numbered or dot connectors |\n| `roadmap` | Milestones, product plans, project journeys | Responsive sinuous SVG path with horizontal/vertical layouts |\n| `circle-list` |',
        "index at-a-glance",
    )
    text = replace_once(
        text,
        'The extension intentionally avoids components that Quarto already handles well. A timeline can be expressed with `steps type="dots"`, while general diagrams can use Mermaid.',
        'The extension intentionally avoids components that Quarto already handles well. A timeline can still be expressed with `steps type="dots"`; `roadmap` is reserved for milestone paths and project journeys where the route itself is part of the presentation. General diagrams can use Mermaid.',
        "index component rationale",
    )
    text = replace_once(
        text,
        '  steps:\n    dot-size: "0.72rem"\n    line-width: "1.5px"\n\n  tree:',
        '  steps:\n    dot-size: "0.72rem"\n    line-width: "1.5px"\n\n  roadmap:\n    orientation: horizontal\n    curve: "0.6"\n    markers: dot\n\n  tree:',
        "index defaults",
    )
    text = replace_once(
        text,
        '| `steps` | `surface-color`, `line-color`, `dot-color`, `dot-fill` |\n| `tree` |',
        '| `steps` | `surface-color`, `line-color`, `dot-color`, `dot-fill` |\n| `roadmap` | `road-color`, `point-color`, `surface-color` |\n| `tree` |',
        "index theme table",
    )

    roadmap_section = r'''# Roadmap

`roadmap` is a milestone path rather than a conventional timeline. In HTML it draws a lightweight SVG road through the markers, with a gentle curve calculated from the number and position of the items. Horizontal roadmaps alternate cards around the route and automatically become vertical on narrow screens.

## Horizontal roadmap

```markdown
::: {.roadmap orientation="horizontal" curve="0.6"}

::: {.roadmap-item title="Research" status="done"}
Review references and define requirements.
:::

::: {.roadmap-item title="Prototype" status="done"}
Build the first working version.
:::

::: {.roadmap-item title="Validation" status="current"}
Test the component with real documents.
:::

::: {.roadmap-item title="Release" status="milestone"}
Publish the stable version.
:::

:::
```

**Output:**

::: {.roadmap orientation="horizontal" curve="0.6"}

::: {.roadmap-item title="Research" status="done"}
Review references and define requirements.
:::

::: {.roadmap-item title="Prototype" status="done"}
Build the first working version.
:::

::: {.roadmap-item title="Validation" status="current"}
Test the component with real documents.
:::

::: {.roadmap-item title="Release" status="milestone"}
Publish the stable version.
:::

:::

## Vertical roadmap and numbered markers

```markdown
::: {.roadmap orientation="vertical" markers="numbers" curve="0.75"}

::: {.roadmap-item title="Collect" status="done"}
Gather the source material.
:::

::: {.roadmap-item title="Process" status="current"}
Transform and validate the data.
:::

::: {.roadmap-item title="Review" status="future"}
Review the result.
:::

::: {.roadmap-item title="Publish" status="milestone"}
Publish the final output.
:::

:::
```

**Output:**

::: {.roadmap orientation="vertical" markers="numbers" curve="0.75"}

::: {.roadmap-item title="Collect" status="done"}
Gather the source material.
:::

::: {.roadmap-item title="Process" status="current"}
Transform and validate the data.
:::

::: {.roadmap-item title="Review" status="future"}
Review the result.
:::

::: {.roadmap-item title="Publish" status="milestone"}
Publish the final output.
:::

:::

`orientation` accepts `horizontal` or `vertical`; `curve` ranges from `0` to `1`; and `markers` accepts `dot`, `numbers`, or `none`. Item statuses are `done`, `current`, `future`, and `milestone`.

Theme-aware customization follows the same extension-wide convention. `road-color`, `point-color`, and `surface-color` accept unsuffixed values plus `-light` and `-dark` overrides. Individual items can override `point-color` in the same way.

In PDF and DOCX the SVG route intentionally degrades to a readable ordered list, preserving the item title, status, and Markdown content.

'''
    text = replace_once(
        text,
        '# Circled Ordered List\n',
        roadmap_section + '# Circled Ordered List\n',
        "index roadmap section",
    )
    text = text.replace(
        '  - steps.lua\n  - tree.lua',
        '  - steps.lua\n  - roadmap.lua\n  - tree.lua',
    )
    text = text.replace(
        'Full styling, light/dark color overrides, generic/file trees, SVG Git DAG, native progress/meter, keyboard/abbreviation semantics, and article collapse/expand',
        'Full styling, light/dark color overrides, sinuous roadmaps, generic/file trees, SVG Git DAG, native progress/meter, keyboard/abbreviation semantics, and article collapse/expand',
    )
    path.write_text(text, encoding="utf-8")


def update_readme() -> None:
    path = Path("README.md")
    text = path.read_text(encoding="utf-8")
    text = replace_once(
        text,
        '- `steps type="dots"`: steps with hollow dots by default and extensive customization;\n- `circle-list`:',
        '- `steps type="dots"`: steps with hollow dots by default and extensive customization;\n- `roadmap`: responsive milestone path with a sinuous SVG route in horizontal or vertical layouts;\n- `circle-list`:',
        "README component list",
    )
    text = replace_once(
        text,
        '  steps:\n    dot-size: "0.72rem"\n    line-width: "1.5px"\n\n  tree:',
        '  steps:\n    dot-size: "0.72rem"\n    line-width: "1.5px"\n\n  roadmap:\n    orientation: horizontal\n    curve: "0.6"\n    markers: dot\n\n  tree:',
        "README defaults",
    )
    text = replace_once(
        text,
        '| `steps` | `surface-color`, `line-color`, `dot-color`, `dot-fill` |\n| `tree` |',
        '| `steps` | `surface-color`, `line-color`, `dot-color`, `dot-fill` |\n| `roadmap` | `road-color`, `point-color`, `surface-color` |\n| `tree` |',
        "README theme table",
    )

    roadmap_section = r'''## Roadmap

`roadmap` is intentionally different from the vertical timeline pattern above: it represents a project journey or milestone path whose route is part of the visual language. HTML draws a smooth SVG path through the markers; horizontal roadmaps automatically switch to vertical on narrow screens.

```markdown
::: {.roadmap orientation="horizontal" curve="0.6"}

::: {.roadmap-item title="Research" status="done"}
Review references and define requirements.
:::

::: {.roadmap-item title="Prototype" status="done"}
Build the first working version.
:::

::: {.roadmap-item title="Validation" status="current"}
Test the component with real documents.
:::

::: {.roadmap-item title="Release" status="milestone"}
Publish the stable version.
:::

:::
```

Options: `orientation="horizontal|vertical"`, `curve="0..1"`, `markers="dot|numbers|none"`, `road-width`, `road-background-width`, and `point-size`. Statuses are `done`, `current`, `future`, and `milestone`.

The colors `road-color`, `point-color`, and `surface-color` support the usual unsuffixed, `-light`, and `-dark` forms; individual `.roadmap-item` blocks can override the point color. PDF and DOCX degrade to an ordered list with titles, statuses, and content preserved.

A fuller gallery is available in [`examples/roadmap.qmd`](examples/roadmap.qmd).

'''
    text = replace_once(
        text,
        '## Circled Ordered List\n',
        roadmap_section + '## Circled Ordered List\n',
        "README roadmap section",
    )
    path.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    update_index()
    update_readme()
    print("Integrated roadmap documentation into index.qmd and README.md")
