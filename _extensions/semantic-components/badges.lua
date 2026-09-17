-- AST-native semantic badges: [Beta]{.semantic-badge ...}
local allowed={neutral=true,info=true,success=true,warning=true,danger=true,accent=true}
local sizes={xs=true,sm=true,md=true,lg=true}; local shapes={pill=true,rounded=true,square=true}; local looks={soft=true,solid=true,outline=true}
local function has_class(el,name) for _,c in ipairs(el.classes or {}) do if c==name then return true end end return false end
local function attr(el,key) return el.attributes and el.attributes[key] or nil end
local function token(value,fallback,set) value=(value or fallback):lower():gsub('[^%w_-]','-'); return set[value] and value or fallback end
local function css(style,name,value) if value and value~='' then style[#style+1]=name..':'..value end end
function Span(el)
  if not has_class(el,'semantic-badge') then return nil end
  local variant=token(attr(el,'variant') or attr(el,'type'),'neutral',allowed); local size=token(attr(el,'size'),'sm',sizes)
  local shape=token(attr(el,'shape'),'pill',shapes); local look=token(attr(el,'appearance'),'soft',looks)
  el.classes:insert('semantic-badge-'..variant); el.classes:insert('semantic-badge-size-'..size); el.classes:insert('semantic-badge-shape-'..shape); el.classes:insert('semantic-badge-'..look)
  local style={}; css(style,'--semantic-badge-fg',attr(el,'fg') or attr(el,'foreground')); css(style,'--semantic-badge-bg',attr(el,'bg') or attr(el,'background'))
  css(style,'--semantic-badge-border',attr(el,'border')); css(style,'--semantic-badge-border-width',attr(el,'border-width')); css(style,'--semantic-badge-radius',attr(el,'radius'))
  css(style,'--semantic-badge-padding',attr(el,'padding')); css(style,'--semantic-badge-weight',attr(el,'weight')); css(style,'--semantic-badge-font-size',attr(el,'font-size'))
  css(style,'--semantic-badge-letter-spacing',attr(el,'letter-spacing')); css(style,'--semantic-badge-shadow',attr(el,'shadow'))
  if #style>0 then el.attributes.style=table.concat(style,';')..';' end
  if attr(el,'uppercase')=='true' then el.classes:insert('semantic-badge-uppercase') end; if attr(el,'font')=='mono' then el.classes:insert('semantic-badge-mono') end
  if not (FORMAT and FORMAT:match('html')) then el.attributes['custom-style']='Semantic Badge' end
  return el
end
