-- Steps and circled lists.
local function has_class(el, name)
  for _, class in ipairs(el.classes or {}) do if class == name then return true end end
  return false
end
local function add_class(el, name) if not has_class(el, name) then el.classes:insert(name) end end
local function attr(el, key) return el.attributes and el.attributes[key] or nil end
local function is_html() return FORMAT and FORMAT:match('html') ~= nil end

if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name = 'quarto-semantic-components', version = '0.4.0',
    stylesheets = {
      'css/base.css', 'css/steps.css', 'css/file-tree.css',
      'css/git-tree.css', 'css/badges.css'
    }
  })
end

local function mode(el)
  local value = attr(el, 'type') or attr(el, 'mode') or attr(el, 'style')
  if value == 'dots' or value == 'dot' or value == 'bullet' or value == 'bullets' then return 'dots' end
  if value == 'git' or value == 'history' or value == 'timeline' then return 'git' end
  if has_class(el, 'steps-dots') or has_class(el, 'dots') then return 'dots' end
  if has_class(el, 'steps-git') or has_class(el, 'git') then return 'git' end
  return 'numbered'
end

local function step_title(header)
  return pandoc.Plain({pandoc.Span(header.content, pandoc.Attr('', {'semantic-step-title'}))})
end

local function from_headings(blocks, list_mode)
  local level
  for _, block in ipairs(blocks) do if block.t == 'Header' then level = block.level break end end
  if not level then return nil end
  local before, items, current = pandoc.List(), pandoc.List(), nil
  for _, block in ipairs(blocks) do
    if block.t == 'Header' and block.level == level then
      current = pandoc.List({step_title(block)}); items:insert(current)
    elseif current then current:insert(block)
    else before:insert(block) end
  end
  if #items == 0 then return nil end
  local out = pandoc.List()
  for _, block in ipairs(before) do out:insert(block) end
  out:insert(list_mode == 'numbered' and pandoc.OrderedList(items) or pandoc.BulletList(items))
  return out
end

local function normalize_list(blocks, list_mode)
  local out, changed = pandoc.List(), false
  for _, block in ipairs(blocks) do
    if not changed and (block.t == 'OrderedList' or block.t == 'BulletList') then
      out:insert(list_mode == 'numbered' and pandoc.OrderedList(block.content) or pandoc.BulletList(block.content)); changed = true
    else out:insert(block) end
  end
  return changed and out or blocks
end

local function append_style(el, declaration)
  if not declaration or declaration == '' then return end
  local value = attr(el, 'style') or ''
  if value ~= '' and value:sub(-1) ~= ';' then value = value .. ';' end
  el.attributes.style = value .. declaration .. ';'
end

local function transform_steps(el)
  local list_mode = mode(el)
  add_class(el, 'semantic-steps'); add_class(el, 'semantic-steps-' .. list_mode)
  if list_mode == 'dots' then
    local dot = attr(el, 'dot-color') or attr(el, 'marker-color')
    local line = attr(el, 'line-color') or attr(el, 'connector-color')
    if dot and dot ~= '' then append_style(el, '--semantic-step-dot-color:' .. dot); el.attributes['data-dot-color'] = dot end
    if line and line ~= '' then append_style(el, '--semantic-step-line-color:' .. line); el.attributes['data-line-color'] = line end
  end
  el.content = from_headings(el.content, list_mode) or normalize_list(el.content, list_mode)
  if not is_html() then el.attributes['data-semantic-steps'] = list_mode end
  return el
end

function Div(el)
  if has_class(el, 'steps') or has_class(el, 'steps-numbered') or has_class(el, 'steps-dots') or has_class(el, 'steps-git') then
    return transform_steps(el)
  end
  if has_class(el, 'circle-list') then add_class(el, 'semantic-circle-list'); return el end
end
