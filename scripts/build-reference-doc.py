#!/usr/bin/env python3
"""Build assets/qsc-reference.docx from Pandoc's default reference.docx.

Requires: pandoc, python-docx.
The committed reference DOCX is used directly by Quarto via _quarto.yml; this
script only makes that binary style template reproducible.
"""
from pathlib import Path
import subprocess
import tempfile
from docx import Document
from docx.enum.style import WD_STYLE_TYPE
from docx.shared import Pt, RGBColor
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "qsc-reference.docx"


def shade(style, fill):
    ppr = style.element.get_or_add_pPr()
    shd = ppr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        ppr.append(shd)
    shd.set(qn("w:fill"), fill)


def border_left(style, color="7C3AED", size="20"):
    ppr = style.element.get_or_add_pPr()
    borders = ppr.find(qn("w:pBdr"))
    if borders is None:
        borders = OxmlElement("w:pBdr")
        ppr.append(borders)
    left = OxmlElement("w:left")
    left.set(qn("w:val"), "single")
    left.set(qn("w:sz"), size)
    left.set(qn("w:space"), "8")
    left.set(qn("w:color"), color)
    borders.append(left)


def ensure_style(doc, name, kind=WD_STYLE_TYPE.PARAGRAPH):
    try:
        return doc.styles[name]
    except KeyError:
        return doc.styles.add_style(name, kind)


with tempfile.TemporaryDirectory() as td:
    ref = Path(td) / "reference.docx"
    data = subprocess.check_output(["pandoc", "--print-default-data-file", "reference.docx"])
    ref.write_bytes(data)
    doc = Document(ref)

normal = doc.styles["Normal"]
normal.font.name = "Liberation Sans"
normal.font.size = Pt(10.5)

for name, size in [("Title", 26), ("Heading 1", 20), ("Heading 2", 15), ("Heading 3", 12.5)]:
    style = doc.styles[name]
    style.font.name = "Liberation Sans"
    style.font.size = Pt(size)
    style.font.color.rgb = RGBColor(36, 41, 47)

source = doc.styles["Source Code"]
source.font.name = "Liberation Mono"
source.font.size = Pt(8.5)
shade(source, "F3F4F6")

article = ensure_style(doc, "Semantic Article")
article.font.name = "Liberation Sans"
shade(article, "FAFAFA")
border_left(article)

properties = ensure_style(doc, "Properties")
properties.font.name = "Liberation Sans"

step = ensure_style(doc, "Step Title", WD_STYLE_TYPE.CHARACTER)
step.font.name = "Liberation Sans"
step.font.bold = True

badge = ensure_style(doc, "Badge", WD_STYLE_TYPE.CHARACTER)
badge.font.name = "Liberation Sans"
badge.font.bold = True
badge.font.size = Pt(8.5)
badge.font.color.rgb = RGBColor(21, 128, 61)

kbd = ensure_style(doc, "Keyboard", WD_STYLE_TYPE.CHARACTER)
kbd.font.name = "Liberation Mono"
kbd.font.bold = True
kbd.font.size = Pt(8.5)

indicator = ensure_style(doc, "Indicator", WD_STYLE_TYPE.CHARACTER)
indicator.font.name = "DejaVu Sans"
indicator.font.color.rgb = RGBColor(37, 99, 235)

OUT.parent.mkdir(parents=True, exist_ok=True)
doc.save(OUT)
print(OUT)
