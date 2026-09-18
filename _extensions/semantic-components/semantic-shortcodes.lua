-- Inline semantic shortcodes: progress, meter, kbd, and abbr.
local function text(value)
  if value==nil then return nil end
  if type(value)=='string' then return value end
  local ok,result=pcall(pandoc.utils.stringify,value)
  return ok and result or tostring(value)
end
local function arg(args,i) return text(args[i]) end
local function kw(kwargs,key,default)
  local value=text(kwargs[key])
  if value==nil or value=='' then return default end
  return value
end
local function esc(value)
  return tostring(value or ''):gsub('&','&amp;'):gsub('<','&lt;'):gsub('>','&gt;'):gsub('"','&quot;')
end
local function is_html() return FORMAT and FORMAT:match('html')~=nil end
local function truthy(value,default)
  if value==nil then return default end
  value=tostring(value):lower()
  if value=='true' or value=='1' or value=='yes' or value=='on' then return true end
  if value=='false' or value=='0' or value=='no' or value=='off' then return false end
  return default
end
local function cssvar(out,name,value)
  if value and value~='' then out[#out+1]=name..':'..value end
end
local function indicator_style(kwargs)
  local style={}
  cssvar(style,'--qsc-indicator-color-base',kw(kwargs,'color'))
  cssvar(style,'--qsc-indicator-color-light',kw(kwargs,'color-light'))
  cssvar(style,'--qsc-indicator-color-dark',kw(kwargs,'color-dark'))
  cssvar(style,'--qsc-indicator-track-base',kw(kwargs,'track-color'))
  cssvar(style,'--qsc-indicator-track-light',kw(kwargs,'track-color-light'))
  cssvar(style,'--qsc-indicator-track-dark',kw(kwargs,'track-color-dark'))
  local width=kw(kwargs,'width')
  if width then style[#style+1]='width:'..width end
  return #style>0 and table.concat(style,';')..';' or ''
end
local function numeric(value,default) return tonumber(value) or default end
local function percent_label(value,max)
  local v,m=numeric(value,0),numeric(max,100)
  if m==0 then return tostring(value) end
  local p=(v/m)*100
  if math.abs(p-math.floor(p+0.5))<0.01 then return tostring(math.floor(p+0.5))..'%' end
  return string.format('%.1f%%',p)
end
local function progress(args,kwargs)
  local value=kw(kwargs,'value',arg(args,1) or '0')
  local max=kw(kwargs,'max','100')
  local label=kw(kwargs,'label','')
  local show=truthy(kw(kwargs,'show-value'),true)
  local value_label=kw(kwargs,'value-label',percent_label(value,max))
  if not is_html() then
    local out={}
    if label~='' then out[#out+1]=pandoc.Str(label..':') ; out[#out+1]=pandoc.Space() end
    out[#out+1]=pandoc.Str(value_label)
    return out
  end
  local html='<span class="qsc-progress" style="'..esc(indicator_style(kwargs))..'">'
  if label~='' then html=html..'<span class="qsc-indicator-label">'..esc(label)..'</span>' else html=html..'<span></span>' end
  html=html..'<progress value="'..esc(value)..'" max="'..esc(max)..'">'..esc(value_label)..'</progress>'
  html=html..(show and '<span class="qsc-indicator-value">'..esc(value_label)..'</span>' or '<span></span>')..'</span>'
  return pandoc.RawInline('html',html)
end
local function meter(args,kwargs)
  local value=kw(kwargs,'value',arg(args,1) or '0')
  local min=kw(kwargs,'min','0')
  local max=kw(kwargs,'max','100')
  local low=kw(kwargs,'low')
  local high=kw(kwargs,'high')
  local optimum=kw(kwargs,'optimum')
  local label=kw(kwargs,'label','')
  local show=truthy(kw(kwargs,'show-value'),true)
  local value_label=kw(kwargs,'value-label',value..' / '..max)
  if not is_html() then
    local out={}
    if label~='' then out[#out+1]=pandoc.Str(label..':'); out[#out+1]=pandoc.Space() end
    out[#out+1]=pandoc.Str(value_label)
    return out
  end
  local attrs=' value="'..esc(value)..'" min="'..esc(min)..'" max="'..esc(max)..'"'
  if low then attrs=attrs..' low="'..esc(low)..'"' end
  if high then attrs=attrs..' high="'..esc(high)..'"' end
  if optimum then attrs=attrs..' optimum="'..esc(optimum)..'"' end
  local html='<span class="qsc-meter" style="'..esc(indicator_style(kwargs))..'">'
  if label~='' then html=html..'<span class="qsc-indicator-label">'..esc(label)..'</span>' else html=html..'<span></span>' end
  html=html..'<meter'..attrs..'>'..esc(value_label)..'</meter>'
  html=html..(show and '<span class="qsc-indicator-value">'..esc(value_label)..'</span>' or '<span></span>')..'</span>'
  return pandoc.RawInline('html',html)
end
local function kbd(args,kwargs)
  local keys=arg(args,1) or kw(kwargs,'keys','')
  local separator=kw(kwargs,'separator','+')
  if not is_html() then return pandoc.Code(keys) end
  local parts={}
  for key in tostring(keys):gmatch('[^+]+') do
    key=key:gsub('^%s+',''):gsub('%s+$','')
    parts[#parts+1]='<kbd>'..esc(key)..'</kbd>'
  end
  return pandoc.RawInline('html','<span class="qsc-kbd-group">'..table.concat(parts,'<span class="qsc-kbd-separator">'..esc(separator)..'</span>')..'</span>')
end
local function abbr(args,kwargs)
  local label=arg(args,1) or kw(kwargs,'label','')
  local title=arg(args,2) or kw(kwargs,'title','')
  if not is_html() then
    if title~='' then return {pandoc.Str(label),pandoc.Space(),pandoc.Str('('..title..')')} end
    return pandoc.Str(label)
  end
  return pandoc.RawInline('html','<abbr class="qsc-abbr" title="'..esc(title)..'">'..esc(label)..'</abbr>')
end

return {progress=progress,meter=meter,kbd=kbd,abbr=abbr}
