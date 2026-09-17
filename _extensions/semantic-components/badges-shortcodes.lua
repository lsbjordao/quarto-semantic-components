-- Inline semantic components for Quarto.
-- Uses `semantic-badge` rather than `badge` so it can coexist with
-- mcanouil/quarto-badge without shortcode-name collisions.

local function text(value)
  if value == nil then return nil end
  if type(value) == 'string' then return value end
  return pandoc.utils.stringify(value)
end

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

return {
  ['semantic-badge'] = function(args, kwargs, meta)
    local label = text(args[1]) or text(kwargs['text']) or ''
    local variant = token(text(kwargs['type']) or text(kwargs['variant']), 'neutral', variants)
    local size = token(text(kwargs['size']), 'sm', sizes)
    local shape = token(text(kwargs['shape']), 'pill', shapes)
    local appearance = token(text(kwargs['appearance']), 'soft', appearances)
    local icon = text(kwargs['icon'])
    local icon_position = (text(kwargs['icon-position']) or 'start'):lower()
    local href = text(kwargs['href']) or text(kwargs['link'])
    local title = text(kwargs['title']) or ''

    local classes = pandoc.List({
      'semantic-badge', 'semantic-badge-' .. variant,
      'semantic-badge-size-' .. size,
      'semantic-badge-shape-' .. shape,
      'semantic-badge-' .. appearance
    })
    if truthy(text(kwargs['uppercase'])) then classes:insert('semantic-badge-uppercase') end
    if text(kwargs['font']) == 'mono' then classes:insert('semantic-badge-mono') end

    local style = {}
    css_var(style, '--semantic-badge-fg', text(kwargs['fg']) or text(kwargs['foreground']))
    css_var(style, '--semantic-badge-bg', text(kwargs['bg']) or text(kwargs['background']))
    css_var(style, '--semantic-badge-border', text(kwargs['border']))
    css_var(style, '--semantic-badge-radius', text(kwargs['radius']))
    css_var(style, '--semantic-badge-weight', text(kwargs['weight']))
    css_var(style, '--semantic-badge-padding', text(kwargs['padding']))
    css_var(style, '--semantic-badge-font-size', text(kwargs['font-size']))
    css_var(style, '--semantic-badge-border-width', text(kwargs['border-width']))
    css_var(style, '--semantic-badge-letter-spacing', text(kwargs['letter-spacing']))
    css_var(style, '--semantic-badge-shadow', text(kwargs['shadow']))

    local attrs = {
      ['data-badge-variant'] = variant,
      ['data-badge-size'] = size,
      ['data-badge-appearance'] = appearance
    }
    if #style > 0 then attrs['style'] = table.concat(style, ';') .. ';' end
    if title ~= '' then attrs['title'] = title end
    if not (FORMAT and FORMAT:match('html')) then attrs['custom-style'] = 'Semantic Badge' end

    local inlines = pandoc.List()
    local icon_span = icon and icon ~= '' and pandoc.Span({ pandoc.Str(icon) }, pandoc.Attr('', { 'semantic-badge-icon' })) or nil
    if icon_span and icon_position ~= 'end' then inlines:insert(icon_span) inlines:insert(pandoc.Space()) end
    inlines:insert(pandoc.Str(label))
    if icon_span and icon_position == 'end' then inlines:insert(pandoc.Space()) inlines:insert(icon_span) end

    local badge = pandoc.Span(inlines, pandoc.Attr('', classes, attrs))
    if href and href ~= '' then return pandoc.Link({ badge }, href, title) end
    return badge
  end
}
