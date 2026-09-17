-- Pipeline / process-flow component. HTML renders connected stages; non-HTML
-- keeps the source list as a portable semantic fallback.
local config=require('./config')

local function has_class(el,name)
  for _,c in ipairs(el.classes or {}) do if c==name then return true end end
  return false
end
local function attr(el,key) return el.attributes and el.attributes[key] or nil end
local function is_html() return FORMAT and FORMAT:match('html') ~= nil end
local function iattr(inline,key)
  return inline and inline.attributes and inline.attributes[key] or nil
end
local function slug(value)
  return (value or 'todo'):lower():gsub('[^%w_-]','-')
end
local function append_style(el,declaration)
  if not declaration or declaration=='' then return end
  local current=attr(el,'style') or ''
  if current~='' and current:sub(-1)~=';' then current=current..';' end
  el.attributes.style=current..declaration..';'
end

if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name='quarto-semantic-components-pipeline',
    version='0.8.0',
    stylesheets={'css/pipeline.css'}
  })
end

local function first_inline(item)
  for _,block in ipairs(item) do
    if block.t=='Plain' or block.t=='Para' then return block,block.content[1] end
  end
  return nil,nil
end

local function make_stage(item,index)
  local block,first=first_inline(item)
  local status=iattr(first,'status') or 'todo'
  local icon=iattr(first,'icon')
  local color=iattr(first,'color') or iattr(first,'colour')
  local title=iattr(first,'title')
  local classes={'pipeline-stage','pipeline-status-'..slug(status)}
  local attrs={['data-status']=status,['data-stage']=tostring(index)}
  if title and title~='' then attrs.title=title end
  if color and color~='' then attrs.style='--pipeline-stage-color:'..color..';' end

  local blocks=pandoc.List()
  for _,b in ipairs(item) do blocks:insert(b) end
  if block and icon and icon~='' then
    local enriched=pandoc.List({pandoc.Span({pandoc.Str(icon)},pandoc.Attr('',{'pipeline-icon'})),pandoc.Space()})
    for _,inline in ipairs(block.content) do enriched:insert(inline) end
    block.content=enriched
  end

  return pandoc.Div(blocks,pandoc.Attr('',classes,attrs))
end

local function transform(el,meta)
  if not has_class(el,'pipeline') then return nil end
  if not is_html() then return el end

  local direction=(attr(el,'direction') or config.default(meta,'pipeline','direction') or 'LR'):upper()
  if direction~='TB' and direction~='BT' then direction='LR' end

  local line_color=attr(el,'line-color') or config.default(meta,'pipeline','line-color')
  local line_width=attr(el,'line-width') or config.default(meta,'pipeline','line-width')
  local gap=attr(el,'gap') or config.default(meta,'pipeline','gap')

  el.classes:insert('semantic-pipeline')
  el.classes:insert('pipeline-'..direction:lower())
  el.attributes['data-direction']=direction
  if line_color then append_style(el,'--pipeline-line-color:'..line_color) end
  if line_width then append_style(el,'--pipeline-line-width:'..line_width) end
  if gap then append_style(el,'--pipeline-gap:'..gap) end

  for i,block in ipairs(el.content) do
    if block.t=='BulletList' or block.t=='OrderedList' then
      local stages=pandoc.List()
      for n,item in ipairs(block.content) do stages:insert(make_stage(item,n)) end
      el.content[i]=pandoc.Div(stages,pandoc.Attr('',{'pipeline-stages'}))
      break
    end
  end
  return el
end

function Pandoc(doc)
  return doc:walk({Div=function(el) return transform(el,doc.meta) end})
end
