-- Inline badge shortcode for Quarto Semantic Components.
-- Public API intentionally uses `badge`. This conflicts with other extensions that
-- register the same shortcode (for example mcanouil/quarto-badge), so authors must
-- choose which badge extension owns `{{< badge ... >}}` in a project.

local config = require('./config')

local function text(value) return config.text(value) end

local variants = { neutral=true, info=true, success=true, warning=true, danger=true, accent=true }
local sizes = { xs=true, sm=true, md=true, lg=true }
local shapes = { pill=true, rounded=true, square=true }
local appearances = { soft=true, solid=true, outline=true }

local function token(value, fallback, allowed)
  value = (value or fallback):lower():gsub('[^%w_-]', '-')
  return allowed[value] and value or fallback
end

local function css_var(style, name, value)
  if value and value ~= '' then style[#style + 1] = name .. ':' .. value end
end

local function truthy(value)
  value = value and value:lower() or ''
  return value == 'true' or value == '1' or value == 'yes'
end

-- Shortcode positional/named arguments are lists of Pandoc inlines. Keep those
-- nodes intact rather than stringify -> Str round-tripping them; this preserves
-- spaces, emphasis/code, and avoids empty labels with newer Quarto/Pandoc builds.
local function copy_inlines(value)
  local out = pandoc.List()
  if value == nil then return out end
  if type(value) == 'string' then
    if value ~= '' then out:insert(pandoc.Str(value)) end
    return out
  end
  for _, inline in ipairs(value) do out:insert(inline) end
  return out
end

local function argument_text(value)
  if value == nil then return nil end
  local result = text(value)
  if result and result ~= '' then return result end

  -- Defensive fallback for inline lists if stringify ever returns an empty value.
  local parts = {}
  if type(value) == 'table' then
    for _, inline in ipairs(value) do
      if inline.t == 'Str' then parts[#parts + 1] = inline.text
      elseif inline.t == 'Space' or inline.t == 'SoftBreak' or inline.t == 'LineBreak' then parts[#parts + 1] = ' '
      elseif inline.text then parts[#parts + 1] = tostring(inline.text) end
    end
  end
  result = table.concat(parts):gsub('^%s+', ''):gsub('%s+$', '')
  return result ~= '' and result or nil
end

local function text_inlines(value)
  local out = pandoc.List()
  if not value or value == '' then return out end
  -- Metadata labels are plain text. Split whitespace into real Space nodes.
  local first = true
  for word in tostring(value):gmatch('%S+') do
    if not first then out:insert(pandoc.Space()) end
    out:insert(pandoc.Str(word))
    first = false
  end
  return out
end

return {
  ['badge'] = function(args, kwargs, meta)
    local first_arg = args[1]
    local first = argument_text(first_arg)
    local explicit_key = argument_text(kwargs['key'])
    local preset_key = explicit_key or first
    local preset = config.preset(meta, 'badge', preset_key)

    local function value(key, aliases)
      return config.resolve(meta, 'badge', kwargs, preset, key, aliases)
    end

    local label_inlines
    if kwargs['text'] ~= nil then
      label_inlines = copy_inlines(kwargs['text'])
    elseif explicit_key and first_arg ~= nil then
      label_inlines = copy_inlines(first_arg)
    else
      local preset_label = config.value(preset, 'label', {'text'})
      if preset_label and preset_label ~= '' then
        label_inlines = text_inlines(preset_label)
      elseif first_arg ~= nil then
        label_inlines = copy_inlines(first_arg)
      else
        label_inlines = text_inlines(preset_key or '')
      end
    end

    local variant = token(value('type', {'variant'}), 'neutral', variants)
    local size = token(value('size'), 'sm', sizes)
    local shape = token(value('shape'), 'pill', shapes)
    local appearance = token(value('appearance'), 'soft', appearances)
    local icon = value('icon')
    local icon_position = (value('icon-position') or 'start'):lower()
    local href = value('href', {'link'})
    local title = value('title') or ''

    local classes = pandoc.List({
      'semantic-badge', 'semantic-badge-' .. variant,
      'semantic-badge-size-' .. size,
      'semantic-badge-shape-' .. shape,
      'semantic-badge-' .. appearance
    })

    local extra_classes = value('class', {'classes'})
    for _, class in ipairs(config.classes(extra_classes)) do classes:insert(class) end
    if truthy(value('uppercase')) then classes:insert('semantic-badge-uppercase') end
    if value('font') == 'mono' then classes:insert('semantic-badge-mono') end

    local style = {}
    css_var(style, '--semantic-badge-fg', value('fg', {'foreground', 'text-colour', 'text-color'}))
    css_var(style, '--semantic-badge-bg', value('bg', {'background', 'colour', 'color'}))
    css_var(style, '--semantic-badge-border', value('border'))
    css_var(style, '--semantic-badge-radius', value('radius'))
    css_var(style, '--semantic-badge-weight', value('weight'))
    css_var(style, '--semantic-badge-padding', value('padding'))
    css_var(style, '--semantic-badge-font-size', value('font-size'))
    css_var(style, '--semantic-badge-border-width', value('border-width'))
    css_var(style, '--semantic-badge-letter-spacing', value('letter-spacing'))
    css_var(style, '--semantic-badge-shadow', value('shadow'))

    local attrs = {
      ['data-badge-variant'] = variant,
      ['data-badge-size'] = size,
      ['data-badge-appearance'] = appearance,
      ['data-semantic-badge-resolved'] = 'true'
    }
    if preset_key and preset then attrs['data-badge-key'] = preset_key end
    if #style > 0 then attrs['style'] = table.concat(style, ';') .. ';' end
    if title ~= '' then attrs['title'] = title end
    if not (FORMAT and FORMAT:match('html')) then attrs['custom-style'] = 'Semantic Badge' end

    local inlines = pandoc.List()
    local icon_span = icon and icon ~= '' and pandoc.Span({ pandoc.Str(icon) }, pandoc.Attr('', { 'semantic-badge-icon' })) or nil
    if icon_span and icon_position ~= 'end' then inlines:insert(icon_span); inlines:insert(pandoc.Space()) end
    for _, inline in ipairs(label_inlines) do inlines:insert(inline) end
    if icon_span and icon_position == 'end' then inlines:insert(pandoc.Space()); inlines:insert(icon_span) end

    local badge = pandoc.Span(inlines, pandoc.Attr('', classes, attrs))
    if href and href ~= '' then return pandoc.Link({ badge }, href, title) end
    return badge
  end
}
