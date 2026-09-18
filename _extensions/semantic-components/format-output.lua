-- Rich non-HTML rendering for Quarto Semantic Components.
-- PDF/LaTeX uses native LaTeX packages; DOCX keeps editable structures when
-- practical and turns graph-only components into generated figures.

local function has_class(el,name)
  for _,c in ipairs(el.classes or {}) do if c==name then return true end end
  return false
end

local function is_latex() return FORMAT and (FORMAT:match('latex') or FORMAT:match('pdf')) end
local function is_docx() return FORMAT and FORMAT:match('docx') end
local function trim(s) return (s or ''):gsub('^%s+',''):gsub('%s+$','') end
local function stringify(x)
  if x==nil then return '' end
  local ok,res=pcall(pandoc.utils.stringify,x)
  return ok and res or tostring(x)
end

local function latex_escape(s)
  s=tostring(s or '')
  local map={
    ['\\']='\\textbackslash{}', ['{']='\\{', ['}']='\\}', ['#']='\\#',
    ['$']='\\$', ['%']='\\%', ['&']='\\&', ['_']='\\_', ['^']='\\textasciicircum{}',
    ['~']='\\textasciitilde{}'
  }
  return (s:gsub('[\\{}#$%%&_%^~]',map))
end

local function xml_escape(s)
  return tostring(s or ''):gsub('&','&amp;'):gsub('<','&lt;'):gsub('>','&gt;'):gsub('"','&quot;'):gsub("'",'&apos;')
end

local function latex_blocks(blocks)
  local ok,res=pcall(pandoc.write,pandoc.Pandoc(blocks or {}),'latex')
  if not ok then return '' end
  return trim(res)
end

local function latex_inlines(inlines)
  return latex_blocks({pandoc.Plain(inlines or {})})
end

local function first_list(blocks)
  for _,b in ipairs(blocks or {}) do
    if b.t=='OrderedList' or b.t=='BulletList' then return b end
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- Steps / circle list
-- ---------------------------------------------------------------------------
local function extract_step(item)
  local title=pandoc.List()
  local body=pandoc.List()
  local first=true
  for _,block in ipairs(item or {}) do
    if first and (block.t=='Plain' or block.t=='Para') then
      local found=false
      for _,inline in ipairs(block.content) do
        if inline.t=='Span' and has_class(inline,'semantic-step-title') then
          for _,x in ipairs(inline.content) do title:insert(x) end
          found=true
        end
      end
      if found then first=false else body:insert(block); first=false end
    else
      body:insert(block)
      first=false
    end
  end
  return title,body
end

local function render_steps_latex(el)
  local list=first_list(el.content)
  if not list then return el end
  local mode=has_class(el,'semantic-steps-dots') and 'dots' or 'numbered'
  local out={'\\begin{qscsteps}'}
  for i,item in ipairs(list.content) do
    local title,body=extract_step(item)
    local title_tex=latex_inlines(title)
    local body_tex=latex_blocks(body)
    local node='qscstep'..tostring(i)
    if mode=='dots' then
      out[#out+1]=string.format('\\item[{\\tikz[remember picture,baseline=(%s.base)]\\node[qsc step dot] (%s) {};}]',node,node)
    else
      out[#out+1]=string.format('\\item[{\\tikz[remember picture,baseline=(%s.base)]\\node[qsc step number] (%s) {%d};}]',node,node,i)
    end
    if i>1 then
      out[#out+1]=string.format('\\tikz[remember picture,overlay]\\draw[qsc step edge] (qscstep%d.south) -- (%s.north);',i-1,node)
    end
    out[#out+1]='\\textbf{'..title_tex..'}\\par\\smallskip'
    if body_tex~='' then out[#out+1]=body_tex end
  end
  out[#out+1]='\\end{qscsteps}'
  return pandoc.RawBlock('latex',table.concat(out,'\n'))
end

local function render_circle_latex(el)
  local list=first_list(el.content)
  if not list then return el end
  local out={'\\begin{enumerate}[label=\\qscCircleNumber{\\arabic*},leftmargin=3em,itemsep=.45em]'}
  for _,item in ipairs(list.content) do out[#out+1]='\\item '..latex_blocks(item) end
  out[#out+1]='\\end{enumerate}'
  return pandoc.RawBlock('latex',table.concat(out,'\n'))
end

-- ---------------------------------------------------------------------------
-- Generic tree / file tree
-- ---------------------------------------------------------------------------
local function row_inlines(item,row_class)
  for _,block in ipairs(item or {}) do
    if block.t=='Plain' or block.t=='Para' then
      for _,inline in ipairs(block.content) do
        if inline.t=='Span' and has_class(inline,row_class) then return inline.content,inline end
      end
      return block.content,nil
    end
  end
  return pandoc.List(),nil
end

local function nested_list(item)
  for _,block in ipairs(item or {}) do
    if block.t=='BulletList' or block.t=='OrderedList' then return block end
  end
  return nil
end

local function forest_node(item)
  local inlines=row_inlines(item,'tree-row')
  local label=latex_escape(stringify(inlines)):gsub('%[','{[}'):gsub('%]','{]}')
  local kids=nested_list(item)
  local chunks={'['..label}
  if kids then for _,child in ipairs(kids.content) do chunks[#chunks+1]=forest_node(child) end end
  chunks[#chunks+1]=']'
  return table.concat(chunks,' ')
end

local function render_tree_latex(el)
  local list=first_list(el.content)
  if not list then return el end
  local nodes={}
  for _,item in ipairs(list.content) do nodes[#nodes+1]=forest_node(item) end
  return pandoc.RawBlock('latex','\\begin{center}\n\\begin{forest}\nqsc tree\n'..table.concat(nodes,'\n')..'\n\\end{forest}\n\\end{center}')
end

local function file_row_parts(item)
  local content,span=row_inlines(item,'file-tree-row')
  return stringify(content),span
end

local function flatten_file_tree(list,depth,out)
  for _,item in ipairs(list.content or {}) do
    local label,span=file_row_parts(item)
    local folder=span and has_class(span,'file-tree-folder') or nested_list(item)~=nil
    local code=span and has_class(span,'file-tree-code-label')
    local text=latex_escape(label)
    if code then text='\\texttt{'..text..'}' elseif folder then text='\\textbf{'..text..'}' end
    out[#out+1]=string.format('.%d %s.',depth,text)
    local nested=nested_list(item)
    if nested then flatten_file_tree(nested,depth+1,out) end
  end
end

local function render_file_tree_latex(el)
  local list=first_list(el.content)
  if not list then return el end
  local lines={}
  flatten_file_tree(list,1,lines)
  return pandoc.RawBlock('latex','\\begin{qscfiletree}\n\\dirtree{%\n'..table.concat(lines,'\n')..'\n}\n\\end{qscfiletree}')
end

-- ---------------------------------------------------------------------------
-- Git tree
-- ---------------------------------------------------------------------------
local function git_parse_row(item,depth)
  local content=row_inlines(item,'git-tree-row')
  local row={depth=depth,ref='commit',message='',tag='',head=false}
  for _,inline in ipairs(content or {}) do
    if inline.t=='Span' and has_class(inline,'git-tree-ref') then row.ref=stringify(inline.content)
    elseif inline.t=='Span' and has_class(inline,'git-tree-message') then row.message=stringify(inline.content)
    elseif inline.t=='Span' and has_class(inline,'git-tree-tag') then row.tag=stringify(inline.content)
    elseif inline.t=='Span' and has_class(inline,'git-tree-head') then row.head=true end
  end
  if row.ref=='commit' and row.message=='' then
    local raw=stringify(content)
    row.ref,row.message=raw:match('^(%S+)%s*(.*)$')
  end
  return row
end

local function collect_git(list,depth,rows)
  for _,item in ipairs(list.content or {}) do
    rows[#rows+1]=git_parse_row(item,depth)
    local nested=nested_list(item)
    if nested then collect_git(nested,depth+1,rows) end
  end
end

local function infer_git_parents(rows)
  local active={}
  local max_depth=0
  for i,row in ipairs(rows) do
    row.index=i
    if row.depth>max_depth then max_depth=row.depth end
    local d=row.depth
    local parents={}
    if i>1 then
      local pd=rows[i-1].depth
      if d>pd then parents[#parents+1]=i-1
      elseif d==pd then parents[#parents+1]=active[d] or (i-1)
      else
        if active[d] then parents[#parents+1]=active[d] end
        for level=d+1,pd do if active[level] then parents[#parents+1]=active[level] end end
        if #parents==0 then parents[#parents+1]=i-1 end
        for level=d+1,max_depth do active[level]=nil end
      end
    end
    row.parents=parents
    active[d]=i
  end
  return max_depth
end

local function git_rows(el)
  local list=first_list(el.content)
  if not list then return {},0 end
  local rows={}
  collect_git(list,0,rows)
  return rows,infer_git_parents(rows)
end

local function render_git_latex(el)
  local rows=git_rows(el)
  if #rows==0 then return el end
  local direction=(el.attributes and el.attributes['data-git-direction']) or 'TB'
  local out={'\\begin{center}','\\begin{tikzpicture}[qsc git]'}
  local n=#rows
  local function y(i) if direction=='BT' then return -(n-i)*0.72 else return -(i-1)*0.72 end end
  for i,row in ipairs(rows) do out[#out+1]=string.format('\\coordinate (qscg%d) at (%.3f,%.3f);',i,row.depth*0.48,y(i)) end
  for i,row in ipairs(rows) do
    for _,p in ipairs(row.parents or {}) do out[#out+1]=string.format('\\draw[qsc git edge] (qscg%d) to[out=-90,in=90] (qscg%d);',p,i) end
  end
  for i,row in ipairs(rows) do
    out[#out+1]=string.format('\\node[qsc git node] at (qscg%d) {};',i)
    local refs='\\qscgitref{'..latex_escape(row.ref)..'}'
    if row.head then refs=refs..' \\qscgittag{HEAD}' end
    if row.tag~='' then refs=refs..' \\qscgittag{'..latex_escape(row.tag)..'}' end
    local msg=row.message~='' and (' '..latex_escape(row.message)) or ''
    out[#out+1]=string.format('\\node[anchor=west,qsc git text] at ([xshift=7pt]qscg%d) {%s%s};',i,refs,msg)
  end
  out[#out+1]='\\end{tikzpicture}'
  out[#out+1]='\\end{center}'
  return pandoc.RawBlock('latex',table.concat(out,'\n'))
end

-- ---------------------------------------------------------------------------
-- DOCX figures for geometry-heavy components
-- ---------------------------------------------------------------------------
local generated_counter=0
local function ensure_generated_dir()
  local dir='_qsc_generated'
  if pandoc.system and pandoc.system.make_directory then pcall(pandoc.system.make_directory,dir,true)
  else os.execute('mkdir -p '..dir) end
  return dir
end

local function write_text(path,text)
  local f=assert(io.open(path,'w')); f:write(text); f:close()
end

local function figure_image(svg,prefix,alt)
  generated_counter=generated_counter+1
  local dir=ensure_generated_dir()
  local svg_path=string.format('%s/%s-%02d.svg',dir,prefix,generated_counter)
  write_text(svg_path,svg)
  local target=svg_path
  local png_path=svg_path:gsub('%.svg$','.png')
  local ok=false
  if pandoc.pipe then
    ok=pcall(pandoc.pipe,'rsvg-convert',{'-o',png_path,svg_path},'')
    if not ok then ok=pcall(pandoc.pipe,'inkscape',{'--export-type=png','--export-filename='..png_path,svg_path},'') end
  end
  if ok then local f=io.open(png_path,'rb'); if f then f:close(); target=png_path end end
  return pandoc.Image({pandoc.Str(alt or 'Semantic component')},target,'',pandoc.Attr('',{}, {width='95%'}))
end

local function wrap_text(text,maxchars)
  text=tostring(text or ''):gsub('%s+',' '):gsub('^%s+',''):gsub('%s+$','')
  if #text<=maxchars then return {text} end
  local lines,cur={},''
  for word in text:gmatch('%S+') do
    if cur=='' then cur=word
    elseif #cur+1+#word<=maxchars then cur=cur..' '..word
    else lines[#lines+1]=cur; cur=word end
  end
  if cur~='' then lines[#lines+1]=cur end
  return lines
end

local function render_steps_docx(el)
  local list=first_list(el.content)
  if not list then return el end
  local mode=has_class(el,'semantic-steps-dots') and 'dots' or 'numbered'
  local rows={}
  for i,item in ipairs(list.content) do
    local title,body=extract_step(item)
    rows[#rows+1]={title=stringify(title),body=stringify(body),index=i}
  end
  local rowh=78; local width=980; local height=math.max(95,#rows*rowh+18); local node_x=30; local text_x=72
  local svg={string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">',width,height,width,height),'<rect width="100%" height="100%" fill="white"/>'}
  if #rows>1 then svg[#svg+1]=string.format('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#9aa0a6" stroke-width="2"/>',node_x,28,node_x,28+(#rows-1)*rowh) end
  for i,row in ipairs(rows) do
    local cy=28+(i-1)*rowh
    if mode=='dots' then svg[#svg+1]=string.format('<circle cx="%d" cy="%d" r="7" fill="white" stroke="#9aa0a6" stroke-width="2"/>',node_x,cy)
    else
      svg[#svg+1]=string.format('<circle cx="%d" cy="%d" r="17" fill="white" stroke="#9aa0a6" stroke-width="2"/>',node_x,cy)
      svg[#svg+1]=string.format('<text x="%d" y="%d" text-anchor="middle" dominant-baseline="middle" font-family="DejaVu Sans,sans-serif" font-size="13" font-weight="700" fill="#374151">%d</text>',node_x,cy+1,i)
    end
    svg[#svg+1]=string.format('<text x="%d" y="%d" font-family="DejaVu Sans,sans-serif" font-size="16" font-weight="700" fill="#24292f">%s</text>',text_x,cy-7,xml_escape(row.title))
    local lines=wrap_text(row.body,92)
    for j,line in ipairs(lines) do if j<=2 then svg[#svg+1]=string.format('<text x="%d" y="%d" font-family="DejaVu Sans,sans-serif" font-size="14" fill="#374151">%s</text>',text_x,cy+17+(j-1)*18,xml_escape(line)) end end
  end
  svg[#svg+1]='</svg>'
  return pandoc.Para({figure_image(table.concat(svg,'\n'),'steps','Steps')})
end

local function collect_hierarchy(list,depth,parent,rows,rowclass)
  for _,item in ipairs(list.content or {}) do
    local content,span=row_inlines(item,rowclass)
    local idx=#rows+1
    rows[idx]={label=stringify(content),depth=depth,parent=parent,span=span,item=item}
    local nested=nested_list(item)
    if nested then collect_hierarchy(nested,depth+1,idx,rows,rowclass) end
  end
end

local function hierarchy_svg(el,rowclass,kind)
  local list=first_list(el.content); if not list then return nil end
  local rows={}; collect_hierarchy(list,0,nil,rows,rowclass)
  local rowh=34; local lane=31; local pad=24; local width=980; local height=math.max(70,#rows*rowh+20)
  local function x(r) return pad+r.depth*lane end
  local function y(i) return 20+(i-1)*rowh end
  local svg={string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">',width,height,width,height),'<rect width="100%" height="100%" fill="white"/>','<g fill="none" stroke="#c2c8d0" stroke-width="1.5" stroke-linecap="round">'}
  for i,row in ipairs(rows) do if row.parent then local p=rows[row.parent]; local x1,y1=x(p),y(row.parent); local x2,y2=x(row),y(i); local mid=x1+lane/2; svg[#svg+1]=string.format('<path d="M %.1f %.1f H %.1f V %.1f H %.1f"/>',x1,y1,mid,y2,x2,y2) end end
  svg[#svg+1]='</g>'
  for i,row in ipairs(rows) do
    local nx,ny=x(row),y(i)
    if kind=='file' then
      local folder=row.span and has_class(row.span,'file-tree-folder') or nested_list(row.item)~=nil
      local lower=row.label:lower()
      if lower:match('schema%.sql') then
        svg[#svg+1]=string.format('<ellipse cx="%.1f" cy="%.1f" rx="8" ry="3.5" fill="#60a5fa"/><path d="M %.1f %.1f v 11 c0 2 16 2 16 0 v -11" fill="#93c5fd" stroke="#2563eb" stroke-width="1"/>',nx,ny-5,nx-8,ny-5)
      elseif folder then svg[#svg+1]=string.format('<path d="M %.1f %.1f h 7 l 3 4 h 14 v 14 h -24 z" fill="#fbbf24" stroke="#d97706" stroke-width="1"/>',nx-7,ny-9)
      else svg[#svg+1]=string.format('<path d="M %.1f %.1f h 13 l 5 5 v 14 h -18 z" fill="#f8fafc" stroke="#94a3b8" stroke-width="1"/>',nx-6,ny-9) end
      svg[#svg+1]=string.format('<text x="%.1f" y="%.1f" font-family="DejaVu Sans Mono,monospace" font-size="13" fill="#24292f">%s</text>',nx+25,ny+4,xml_escape(row.label))
    else
      svg[#svg+1]=string.format('<circle cx="%.1f" cy="%.1f" r="4.5" fill="white" stroke="#64748b" stroke-width="1.5"/>',nx,ny)
      svg[#svg+1]=string.format('<text x="%.1f" y="%.1f" font-family="DejaVu Sans,sans-serif" font-size="14" fill="#24292f">%s</text>',nx+13,ny+4,xml_escape(row.label))
    end
  end
  svg[#svg+1]='</svg>'
  return table.concat(svg,'\n')
end

local function render_tree_docx(el)
  local svg=hierarchy_svg(el,'tree-row','tree'); if not svg then return el end
  return pandoc.Para({figure_image(svg,'tree','Hierarchy tree')})
end
local function render_file_tree_docx(el)
  local svg=hierarchy_svg(el,'file-tree-row','file'); if not svg then return el end
  return pandoc.Para({figure_image(svg,'file-tree','File tree')})
end

local function render_circle_docx(el)
  local list=first_list(el.content); if not list then return el end
  local width=900; local rowh=42; local height=#list.content*rowh+18
  local svg={string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">',width,height,width,height),'<rect width="100%" height="100%" fill="white"/>'}
  for i,item in ipairs(list.content) do local cy=22+(i-1)*rowh; svg[#svg+1]=string.format('<circle cx="24" cy="%d" r="13" fill="white" stroke="#64748b" stroke-width="1.5"/>',cy); svg[#svg+1]=string.format('<text x="24" y="%d" text-anchor="middle" dominant-baseline="middle" font-family="DejaVu Sans,sans-serif" font-size="11" font-weight="700" fill="#374151">%d</text>',cy+1,i); svg[#svg+1]=string.format('<text x="50" y="%d" font-family="DejaVu Sans,sans-serif" font-size="14" fill="#24292f">%s</text>',cy+5,xml_escape(stringify(item))) end
  svg[#svg+1]='</svg>'
  return pandoc.Para({figure_image(table.concat(svg,'\n'),'circle-list','Circled ordered list')})
end

local function render_git_docx(el)
  local rows=git_rows(el); if #rows==0 then return el end
  local rowh=38; local lane=28; local width=980; local height=math.max(80,#rows*rowh+24); local pad=22
  local function x(row) return pad+row.depth*lane end
  local function y(i) return 22+(i-1)*rowh end
  local direction=(el.attributes and el.attributes['data-git-direction']) or 'TB'
  if direction=='BT' then y=function(i) return 22+(#rows-i)*rowh end end
  local svg={string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">',width,height,width,height),'<rect width="100%" height="100%" fill="white"/>','<g fill="none" stroke="#9aa0a6" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'}
  for i,row in ipairs(rows) do for _,p in ipairs(row.parents or {}) do local x1,y1=x(rows[p]),y(p); local x2,y2=x(row),y(i); if math.abs(x1-x2)<0.1 then svg[#svg+1]=string.format('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f"/>',x1,y1,x2,y2) else local mid=(y1+y2)/2; svg[#svg+1]=string.format('<path d="M %.1f %.1f C %.1f %.1f, %.1f %.1f, %.1f %.1f"/>',x1,y1,x1,mid,x2,mid,x2,y2) end end end
  svg[#svg+1]='</g>'
  for i,row in ipairs(rows) do
    local nx,ny=x(row),y(i); svg[#svg+1]=string.format('<circle cx="%.1f" cy="%.1f" r="5.5" fill="white" stroke="#30363d" stroke-width="2"/>',nx,ny)
    local tx=nx+14; local refw=math.max(42,#row.ref*7+16); svg[#svg+1]=string.format('<rect x="%.1f" y="%.1f" width="%.1f" height="22" rx="11" fill="#f3f4f6" stroke="#d1d5db"/>',tx,ny-11,refw); svg[#svg+1]=string.format('<text x="%.1f" y="%.1f" font-family="DejaVu Sans Mono,monospace" font-size="13" font-weight="600" fill="#24292f">%s</text>',tx+8,ny+4.5,xml_escape(row.ref)); local mx=tx+refw+9
    if row.head then svg[#svg+1]=string.format('<text x="%.1f" y="%.1f" font-family="DejaVu Sans,sans-serif" font-size="11" font-weight="700" fill="#7c3aed">HEAD</text>',mx,ny+4); mx=mx+38 end
    if row.tag~='' then svg[#svg+1]=string.format('<text x="%.1f" y="%.1f" font-family="DejaVu Sans,sans-serif" font-size="11" font-weight="700" fill="#0f766e">%s</text>',mx,ny+4,xml_escape(row.tag)); mx=mx+#row.tag*7+12 end
    svg[#svg+1]=string.format('<text x="%.1f" y="%.1f" font-family="DejaVu Sans Mono,monospace" font-size="13" fill="#24292f">%s</text>',mx,ny+4.5,xml_escape(row.message))
  end
  svg[#svg+1]='</svg>'
  return pandoc.Para({figure_image(table.concat(svg,'\n'),'git-tree','Git commit graph')})
end

-- ---------------------------------------------------------------------------
-- Properties / article / badge
-- ---------------------------------------------------------------------------
local function render_properties_latex(el)
  local def
  for _,b in ipairs(el.content or {}) do if b.t=='DefinitionList' then def=b break end end
  if not def then return el end
  local rows={'\\begin{qscproperties}'}
  for _,item in ipairs(def.content) do
    local value_blocks=pandoc.List()
    for _,definition in ipairs(item[2] or {}) do for _,block in ipairs(definition) do value_blocks:insert(block) end end
    rows[#rows+1]=latex_inlines(item[1])..' & '..latex_blocks(value_blocks)..' \\\\'
  end
  rows[#rows+1]='\\end{qscproperties}'
  return pandoc.RawBlock('latex',table.concat(rows,'\n'))
end

local function render_article_latex(el)
  local accent=has_class(el,'article-accent-left')
  local accent_color='qscAccent'
  local style=(el.attributes and el.attributes.style) or ''; local lower=style:lower()
  if lower:find('warning',1,true) then accent_color='qscWarning'
  elseif lower:find('danger',1,true) or lower:find('caution',1,true) then accent_color='qscDanger'
  elseif lower:find('success',1,true) or lower:find('tip',1,true) then accent_color='qscSuccess'
  elseif lower:find('note',1,true) or lower:find('info',1,true) then accent_color='qscInfo' end
  local west=accent and ('borderline west={3pt}{0pt}{'..accent_color..'},') or ''
  return pandoc.RawBlock('latex','\\begin{tcolorbox}[qsc article,'..west..']\n'..latex_blocks(el.content)..'\n\\end{tcolorbox}')
end

local function badge_variant(span)
  local variants={neutral=true,info=true,success=true,warning=true,danger=true,accent=true}
  for _,c in ipairs(span.classes or {}) do local v=c:match('^qsc%-badge%-(.+)$'); if v and variants[v] then return v end end
  return 'neutral'
end
local function render_badge_latex(span) return pandoc.RawInline('latex','\\qscbadge{'..badge_variant(span)..'}{'..latex_inlines(span.content)..'}') end

-- ---------------------------------------------------------------------------
-- Dispatcher
-- ---------------------------------------------------------------------------
function Div(el)
  if is_latex() then
    if has_class(el,'semantic-steps') then return render_steps_latex(el) end
    if has_class(el,'semantic-circle-list') then return render_circle_latex(el) end
    if has_class(el,'semantic-tree') then return render_tree_latex(el) end
    if has_class(el,'semantic-file-tree') then return render_file_tree_latex(el) end
    if has_class(el,'semantic-git-tree') then return render_git_latex(el) end
    if has_class(el,'semantic-properties') then return render_properties_latex(el) end
    if has_class(el,'semantic-article') then return render_article_latex(el) end
  elseif is_docx() then
    if has_class(el,'semantic-git-tree') then return render_git_docx(el) end
    if has_class(el,'semantic-steps') then return render_steps_docx(el) end
    if has_class(el,'semantic-circle-list') then return render_circle_docx(el) end
    if has_class(el,'semantic-tree') then return render_tree_docx(el) end
    if has_class(el,'semantic-file-tree') then return render_file_tree_docx(el) end
    if has_class(el,'semantic-article') then el.attributes=el.attributes or {}; el.attributes['custom-style']='Semantic Article'; return el end
    if has_class(el,'semantic-properties') then el.attributes=el.attributes or {}; el.attributes['custom-style']='Properties'; return el end
  end
end

function Span(el)
  if has_class(el,'qsc-badge') then
    if is_latex() then return render_badge_latex(el) end
    if is_docx() then el.attributes=el.attributes or {}; el.attributes['custom-style']='Badge'; return el end
  end
end
