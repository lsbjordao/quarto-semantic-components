-- AST-native badges: [Beta]{.badge ...}
local config=require('./config')
local allowed={neutral=true,info=true,success=true,warning=true,danger=true,accent=true}
local sizes={xs=true,sm=true,md=true,lg=true}; local shapes={pill=true,rounded=true,square=true}; local looks={soft=true,solid=true,outline=true}
local function has_class(el,name) for _,c in ipairs(el.classes or {}) do if c==name then return true end end return false end
local function remove_class(classes,name)
  local out=pandoc.List()
  for _,c in ipairs(classes or {}) do if c~=name then out:insert(c) end end
  return out
end
local function attr(el,key) return el.attributes and el.attributes[key] or nil end
local function token(value,fallback,set) value=(value or fallback):lower():gsub('[^%w_-]','-'); return set[value] and value or fallback end
local function css(style,name,value) if value and value~='' then style[#style+1]=name..':'..value end end
local function append_unique(classes,value) for _,c in ipairs(classes) do if c==value then return end end classes:insert(value) end

local function transform(el,meta)
  -- `.badge` is the public AST-native API. Internally it is immediately replaced
  -- by a private class so Bootstrap's `.badge` styles do not own the rendering.
  if not has_class(el,'badge') and not has_class(el,'qsc-badge') then return nil end
  if attr(el,'data-qsc-badge-resolved')=='true' then return el end

  el.classes=remove_class(el.classes,'badge')
  append_unique(el.classes,'qsc-badge')

  local content_key=pandoc.utils.stringify(el.content)
  local preset_key=attr(el,'key') or content_key
  local preset=config.preset(meta,'badge',preset_key)
  local function value(key,aliases) return config.resolve(meta,'badge',el.attributes,preset,key,aliases) end

  local variant=token(value('variant',{'type'}),'neutral',allowed); local size=token(value('size'),'sm',sizes)
  local shape=token(value('shape'),'pill',shapes); local look=token(value('appearance'),'soft',looks)
  append_unique(el.classes,'qsc-badge-'..variant); append_unique(el.classes,'qsc-badge-size-'..size)
  append_unique(el.classes,'qsc-badge-shape-'..shape); append_unique(el.classes,'qsc-badge-'..look)

  for _,class in ipairs(config.classes(value('class',{'classes'}))) do append_unique(el.classes,class) end

  local style={}
  css(style,'--semantic-badge-fg',value('fg',{'foreground','text-colour','text-color'}))
  css(style,'--semantic-badge-fg-light',value('fg-light',{'foreground-light','text-colour-light','text-color-light'}))
  css(style,'--semantic-badge-fg-dark',value('fg-dark',{'foreground-dark','text-colour-dark','text-color-dark'}))
  css(style,'--semantic-badge-bg',value('bg',{'background','colour','color'}))
  css(style,'--semantic-badge-bg-light',value('bg-light',{'background-light','colour-light','color-light'}))
  css(style,'--semantic-badge-bg-dark',value('bg-dark',{'background-dark','colour-dark','color-dark'}))
  css(style,'--semantic-badge-border',value('border'))
  css(style,'--semantic-badge-border-light',value('border-light'))
  css(style,'--semantic-badge-border-dark',value('border-dark'))
  css(style,'--semantic-badge-border-width',value('border-width')); css(style,'--semantic-badge-radius',value('radius'))
  css(style,'--semantic-badge-padding',value('padding')); css(style,'--semantic-badge-weight',value('weight')); css(style,'--semantic-badge-font-size',value('font-size'))
  css(style,'--semantic-badge-letter-spacing',value('letter-spacing')); css(style,'--semantic-badge-shadow',value('shadow'))
  if #style>0 then
    local existing=attr(el,'style') or ''; if existing~='' and existing:sub(-1)~=';' then existing=existing..';' end
    el.attributes.style=existing..table.concat(style,';')..';'
  end
  if value('uppercase')=='true' then append_unique(el.classes,'qsc-badge-uppercase') end; if value('font')=='mono' then append_unique(el.classes,'qsc-badge-mono') end
  if preset then el.attributes['data-badge-key']=preset_key end
  el.attributes['data-qsc-badge-resolved']='true'
  if not (FORMAT and FORMAT:match('html')) then el.attributes['custom-style']='Badge' end
  return el
end

function Pandoc(doc)
  return doc:walk({Span=function(el) return transform(el,doc.meta) end})
end
