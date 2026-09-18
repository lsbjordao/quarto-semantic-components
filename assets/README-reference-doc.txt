qsc-reference.docx is the Quarto/Pandoc reference document used by the DOCX renderer.
It is reproducible with:

    python scripts/build-reference-doc.py

The final DOCX itself is always generated from index.qmd with `quarto render`.
