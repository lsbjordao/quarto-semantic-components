-- Sinuous roadmap component. HTML gets an SVG road and responsive geometry;
-- PDF/DOCX keep a simple ordered list so the source remains readable.
local config=require('./config')

local function has_class(el,name)
  for _,c in ipairs(el.classes or {}) do if c==name then return true end end
  return false
end
local function add_class(el,name) if not has_class(el,name) then el.classes:insert(name) end end
local function attr(el,key) return el.attributes and el.attributes[key] or nil end
local function is_html() return FORMAT and FORMAT:match('html')~=nil end
local function setting(el,meta,key,aliases)
  return attr(el,key) or config.default(meta,'roadmap',key,aliases)
end
local function append_style(el,declaration)
  if not declaration or declaration=='' then return end
  local current=attr(el,'style') or ''
  if current~='' and current:sub(-1)~=';' then current=current..';' end
  el.attributes.style=current..declaration..';'
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
local function append_theme_style(el,variable,base,light,dark)
  if base and base~='' then append_style(el,variable..'-base:'..base) end
  if light and light~='' then append_style(el,variable..'-light:'..light) end
  if dark and dark~='' then append_style(el,variable..'-dark:'..dark) end
end
local function clamp_curve(value)
  local n=tonumber(value)
  if not n then return 0.6 end
  if n<0 then n=0 elseif n>1 then n=1 end
  return n
end
local function normalize_orientation(value)
  value=tostring(value or ''):lower()
  if value=='vertical' or value=='v' or value=='column' then return 'vertical' end
  return 'horizontal'
end
local function normalize_markers(value)
  value=tostring(value or ''):lower()
  if value=='numbers' or value=='number' or value=='numeric' then return 'numbers' end
  if value=='none' or value=='off' or value=='false' then return 'none' end
  return 'dot'
end
local function normalize_status(value)
  value=tostring(value or ''):lower()
  if value=='done' or value=='complete' or value=='completed' then return 'done' end
  if value=='current' or value=='active' or value=='now' or value=='in-progress' then return 'current' end
  if value=='future' or value=='pending' or value=='planned' then return 'future' end
  if value=='milestone' or value=='major' then return 'milestone' end
  return nil
end
local function has_title_block(blocks)
  for _,block in ipairs(blocks or {}) do
    if block.t=='Header' then return true end
    if block.t=='Para' or block.t=='Plain' then
      for _,inline in ipairs(block.content or {}) do
        if inline.t=='Span' and has_class(inline,'roadmap-title') then return true end
      end
    end
  end
  return false
end
local function ensure_title(item)
  local title=attr(item,'title')
  if not title or title=='' or has_title_block(item.content) then return end
  item.content:insert(1,pandoc.Para({
    pandoc.Span({pandoc.Str(title)},pandoc.Attr('',{'roadmap-title'}))
  }))
end
local function item_theme(item)
  local function read(key,aliases)
    local value=attr(item,key)
    if value and value~='' then return value end
    for _,alias in ipairs(aliases or {}) do
      value=attr(item,alias)
      if value and value~='' then return value end
    end
    return nil
  end
  return
    read('point-color',{'marker-color'}),
    read('point-color-light',{'marker-color-light'}),
    read('point-color-dark',{'marker-color-dark'})
end

if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name='quarto-semantic-components-roadmap',
    version='0.1.0',
    scripts={'js/roadmap.js'},
    stylesheets={'css/roadmap.css'}
  })
end

local function collect_items(el)
  local items={}
  for _,block in ipairs(el.content or {}) do
    if block.t=='Div' and has_class(block,'roadmap-item') then items[#items+1]=block end
  end
  return items
end

local function static_item(item)
  ensure_title(item)
  local blocks=pandoc.List()
  local status=normalize_status(attr(item,'status'))
  if status then
    blocks:insert(pandoc.Para({pandoc.Emph({pandoc.Str('Status: '..status)})}))
  end
  for _,block in ipairs(item.content or {}) do blocks:insert(block) end
  return blocks
end

local function static_roadmap(el)
  local items=collect_items(el)
  if #items==0 then return el end
  local list=pandoc.List()
  for _,item in ipairs(items) do list:insert(static_item(item)) end
  return pandoc.OrderedList(list)
end

local function html_item(item,index,markers)
  ensure_title(item)
  add_class(item,'semantic-roadmap-item')
  item.attributes.title=nil
  item.attributes.role='listitem'

  local status=normalize_status(attr(item,'status'))
  if status then add_class(item,'roadmap-status-'..status); item.attributes['data-roadmap-status']=status end
  item.attributes['data-roadmap-index']=tostring(index)

  local point,point_light,point_dark=item_theme(item)
  append_theme_style(item,'--roadmap-item-point-color',point,point_light,point_dark)

  local original=pandoc.List()
  if status then
    original:insert(pandoc.Plain({
      pandoc.Span({pandoc.Str('Status: '..status)},pandoc.Attr('',{'roadmap-status-label'}))
    }))
  end
  for _,block in ipairs(item.content or {}) do original:insert(block) end
  local card=pandoc.Div(original,pandoc.Attr('',{'roadmap-card'}))
  local marker=pandoc.Div({},pandoc.Attr('',{'roadmap-marker'},{['aria-hidden']='true'}))
  if markers=='numbers' then
    marker.content:insert(pandoc.Plain({pandoc.Span({pandoc.Str(tostring(index))},pandoc.Attr('',{'roadmap-marker-label'}))}))
  end
  item.content=pandoc.List({marker,card})
  return item
end

local function transform(el,meta)
  if not has_class(el,'roadmap') then return nil end
  if not is_html() then return static_roadmap(el) end

  add_class(el,'semantic-roadmap')
  el.attributes.role='list'
  local orientation=normalize_orientation(setting(el,meta,'orientation',{'direction','layout'}))
  local markers=normalize_markers(setting(el,meta,'markers',{'marker','marker-style'}))
  local curve=clamp_curve(setting(el,meta,'curve',{'curvature','sinuosity'}))
  el.attributes['data-roadmap-orientation']=orientation
  el.attributes['data-roadmap-effective-orientation']=orientation
  el.attributes['data-roadmap-markers']=markers
  el.attributes['data-roadmap-curve']=string.format('%.3f',curve)

  local road,road_light,road_dark=themed_setting(el,meta,'road-color',{'line-color','path-color'})
  local point,point_light,point_dark=themed_setting(el,meta,'point-color',{'marker-color','dot-color'})
  local surface,surface_light,surface_dark=themed_setting(el,meta,'surface-color',{'card-color','card-background'})
  append_theme_style(el,'--roadmap-road-color',road,road_light,road_dark)
  append_theme_style(el,'--roadmap-point-color',point,point_light,point_dark)
  append_theme_style(el,'--roadmap-surface-color',surface,surface_light,surface_dark)

  local road_width=setting(el,meta,'road-width',{'line-width','path-width'})
  local road_background_width=setting(el,meta,'road-background-width',{'road-bed-width','path-background-width'})
  local point_size=setting(el,meta,'point-size',{'marker-size','dot-size'})
  if road_width and road_width~='' then append_style(el,'--roadmap-road-width:'..road_width) end
  if road_background_width and road_background_width~='' then append_style(el,'--roadmap-road-background-width:'..road_background_width) end
  if point_size and point_size~='' then append_style(el,'--roadmap-point-size:'..point_size) end

  local transformed=pandoc.List()
  local index=0
  for _,block in ipairs(el.content or {}) do
    if block.t=='Div' and has_class(block,'roadmap-item') then
      index=index+1
      transformed:insert(html_item(block,index,markers))
    else
      transformed:insert(block)
    end
  end
  el.content=transformed
  el.attributes['data-roadmap-count']=tostring(index)
  append_style(el,'--roadmap-count:'..math.max(index,1))
  return el
end

function Pandoc(doc)
  return doc:walk({Div=function(el) return transform(el,doc.meta) end})
end
