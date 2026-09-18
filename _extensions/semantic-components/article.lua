-- Generic semantic <article> component with a neutral rounded container.
local config=require('./config')

local function has_class(el,name)
  for _,c in ipairs(el.classes or {}) do if c==name then return true end end
  return false
end
local function attr(el,key) return el.attributes and el.attributes[key] or nil end
local function is_html() return FORMAT and FORMAT:match('html') ~= nil end
local function esc(value)
  return tostring(value or ''):gsub('&','&amp;'):gsub('<','&lt;'):gsub('>','&gt;'):gsub('"','&quot;')
end
local function append_style(el,declaration)
  if not declaration or declaration=='' then return end
  local current=attr(el,'style') or ''
  if current~='' and current:sub(-1)~=';' then current=current..';' end
  el.attributes.style=current..declaration..';'
end
local function setting(el,meta,key,aliases)
  return attr(el,key) or config.default(meta,'article',key,aliases)
end

if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name='quarto-semantic-components-article',
    version='0.9.0',
    stylesheets={'css/article.css'}
  })
end

local function transform(el,meta)
  if not has_class(el,'article') then return nil end

  local styles={
    {'--article-border-color',setting(el,meta,'border-color',{'border'})},
    {'--article-radius',setting(el,meta,'radius',{'border-radius'})},
    {'--article-padding',setting(el,meta,'padding')},
    {'--article-background',setting(el,meta,'background',{'bg'})},
    {'--article-shadow',setting(el,meta,'shadow')}
  }
  for _,pair in ipairs(styles) do
    if pair[2] and pair[2]~='' then append_style(el,pair[1]..':'..pair[2]) end
  end

  if is_html() then
    local id=el.identifier and el.identifier~='' and (' id="'..esc(el.identifier)..'"') or ''
    local style=attr(el,'style')
    local style_attr=style and style~='' and (' style="'..esc(style)..'"') or ''
    local out=pandoc.List({
      pandoc.RawBlock('html','<article'..id..' class="semantic-article"'..style_attr..'>')
    })
    for _,block in ipairs(el.content) do out:insert(block) end
    out:insert(pandoc.RawBlock('html','</article>'))
    return out
  end

  local attrs={}
  if attr(el,'style') and attr(el,'style')~='' then attrs.style=attr(el,'style') end
  return pandoc.Div(el.content,pandoc.Attr(el.identifier or '',{'semantic-article'},attrs))
end

function Pandoc(doc)
  return doc:walk({Div=function(el) return transform(el,doc.meta) end})
end
