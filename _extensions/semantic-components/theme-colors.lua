-- Theme-aware color attributes shared by semantic components.
-- Unsuffixed colors remain the fallback for both themes; `-light` and `-dark`
-- values override them only in the matching Quarto color mode.
local config=require('./config')

local function has_class(el,name)
  for _,class in ipairs(el.classes or {}) do if class==name then return true end end
  return false
end

local function attr(el,key)
  return el.attributes and el.attributes[key] or nil
end

local function append_style(el,declaration)
  if not declaration or declaration=='' then return end
  local current=attr(el,'style') or ''
  if current~='' and current:sub(-1)~=';' then current=current..';' end
  el.attributes.style=current..declaration..';'
end

local function suffixed_aliases(aliases,suffix)
  local out={}
  for _,alias in ipairs(aliases or {}) do out[#out+1]=alias..suffix end
  return out
end

local function themed_setting(el,meta,component,key,aliases,suffix)
  local full=key..suffix
  return attr(el,full) or config.default(meta,component,full,suffixed_aliases(aliases,suffix))
end

local accent_colors={
  note='var(--quarto-callout-color-note,var(--bs-info,#0dcaf0))',
  info='var(--quarto-callout-color-note,var(--bs-info,#0dcaf0))',
  warning='var(--quarto-callout-color-warning,var(--bs-warning,#ffc107))',
  danger='var(--quarto-callout-color-caution,var(--bs-danger,#dc3545))',
  caution='var(--quarto-callout-color-caution,var(--bs-danger,#dc3545))',
  success='var(--quarto-callout-color-tip,var(--bs-success,#198754))',
  tip='var(--quarto-callout-color-tip,var(--bs-success,#198754))',
  important='var(--quarto-callout-color-important,var(--bs-primary,#0d6efd))'
}

local function accent_value(value)
  if not value or value=='' then return nil end
  return accent_colors[tostring(value):lower()] or value
end

local function apply_article(el,meta)
  for _,suffix in ipairs({'-light','-dark'}) do
    local border=themed_setting(el,meta,'article','border-color',{'border'},suffix)
    local background=themed_setting(el,meta,'article','background',{'bg'},suffix)
    local accent=accent_value(themed_setting(el,meta,'article','accent-color',{'accent-colour'},suffix))
    if border and border~='' then append_style(el,'--article-border-color'..suffix..':'..border) end
    if background and background~='' then append_style(el,'--article-background'..suffix..':'..background) end
    if accent and accent~='' then append_style(el,'--article-accent-color'..suffix..':'..accent) end
  end
end

local function apply_git_tree(el,meta)
  for _,suffix in ipairs({'-light','-dark'}) do
    local line=themed_setting(el,meta,'git-tree','line-color',{'edge-color'},suffix)
    local node=themed_setting(el,meta,'git-tree','node-bg',{'node-background'},suffix)
    if line and line~='' then append_style(el,'--semantic-git-line'..suffix..':'..line) end
    if node and node~='' then append_style(el,'--semantic-git-node-bg'..suffix..':'..node) end
  end
end

function Pandoc(doc)
  return doc:walk({
    Div=function(el)
      if has_class(el,'article') then apply_article(el,doc.meta) end
      if has_class(el,'git-tree') then apply_git_tree(el,doc.meta) end
      return el
    end
  })
end
