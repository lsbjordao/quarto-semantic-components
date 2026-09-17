-- Git-style history tree. The graph itself is CSS, never ASCII art.
local config=require('./config')
local function has_class(el,name) for _,c in ipairs(el.classes or {}) do if c==name then return true end end return false end
local function add_class(el,name) if not has_class(el,name) then el.classes:insert(name) end end
local function attr(el,key) return el.attributes and el.attributes[key] or nil end
local function stringify(inlines) return pandoc.utils.stringify(pandoc.Plain(inlines)) end
local function append_style(el,declaration)
  if not declaration or declaration=='' then return end
  local current=attr(el,'style') or ''; if current~='' and current:sub(-1)~=';' then current=current..';' end
  el.attributes.style=current..declaration..';'
end
local function parse(inlines)
  if #inlines==0 then return {ref='commit',message=pandoc.List()} end
  local first=inlines[1]; local row={message=pandoc.List()}
  if first.t=='Code' then row.ref=first.text; for i=2,#inlines do row.message:insert(inlines[i]) end
  else
    local raw=stringify(inlines):gsub('^%s+',''):gsub('%s+$',''); row.ref,row.text=raw:match('^(%S+)%s+(.+)$'); row.ref=row.ref or 'commit'
    row.message=row.text and pandoc.List({pandoc.Str(row.text)}) or pandoc.List()
  end
  while #row.message>0 and row.message[1].t=='Space' do row.message:remove(1) end
  return row
end
local function make_row(row,branch,depth)
  local classes=pandoc.List({'git-tree-row','git-tree-depth-'..tostring(depth or 0)}); if branch then classes:insert('git-tree-branch-point') end
  local out=pandoc.List({pandoc.Span({pandoc.Code(row.ref)},pandoc.Attr('',{'git-tree-ref'}))})
  if #row.message>0 then out:insert(pandoc.Space()); out:insert(pandoc.Span(row.message,pandoc.Attr('',{'git-tree-message'}))) end
  return pandoc.Plain({pandoc.Span(out,pandoc.Attr('',classes))})
end
local function walk(list,depth)
  for _,item in ipairs(list.content) do
    local nested,row_index,row_block
    for i,block in ipairs(item) do
      if block.t=='BulletList' or block.t=='OrderedList' then nested=block
      elseif not row_block and (block.t=='Plain' or block.t=='Para') then row_index,row_block=i,block end
    end
    if row_block then item[row_index]=make_row(parse(row_block.content),nested~=nil,depth) end
    if nested then
      if nested.t=='OrderedList' then nested=pandoc.BulletList(nested.content); for i,b in ipairs(item) do if b.t=='OrderedList' then item[i]=nested break end end end
      walk(nested,depth+1)
    end
  end
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
      if block.t=='OrderedList' then block=pandoc.BulletList(block.content); el.content[i]=block end
      walk(block,0)
    end
  end
  return el
end

function Pandoc(doc)
  return doc:walk({Div=function(el) return transform(el,doc.meta) end})
end
