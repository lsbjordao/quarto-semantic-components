-- Generic semantic <aside> component.
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
local function slug(value)
  value=(value or 'default'):lower():gsub('[^%w_-]+','-'):gsub('^-+',''):gsub('-+$','')
  return value~='' and value or 'default'
end

if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name='quarto-semantic-components-aside',
    version='0.9.0',
    stylesheets={'css/aside.css'}
  })
end

local function transform(el,meta)
  if not has_class(el,'aside') then return nil end

  local variant=attr(el,'variant') or config.default(meta,'aside','variant') or 'default'
  local title=attr(el,'title') or attr(el,'label') or config.default(meta,'aside','title',{'label'})
  local variant_class='semantic-aside-'..slug(variant)

  if is_html() then
    local id=el.identifier and el.identifier~='' and (' id="'..esc(el.identifier)..'"') or ''
    local out=pandoc.List({
      pandoc.RawBlock('html','<aside'..id..' class="semantic-aside '..variant_class..'">')
    })
    if title and title~='' then
      out:insert(pandoc.RawBlock('html','<div class="semantic-aside-title">'..esc(title)..'</div>'))
    end
    for _,block in ipairs(el.content) do out:insert(block) end
    out:insert(pandoc.RawBlock('html','</aside>'))
    return out
  end

  local blocks=pandoc.List()
  if title and title~='' then
    blocks:insert(pandoc.Para({pandoc.Strong({pandoc.Str(title)})}))
  end
  for _,block in ipairs(el.content) do blocks:insert(block) end
  return pandoc.Div(blocks,pandoc.Attr(el.identifier or '',{'semantic-aside',variant_class}))
end

function Pandoc(doc)
  return doc:walk({Div=function(el) return transform(el,doc.meta) end})
end
