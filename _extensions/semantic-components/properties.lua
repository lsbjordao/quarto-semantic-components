-- Description-list properties component.
local config=require('./config')
local function has_class(el,name)
  for _,c in ipairs(el.classes or {}) do if c==name then return true end end
  return false
end
local function add_class(el,name) if not has_class(el,name) then el.classes:insert(name) end end
local function attr(el,key) return el.attributes and el.attributes[key] or nil end
local function is_html() return FORMAT and FORMAT:match('html')~=nil end
local function setting(el,meta,key,aliases)
  return attr(el,key) or config.default(meta,'properties',key,aliases)
end
local function append_style(el,declaration)
  local current=attr(el,'style') or ''
  if current~='' and current:sub(-1)~=';' then current=current..';' end
  el.attributes.style=current..declaration..';'
end

if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name='quarto-semantic-components-properties',
    version='0.1.0',
    stylesheets={'css/properties.css'}
  })
end

local function transform(el,meta)
  if not has_class(el,'properties') then return nil end
  add_class(el,'semantic-properties')
  local gap=setting(el,meta,'gap')
  local term_width=setting(el,meta,'term-width',{'key-width'})
  local compact=setting(el,meta,'compact')
  if gap and gap~='' then append_style(el,'--properties-gap:'..gap) end
  if term_width and term_width~='' then append_style(el,'--properties-term-width:'..term_width) end
  if compact and tostring(compact):lower()=='true' then add_class(el,'properties-compact') end
  return el
end

function Pandoc(doc)
  return doc:walk({Div=function(el) return transform(el,doc.meta) end})
end
