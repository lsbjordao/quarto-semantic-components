-- Shared configuration resolver for Quarto Semantic Components.
--
-- Supported project metadata styles:
--
-- extensions:
--   badge:
--     - key: stable
--       type: success
--       appearance: solid
--
-- semantic-components:
--   steps:
--     dot-size: 0.8rem
--   badge:
--     defaults:
--       shape: pill
--     presets:
--       - key: stable
--         bg: springgreen

local M = {}

local component_aliases = {
  badge = { 'badge', 'badges' },
  steps = { 'steps' },
  ['file-tree'] = { 'file-tree', 'file_tree', 'filetree' },
  ['git-tree'] = { 'git-tree', 'git_tree', 'gittree' },
  ['circle-list'] = { 'circle-list', 'circle_list', 'circlelist' },
  tree = { 'tree' },
  properties = { 'properties', 'property-list', 'property_list' },
  article = { 'article' }
}

function M.text(value)
  if value == nil then return nil end
  if type(value) == 'string' then return value end
  return pandoc.utils.stringify(value)
end

local function aliases(name)
  return component_aliases[name] or { name }
end

local function child(map, names)
  if type(map) ~= 'table' then return nil end
  for _, name in ipairs(names) do
    if map[name] ~= nil then return map[name] end
  end
  return nil
end

-- Return config sources from highest to lowest priority.
function M.sources(meta, name)
  local out = {}
  local names = aliases(name)
  meta = meta or {}

  local scoped = meta['semantic-components'] or meta.semantic_components
  local value = child(scoped, names)
  if value ~= nil then out[#out + 1] = value end

  local extensions = meta.extensions
  if type(extensions) == 'table' then
    local extension_scope = extensions['semantic-components'] or extensions.semantic_components
    value = child(extension_scope, names)
    if value ~= nil then out[#out + 1] = value end

    value = child(extensions, names)
    if value ~= nil then out[#out + 1] = value end
  end

  return out
end

local function candidate(map, key, aliases_)
  if type(map) ~= 'table' then return nil end
  if map[key] ~= nil then return map[key] end
  for _, alias in ipairs(aliases_ or {}) do
    if map[alias] ~= nil then return map[alias] end
  end
  return nil
end

local function usable(value)
  if value == nil then return nil end
  local rendered = M.text(value)
  if rendered == nil or rendered == '' then return nil end
  return rendered
end

-- Resolve a component default. `defaults:` is preferred, but compact maps
-- (e.g. extensions.steps.dot-size) are accepted too.
function M.default(meta, name, key, aliases_)
  for _, source in ipairs(M.sources(meta, name)) do
    if type(source) == 'table' then
      if type(source.defaults) == 'table' then
        local value = candidate(source.defaults, key, aliases_)
        local rendered = usable(value)
        if rendered ~= nil then return rendered end
      end
      local value = candidate(source, key, aliases_)
      local rendered = usable(value)
      if rendered ~= nil and key ~= 'key' and key ~= 'presets' and key ~= 'defaults' then
        return rendered
      end
    end
  end
  return nil
end

local function preset_in_list(list, wanted)
  if type(list) ~= 'table' then return nil end
  for _, item in ipairs(list) do
    if type(item) == 'table' and M.text(item.key) == wanted then return item end
  end
  return nil
end

-- Resolve a named preset. Supports either a direct list or `presets:`.
function M.preset(meta, name, key)
  if not key or key == '' then return nil end
  for _, source in ipairs(M.sources(meta, name)) do
    if type(source) == 'table' then
      local found = preset_in_list(source, key)
      if found then return found end
      found = preset_in_list(source.presets, key)
      if found then return found end
      found = preset_in_list(source.items, key)
      if found then return found end
      if type(source[key]) == 'table' then return source[key] end
    end
  end
  return nil
end

function M.value(map, key, aliases_)
  return usable(candidate(map, key, aliases_))
end

-- Explicit values win over presets, presets over project defaults. Empty
-- shortcode kwargs are ignored so they do not accidentally mask preset fields.
function M.resolve(meta, component, explicit, preset, key, aliases_)
  local value = usable(candidate(explicit, key, aliases_))
  if value ~= nil then return value end
  value = usable(candidate(preset, key, aliases_))
  if value ~= nil then return value end
  return M.default(meta, component, key, aliases_)
end

function M.classes(value)
  local out = {}
  if value == nil then return out end
  if type(value) == 'table' then
    for _, item in ipairs(value) do
      local text = M.text(item)
      if text then for class in text:gmatch('%S+') do out[#out + 1] = class end end
    end
  else
    local text = M.text(value)
    if text then for class in text:gmatch('%S+') do out[#out + 1] = class end end
  end
  return out
end

return M
