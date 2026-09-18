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
local accent_colors={
  note='var(--quarto-callout-color-note,var(--bs-info,#0dcaf0))',
  info='var(--quarto-callout-color-note,var(--bs-info,#0dcaf0))',
  warning='var(--quarto-callout-color-warning,var(--bs-warning,#ffc107))',
  danger='var(--quarto-callout-color-caution,var(--bs-danger,#dc3545))',
  caution='var(--quarto-callout-color-caution,var(--bs-danger,#dc3545))',
  success='var(--quarto-callout-color-tip,var(--bs-success,#198754))',
  tip='var(--quarto-callout-color-tip,var(--bs-success,#198754))',
  important='var(--quarto-callout-color-important,var(--bs-primary,#0d6efd))'
}
local function accent_color(el,meta)
  local value=setting(el,meta,'accent-color',{'accent-colour'})
  if not value or value=='' then return nil end
  local named=accent_colors[tostring(value):lower()]
  return named or value
end
local function append_unique(list,value)
  if not value or value=='' then return end
  for _,item in ipairs(list) do if item==value then return end end
  list[#list+1]=value
end

local function semantic_heading(header)
  local attrs={
    ['role']='heading',
    ['aria-level']=tostring(header.level),
    ['data-heading-level']=tostring(header.level)
  }
  for key,value in pairs(header.attributes or {}) do
    attrs[key]=value
  end
  local classes={'semantic-article-heading','semantic-article-heading-'..tostring(header.level)}
  for _,class in ipairs(header.classes or {}) do classes[#classes+1]=class end
  return pandoc.Div(
    {pandoc.Plain(header.content)},
    pandoc.Attr(header.identifier or '',classes,attrs)
  )
end

local function article_content(blocks)
  local wrapper=pandoc.Div(blocks)
  wrapper=wrapper:walk({Header=semantic_heading})
  return wrapper.content
end

if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name='quarto-semantic-components-article',
    version='0.12.0',
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
  local explicit_expanded=attr(el,'expanded') or attr(el,'open') or attr(el,'expand')
  local explicit_collapsed=attr(el,'collapsed')
  local expanded_value=explicit_expanded or config.default(meta,'article','expanded',{'open','expand'})
  local collapsed_value=explicit_collapsed or config.default(meta,'article','collapsed')

  local collapsible=truthy(collapsible_value)
  if collapsible==nil and (explicit_expanded~=nil or explicit_collapsed~=nil) then collapsible=true end
  if collapsible==nil then collapsible=false end

  local expanded=truthy(expanded_value)
  local collapsed=truthy(collapsed_value)
  if collapsed~=nil then expanded=not collapsed end
  if expanded==nil then expanded=true end

  local summary=setting(el,meta,'summary',{'title','label'}) or 'Content'
  return collapsible,expanded,summary
end

local function article_classes(el,left,collapsible)
  local classes={'semantic-article'}
  for _,class in ipairs(el.classes or {}) do
    if class~='article' then append_unique(classes,class) end
  end
  if left then append_unique(classes,'article-accent-left') end
  if collapsible then append_unique(classes,'article-collapsible') end
  return table.concat(classes,' ')
end

local function transform(el,meta)
  if not has_class(el,'article') then return nil end

  local left=accent_left(el,meta)
  local collapsible,expanded,summary=collapse_settings(el,meta)

  local styles={
    {'--article-border-color',setting(el,meta,'border-color',{'border'})},
    {'--article-radius',setting(el,meta,'radius',{'border-radius'})},
    {'--article-padding',setting(el,meta,'padding')},
    {'--article-background',setting(el,meta,'background',{'bg'})},
    {'--article-shadow',setting(el,meta,'shadow')},
    {'--article-accent-color',accent_color(el,meta)},
    {'--article-accent-width',setting(el,meta,'accent-width')}
  }
  for _,pair in ipairs(styles) do
    if pair[2] and pair[2]~='' then append_style(el,pair[1]..':'..pair[2]) end
  end

  local classes=article_classes(el,left,collapsible)

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
      out:insert(pandoc.Div(article_content(el.content),pandoc.Attr('',{'semantic-article-body'})))
      out:insert(pandoc.RawBlock('html','</details>'))
    else
      out:insert(pandoc.Div(article_content(el.content),pandoc.Attr('',{'semantic-article-content'})))
    end

    out:insert(pandoc.RawBlock('html','</article>'))
    return out
  end

  local fallback_classes={'semantic-article'}
  if left then fallback_classes[#fallback_classes+1]='article-accent-left' end

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
