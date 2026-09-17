# Quarto Semantic Components

Extensão Quarto/Pandoc com componentes semânticos reutilizáveis para HTML, PDF e DOCX. A estrutura principal permanece no AST do Pandoc; o HTML acrescenta apresentação rica, enquanto formatos não HTML preservam listas, links e conteúdo textual.

## Componentes

- `steps`: sequência numerada inspirada no Vocs;
- `steps type="dots"`: steps com bolinhas, defaults por bloco e cores por etapa;
- `circle-list`: lista ordenada com números circulados;
- `git-tree`: histórico Git com branches aninhados e conectores CSS compactos, sem ASCII art;
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

O projeto [`mcanouil/quarto-badge`](https://github.com/mcanouil/quarto-badge) define tipos de badge na configuração e os reutiliza por chave/valor. Esta extensão usa **`semantic-badge`** e prioriza customização por instância.

```markdown
{{< semantic-badge "Estável" type="success" icon="✓" >}}
{{< semantic-badge "v0.4.1" type="accent" appearance="solid" size="md" >}}
{{< semantic-badge "Custom" bg="#111827" fg="#fff" border="#60a5fa" border-width="2px" radius="0.35rem" padding="0.2em 0.7em" shadow="0 2px 8px rgb(0 0 0 / .16)" >}}
```

Também existe a forma AST-native:

```markdown
[Beta]{.semantic-badge variant="info" appearance="outline"}
```

## Steps

Os exemplos usam `##` como padrão. O filtro considera o primeiro nível de heading encontrado dentro do componente, então `###` e outros níveis continuam válidos.

```markdown
:::steps
## Primeiro passo
Conteúdo.

## Segundo passo
Conteúdo.
:::
```

### Bolinhas: cor default

```markdown
::: {.steps type="dots" dot-color="#6366f1" line-color="#a5b4fc"}
## Extrair
Conteúdo.

## Validar
Conteúdo.

## Publicar
Conteúdo.
:::
```

`dot-color` controla a cor default das bolinhas; `line-color` controla a cor default dos conectores.

### Bolinhas: cor individual por etapa

Atributos no próprio heading sobrescrevem o default somente naquela etapa:

```markdown
::: {.steps type="dots" dot-color="#8c959f" line-color="#d0d7de"}
## Extrair {dot-color="#2563eb"}
Conteúdo.

## Deduplicar {dot-color="#f59e0b" line-color="#f59e0b"}
Conteúdo.

## Publicar {dot-color="#2da44e"}
Conteúdo.
:::
```

Assim é possível combinar um tema padrão para todo o componente com exceções em cada bolinha. `line-color` também pode ser sobrescrito individualmente.

## Circle list

```markdown
:::circle-list
1. Item um
2. Item dois
3. Item três
:::
```

## Git tree

Branches são listas aninhadas. O grafo HTML é desenhado por CSS com linhas, curvas e nós circulares, sem caracteres ASCII. As lanes são compactas: cada nível adicional fica próximo ao anterior, em vez de formar colunas muito afastadas.

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
- `main` release v0.4.1
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

### Providers de ícones

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

Links Markdown são preservados e o destino é escolhido pelo autor:

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

- **HTML**: apresentação completa, ícones, conectores, cores por etapa e badges ricos;
- **PDF**: conteúdo estrutural e links são preservados; decoração HTML degrada com segurança;
- **DOCX**: listas, links e texto permanecem editáveis.

## Exemplos

`index.qmd` contém a galeria completa. Cada exemplo mostra primeiro o código gerador e depois o output.

```bash
quarto preview index.qmd
```
