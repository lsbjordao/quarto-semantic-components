#!/usr/bin/env bash
set -euo pipefail

rm -rf _qsc_generated

quarto render index.qmd --to html --output index.html
quarto render index.qmd --to pdf --output quarto-semantic-components.pdf
quarto render index.qmd --to docx --output quarto-semantic-components.docx

printf '\nRendered with Quarto:\n'
printf '  %s\n' index.html quarto-semantic-components.pdf quarto-semantic-components.docx
