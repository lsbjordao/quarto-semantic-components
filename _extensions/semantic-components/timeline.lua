-- Timeline component. HTML gets a rich vertical timeline; non-HTML keeps the
-- original semantic headings and content.
local config=require('./config')

local function has_class(el,name)
  for _,c in ipairs(el.classes or {}) do if c==name then return true end end
  return false
end
local function attr(el,key) return el.attributes and el.attributes[key] or nil end
local function is_html() return FORMAT and FORMAT:match('html') ~= nil end
local function append_style(el,declaration)
  if not declaration or declaration=='' then return end
  local current=attr(el,'style') or ''
  if current~='' and current:sub(-1)~=';' then current=current..';' end
  el.attributes.style=current..declaration..';'
end
local function h_attr(header,key,alias)
  if not header.attributes then return nil end
  return header.attributes[key] or (alias and header.attributes[alias]) or nil
end

if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name='quarto-semantic-components-timeline',
    version='0.8.0',
    stylesheets={'css/timeline.css'}
  })
end

local function item_from(header,body)
  local attrs={}
  local status=h_attr(header,'status')
  local date=h_attr(header,'date') or h_attr(header,'time')
  local color=h_attr(header,'color') or h_attr(header,'colour')
  local marker_fill=h_attr(header,'marker-fill') or h_attr(header,'dot-fill')
  local marker_size=h_attr(header,'marker-size') or h_attr(header,'dot-size')
  if color and color~='' then attrs.style='--timeline-item-color:'..color..';' end
  if marker_fill and marker_fill~='' then
    attrs.style=(attrs.style or '')..'--timeline-item-fill:'..marker_fill..';'
  end
  if marker_size and marker_size~='' then
    attrs.style=(attrs.style or '')..'--timeline-item-marker-size:'..marker_size..';'
  end
  if status and status~='' then attrs['data-status']=status end

  local head=pandoc.List()
  if date and date~='' then
    head:insert(pandoc.Span({pandoc.Str(date)},pandoc.Attr('',{'timeline-date'})))
    head:insert(pandoc.Space())
  end
  head:insert(pandoc.Span(header.content,pandoc.Attr('',{'timeline-title'})))
  if status and status~='' then
    head:insert(pandoc.Space())
    head:insert(pandoc.Span({pandoc.Str(status)},pandoc.Attr('',{'timeline-status','timeline-status-'..status:gsub('[^%w_-]','-')})))
  end

  local blocks=pandoc.List({pandoc.Plain(head)})
  for _,b in ipairs(body) do blocks:insert(b) end
  return pandoc.Div(blocks,pandoc.Attr('',{'timeline-item'},attrs))
end

local function transform(el,meta)
  if not has_class(el,'timeline') then return nil end
  if not is_html() then return el end

  local first_level
  for _,b in ipairs(el.content) do if b.t=='Header' then first_level=b.level break end end
  if not first_level then return el end

  local before=pandoc.List()
  local items=pandoc.List()
  local current_header=nil
  local current_body=pandoc.List()

  local function flush()
    if current_header then
      items:insert(item_from(current_header,current_body))
      current_header=nil
      current_body=pandoc.List()
    end
  end

  for _,b in ipairs(el.content) do
    if b.t=='Header' and b.level==first_level then
      flush(); current_header=b
    elseif current_header then
      current_body:insert(b)
    else
      before:insert(b)
    end
  end
  flush()

  local line_color=attr(el,'line-color') or config.default(meta,'timeline','line-color')
  local line_width=attr(el,'line-width') or config.default(meta,'timeline','line-width')
  local marker_size=attr(el,'marker-size') or attr(el,'dot-size') or config.default(meta,'timeline','marker-size',{'dot-size'})
  local marker_color=attr(el,'marker-color') or attr(el,'dot-color') or config.default(meta,'timeline','marker-color',{'dot-color'})
  local marker_fill=attr(el,'marker-fill') or attr(el,'dot-fill') or config.default(meta,'timeline','marker-fill',{'dot-fill'})

  el.classes:insert('semantic-timeline')
  if line_color then append_style(el,'--timeline-line-color:'..line_color) end
  if line_width then append_style(el,'--timeline-line-width:'..line_width) end
  if marker_size then append_style(el,'--timeline-marker-size:'..marker_size) end
  if marker_color then append_style(el,'--timeline-marker-color:'..marker_color) end
  if marker_fill then append_style(el,'--timeline-marker-fill:'..marker_fill) end

  local out=pandoc.List()
  for _,b in ipairs(before) do out:insert(b) end
  out:insert(pandoc.Div(items,pandoc.Attr('',{'timeline-items'})))
  el.content=out
  return el
end

function Pandoc(doc)
  return doc:walk({Div=function(el) return transform(el,doc.meta) end})
end
