local uv = vim.loop

local util = require "boundary.util"

local M = {}

local config_files = {
  "tsconfig.json",
  "tsconfig.base.json",
  "jsconfig.json",
}

local cache = {}

local function read_file(path)
  local fd = uv.fs_open(path, "r", 438)
  if not fd then
    return nil
  end

  local stat = uv.fs_fstat(fd)
  if not stat then
    uv.fs_close(fd)
    return nil
  end

  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  return data
end

local function decode_json(path)
  local contents = read_file(path)
  if not contents then
    return nil
  end

  local ok, decoded = pcall(vim.json.decode, contents)
  if not ok then
    return nil
  end

  return decoded
end

local function file_exists(path)
  local stat = uv.fs_stat(path)
  return stat ~= nil
end

local function normalize_alias(pattern)
  if pattern:sub(-2) == "/*" then
    return pattern:sub(1, -3) .. "/"
  end
  if pattern:sub(-1) == "*" then
    return pattern:sub(1, -2)
  end
  return pattern
end

local function normalize_target(pattern)
  if pattern:sub(-2) == "/*" then
    pattern = pattern:sub(1, -3)
  elseif pattern:sub(-1) == "*" then
    pattern = pattern:sub(1, -2)
  end
  pattern = pattern:gsub("^%.[/\\]", "")
  return pattern
end

local function resolve_extends(path, extends)
  if type(extends) ~= "string" or extends == "" then
    return nil
  end

  if util.is_absolute(extends) then
    if file_exists(extends) then
      return util.normalize_path(extends)
    end
    if not extends:match "%.json$" then
      local candidate = extends .. ".json"
      if file_exists(candidate) then
        return util.normalize_path(candidate)
      end
    end
    return nil
  end

  if not extends:match "[/\\]" and not extends:match "^%." then
    return nil
  end

  local dir = util.dirname(path)
  if not dir then
    return nil
  end

  local candidates = { util.join_paths(dir, extends) }
  if not extends:match "%.json$" then
    candidates[#candidates + 1] = util.join_paths(dir, extends .. ".json")
  end

  for _, candidate in ipairs(candidates) do
    if file_exists(candidate) then
      return util.normalize_path(candidate)
    end
  end

  return nil
end

local function resolve_base_url(path, value)
  if type(value) ~= "string" or value == "" then
    return nil
  end

  if util.is_absolute(value) then
    return util.normalize_path(value)
  end

  local dir = util.dirname(path)
  if not dir then
    return nil
  end

  return util.normalize_path(util.join_paths(dir, value))
end

local function merge_aliases(base, overrides)
  if not base or util.tbl_is_empty(base) then
    base = {}
  end

  if overrides then
    for alias, target in pairs(overrides) do
      base[alias] = target
    end
  end

  return base
end

local function collect_from_config(path, visited)
  visited = visited or {}
  if visited[path] then
    return { aliases = {}, base_url = nil }
  end
  visited[path] = true

  local data = decode_json(path)
  if not data then
    return { aliases = {}, base_url = nil }
  end

  local compiler_options = type(data.compilerOptions) == "table" and data.compilerOptions or {}

  local extends_aliases = {}
  local extends_base

  if data.extends then
    local resolved_extends = resolve_extends(path, data.extends)
    if resolved_extends then
      local extends_data = collect_from_config(resolved_extends, visited)
      extends_aliases = extends_data.aliases or {}
      extends_base = extends_data.base_url
    end
  end

  local base_url = resolve_base_url(path, compiler_options.baseUrl) or extends_base
  if not base_url then
    local dir = util.dirname(path)
    if dir then
      base_url = util.normalize_path(dir)
    end
  end

  local aliases = {}
  local paths = compiler_options.paths
  if type(paths) == "table" then
    for alias_pattern, targets in pairs(paths) do
      if type(targets) == "table" then
        local alias = normalize_alias(alias_pattern)
        for _, target in ipairs(targets) do
          if type(target) == "string" and target ~= "" then
            local normalized_target = normalize_target(target)
            local resolved
            if util.is_absolute(normalized_target) then
              resolved = util.normalize_path(normalized_target)
            else
              resolved = util.normalize_path(util.join_paths(base_url, normalized_target))
            end
            aliases[alias] = resolved
            break
          end
        end
      end
    end
  end

  local merged = merge_aliases(vim.deepcopy(extends_aliases), aliases)

  return { aliases = merged, base_url = base_url }
end

local function detect_aliases(project_root)
  if not project_root or project_root == "" then
    return {}
  end

  if cache[project_root] then
    return cache[project_root]
  end

  for _, name in ipairs(config_files) do
    local path = util.join_paths(project_root, name)
    if file_exists(path) then
      local detected = collect_from_config(path).aliases or {}
      cache[project_root] = detected
      return detected
    end
  end

  cache[project_root] = {}
  return cache[project_root]
end

function M.get_aliases(conf, base_dir)
  local manual = conf.aliases or {}
  local project_root = util.find_project_root(base_dir, conf.root_patterns)
  local detected = detect_aliases(project_root)

  local combined = {}
  for alias, target in pairs(detected) do
    combined[alias] = target
  end
  for alias, target in pairs(manual) do
    combined[alias] = target
  end

  return combined
end

function M.reset()
  cache = {}
end

return M
