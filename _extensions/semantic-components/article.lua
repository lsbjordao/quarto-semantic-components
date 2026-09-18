-- Generic semantic <article> component with optional left accent and collapse.
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
local function truthy(value)
  if value==nil then return nil end
  value=tostring(value):lower()
  if value=='true' or value=='1' or value=='yes' or value=='on' or value=='open' then return true end
  if value=='false' or value=='0' or value=='no' or value=='off' or value=='closed' then return false end
  return nil
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
local function append_unique(list,value)
  if not value or value=='' then return end
  for _,item in ipairs(list) do if item==value then return end end
  list[#list+1]=value
end

if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name='quarto-semantic-components-article',
    version='0.10.0',
    stylesheets={'css/article.css'}
  })
end

local function accent_left(el,meta)
  local accent=setting(el,meta,'accent',{'border-accent'})
  if accent then
    local value=tostring(accent):lower()
    if value=='left' or truthy(value)==true then return true end
  end
  return truthy(setting(el,meta,'left-border',{'accent-left'}))==true
end

local function collapse_settings(el,meta)
  local collapsible_value=setting(el,meta,'collapsible',{'collapse'})
  local expanded_value=attr(el,'expanded') or attr(el,'open') or config.default(meta,'article','expanded',{'open'})
  local collapsed_value=attr(el,'collapsed') or config.default(meta,'article','collapsed')

  local collapsible=truthy(collapsible_value)
  if collapsible==nil and (expanded_value~=nil or collapsed_value~=nil) then collapsible=true end
  if collapsible==nil then collapsible=false end

  local expanded=truthy(expanded_value)
  local collapsed=truthy(collapsed_value)
  if collapsed~=nil then expanded=not collapsed end
  if expanded==nil then expanded=true end

  local summary=setting(el,meta,'summary',{'title','label'}) or 'Conteúdo'
  return collapsible,expanded,summary
end

local function article_classes(el,variant,left,collapsible)
  local classes={'semantic-article'}
  for _,class in ipairs(el.classes or {}) do
    if class~='article' then append_unique(classes,class) end
  end
  if left then append_unique(classes,'article-accent-left') end
  if variant and variant~='' then append_unique(classes,'article-variant-'..slug(variant)) end
  if collapsible then append_unique(classes,'article-collapsible') end
  return table.concat(classes,' ')
end

local function transform(el,meta)
  if not has_class(el,'article') then return nil end

  local variant=setting(el,meta,'variant') or 'default'
  local left=accent_left(el,meta)
  local collapsible,expanded,summary=collapse_settings(el,meta)

  local styles={
    {'--article-border-color',setting(el,meta,'border-color',{'border'})},
    {'--article-radius',setting(el,meta,'radius',{'border-radius'})},
    {'--article-padding',setting(el,meta,'padding')},
    {'--article-background',setting(el,meta,'background',{'bg'})},
    {'--article-shadow',setting(el,meta,'shadow')},
    {'--article-accent-color',setting(el,meta,'accent-color')},
    {'--article-accent-width',setting(el,meta,'accent-width')},
    {'--article-accent-inset',setting(el,meta,'accent-inset')}
  }
  for _,pair in ipairs(styles) do
    if pair[2] and pair[2]~='' then append_style(el,pair[1]..':'..pair[2]) end
  end

  local classes=article_classes(el,variant,left,collapsible)

  if is_html() then
    local id=el.identifier and el.identifier~='' and (' id="'..esc(el.identifier)..'"') or ''
    local style=attr(el,'style')
    local style_attr=style and style~='' and (' style="'..esc(style)..'"') or ''
    local out=pandoc.List({
      pandoc.RawBlock('html','<article'..id..' class="'..esc(classes)..'"'..style_attr..'>')
    })

    if collapsible then
      local open_attr=expanded and ' open' or ''
      out:insert(pandoc.RawBlock('html','<details class="semantic-article-details"'..open_attr..'>'))
      out:insert(pandoc.RawBlock('html','<summary class="semantic-article-summary">'..esc(summary)..'</summary>'))
      out:insert(pandoc.RawBlock('html','<div class="semantic-article-body">'))
      for _,block in ipairs(el.content) do out:insert(block) end
      out:insert(pandoc.RawBlock('html','</div></details>'))
    else
      for _,block in ipairs(el.content) do out:insert(block) end
    end

    out:insert(pandoc.RawBlock('html','</article>'))
    return out
  end

  local fallback_classes={'semantic-article'}
  if left then fallback_classes[#fallback_classes+1]='article-accent-left' end
  fallback_classes[#fallback_classes+1]='article-variant-'..slug(variant)

  local blocks=pandoc.List()
  if collapsible and summary and summary~='' then
    blocks:insert(pandoc.Para({pandoc.Strong({pandoc.Str(summary)})}))
  end
  for _,block in ipairs(el.content) do blocks:insert(block) end

  local attrs={}
  if attr(el,'style') and attr(el,'style')~='' then attrs.style=attr(el,'style') end
  return pandoc.Div(blocks,pandoc.Attr(el.identifier or '',fallback_classes,attrs))
end

function Pandoc(doc)
  return doc:walk({Div=function(el) return transform(el,doc.meta) end})
end
