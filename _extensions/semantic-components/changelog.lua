-- Changelog component with release and change-group semantics.
local config=require('./config')

local function has_class(el,name)
  for _,c in ipairs(el.classes or {}) do if c==name then return true end end
  return false
end
local function attr(el,key) return el.attributes and el.attributes[key] or nil end
local function is_html() return FORMAT and FORMAT:match('html') ~= nil end
local function stringify(inlines) return pandoc.utils.stringify(pandoc.Plain(inlines)) end
local function slug(value)
  value=(value or 'changes'):lower():gsub('[^%w]+','-'):gsub('^-+',''):gsub('-+$','')
  return value~='' and value or 'changes'
end

if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name='quarto-semantic-components-changelog',
    version='0.8.0',
    stylesheets={'css/changelog.css'}
  })
end

local function release_header(header)
  local date=header.attributes and (header.attributes.date or header.attributes.released) or nil
  local status=header.attributes and header.attributes.status or nil
  local content=pandoc.List({pandoc.Span(header.content,pandoc.Attr('',{'changelog-version'}))})
  if date and date~='' then
    content:insert(pandoc.Space())
    content:insert(pandoc.Span({pandoc.Str(date)},pandoc.Attr('',{'changelog-date'})))
  end
  if status and status~='' then
    content:insert(pandoc.Space())
    content:insert(pandoc.Span({pandoc.Str(status)},pandoc.Attr('',{'changelog-release-status','changelog-release-status-'..slug(status)})))
  end
  return pandoc.Plain(content)
end

local function group_block(header,body)
  local name=stringify(header.content)
  local blocks=pandoc.List({pandoc.Plain({pandoc.Span(header.content,pandoc.Attr('',{'changelog-group-title'}))})})
  for _,b in ipairs(body) do blocks:insert(b) end
  return pandoc.Div(blocks,pandoc.Attr('',{'changelog-group','changelog-group-'..slug(name)},{['data-group']=name}))
end

local function transform(el,meta)
  if not has_class(el,'changelog') then return nil end
  if not is_html() then return el end

  local release_level
  for _,b in ipairs(el.content) do if b.t=='Header' then release_level=b.level break end end
  if not release_level then return el end

  local before=pandoc.List()
  local releases=pandoc.List()
  local release=nil
  local release_blocks=pandoc.List()
  local group_header=nil
  local group_body=pandoc.List()

  local function flush_group()
    if group_header then
      release_blocks:insert(group_block(group_header,group_body))
      group_header=nil
      group_body=pandoc.List()
    end
  end

  local function flush_release()
    if release then
      flush_group()
      local blocks=pandoc.List({release_header(release)})
      for _,b in ipairs(release_blocks) do blocks:insert(b) end
      releases:insert(pandoc.Div(blocks,pandoc.Attr('',{'changelog-release'})))
      release=nil
      release_blocks=pandoc.List()
    end
  end

  for _,b in ipairs(el.content) do
    if b.t=='Header' and b.level==release_level then
      flush_release(); release=b
    elseif release and b.t=='Header' and b.level>release_level then
      flush_group(); group_header=b
    elseif group_header then
      group_body:insert(b)
    elseif release then
      release_blocks:insert(b)
    else
      before:insert(b)
    end
  end
  flush_release()

  el.classes:insert('semantic-changelog')
  local compact=attr(el,'compact') or config.default(meta,'changelog','compact')
  if compact and tostring(compact):lower()=='true' then el.classes:insert('changelog-compact') end
  local out=pandoc.List()
  for _,b in ipairs(before) do out:insert(b) end
  out:insert(pandoc.Div(releases,pandoc.Attr('',{'changelog-releases'})))
  el.content=out
  return el
end

function Pandoc(doc)
  return doc:walk({Div=function(el) return transform(el,doc.meta) end})
end
