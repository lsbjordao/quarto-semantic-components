-- Generic hierarchical tree. Nested Markdown lists remain semantic in all
-- formats; HTML adds connectors and optional expand/collapse behavior.
local config=require('./config')

local function has_class(el,name)
  for _,c in ipairs(el.classes or {}) do if c==name then return true end end
  return false
end
local function add_class(el,name) if not has_class(el,name) then el.classes:insert(name) end end
local function attr(el,key) return el.attributes and el.attributes[key] or nil end
local function is_html() return FORMAT and FORMAT:match('html')~=nil end
local function stringify(inlines) return pandoc.utils.stringify(pandoc.Plain(inlines)) end
local function truthy(value)
  if value==nil then return nil end
  value=tostring(value):lower()
  if value=='true' or value=='1' or value=='yes' or value=='on' or value=='open' then return true end
  if value=='false' or value=='0' or value=='no' or value=='off' or value=='closed' then return false end
  return nil
end
local function esc(value)
  return tostring(value or ''):gsub('&','&amp;'):gsub('<','&lt;'):gsub('>','&gt;'):gsub('"','&quot;')
end
local function setting(el,meta,key,aliases)
  return attr(el,key) or config.default(meta,'tree',key,aliases)
end
local function append_style(el,declaration)
  if not declaration or declaration=='' then return end
  local current=attr(el,'style') or ''
  if current~='' and current:sub(-1)~=';' then current=current..';' end
  el.attributes.style=current..declaration..';'
end
local function themed(el,meta,key,aliases)
  local function suffixed(suffix)
    local aa={}
    for _,a in ipairs(aliases or {}) do aa[#aa+1]=a..suffix end
    return setting(el,meta,key..suffix,aa)
  end
  return setting(el,meta,key,aliases),suffixed('-light'),suffixed('-dark')
end

if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name='quarto-semantic-components-tree',
    version='0.1.0',
    scripts={'js/tree.js'},
    stylesheets={'css/tree.css'}
  })
end

local function row_attrs(source,row)
  if not source then return end
  row.expanded=attr(source,'expanded') or attr(source,'open') or row.expanded
  row.collapsed=attr(source,'collapsed') or row.collapsed
  row.info=attr(source,'info') or row.info
end

local function parse_row(block)
  if not block or not block.content or #block.content==0 then return nil end
  local first=block.content[1]
  local row={content=block.content}

  if first.t=='Span' then
    row.label=stringify(first.content)
    row_attrs(first,row)
  elseif first.t=='Link' then
    row.label=stringify(first.content)
    row_attrs(first,row)
  elseif first.t=='Code' then
    row.label=first.text
    row_attrs(first,row)
  else
    row.label=stringify(block.content)
  end
  return row
end

local function expanded_state(row,default_expanded)
  local explicit=truthy(row and row.expanded)
  if explicit~=nil then return explicit end
  local collapsed=truthy(row and row.collapsed)
  if collapsed~=nil then return not collapsed end
  return default_expanded
end

local function decorate_list(list,default_expanded)
  if list.t=='OrderedList' then list=pandoc.BulletList(list.content) end

  for _,item in ipairs(list.content) do
    local nested,nested_index,row_block,row_index
    for i,block in ipairs(item) do
      if block.t=='BulletList' or block.t=='OrderedList' then
        nested,nested_index=block,i
      elseif not row_block and (block.t=='Plain' or block.t=='Para') then
        row_block,row_index=block,i
      end
    end

    local row=parse_row(row_block)
    local has_children=nested~=nil

    if row_block then
      local classes={'tree-row'}
      local attrs={}
      if has_children then
        classes[#classes+1]='tree-branch'
        local expanded=expanded_state(row,default_expanded)
        attrs['data-tree-toggle']='true'
        attrs['data-tree-expanded']=expanded and 'true' or 'false'
        attrs['aria-expanded']=expanded and 'true' or 'false'
        attrs['data-tree-label']=row and row.label or 'branch'
      else
        classes[#classes+1]='tree-leaf'
      end

      local content=pandoc.List()
      if is_html() and has_children then
        local label=esc(row and row.label or 'branch')
        content:insert(pandoc.RawInline('html','<button class="tree-toggle" type="button" aria-label="'..
          (expanded_state(row,default_expanded) and 'Collapse ' or 'Expand ')..label..
          '" aria-expanded="'..(expanded_state(row,default_expanded) and 'true' or 'false')..'"></button>'))
        content:insert(pandoc.Space())
      end
      for _,inline in ipairs(row_block.content) do content:insert(inline) end
      if is_html() and row and row.info and row.info~='' then
        content:insert(pandoc.Space())
        content:insert(pandoc.Span({pandoc.Str('i')},pandoc.Attr('',{'tree-info'},{title=row.info,['aria-label']=row.info,tabindex='0'})))
      end
      item[row_index]=pandoc.Plain({pandoc.Span(content,pandoc.Attr('',classes,attrs))})
    end

    if nested then
      if nested.t=='OrderedList' then
        nested=pandoc.BulletList(nested.content)
        item[nested_index]=nested
      end
      decorate_list(nested,default_expanded)
    end
  end
  return list
end

local function transform(el,meta)
  if not has_class(el,'tree') then return nil end
  add_class(el,'semantic-tree')

  local indent=setting(el,meta,'indent',{'level-indent','indent-size','child-indent'})
  if indent and indent~='' then append_style(el,'--tree-indent:'..indent) end

  local line,line_light,line_dark=themed(el,meta,'line-color',{'connector-color'})
  if line and line~='' then append_style(el,'--tree-line-color-base:'..line) end
  if line_light and line_light~='' then append_style(el,'--tree-line-color-light:'..line_light) end
  if line_dark and line_dark~='' then append_style(el,'--tree-line-color-dark:'..line_dark) end

  local expanded_value=setting(el,meta,'expanded',{'open'})
  local collapsed_value=setting(el,meta,'collapsed')
  local default_expanded=truthy(expanded_value)
  if default_expanded==nil then
    local collapsed=truthy(collapsed_value)
    default_expanded=collapsed==nil and true or not collapsed
  end
  el.attributes['data-tree-expanded']=default_expanded and 'true' or 'false'

  for i,block in ipairs(el.content) do
    if block.t=='BulletList' or block.t=='OrderedList' then
      if block.t=='OrderedList' then block=pandoc.BulletList(block.content) end
      el.content[i]=decorate_list(block,default_expanded)
    end
  end
  return el
end

function Pandoc(doc)
  return doc:walk({Div=function(el) return transform(el,doc.meta) end})
end
