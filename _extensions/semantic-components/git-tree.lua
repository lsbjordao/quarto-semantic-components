-- Git commit graph. HTML renders a real node/edge DAG in SVG; non-HTML keeps
-- semantic lists. The simple nested-list syntax infers parents, while optional
-- commit ids / parent attributes allow explicit DAGs and merge commits.
local config=require('./config')

local function has_class(el,name)
  for _,c in ipairs(el.classes or {}) do if c==name then return true end end
  return false
end
local function add_class(el,name) if not has_class(el,name) then el.classes:insert(name) end end
local function attr(el,key) return el.attributes and el.attributes[key] or nil end
local function stringify(inlines) return pandoc.utils.stringify(pandoc.Plain(inlines)) end
local function is_html() return FORMAT and FORMAT:match('html') ~= nil end

local function append_style(el,declaration)
  if not declaration or declaration=='' then return end
  local current=attr(el,'style') or ''
  if current~='' and current:sub(-1)~=';' then current=current..';' end
  el.attributes.style=current..declaration..';'
end

local function inline_attr(inline,key)
  if not inline then return nil end
  if key=='id' and inline.identifier and inline.identifier~='' then return inline.identifier end
  return inline.attributes and inline.attributes[key] or nil
end

local function tail(inlines,start)
  local out=pandoc.List()
  for i=start or 2,#inlines do out:insert(inlines[i]) end
  while #out>0 and out[1].t=='Space' do out:remove(1) end
  return out
end

local function parse(inlines)
  if #inlines==0 then return {ref='commit',message=pandoc.List()} end
  local first=inlines[1]
  local row={message=pandoc.List()}

  if first.t=='Code' then
    row.ref=first.text
    row.id=inline_attr(first,'id') or inline_attr(first,'commit') or inline_attr(first,'commit-id')
    row.parents_spec=inline_attr(first,'parents') or inline_attr(first,'parent')
    row.tag=inline_attr(first,'tag') or inline_attr(first,'tags')
    row.head=inline_attr(first,'head')
    row.message=tail(inlines,2)
  elseif first.t=='Span' then
    row.ref=stringify(first.content)
    row.id=inline_attr(first,'id') or inline_attr(first,'commit') or inline_attr(first,'commit-id')
    row.parents_spec=inline_attr(first,'parents') or inline_attr(first,'parent')
    row.tag=inline_attr(first,'tag') or inline_attr(first,'tags')
    row.head=inline_attr(first,'head')
    row.message=tail(inlines,2)
  else
    local raw=stringify(inlines):gsub('^%s+',''):gsub('%s+$','')
    row.ref,row.text=raw:match('^(%S+)%s+(.+)$')
    row.ref=row.ref or 'commit'
    row.message=row.text and pandoc.List({pandoc.Str(row.text)}) or pandoc.List()
  end
  while #row.message>0 and row.message[1].t=='Space' do row.message:remove(1) end
  return row
end

local function row_parts(item)
  local nested,row_block
  for _,block in ipairs(item) do
    if block.t=='BulletList' or block.t=='OrderedList' then nested=block
    elseif not row_block and (block.t=='Plain' or block.t=='Para') then row_block=block end
  end
  return row_block,nested
end

local function collect(list,depth,rows)
  for _,item in ipairs(list.content) do
    local row_block,nested=row_parts(item)
    if row_block then
      local row=parse(row_block.content)
      row.depth=depth
      rows[#rows+1]=row
    end
    if nested then collect(nested,depth+1,rows) end
  end
end

-- Semantic fallback for PDF/DOCX and other non-HTML outputs.
local function make_semantic_row(row,depth)
  local classes=pandoc.List({'git-tree-row','git-tree-depth-'..tostring(depth or 0)})
  local out=pandoc.List({pandoc.Span({pandoc.Code(row.ref)},pandoc.Attr('',{'git-tree-ref'}))})
  if row.tag and row.tag~='' then
    out:insert(pandoc.Space())
    out:insert(pandoc.Span({pandoc.Str(row.tag)},pandoc.Attr('',{'git-tree-tag'})))
  end
  if #row.message>0 then
    out:insert(pandoc.Space())
    out:insert(pandoc.Span(row.message,pandoc.Attr('',{'git-tree-message'})))
  end
  return pandoc.Plain({pandoc.Span(out,pandoc.Attr('',classes))})
end

local function walk_semantic(list,depth)
  for _,item in ipairs(list.content) do
    local nested,row_index,row_block
    for i,block in ipairs(item) do
      if block.t=='BulletList' or block.t=='OrderedList' then nested=block
      elseif not row_block and (block.t=='Plain' or block.t=='Para') then row_index,row_block=i,block end
    end
    if row_block then item[row_index]=make_semantic_row(parse(row_block.content),depth) end
    if nested then
      if nested.t=='OrderedList' then
        nested=pandoc.BulletList(nested.content)
        for i,b in ipairs(item) do if b.t=='OrderedList' then item[i]=nested break end end
      end
      walk_semantic(nested,depth+1)
    end
  end
end

local function number_length(value,default)
  if not value or value=='' then return default end
  local number,unit=tostring(value):match('^%s*([%d%.]+)%s*([%a%%]*)%s*$')
  number=tonumber(number)
  if not number then return default end
  unit=(unit or ''):lower()
  if unit=='' or unit=='px' then return number end
  if unit=='rem' or unit=='em' then return number*16 end
  return default
end

local function fmt(n)
  if math.abs(n-math.floor(n+0.5))<0.001 then return tostring(math.floor(n+0.5)) end
  return string.format('%.2f',n):gsub('0+$',''):gsub('%.$','')
end

local function normal_direction(value)
  value=(value or 'TB'):upper():gsub('[^A-Z]','')
  if value=='BT' or value=='BOTTOMTOP' or value=='BOTTOMTOTOP' then return 'BT' end
  return 'TB'
end

local function truthy(value)
  value=value and tostring(value):lower() or ''
  return value=='true' or value=='1' or value=='yes' or value=='on' or value=='head'
end

local function append_unique(list,value)
  if value==nil then return end
  for _,item in ipairs(list) do if item==value then return end end
  list[#list+1]=value
end

local function infer_parents(rows)
  local active={}
  local id_map={}
  local max_depth=0

  for i,row in ipairs(rows) do
    row.index=i
    row.id=row.id or ('c'..tostring(i))
    id_map[row.id]=i
    if row.depth>max_depth then max_depth=row.depth end
  end

  -- First pass: infer a valid commit DAG from nested-list depth. A child branch
  -- starts at the immediately preceding commit. Returning to a shallower lane
  -- creates a merge commit whose parents are the previous tip of the target lane
  -- plus the tips of every lane being closed.
  for i,row in ipairs(rows) do
    local d=row.depth
    local parents={}
    if i>1 then
      local pd=rows[i-1].depth
      if d>pd then
        append_unique(parents,i-1)
      elseif d==pd then
        append_unique(parents,active[d] or (i-1))
      else
        append_unique(parents,active[d])
        for level=d+1,pd do append_unique(parents,active[level]) end
        if #parents==0 then append_unique(parents,i-1) end
        for level=d+1,max_depth do active[level]=nil end
      end
    end
    row.parents=parents
    active[d]=i
  end

  -- Second pass: explicit parent(s) override inference. This makes arbitrary DAGs
  -- and merge commits representable without abandoning the compact list syntax.
  for _,row in ipairs(rows) do
    if row.parents_spec and row.parents_spec~='' then
      local spec=tostring(row.parents_spec)
      if spec:lower()=='none' or spec=='-' then
        row.parents={}
      else
        local explicit={}
        for id in spec:gmatch('[^,%s]+') do append_unique(explicit,id_map[id]) end
        if #explicit>0 then row.parents=explicit end
      end
    end
  end

  return max_depth
end

local function edge_path(x1,y1,x2,y2)
  if math.abs(x1-x2)<0.001 then
    return '<line class="git-tree-edge" x1="'..fmt(x1)..'" y1="'..fmt(y1)..'" x2="'..fmt(x2)..'" y2="'..fmt(y2)..'" />'
  end
  local dy=y2-y1
  local sign=dy>=0 and 1 or -1
  local bend=math.max(10,math.abs(dy)*0.38)
  local c1y=y1+sign*bend
  local c2y=y2-sign*bend
  return '<path class="git-tree-edge" d="M '..fmt(x1)..' '..fmt(y1)..' C '..fmt(x1)..' '..fmt(c1y)..', '..fmt(x2)..' '..fmt(c2y)..', '..fmt(x2)..' '..fmt(y2)..'" />'
end

local function graph_svg(rows,max_depth,lane,node_size,row_height,direction)
  local r=node_size/2
  local pad=r+3
  local width=pad*2+max_depth*lane
  local height=math.max(row_height,#rows*row_height)
  local function x(row) return pad+row.depth*lane end
  local function y(index)
    if direction=='BT' then return (#rows-index+0.5)*row_height end
    return (index-0.5)*row_height
  end
  local parts={}

  -- Edges first, so commit nodes sit cleanly on top of all joins. Every edge is
  -- commit-to-commit: branches originate at nodes and merges terminate at nodes.
  for i,row in ipairs(rows) do
    for _,parent_index in ipairs(row.parents or {}) do
      local parent=rows[parent_index]
      if parent then parts[#parts+1]=edge_path(x(parent),y(parent_index),x(row),y(i)) end
    end
  end

  for i,row in ipairs(rows) do
    parts[#parts+1]='<circle class="git-tree-node" data-commit="'..row.id..'" cx="'..fmt(x(row))..'" cy="'..fmt(y(i))..'" r="'..fmt(r)..'" />'
  end

  return '<svg class="git-tree-graph" viewBox="0 0 '..fmt(width)..' '..fmt(height)..'" width="'..fmt(width)..'" height="'..fmt(height)..'" aria-hidden="true">'..table.concat(parts)..'</svg>',height,width
end

local function ref_span(text,class_name)
  return pandoc.Span({pandoc.Code(text)},pandoc.Attr('',{class_name}))
end

local function text_span(text,class_name)
  return pandoc.Span({pandoc.Str(text)},pandoc.Attr('',{class_name}))
end

local function row_content(row)
  local content=pandoc.List({ref_span(row.ref,'git-tree-ref')})
  if truthy(row.head) then
    content:insert(pandoc.Space())
    content:insert(text_span('HEAD','git-tree-head'))
  end
  if row.tag and row.tag~='' then
    for tag in tostring(row.tag):gmatch('[^,%s]+') do
      content:insert(pandoc.Space())
      content:insert(text_span(tag,'git-tree-tag'))
    end
  end
  if #row.message>0 then
    content:insert(pandoc.Space())
    content:insert(pandoc.Span(row.message,pandoc.Attr('',{'git-tree-message'})))
  end
  return content
end

local function render_rows(rows,el,meta,direction)
  local max_depth=infer_parents(rows)
  local lane_value=attr(el,'lane-gap') or config.default(meta,'git-tree','lane-gap')
  local node_value=attr(el,'node-size') or config.default(meta,'git-tree','node-size')
  local row_height_value=attr(el,'row-height') or config.default(meta,'git-tree','row-height')
  local lane=number_length(lane_value,13)
  local node_size=number_length(node_value,11)
  local row_height=number_length(row_height_value,36)
  local svg,height=graph_svg(rows,max_depth,lane,node_size,row_height,direction)

  local contents=pandoc.List()
  if direction=='BT' then
    for i=#rows,1,-1 do
      contents:insert(pandoc.Div({pandoc.Plain({pandoc.Span(row_content(rows[i]),pandoc.Attr('',{'git-tree-content'}))})},pandoc.Attr('',{'git-tree-entry'},{style='--git-row-height:'..fmt(row_height)..'px;','data-commit'=rows[i].id})))
    end
  else
    for _,row in ipairs(rows) do
      contents:insert(pandoc.Div({pandoc.Plain({pandoc.Span(row_content(row),pandoc.Attr('',{'git-tree-content'}))})},pandoc.Attr('',{'git-tree-entry'},{style='--git-row-height:'..fmt(row_height)..'px;','data-commit'=row.id})))
    end
  end

  local layout=pandoc.Div({
    pandoc.RawBlock('html',svg),
    pandoc.Div(contents,pandoc.Attr('',{'git-tree-content-rows'}))
  },pandoc.Attr('',{'git-tree-layout'},{style='--git-graph-height:'..fmt(height)..'px;'}))
  return pandoc.List({layout})
end

local function setting(el,meta,key,aliases)
  return attr(el,key) or config.default(meta,'git-tree',key,aliases)
end

local function transform(el,meta)
  if not has_class(el,'git-tree') then return nil end
  add_class(el,'semantic-git-tree')

  local direction=normal_direction(setting(el,meta,'direction',{'orientation'}))
  el.attributes['data-git-direction']=direction
  local styles={
    {'--semantic-git-line',setting(el,meta,'line-color',{'edge-color'})},
    {'--git-line-width',setting(el,meta,'line-width',{'edge-width'})},
    {'--git-node-size',setting(el,meta,'node-size')},
    {'--git-lane-gap',setting(el,meta,'lane-gap')},
    {'--git-row-indent',setting(el,meta,'row-indent')},
    {'--semantic-git-node-bg',setting(el,meta,'node-bg',{'node-background'})}
  }
  for _,pair in ipairs(styles) do if pair[2] and pair[2]~='' then append_style(el,pair[1]..':'..pair[2]) end end

  for i,block in ipairs(el.content) do
    if block.t=='BulletList' or block.t=='OrderedList' then
      if is_html() then
        local rows={}
        collect(block,0,rows)
        el.content[i]=pandoc.Div(render_rows(rows,el,meta,direction),pandoc.Attr('',{'git-tree-rows'}))
      else
        if block.t=='OrderedList' then block=pandoc.BulletList(block.content); el.content[i]=block end
        walk_semantic(block,0)
      end
    end
  end
  return el
end

function Pandoc(doc)
  return doc:walk({Div=function(el) return transform(el,doc.meta) end})
end
