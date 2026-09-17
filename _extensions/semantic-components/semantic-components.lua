-- semantic-components.lua
-- Quarto/Pandoc filter for semantic document components that remain usable
-- across HTML, PDF and DOCX outputs.

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

if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name = 'quarto-semantic-components',
    version = '0.2.0',
    stylesheets = { 'semantic-components.css' }
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

  local list = mode == 'numbered' and pandoc.OrderedList(items) or pandoc.BulletList(items)
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
      result:insert(mode == 'numbered' and pandoc.OrderedList(block.content) or pandoc.BulletList(block.content))
      changed = true
    else
      result:insert(block)
    end
  end
  return changed and result or blocks
end

local function transform_steps(el)
  local mode = step_mode(el)
  add_class(el, 'semantic-steps')
  add_class(el, 'semantic-steps-' .. mode)

  local grouped = group_heading_steps(el.content, mode)
  el.content = grouped or normalize_existing_steps(el.content, mode)

  if not is_html() then
    el.attributes['data-semantic-steps'] = mode
  end
  return el
end

local function stringify_inlines(inlines)
  return pandoc.utils.stringify(pandoc.Plain(inlines))
end

local function inline_has_class(inline, class_name)
  if not inline.classes then
    return false
  end
  for _, class in ipairs(inline.classes) do
    if class == class_name then
      return true
    end
  end
  return false
end

local function copy_tail(inlines, start_index)
  local tail = pandoc.List()
  for i = start_index, #inlines do
    tail:insert(inlines[i])
  end
  while #tail > 0 and tail[1].t == 'Space' do
    tail:remove(1)
  end
  return tail
end

local function parse_named_row(inlines)
  if #inlines == 0 then
    return nil
  end

  local first = inlines[1]
  local name = nil
  local highlighted = false
  local icon = nil
  local comment_inlines = pandoc.List()

  if first.t == 'Code' then
    name = first.text
    icon = first.attributes and first.attributes['icon'] or nil
    highlighted = inline_has_class(first, 'highlight') or inline_has_class(first, 'featured')
    comment_inlines = copy_tail(inlines, 2)
  elseif first.t == 'Strong' then
    name = stringify_inlines(first.content)
    highlighted = true
    comment_inlines = copy_tail(inlines, 2)
  else
    local raw = stringify_inlines(inlines):gsub('^%s+', ''):gsub('%s+$', '')
    local parsed_name, comment = raw:match('^(%S+)%s+(.+)$')
    name = parsed_name or raw
    if comment then
      comment_inlines = pandoc.List({ pandoc.Str(comment) })
    end
  end

  local explicit_folder = false
  if name and name:sub(1, 1) == '+' then
    explicit_folder = true
    name = name:sub(2)
  end

  return {
    name = name,
    highlighted = highlighted,
    icon = icon,
    comment = comment_inlines,
    explicit_folder = explicit_folder
  }
end

local named_icons = {
  file = true, folder = true, code = true, terminal = true,
  database = true, data = true, image = true, config = true,
  docs = true, package = true, test = true, lock = true,
  git = true, notebook = true, leaf = true, star = true, rocket = true
}

local exact_file_icons = {
  ['dockerfile'] = 'docker',
  ['makefile'] = 'terminal',
  ['package.json'] = 'package',
  ['package-lock.json'] = 'lock',
  ['pnpm-lock.yaml'] = 'lock',
  ['yarn.lock'] = 'lock',
  ['cargo.toml'] = 'rust',
  ['cargo.lock'] = 'lock',
  ['go.mod'] = 'go',
  ['go.sum'] = 'go',
  ['requirements.txt'] = 'python',
  ['pyproject.toml'] = 'python',
  ['renv.lock'] = 'r',
  ['.gitignore'] = 'git',
  ['.gitattributes'] = 'git',
  ['_quarto.yml'] = 'quarto'
}

local extension_icons = {
  r = 'r', rmd = 'r',
  py = 'python', pyw = 'python',
  js = 'javascript', mjs = 'javascript', cjs = 'javascript', jsx = 'javascript',
  ts = 'typescript', mts = 'typescript', cts = 'typescript', tsx = 'typescript',
  html = 'html', htm = 'html',
  css = 'css', scss = 'css', sass = 'css', less = 'css',
  json = 'json', jsonl = 'json',
  yml = 'yaml', yaml = 'yaml',
  qmd = 'quarto',
  md = 'markdown', markdown = 'markdown',
  lua = 'lua',
  rs = 'rust',
  go = 'go',
  java = 'java',
  c = 'c', h = 'c',
  cpp = 'cpp', cc = 'cpp', cxx = 'cpp', hpp = 'cpp', hh = 'cpp', hxx = 'cpp',
  sql = 'sql',
  sh = 'shell', bash = 'shell', zsh = 'shell', fish = 'shell',
  ipynb = 'notebook',
  csv = 'data', tsv = 'data', parquet = 'data', feather = 'data', arrow = 'data',
  db = 'database', sqlite = 'database', sqlite3 = 'database',
  png = 'image', jpg = 'image', jpeg = 'image', gif = 'image', webp = 'image', svg = 'image',
  toml = 'config', ini = 'config', env = 'config', conf = 'config', cfg = 'config',
  lock = 'lock'
}

local function automatic_file_icon(name, folder)
  if folder then
    return 'folder'
  end
  local lower = (name or ''):lower()
  if exact_file_icons[lower] then
    return exact_file_icons[lower]
  end
  local ext = lower:match('%.([%w]+)$')
  return (ext and extension_icons[ext]) or 'file'
end

local function image_icon(value)
  if not value then
    return false
  end
  local lower = value:lower()
  return lower:match('%.svg$') or lower:match('%.png$') or lower:match('%.jpe?g$') or lower:match('%.webp$') or lower:match('%.gif$')
end

local function make_inline_custom_icon(value)
  if not value or value == '' then
    return nil
  end
  if image_icon(value) then
    return pandoc.Span(
      { pandoc.Image({}, value, '') },
      pandoc.Attr('', { 'file-tree-custom-icon', 'file-tree-custom-icon-image' })
    )
  end
  return pandoc.Span(
    { pandoc.Str(value) },
    pandoc.Attr('', { 'file-tree-custom-icon', 'file-tree-custom-icon-text' })
  )
end

local function make_file_row(parsed, folder)
  local icon = parsed.icon
  local icon_name = nil
  local inline_icon = nil

  if icon and named_icons[icon:lower()] then
    icon_name = icon:lower()
  elseif icon and icon ~= 'auto' then
    inline_icon = make_inline_custom_icon(icon)
  else
    icon_name = automatic_file_icon(parsed.name, folder)
  end

  local classes = pandoc.List({
    'file-tree-row',
    folder and 'file-tree-folder' or 'file-tree-file'
  })
  if parsed.highlighted then
    classes:insert('file-tree-highlighted')
  end
  if icon_name then
    classes:insert('file-icon-' .. icon_name)
  end
  if inline_icon then
    classes:insert('file-tree-has-inline-icon')
  end

  local row = pandoc.List()
  if inline_icon then
    row:insert(inline_icon)
    row:insert(pandoc.Space())
  end

  if folder then
    row:insert(pandoc.Strong({ pandoc.Str(parsed.name) }))
  else
    row:insert(pandoc.Code(parsed.name))
  end

  if parsed.comment and #parsed.comment > 0 then
    row:insert(pandoc.Space())
    row:insert(pandoc.Span(parsed.comment, pandoc.Attr('', { 'file-tree-comment' })))
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

    local row_index, row_block = nil, nil
    for index, block in ipairs(item) do
      if block.t == 'Plain' or block.t == 'Para' then
        row_index, row_block = index, block
        break
      end
    end

    if row_block then
      local parsed = parse_named_row(row_block.content)
      if parsed and parsed.name and parsed.name ~= '' then
        item[row_index] = make_file_row(parsed, parsed.explicit_folder or nested ~= nil)
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

local function make_git_row(parsed, branch_point)
  local classes = pandoc.List({ 'git-tree-row' })
  if branch_point then
    classes:insert('git-tree-branch-point')
  end

  local inlines = pandoc.List()
  if parsed.name and parsed.name ~= '' then
    inlines:insert(pandoc.Span({ pandoc.Code(parsed.name) }, pandoc.Attr('', { 'git-tree-ref' })))
  end
  if parsed.comment and #parsed.comment > 0 then
    if #inlines > 0 then inlines:insert(pandoc.Space()) end
    inlines:insert(pandoc.Span(parsed.comment, pandoc.Attr('', { 'git-tree-message' })))
  end
  if #inlines == 0 then
    inlines:insert(pandoc.Str('commit'))
  end

  return pandoc.Plain({ pandoc.Span(inlines, pandoc.Attr('', classes)) })
end

local function transform_git_list(list, depth)
  depth = depth or 0
  for _, item in ipairs(list.content) do
    local nested = nil
    for _, block in ipairs(item) do
      if block.t == 'BulletList' or block.t == 'OrderedList' then
        nested = block
        break
      end
    end

    local row_index, row_block = nil, nil
    for index, block in ipairs(item) do
      if block.t == 'Plain' or block.t == 'Para' then
        row_index, row_block = index, block
        break
      end
    end

    if row_block then
      local parsed = parse_named_row(row_block.content)
      if parsed then
        item[row_index] = make_git_row(parsed, nested ~= nil)
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
      transform_git_list(nested, depth + 1)
    end
  end
  return list
end

local function transform_git_tree(el)
  add_class(el, 'semantic-git-tree')
  for index, block in ipairs(el.content) do
    if block.t == 'BulletList' or block.t == 'OrderedList' then
      if block.t == 'OrderedList' then
        block = pandoc.BulletList(block.content)
        el.content[index] = block
      end
      transform_git_list(block, 0)
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

  if has_class(el, 'git-tree') then
    return transform_git_tree(el)
  end

  return nil
end
