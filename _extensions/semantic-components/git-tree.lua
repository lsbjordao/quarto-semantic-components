-- Git-style history tree. HTML uses an SVG lane graph; non-HTML keeps semantic lists.
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

local function parse(inlines)
  if #inlines==0 then return {ref='commit',message=pandoc.List()} end
  local first=inlines[1]
  local row={message=pandoc.List()}
  if first.t=='Code' then
    row.ref=first.text
    for i=2,#inlines do row.message:insert(inlines[i]) end
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

local function line(x1,y1,x2,y2)
  return '<line class="git-tree-edge" x1="'..fmt(x1)..'" y1="'..fmt(y1)..'" x2="'..fmt(x2)..'" y2="'..fmt(y2)..'" />'
end

local function curve(x1,y1,x2,y2)
  local dy=math.max(5,(y2-y1)*0.55)
  return '<path class="git-tree-edge" d="M '..fmt(x1)..' '..fmt(y1)..' C '..fmt(x1)..' '..fmt(y1+dy)..', '..fmt(x2)..' '..fmt(y2-dy)..', '..fmt(x2)..' '..fmt(y2)..'" />'
end

local function graph_svg(depth,prev_depth,next_depth,max_depth,lane,node_size)
  local r=node_size/2
  local pad=r+2
  local node_y=math.max(10,r+4)
  local merge_step=math.max(7,r+3)
  local height=30
  if next_depth and next_depth<depth then
    height=math.max(height,node_y+(depth-next_depth)*merge_step+8)
  end
  local width=pad*2+max_depth*lane
  local function x(d) return pad+d*lane end
  local parts={}

  -- Persistent ancestor lanes above the current commit.
  for level=0,depth-1 do parts[#parts+1]=line(x(level),0,x(level),node_y) end
  if prev_depth~=nil then parts[#parts+1]=line(x(depth),0,x(depth),node_y) end

  if next_depth==nil then
    -- No outgoing edge from the final visible commit.
  elseif next_depth==depth then
    for level=0,depth do parts[#parts+1]=line(x(level),node_y,x(level),height) end
  elseif next_depth>depth then
    -- Parent lanes continue while a child branch peels off to the right.
    for level=0,depth do parts[#parts+1]=line(x(level),node_y,x(level),height) end
    local cx,cy=x(depth),node_y
    for level=depth+1,next_depth do
      local ny=height-(next_depth-level)*merge_step
      parts[#parts+1]=curve(cx,cy,x(level),ny)
      cx,cy=x(level),ny
    end
  else
    -- Nested branches merge one lane at a time. This avoids detached hooks
    -- when several nested levels finish before the same parent commit.
    for level=0,next_depth do parts[#parts+1]=line(x(level),node_y,x(level),height) end
    local cx,cy=x(depth),node_y
    for level=depth,next_depth+1,-1 do
      local nx=x(level-1)
      local ny=node_y+(depth-level+1)*merge_step
      if level-1>next_depth then parts[#parts+1]=line(nx,0,nx,ny) end
      parts[#parts+1]=curve(cx,cy,nx,ny)
      cx,cy=nx,ny
    end
  end

  parts[#parts+1]='<circle class="git-tree-node" cx="'..fmt(x(depth))..'" cy="'..fmt(node_y)..'" r="'..fmt(r)..'" />'
  return '<svg class="git-tree-graph" viewBox="0 0 '..fmt(width)..' '..fmt(height)..'" width="'..fmt(width)..'" height="'..fmt(height)..'" aria-hidden="true">'..table.concat(parts)..'</svg>',height
end

local function render_rows(rows,el,meta)
  local max_depth=0
  for _,row in ipairs(rows) do if row.depth>max_depth then max_depth=row.depth end end

  local lane_value=attr(el,'lane-gap') or config.default(meta,'git-tree','lane-gap')
  local node_value=attr(el,'node-size') or config.default(meta,'git-tree','node-size')
  local lane=number_length(lane_value,13)
  local node_size=number_length(node_value,11)
  local out=pandoc.List()

  for i,row in ipairs(rows) do
    local prev_depth=i>1 and rows[i-1].depth or nil
    local next_depth=i<#rows and rows[i+1].depth or nil
    local svg,height=graph_svg(row.depth,prev_depth,next_depth,max_depth,lane,node_size)
    local content=pandoc.List({pandoc.Span({pandoc.Code(row.ref)},pandoc.Attr('',{'git-tree-ref'}))})
    if #row.message>0 then
      content:insert(pandoc.Space())
      content:insert(pandoc.Span(row.message,pandoc.Attr('',{'git-tree-message'})))
    end
    local row_content=pandoc.List({
      pandoc.RawInline('html',svg),
      pandoc.Span(content,pandoc.Attr('',{'git-tree-content'}))
    })
    out:insert(pandoc.Div({pandoc.Plain(row_content)},pandoc.Attr('',{'git-tree-entry','git-tree-depth-'..tostring(row.depth)},{style='--git-row-height:'..fmt(height)..'px;'})))
  end
  return out
end

local function setting(el,meta,key,aliases)
  return attr(el,key) or config.default(meta,'git-tree',key,aliases)
end

local function transform(el,meta)
  if not has_class(el,'git-tree') then return nil end
  add_class(el,'semantic-git-tree')

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
        el.content[i]=pandoc.Div(render_rows(rows,el,meta),pandoc.Attr('',{'git-tree-rows'}))
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
