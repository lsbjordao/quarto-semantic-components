# Quarto Semantic Components

Extensão Quarto/Pandoc com componentes semânticos reutilizáveis e independentes do formato final. A mesma fonte `.qmd` pode ser renderizada para HTML, PDF e DOCX; o HTML recebe apresentação rica em CSS e os demais formatos preservam uma estrutura legível baseada na AST do Pandoc.

## Componentes

- `steps`: sequência numerada inspirada no Vocs;
- `steps type="dots"`: sequência com marcadores em bolinha;
- `circle-list`: lista ordenada com números circulados;
- `git-tree`: histórico de versionamento com ramificações aninhadas;
- `file-tree`: árvore de arquivos com autodetecção de tipos e ícones customizados;
- `badge`: shortcode inline com variantes semânticas.

## Instalação

```bash
quarto add lsbjordao/quarto-semantic-components
```

Ative o filtro no documento ou no `_quarto.yml`:

```yaml
filters:
  - semantic-components
```

Os shortcodes distribuídos pela extensão, como `badge`, ficam disponíveis junto com a extensão instalada.

## Estrutura

```text
.
├── index.qmd
├── README.md
└── _extensions/
    └── semantic-components/
        ├── _extension.yml
        ├── semantic-components.lua
        ├── semantic-components-shortcodes.lua
        └── semantic-components.css
```

## Badges inline

```markdown
Status: {{< badge "Beta" >}}
{{< badge "Estável" type="success" icon="✓" >}}
{{< badge "Experimental" type="warning" >}}
{{< badge "Deprecated" type="danger" >}}
{{< badge "v0.2.0" type="accent" >}}
```

Variantes: `neutral`, `info`, `success`, `warning`, `danger` e `accent`.

## Steps

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

## Circle list

```markdown
:::circle-list
1. Item um
2. Item dois
3. Item três
:::
```

## Git tree

Use listas aninhadas para criar ramificações. O primeiro token entre crases é exibido como referência/branch.

```markdown
:::git-tree
- `main` initial commit
- `main` prepara a arquitetura
  - `feature/icons` cria o branch
  - `feature/icons` adiciona autodetecção
    - `docs/icons` documenta a funcionalidade
    - `docs/icons` adiciona exemplos
  - `feature/icons` adiciona customização
- `main` merge feature/icons
- `main` release v0.2.0
:::
```

A sintaxe antiga `::: {.steps type="git"}` continua funcionando como compatibilidade, mas `git-tree` é recomendado quando houver ramificações.

## File tree

```markdown
:::file-tree
- README.md documentação
- +src código-fonte
  - analysis.R
  - pipeline.py
  - app.js
  - types.ts
  - report.qmd
- +data
  - occurrences.csv
  - warehouse.parquet
:::
```

### Ícones automáticos

O filtro reconhece automaticamente os principais tipos de arquivo, incluindo:

- R / R Markdown;
- Python;
- JavaScript / JSX;
- TypeScript / TSX;
- HTML e CSS/SCSS/Sass/Less;
- JSON e YAML;
- Quarto e Markdown;
- Lua, Rust, Go, Java, C e C++;
- SQL e shells;
- Jupyter notebooks;
- CSV/TSV/Parquet/Arrow;
- SQLite e bancos locais;
- imagens;
- arquivos de configuração e lockfiles;
- arquivos conhecidos como `package.json`, `Cargo.toml`, `go.mod`, `Dockerfile`, `.gitignore` e `_quarto.yml`.

Os ícones embutidos são monocromáticos e herdam o tema do documento, funcionando em light/dark sem dependência de CDN.

### Ícones customizados

Use um inline code com o atributo `icon`:

```markdown
:::file-tree
- `species.csv`{icon="leaf"} dados de espécies
- `warehouse.db`{icon="database"} banco consolidado
- `golden.parquet`{icon="★"} base curada
- `deduplicate.py`{icon="🧬"} processamento
- `special.dat`{icon="assets/special.svg"} imagem local
:::
```

Ícones nomeados disponíveis: `file`, `folder`, `code`, `terminal`, `database`, `data`, `image`, `config`, `docs`, `package`, `test`, `lock`, `git`, `notebook`, `leaf`, `star` e `rocket`.

Qualquer outro valor é tratado como conteúdo inline (por exemplo, emoji). Valores terminados em `.svg`, `.png`, `.jpg`, `.jpeg`, `.webp` ou `.gif` são tratados como imagens locais.

## Compatibilidade

A extensão evita depender de HTML bruto para a estrutura principal:

- **HTML**: CSS fornece badges, conectores, círculos, árvore Git e ícones;
- **PDF**: listas e conteúdo textual permanecem estruturados; elementos decorativos degradam com segurança;
- **DOCX**: listas e conteúdo inline permanecem editáveis no Word; badges recebem o estilo `Semantic Badge` quando suportado pelo writer.

## Desenvolvimento

O arquivo `index.qmd` na raiz demonstra todos os componentes.

```bash
quarto preview index.qmd
```
