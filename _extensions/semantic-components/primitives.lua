-- CSS dependency for inline semantic primitives rendered by shortcodes.
local function is_html() return FORMAT and FORMAT:match('html')~=nil end
if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name='quarto-semantic-components-primitives',
    version='0.12.0',
    stylesheets={'css/primitives.css'}
  })
end
return {}
