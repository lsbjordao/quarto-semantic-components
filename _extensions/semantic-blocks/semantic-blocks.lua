-- semantic-blocks.lua
-- Quarto/Pandoc filter for Vocs-inspired steps, circled lists and file trees.

local function has_class(el, class_name)
  for _, class in ipairs(el.classes or {}) do
    if class == class_name then
      return true
    end
  end
  return false
end

local function add_class(el, class_name)
  if not has_class(el, class_name) then
    el.classes:insert(class_name)
  end
end

local function attr_value(el, key)
  if el.attributes then
    return el.attributes[key]
  end
  return nil
end

local function is_html()
  return FORMAT and FORMAT:match('html') ~= nil
end

-- Add the stylesheet only to HTML-family outputs. Non-HTML formats retain
-- the semantic AST and therefore degrade to native lists/blocks.
if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name = 'semantic-blocks',
    version = '0.1.0',
    stylesheets = { 'semantic-blocks.css' }
  })
end

local function step_mode(el)
  local mode = attr_value(el, 'type') or attr_value(el, 'style') or attr_value(el, 'mode')
  if mode == 'dots' or mode == 'dot' or mode == 'bullets' or mode == 'bullet' then
    return 'dots'
  elseif mode == 'git' or mode == 'history' or mode == 'timeline' then
    return 'git'
  elseif mode == 'numbered' or mode == 'numbers' or mode == 'number' then
    return 'numbered'
  end

  if has_class(el, 'steps-dots') or has_class(el, 'dots') then
    return 'dots'
  elseif has_class(el, 'steps-git') or has_class(el, 'git') then
    return 'git'
  end
  return 'numbered'
end

local function make_step_title(header)
  local title = pandoc.Span(header.content, pandoc.Attr('', { 'semantic-step-title' }))
  return pandoc.Plain({ title })
end

local function group_heading_steps(blocks, mode)
  local heading_level = nil
  for _, block in ipairs(blocks) do
    if block.t == 'Header' then
      heading_level = block.level
      break
    end
  end
  if not heading_level then
    return nil
  end

  local preamble = pandoc.List()
  local items = pandoc.List()
  local current = nil

  for _, block in ipairs(blocks) do
    if block.t == 'Header' and block.level == heading_level then
      current = pandoc.List({ make_step_title(block) })
      items:insert(current)
    elseif current then
      current:insert(block)
    else
      preamble:insert(block)
    end
  end

  if #items == 0 then
    return nil
  end

  local list
  if mode == 'numbered' then
    list = pandoc.OrderedList(items)
  else
    list = pandoc.BulletList(items)
  end

  local result = pandoc.List()
  for _, block in ipairs(preamble) do
    result:insert(block)
  end
  result:insert(list)
  return result
end

local function normalize_existing_steps(blocks, mode)
  local changed = false
  local result = pandoc.List()

  for _, block in ipairs(blocks) do
    if not changed and (block.t == 'OrderedList' or block.t == 'BulletList') then
      if mode == 'numbered' then
        result:insert(pandoc.OrderedList(block.content))
      else
        result:insert(pandoc.BulletList(block.content))
      end
      changed = true
    else
      result:insert(block)
    end
  end

  if changed then
    return result
  end
  return blocks
end

local function transform_steps(el)
  local mode = step_mode(el)
  add_class(el, 'semantic-steps')
  add_class(el, 'semantic-steps-' .. mode)

  local grouped = group_heading_steps(el.content, mode)
  if grouped then
    el.content = grouped
  else
    el.content = normalize_existing_steps(el.content, mode)
  end

  -- Avoid carrying presentation-only selector aliases into non-HTML writers.
  if not is_html() then
    el.attributes['data-semantic-steps'] = mode
  end

  return el
end

local function first_text_inline(inlines)
  for index, inline in ipairs(inlines) do
    if inline.t == 'Str' or inline.t == 'Code' then
      return index, inline
    elseif inline.t == 'Strong' or inline.t == 'Emph' or inline.t == 'Span' then
      local inner_index, inner = first_text_inline(inline.content)
      if inner then
        return index, inline, inner_index, inner
      end
    end
  end
  return nil
end

local function strip_leading_plus(inline)
  if inline.t == 'Str' or inline.t == 'Code' then
    local text = inline.text or ''
    if text:sub(1, 1) == '+' then
      inline.text = text:sub(2)
      return true
    end
  elseif inline.content then
    for _, child in ipairs(inline.content) do
      if strip_leading_plus(child) then
        return true
      end
    end
  end
  return false
end

local function stringify_inlines(inlines)
  return pandoc.utils.stringify(pandoc.Plain(inlines))
end

local function split_file_row(inlines)
  local raw = stringify_inlines(inlines)
  raw = raw:gsub('^%s+', ''):gsub('%s+$', '')
  local folder = raw:sub(1, 1) == '+'
  local cleaned = raw
  if folder then
    cleaned = cleaned:sub(2)
  end

  local name, comment = cleaned:match('^(%S+)%s+(.+)$')
  if not name then
    name = cleaned
    comment = nil
  end

  local highlighted = false
  if inlines[1] and inlines[1].t == 'Strong' then
    highlighted = true
  end

  return name, comment, folder, highlighted
end

local function make_file_row(name, comment, folder, highlighted)
  local classes = pandoc.List({ 'file-tree-row', folder and 'file-tree-folder' or 'file-tree-file' })
  if highlighted then
    classes:insert('file-tree-highlighted')
  end

  local name_inline
  if folder then
    name_inline = pandoc.Strong({ pandoc.Str(name) })
  else
    name_inline = pandoc.Code(name)
  end

  local row = pandoc.List({ name_inline })
  if comment and comment ~= '' then
    row:insert(pandoc.Space())
    row:insert(pandoc.Span({ pandoc.Str(comment) }, pandoc.Attr('', { 'file-tree-comment' })))
  end

  return pandoc.Plain({ pandoc.Span(row, pandoc.Attr('', classes)) })
end

local function transform_file_list(list)
  for _, item in ipairs(list.content) do
    local nested = nil
    for _, block in ipairs(item) do
      if block.t == 'BulletList' or block.t == 'OrderedList' then
        nested = block
        break
      end
    end

    local row_index = nil
    local row_block = nil
    for index, block in ipairs(item) do
      if block.t == 'Plain' or block.t == 'Para' then
        row_index = index
        row_block = block
        break
      end
    end

    if row_block then
      local name, comment, explicit_folder, highlighted = split_file_row(row_block.content)
      local is_folder = explicit_folder or nested ~= nil

      -- Preserve arbitrary Markdown if a useful filename cannot be extracted.
      if name and name ~= '' then
        item[row_index] = make_file_row(name, comment, is_folder, highlighted)
      end
    end

    if nested then
      if nested.t == 'OrderedList' then
        nested = pandoc.BulletList(nested.content)
        for i, block in ipairs(item) do
          if block.t == 'OrderedList' then
            item[i] = nested
            break
          end
        end
      end
      transform_file_list(nested)
    end
  end
  return list
end

local function transform_file_tree(el)
  add_class(el, 'semantic-file-tree')

  for index, block in ipairs(el.content) do
    if block.t == 'BulletList' or block.t == 'OrderedList' then
      if block.t == 'OrderedList' then
        block = pandoc.BulletList(block.content)
        el.content[index] = block
      end
      transform_file_list(block)
    end
  end

  return el
end

function Div(el)
  if has_class(el, 'steps') or has_class(el, 'steps-numbered') or has_class(el, 'steps-dots') or has_class(el, 'steps-git') then
    return transform_steps(el)
  end

  if has_class(el, 'circle-list') then
    add_class(el, 'semantic-circle-list')
    return el
  end

  if has_class(el, 'file-tree') then
    return transform_file_tree(el)
  end

  return nil
end
