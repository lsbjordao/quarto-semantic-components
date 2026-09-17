-- Inline semantic components for Quarto.

local function text(value)
  if value == nil then
    return nil
  end
  if type(value) == 'string' then
    return value
  end
  return pandoc.utils.stringify(value)
end

local variants = {
  neutral = true,
  info = true,
  success = true,
  warning = true,
  danger = true,
  accent = true
}

return {
  ['badge'] = function(args, kwargs, meta)
    local label = text(args[1]) or ''
    local variant = text(kwargs['type']) or text(kwargs['variant']) or 'neutral'
    local icon = text(kwargs['icon'])

    variant = variant:lower():gsub('[^%w_-]', '-')
    if not variants[variant] then
      variant = 'neutral'
    end

    local inlines = pandoc.List()
    if icon and icon ~= '' then
      inlines:insert(pandoc.Span({ pandoc.Str(icon) }, pandoc.Attr('', { 'semantic-badge-icon' })))
      inlines:insert(pandoc.Space())
    end
    inlines:insert(pandoc.Str(label))

    local attrs = { ['data-badge-variant'] = variant }
    if not (FORMAT and FORMAT:match('html')) then
      attrs['custom-style'] = 'Semantic Badge'
    end

    return pandoc.Span(
      inlines,
      pandoc.Attr('', { 'semantic-badge', 'semantic-badge-' .. variant }, attrs)
    )
  end
}
