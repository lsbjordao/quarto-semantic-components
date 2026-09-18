-- Theme-aware circled ordered lists.
local config=require('./config')

local function has_class(el,name)
  for _,class in ipairs(el.classes or {}) do if class==name then return true end end
  return false
end

local function add_class(el,name)
  if not has_class(el,name) then el.classes:insert(name) end
end

local function attr(el,key)
  return el.attributes and el.attributes[key] or nil
end

local function is_html()
  return FORMAT and FORMAT:match('html')~=nil
end

if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name='quarto-semantic-components-circle-list',
    version='0.1.0',
    stylesheets={'css/circle-list.css'}
  })
end

local function setting(el,meta,key,aliases)
  return attr(el,key) or config.default(meta,'circle-list',key,aliases)
end

local function suffixed_aliases(aliases,suffix)
  local out={}
  for _,alias in ipairs(aliases or {}) do out[#out+1]=alias..suffix end
  return out
end

local function themed_setting(el,meta,key,aliases)
  return
    setting(el,meta,key,aliases),
    setting(el,meta,key..'-light',suffixed_aliases(aliases,'-light')),
    setting(el,meta,key..'-dark',suffixed_aliases(aliases,'-dark'))
end

local function append_style(el,declaration)
  if not declaration or declaration=='' then return end
  local value=attr(el,'style') or ''
  if value~='' and value:sub(-1)~=';' then value=value..';' end
  el.attributes.style=value..declaration..';'
end

local function append_theme_style(el,variable,base,light,dark)
  if base and base~='' then append_style(el,variable..'-base:'..base) end
  if light and light~='' then append_style(el,variable..'-light:'..light) end
  if dark and dark~='' then append_style(el,variable..'-dark:'..dark) end
end

local function transform_circle_list(el,meta)
  if not (has_class(el,'circle-list') or has_class(el,'semantic-circle-list')) then return nil end

  add_class(el,'semantic-circle-list')
  if not is_html() then return el end

  local border,border_light,border_dark=themed_setting(el,meta,'border-color',{
    'circle-border-color','marker-border-color'
  })
  local text_color,text_light,text_dark=themed_setting(el,meta,'text-color',{
    'number-color','marker-color','color'
  })
  local background,background_light,background_dark=themed_setting(el,meta,'background-color',{
    'background','fill','marker-fill'
  })

  append_theme_style(el,'--circle-list-border-color',border,border_light,border_dark)
  append_theme_style(el,'--circle-list-text-color',text_color,text_light,text_dark)
  append_theme_style(el,'--circle-list-background-color',background,background_light,background_dark)

  return el
end

function Pandoc(doc)
  return doc:walk({Div=function(el) return transform_circle_list(el,doc.meta) end})
end
