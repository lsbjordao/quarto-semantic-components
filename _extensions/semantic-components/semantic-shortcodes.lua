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
local function is_latex() return FORMAT and (FORMAT:match('latex') or FORMAT:match('pdf')) end
local function is_docx() return FORMAT and FORMAT:match('docx')~=nil end
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
local function indicator_width(value)
  if not value or value=='' then return nil end
  local presets={
    xs='14rem',
    sm='18rem',
    md='26rem',
    lg='36rem',
    xl='48rem',
    full='100%'
  }
  local key=tostring(value):lower()
  return presets[key] or value
end
local function indicator_style(kwargs)
  local style={}
  cssvar(style,'--qsc-indicator-color-base',kw(kwargs,'color'))
  cssvar(style,'--qsc-indicator-color-light',kw(kwargs,'color-light'))
  cssvar(style,'--qsc-indicator-color-dark',kw(kwargs,'color-dark'))
  cssvar(style,'--qsc-indicator-track-base',kw(kwargs,'track-color'))
  cssvar(style,'--qsc-indicator-track-light',kw(kwargs,'track-color-light'))
  cssvar(style,'--qsc-indicator-track-dark',kw(kwargs,'track-color-dark'))
  local width=indicator_width(kw(kwargs,'width') or kw(kwargs,'size'))
  if width then
    cssvar(style,'--qsc-indicator-width',width)
    cssvar(style,'--qsc-indicator-bar-min','0')
    cssvar(style,'--qsc-indicator-bar-max','1fr')
  end
  return #style>0 and table.concat(style,';')..';' or ''
end
local function numeric(value,default) return tonumber(value) or default end
local function clamp(value,min,max) return math.max(min,math.min(max,value)) end
local function percent_label(value,max)
  local v,m=numeric(value,0),numeric(max,100)
  if m==0 then return tostring(value) end
  local p=(v/m)*100
  if math.abs(p-math.floor(p+0.5))<0.01 then return tostring(math.floor(p+0.5))..'%' end
  return string.format('%.1f%%',p)
end
local function latex_escape(value)
  local s=tostring(value or '')
  local map={
    ['\\']='\\textbackslash{}',['{']='\\{',['}']='\\}',['#']='\\#',['$']='\\$',
    ['%']='\\%',['&']='\\&',['_']='\\_',['^']='\\textasciicircum{}',['~']='\\textasciitilde{}'
  }
  return (s:gsub('[\\{}#$%%&_%^~]',map))
end
local function text_bar(fraction,cells)
  cells=cells or 10
  fraction=clamp(fraction,0,1)
  local full=math.floor(fraction*cells+0.5)
  return string.rep('■',full)..string.rep('□',cells-full)
end
local function docx_indicator(label,fraction,value_label)
  local parts=pandoc.List()
  if label~='' then
    parts:insert(pandoc.Strong({pandoc.Str(label)}))
    parts:insert(pandoc.Space())
  end
  parts:insert(pandoc.Span({pandoc.Str(text_bar(fraction,10))},pandoc.Attr('',{}, {['custom-style']='Indicator'})))
  parts:insert(pandoc.Space())
  parts:insert(pandoc.Str(value_label))
  return parts
end
local function progress(args,kwargs)
  local value=kw(kwargs,'value',arg(args,1) or '0')
  local max=kw(kwargs,'max','100')
  local label=kw(kwargs,'label','')
  local show=truthy(kw(kwargs,'show-value'),true)
  local value_label=kw(kwargs,'value-label',percent_label(value,max))
  local v,m=numeric(value,0),numeric(max,100)
  local fraction=m~=0 and clamp(v/m,0,1) or 0
  if is_latex() then
    return pandoc.RawInline('latex','\\qscprogress{'..latex_escape(label)..'}{'..string.format('%.5f',fraction)..'}{'..latex_escape(show and value_label or '')..'}')
  end
  if is_docx() then return docx_indicator(label,fraction,show and value_label or '') end
  if not is_html() then
    local out={}
    if label~='' then out[#out+1]=pandoc.Str(label..':'); out[#out+1]=pandoc.Space() end
    out[#out+1]=pandoc.Str(value_label)
    return out
  end
  local html='<span class="qsc-progress" style="'..esc(indicator_style(kwargs))..'">'
  if label~='' then html=html..'<span class="qsc-indicator-label">'..esc(label)..'</span>' else html=html..'<span></span>' end
  local aria=label~='' and (' aria-label="'..esc(label)..'"') or ''
  html=html..'<progress'..aria..' value="'..esc(value)..'" max="'..esc(max)..'">'..esc(value_label)..'</progress>'
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
  local v,lo,hi=numeric(value,0),numeric(min,0),numeric(max,100)
  local fraction=hi~=lo and clamp((v-lo)/(hi-lo),0,1) or 0
  if is_latex() then
    return pandoc.RawInline('latex','\\qscmeter{'..latex_escape(label)..'}{'..string.format('%.5f',fraction)..'}{'..latex_escape(show and value_label or '')..'}')
  end
  if is_docx() then return docx_indicator(label,fraction,show and value_label or '') end
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
  local aria=label~='' and (' aria-label="'..esc(label)..'"') or ''
  html=html..'<meter'..aria..attrs..'>'..esc(value_label)..'</meter>'
  html=html..(show and '<span class="qsc-indicator-value">'..esc(value_label)..'</span>' or '<span></span>')..'</span>'
  return pandoc.RawInline('html',html)
end
local function kbd(args,kwargs)
  local keys=arg(args,1) or kw(kwargs,'keys','')
  local separator=kw(kwargs,'separator','+')
  if is_latex() then return pandoc.RawInline('latex','\\qsckbd{'..latex_escape(keys)..'}') end
  if is_docx() then return pandoc.Span({pandoc.Str(keys)},pandoc.Attr('',{}, {['custom-style']='Keyboard'})) end
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
  if is_latex() then return pandoc.RawInline('latex','\\qscabbr{'..latex_escape(label)..'}{'..latex_escape(title)..'}') end
  if not is_html() then
    if title~='' then return {pandoc.Str(label),pandoc.Space(),pandoc.Str('('..title..')')} end
    return pandoc.Str(label)
  end
  return pandoc.RawInline('html','<abbr class="qsc-abbr" title="'..esc(title)..'">'..esc(label)..'</abbr>')
end

return {progress=progress,meter=meter,kbd=kbd,abbr=abbr}
