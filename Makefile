.PHONY: render render-html render-pdf render-docx clean

render: render-html render-pdf render-docx

render-html:
	quarto render index.qmd --to html --output index.html

render-pdf:
	quarto render index.qmd --to pdf --output quarto-semantic-components.pdf

render-docx:
	quarto render index.qmd --to docx --output quarto-semantic-components.docx

clean:
	rm -rf _qsc_generated

