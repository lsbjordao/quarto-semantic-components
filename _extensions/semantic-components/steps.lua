-- Steps and circled lists.
local config=require('./config')
local function has_class(el, name)
  for _, class in ipairs(el.classes or {}) do if class == name then return true end end
  return false
end
local function add_class(el, name) if not has_class(el, name) then el.classes:insert(name) end end
local function attr(el, key) return el.attributes and el.attributes[key] or nil end
local function is_html() return FORMAT and FORMAT:match('html') ~= nil end

if quarto and quarto.doc and quarto.doc.add_html_dependency and is_html() then
  quarto.doc.add_html_dependency({
    name = 'quarto-semantic-components', version='0.1.0',
    stylesheets = {
      'css/base.css', 'css/steps.css', 'css/file-tree.css',
      'css/git-tree.css', 'css/badges.css'
    }
  })
end

local function setting(el, meta, key, aliases)
  return attr(el,key) or config.default(meta,'steps',key,aliases)
end

local function suffixed_aliases(aliases, suffix)
  local out={}
  for _,alias in ipairs(aliases or {}) do out[#out+1]=alias..suffix end
  return out
end

local function themed_setting(el, meta, key, aliases)
  return
    setting(el,meta,key,aliases),
    setting(el,meta,key..'-light',suffixed_aliases(aliases,'-light')),
    setting(el,meta,key..'-dark',suffixed_aliases(aliases,'-dark'))
end

local function mode(el,meta)
  local value = setting(el,meta,'type',{'mode','style'})
  if value == 'dots' or value == 'dot' or value == 'bullet' or value == 'bullets' then return 'dots' end
  if value == 'git' or value == 'history' then return 'git' end
  if has_class(el, 'steps-dots') or has_class(el, 'dots') then return 'dots' end
  if has_class(el, 'steps-git') or has_class(el, 'git') then return 'git' end
  return 'numbered'
end

local function visual_span(class_name, styles)
  local declarations = {}
  for _, pair in ipairs(styles or {}) do
    local variable, value = pair[1], pair[2]
    if value and value ~= '' then declarations[#declarations + 1] = variable .. ':' .. value .. ';' end
  end
  local attributes = {}
  if #declarations > 0 then attributes.style = table.concat(declarations) end
  return pandoc.Span({}, pandoc.Attr('', {class_name}, attributes))
end

local function heading_attr(header, primary, alias)
  if not header.attributes then return nil end
  return header.attributes[primary] or (alias and header.attributes[alias]) or nil
end

local function heading_theme_attr(header, primary, alias)
  return
    heading_attr(header,primary,alias),
    heading_attr(header,primary..'-light',alias and (alias..'-light') or nil),
    heading_attr(header,primary..'-dark',alias and (alias..'-dark') or nil)
end

local function surface_fill(value)
  if not value or value=='' then return value end
  local normalized=tostring(value):lower()
  if normalized=='transparent' or normalized=='none' then
    return 'var(--semantic-step-surface)'
  end
  return value
end

local function step_title(header, list_mode)
  local title = pandoc.Span(header.content, pandoc.Attr(header.identifier or '', {'semantic-step-title'}))
  if list_mode ~= 'dots' or not is_html() then return pandoc.Plain({title}) end

  local dot_color,dot_color_light,dot_color_dark = heading_theme_attr(header, 'dot-color', 'marker-color')
  local dot_fill,dot_fill_light,dot_fill_dark = heading_theme_attr(header, 'dot-fill', 'marker-fill')
  dot_fill=surface_fill(dot_fill); dot_fill_light=surface_fill(dot_fill_light); dot_fill_dark=surface_fill(dot_fill_dark)
  local dot_size = heading_attr(header, 'dot-size', 'marker-size')
  local dot_border_width = heading_attr(header, 'dot-border-width', 'marker-border-width')
  local line_color,line_color_light,line_color_dark = heading_theme_attr(header, 'line-color', 'connector-color')
  local line_width = heading_attr(header, 'line-width', 'connector-width')

  return pandoc.Plain({
    visual_span('semantic-step-marker', {
      {'--semantic-step-item-dot-color-base', dot_color},
      {'--semantic-step-item-dot-color-light', dot_color_light},
      {'--semantic-step-item-dot-color-dark', dot_color_dark},
      {'--semantic-step-item-dot-fill-base', dot_fill},
      {'--semantic-step-item-dot-fill-light', dot_fill_light},
      {'--semantic-step-item-dot-fill-dark', dot_fill_dark},
      {'--semantic-step-item-dot-size', dot_size},
      {'--semantic-step-item-dot-border-width', dot_border_width}
    }),
    visual_span('semantic-step-connector', {
      {'--semantic-step-item-line-color-base', line_color},
      {'--semantic-step-item-line-color-light', line_color_light},
      {'--semantic-step-item-line-color-dark', line_color_dark},
      {'--semantic-step-item-line-width', line_width},
      {'--semantic-step-item-dot-size', dot_size}
    }),
    title
  })
end

local function from_headings(blocks, list_mode)
  local level
  for _, block in ipairs(blocks) do if block.t == 'Header' then level = block.level break end end
  if not level then return nil end
  local before, items, current = pandoc.List(), pandoc.List(), nil
  for _, block in ipairs(blocks) do
    if block.t == 'Header' and block.level == level then
      current = pandoc.List({step_title(block, list_mode)}); items:insert(current)
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

local function append_theme_style(el, variable, base, light, dark)
  if base and base~='' then append_style(el,variable..'-base:'..base) end
  if light and light~='' then append_style(el,variable..'-light:'..light) end
  if dark and dark~='' then append_style(el,variable..'-dark:'..dark) end
end

local function has_marker(item)
  for _, block in ipairs(item) do
    if block.t == 'Plain' or block.t == 'Para' then
      for _, inline in ipairs(block.content) do
        if inline.t == 'Span' and has_class(inline, 'semantic-step-marker') then return true end
      end
      return false
    end
  end
  return false
end

local function ensure_dot_markers(blocks)
  if not is_html() then return end
  for _, block in ipairs(blocks) do
    if block.t == 'BulletList' then
      for _, item in ipairs(block.content) do
        if not has_marker(item) then
          item:insert(1, pandoc.Plain({
            visual_span('semantic-step-marker', {}),
            visual_span('semantic-step-connector', {})
          }))
        end
      end
      return
    end
  end
end

local function transform_steps(el,meta)
  local list_mode = mode(el,meta)
  add_class(el, 'semantic-steps'); add_class(el, 'semantic-steps-' .. list_mode)

  if list_mode == 'dots' or list_mode == 'numbered' then
    local line_color,line_color_light,line_color_dark = themed_setting(el,meta,'line-color',{'connector-color'})
    local line_width = setting(el,meta,'line-width',{'connector-width'})
    local surface_color,surface_color_light,surface_color_dark = themed_setting(el,meta,'surface-color',{'surface','dot-surface'})
    append_theme_style(el,'--semantic-step-line-color',line_color,line_color_light,line_color_dark)
    append_theme_style(el,'--semantic-step-surface',surface_color,surface_color_light,surface_color_dark)
    if line_width and line_width ~= '' then append_style(el, '--semantic-step-line-width:' .. line_width) end
  end

  if list_mode == 'dots' then
    local dot_color,dot_color_light,dot_color_dark = themed_setting(el,meta,'dot-color',{'marker-color'})
    local dot_fill,dot_fill_light,dot_fill_dark = themed_setting(el,meta,'dot-fill',{'marker-fill'})
    dot_fill=surface_fill(dot_fill); dot_fill_light=surface_fill(dot_fill_light); dot_fill_dark=surface_fill(dot_fill_dark)
    local dot_size = setting(el,meta,'dot-size',{'marker-size'})
    local dot_border_width = setting(el,meta,'dot-border-width',{'marker-border-width'})
    append_theme_style(el,'--semantic-step-dot-color',dot_color,dot_color_light,dot_color_dark)
    append_theme_style(el,'--semantic-step-dot-fill',dot_fill,dot_fill_light,dot_fill_dark)
    if dot_size and dot_size ~= '' then append_style(el, '--semantic-step-dot-size:' .. dot_size) end
    if dot_border_width and dot_border_width ~= '' then append_style(el, '--semantic-step-dot-border-width:' .. dot_border_width) end
  end
  el.content = from_headings(el.content, list_mode) or normalize_list(el.content, list_mode)
  if list_mode == 'dots' then ensure_dot_markers(el.content) end
  if not is_html() then el.attributes['data-semantic-steps'] = list_mode end
  return el
end

local function transform_div(el,meta)
  if has_class(el, 'steps') or has_class(el, 'steps-numbered') or has_class(el, 'steps-dots') or has_class(el, 'steps-git') then
    return transform_steps(el,meta)
  end
  if has_class(el, 'circle-list') then add_class(el, 'semantic-circle-list'); return el end
end

function Pandoc(doc)
  return doc:walk({Div=function(el) return transform_div(el,doc.meta) end})
end
