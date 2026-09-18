-- File tree with links, selectable icon providers, optional inline-code labels,
-- tooltips, and collapsible folders in HTML.
local config=require('./config')
local function has_class(el, name)
  for _, class in ipairs(el.classes or {}) do if class == name then return true end end
  return false
end
local function add_class(el, name) if not has_class(el, name) then el.classes:insert(name) end end
local function attr(el, key) return el.attributes and el.attributes[key] or nil end
local function is_html() return FORMAT and FORMAT:match('html') ~= nil end
local function stringify(inlines) return pandoc.utils.stringify(pandoc.Plain(inlines)) end
local function tail(inlines)
  local out = pandoc.List(); for i = 2, #inlines do out:insert(inlines[i]) end
  while #out > 0 and out[1].t == 'Space' do out:remove(1) end
  return out
end
local function truthy(value)
  if value == nil then return nil end
  value=tostring(value):lower()
  if value=='true' or value=='1' or value=='yes' or value=='on' or value=='open' then return true end
  if value=='false' or value=='0' or value=='no' or value=='off' or value=='closed' then return false end
  return nil
end

if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name='quarto-semantic-components-file-tree',
    version='0.10.4',
    scripts={'js/file-tree.js'}
  })
end

local QUARTO_ICON = 'https://quarto.org/favicon.png'

local exact = {
  ['dockerfile']='docker', ['package.json']='nodejs', ['package-lock.json']='lock',
  ['cargo.toml']='rust', ['go.mod']='go', ['requirements.txt']='python',
  ['pyproject.toml']='python', ['renv.lock']='r', ['.gitignore']='git',
  ['_quarto.yml']='quarto', ['quarto.yml']='quarto', ['readme.md']='markdown',
  ['schema.sql']='database'
}
local ext = {
  r='r', rmd='r', py='python', js='javascript', jsx='javascript', ts='typescript', tsx='typescript',
  html='html5', css='css3', scss='sass', sass='sass', json='json', yml='yaml', yaml='yaml',
  qmd='quarto', md='markdown', lua='lua', rs='rust', go='go', java='java', c='c',
  cpp='cplusplus', cc='cplusplus', cxx='cplusplus', sql='sql', sh='bash', bash='bash',
  zsh='bash', ipynb='jupyter', db='sqlite', sqlite='sqlite', sqlite3='sqlite',
  csv='data', tsv='data', parquet='data', arrow='data', feather='data',
  png='image', jpg='image', jpeg='image', gif='image', webp='image', svg='image',
  toml='config', ini='config', env='config', conf='config', cfg='config', lock='lock'
}
local devicon = {
  r='devicon-r-plain colored', python='devicon-python-plain colored',
  javascript='devicon-javascript-plain colored', typescript='devicon-typescript-plain colored',
  html5='devicon-html5-plain colored', css3='devicon-css3-plain colored',
  sass='devicon-sass-original colored', json='devicon-json-plain colored', yaml='devicon-yaml-plain colored',
  markdown='devicon-markdown-original colored', lua='devicon-lua-plain colored',
  rust='devicon-rust-original colored', go='devicon-go-original-wordmark colored',
  java='devicon-java-plain colored', c='devicon-c-plain colored', cplusplus='devicon-cplusplus-plain colored',
  bash='devicon-bash-plain colored', jupyter='devicon-jupyter-plain colored',
  sqlite='devicon-sqlite-plain colored', docker='devicon-docker-plain colored',
  git='devicon-git-plain colored', nodejs='devicon-nodejs-plain colored'
}
local simple = {
  r='r', python='python', javascript='javascript', typescript='typescript', html5='html5', css3='css',
  sass='sass', json='json', yaml='yaml', quarto='quarto', markdown='markdown', lua='lua', rust='rust',
  go='go', java='openjdk', c='c', cplusplus='cplusplus', bash='gnubash', jupyter='jupyter',
  sqlite='sqlite', docker='docker', git='git', nodejs='nodedotjs'
}
local builtin = {file=true,folder=true,data=true,image=true,config=true,docs=true,package=true,test=true,
  lock=true,git=true,notebook=true,leaf=true,star=true,rocket=true,quarto=true,terminal=true,database=true,code=true}

local function library(value)
  value = (value or 'devicon'):lower()
  if value == 'simple' or value == 'simpleicons' then value = 'simple-icons' end
  if value == 'off' then value = 'none' end
  if value ~= 'devicon' and value ~= 'simple-icons' and value ~= 'builtin' and value ~= 'none' then value = 'devicon' end
  return value
end
local function automatic(name, folder)
  if folder then return 'folder' end
  local lower = (name or ''):lower(); if exact[lower] then return exact[lower] end
  local suffix = lower:match('%.([%w]+)$'); return (suffix and ext[suffix]) or 'file'
end
local function provider_icon(value, fallback)
  if not value then return nil, fallback end
  local provider, icon = value:match('^([%w%-]+):(.+)$')
  if provider and icon then return icon, library(provider) end
  return value, fallback
end
local function esc(value) return tostring(value):gsub('&','&amp;'):gsub('<','&lt;'):gsub('>','&gt;'):gsub('"','&quot;') end
local function image_icon(value)
  local lower = value and value:lower() or ''
  return lower:match('%.svg$') or lower:match('%.png$') or lower:match('%.jpe?g$') or lower:match('%.webp$') or lower:match('%.gif$')
end

local function apply_attrs(source, row)
  row.icon = attr(source,'icon') or row.icon
  row.icon_library = attr(source,'icon-library') or attr(source,'icons') or row.icon_library
  row.tooltip = attr(source,'tooltip') or attr(source,'info') or row.tooltip
  row.expanded = attr(source,'expanded') or attr(source,'open') or row.expanded
  row.collapsed = attr(source,'collapsed') or row.collapsed
end

local function parse_label(content, row)
  row.name = stringify(content)
  if #content == 1 and content[1].t == 'Code' then
    row.code = true
    row.name = content[1].text
  elseif #content == 1 and content[1].t == 'Strong' then
    row.highlight = true
    row.name = stringify(content[1].content)
  end
end

local function parse(inlines)
  if #inlines == 0 then return nil end
  local first, row = inlines[1], {comment=tail(inlines), code=false}

  if first.t == 'Link' then
    parse_label(first.content, row)
    row.href = first.target
    row.title = first.title
    apply_attrs(first, row)
  elseif first.t == 'Code' then
    row.name = first.text
    row.code = true
    row.href = attr(first,'href') or attr(first,'link')
    row.title = attr(first,'title')
    apply_attrs(first, row)
  elseif first.t == 'Span' then
    parse_label(first.content, row)
    row.href = attr(first,'href') or attr(first,'link')
    row.title = attr(first,'title')
    apply_attrs(first, row)
  elseif first.t == 'Strong' then
    row.name = stringify(first.content)
    row.highlight = true
  else
    local raw = stringify(inlines):gsub('^%s+',''):gsub('%s+$','')
    row.name, row.comment_text = raw:match('^(%S+)%s+(.+)$')
    row.name = row.name or raw
    row.comment = row.comment_text and pandoc.List({pandoc.Str(row.comment_text)}) or pandoc.List()
  end

  if row.name and row.name:sub(1,1) == '+' then row.folder = true; row.name = row.name:sub(2) end
  return row
end

local function library_icon(name, lib)
  if not is_html() or lib == 'none' then return nil end
  if lib == 'devicon' and name == 'quarto' then
    return pandoc.RawInline('html','<img class="file-tree-library-icon file-tree-quarto-icon" src="'..QUARTO_ICON..'" alt="" aria-hidden="true" />')
  end
  if lib == 'devicon' and devicon[name] then
    return pandoc.RawInline('html','<i class="file-tree-library-icon '..devicon[name]..'" aria-hidden="true"></i>')
  end
  if lib == 'simple-icons' and simple[name] then
    return pandoc.RawInline('html','<img class="file-tree-library-icon file-tree-simple-icon" src="https://cdn.simpleicons.org/'..esc(simple[name])..'" alt="" aria-hidden="true" />')
  end
end
local function custom_icon(value)
  if not is_html() or not value or value == '' then return nil end
  if image_icon(value) then return pandoc.Span({pandoc.Image({},value,'')},pandoc.Attr('',{'file-tree-custom-icon','file-tree-custom-icon-image'})) end
  return pandoc.Span({pandoc.Str(value)},pandoc.Attr('',{'file-tree-custom-icon'}))
end

local function tooltip_icon(text)
  if not is_html() or not text or text == '' then return nil end
  return pandoc.Span(
    {pandoc.Str('i')},
    pandoc.Attr('', {'file-tree-info'}, {title=text, ['aria-label']=text, tabindex='0'})
  )
end

local function make_label(row, folder)
  if row.code then return pandoc.Code(row.name) end
  if folder or row.highlight then return pandoc.Strong({pandoc.Str(row.name)}) end
  return pandoc.Str(row.name)
end

local function folder_expanded(row, default_expanded)
  local explicit=truthy(row.expanded)
  if explicit~=nil then return explicit end
  local collapsed=truthy(row.collapsed)
  if collapsed~=nil then return not collapsed end
  return default_expanded
end

local function make_row(row, folder, default_lib, default_expanded, has_children)
  local lib = library(row.icon_library or default_lib); local requested
  requested, lib = provider_icon(row.icon, lib)
  local icon_name = requested or automatic(row.name, folder)
  local icon = library_icon(icon_name, lib); local builtin_name
  if lib ~= 'none' and not icon then
    if builtin[icon_name] then builtin_name = icon_name
    elseif row.icon and row.icon ~= 'auto' then icon = custom_icon(row.icon)
    else builtin_name = folder and 'folder' or 'file' end
  end
  local classes = pandoc.List({'file-tree-row', folder and 'file-tree-folder' or 'file-tree-file'})
  if row.highlight then classes:insert('file-tree-highlighted') end
  if row.code then classes:insert('file-tree-code-label') end
  if icon then classes:insert('file-tree-has-inline-icon') end
  if builtin_name then classes:insert('file-icon-'..builtin_name) end
  if row.href then classes:insert('file-tree-linked') end
  if row.tooltip then classes:insert('file-tree-has-tooltip') end

  local attrs={}
  if is_html() and folder and has_children then
    classes:insert('file-tree-collapsible')
    local expanded=folder_expanded(row,default_expanded)
    attrs['data-file-tree-toggle']='true'
    attrs['data-file-tree-expanded']=expanded and 'true' or 'false'
    attrs['data-file-tree-name']=row.name or 'folder'
    attrs['aria-expanded']=expanded and 'true' or 'false'
  end

  local out = pandoc.List()
  if icon then out:insert(icon); out:insert(pandoc.Space()) end

  local label = make_label(row, folder)
  out:insert(row.href and pandoc.Link({label},row.href,row.title or '') or label)

  local info = tooltip_icon(row.tooltip)
  if info then out:insert(pandoc.Space()); out:insert(info) end

  if row.comment and #row.comment > 0 then
    out:insert(pandoc.Space())
    out:insert(pandoc.Span(row.comment,pandoc.Attr('',{'file-tree-comment'})))
  end
  return pandoc.Plain({pandoc.Span(out,pandoc.Attr('',classes,attrs))})
end

local function walk(list, default_lib, default_expanded)
  for _, item in ipairs(list.content) do
    local nested, row_index, row_block
    for i, block in ipairs(item) do
      if block.t == 'BulletList' or block.t == 'OrderedList' then nested = block
      elseif not row_block and (block.t == 'Plain' or block.t == 'Para') then row_index,row_block=i,block end
    end
    if nested and nested.t == 'OrderedList' then
      nested=pandoc.BulletList(nested.content)
      for i,b in ipairs(item) do if b.t=='OrderedList' then item[i]=nested break end end
    end
    if row_block then
      local row=parse(row_block.content)
      if row and row.name~='' then
        item[row_index]=make_row(row,row.folder or nested~=nil,default_lib,default_expanded,nested~=nil)
      end
    end
    if nested then walk(nested,default_lib,default_expanded) end
  end
end

local function transform(el,meta)
  if not has_class(el,'file-tree') then return nil end
  add_class(el,'semantic-file-tree')
  local configured=config.default(meta,'file-tree','icons',{'icon-library'})
  local default_lib=library(attr(el,'icons') or attr(el,'icon-library') or configured)
  local indent=attr(el,'indent') or attr(el,'level-indent') or attr(el,'indent-size')
    or config.default(meta,'file-tree','indent',{'level-indent','indent-size','child-indent'})
  if indent and indent~='' then
    local style=attr(el,'style') or ''
    if style~='' and style:sub(-1)~=';' then style=style..';' end
    el.attributes.style=style..'--file-tree-indent:'..indent..';'
  end
  local expanded_value=attr(el,'expanded') or attr(el,'open') or config.default(meta,'file-tree','expanded',{'open','folders-open'})
  local collapsed_value=attr(el,'collapsed') or config.default(meta,'file-tree','collapsed',{'folders-collapsed'})
  local default_expanded=truthy(expanded_value)
  if default_expanded==nil then
    local collapsed=truthy(collapsed_value)
    default_expanded=collapsed==nil and true or not collapsed
  end
  el.attributes['data-icon-library']=default_lib
  el.attributes['data-folders-expanded']=default_expanded and 'true' or 'false'
  for i,block in ipairs(el.content) do
    if block.t=='BulletList' or block.t=='OrderedList' then
      if block.t=='OrderedList' then block=pandoc.BulletList(block.content); el.content[i]=block end
      walk(block,default_lib,default_expanded)
    end
  end
  return el
end

function Pandoc(doc)
  return doc:walk({Div=function(el) return transform(el,doc.meta) end})
end
