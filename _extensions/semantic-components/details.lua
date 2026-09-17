-- Collapsible details. HTML uses native <details>; PDF/DOCX keep the summary
-- and full body visible.
local config=require('./config')

local function has_class(el,name)
  for _,c in ipairs(el.classes or {}) do if c==name then return true end end
  return false
end
local function attr(el,key) return el.attributes and el.attributes[key] or nil end
local function is_html() return FORMAT and FORMAT:match('html') ~= nil end
local function truthy(value)
  if value==nil then return nil end
  value=tostring(value):lower()
  if value=='true' or value=='1' or value=='yes' or value=='on' or value=='open' then return true end
  if value=='false' or value=='0' or value=='no' or value=='off' or value=='closed' then return false end
  return nil
end
local function esc(value)
  return tostring(value or ''):gsub('&','&amp;'):gsub('<','&lt;'):gsub('>','&gt;'):gsub('"','&quot;')
end

if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name='quarto-semantic-components-details',
    version='0.8.0',
    stylesheets={'css/details.css'}
  })
end

local function transform(el,meta)
  if not has_class(el,'details') then return nil end
  local summary=attr(el,'summary') or attr(el,'title') or config.default(meta,'details','summary',{'title'}) or 'Details'
  local open=truthy(attr(el,'open'))
  if open==nil then open=truthy(config.default(meta,'details','open')) end
  local variant=attr(el,'variant') or config.default(meta,'details','variant') or 'default'

  if is_html() then
    local open_attr=open and ' open' or ''
    local html='<details class="semantic-details semantic-details-'..esc(variant)..'"'..open_attr..'><summary>'..esc(summary)..'</summary><div class="semantic-details-body">'
    local out=pandoc.List({pandoc.RawBlock('html',html)})
    for _,b in ipairs(el.content) do out:insert(b) end
    out:insert(pandoc.RawBlock('html','</div></details>'))
    return out
  end

  local blocks=pandoc.List({pandoc.Para({pandoc.Strong({pandoc.Str(summary)})})})
  for _,b in ipairs(el.content) do blocks:insert(b) end
  return pandoc.Div(blocks,pandoc.Attr('',{'semantic-details','semantic-details-'..variant}))
end

function Pandoc(doc)
  return doc:walk({Div=function(el) return transform(el,doc.meta) end})
end
