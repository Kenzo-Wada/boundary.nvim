local uv = vim.loop

local directives = require "boundary.directives"
local util = require "boundary.util"

local M = {}

local function has_extension(import_path)
  return import_path:match "%.[^/]+$" ~= nil
end

local function resolve_alias(conf, base_dir, import_path)
  if util.tbl_is_empty(conf.aliases) then
    return {}
  end

  for alias, target in pairs(conf.aliases) do
    if import_path:sub(1, #alias) == alias then
      local remainder = import_path:sub(#alias + 1)
      remainder = remainder:gsub("^/", "")
      local target_path = target or ""
      if target_path == "." then
        target_path = ""
      end
      target_path = target_path:gsub("^%./", "")

      local candidates = {}
      local added = {}
      local function push(path)
        if not path or path == "" then
          return
        end
        local combined = util.join_paths(path, remainder)
        if combined ~= "" then
          local normalized = util.normalize_path(combined)
          if not added[normalized] then
            candidates[#candidates + 1] = normalized
            added[normalized] = true
          end
        end
      end

      if util.is_absolute(target_path) then
        push(target_path)
      else
        local project_root = util.find_project_root(base_dir, conf.root_patterns)
        if project_root then
          push(util.join_paths(project_root, target_path))
        end

        local cwd = uv.cwd()
        if cwd and cwd ~= "" then
          push(util.join_paths(cwd, target_path))
        end

        push(util.join_paths(base_dir, target_path))
      end

      return candidates
    end
  end

  return {}
end

function M.resolve_import_paths(conf, base_dir, import_path)
  local base_paths = {}
  if import_path:match "^%." then
    local base_path = vim.fn.fnamemodify(base_dir .. "/" .. import_path, ":p")
    if base_path and base_path ~= "" then
      base_paths[1] = util.normalize_path(base_path)
    end
  else
    base_paths = resolve_alias(conf, base_dir, import_path)
  end

  if util.tbl_is_empty(base_paths) then
    return {}
  end

  local resolved = {}
  local added = {}

  local function add(path)
    if path and not added[path] then
      local stat = uv.fs_stat(path)
      if stat and stat.type == "file" then
        resolved[#resolved + 1] = path
        added[path] = true
      end
    end
  end

  for _, base_path in ipairs(base_paths) do
    add(base_path)

    if not has_extension(import_path) then
      for _, ext in ipairs(conf.search_extensions) do
        add(base_path .. ext)
      end

      local stat = uv.fs_stat(base_path)
      if stat and stat.type == "directory" then
        for _, ext in ipairs(conf.search_extensions) do
          add(util.join_paths(base_path, "index" .. ext))
        end
      end
    end
  end

  return resolved
end

function M.gather_import_statements(lines)
  local statements = {}
  local current
  for _, line in ipairs(lines) do
    if current then
      current = current .. " " .. line
    elseif line:match "^%s*import%s" then
      current = line
    end

    if current then
      if current:match "^%s*import%s+['\"][^'\"]+['\"]" then
        statements[#statements + 1] = current
        current = nil
      elseif current:match "from%s+['\"][^'\"]+['\"]" then
        statements[#statements + 1] = current
        current = nil
      end
    end
  end
  return statements
end

local function split_named_specifiers(body)
  local specifiers = {}
  for chunk in body:gmatch "[^,]+" do
    local trimmed = util.trim(chunk)
    if trimmed ~= "" and not trimmed:match "^type%s+" then
      local alias = trimmed:match "^.-%s+as%s+(.-)$"
      if alias then
        specifiers[#specifiers + 1] = util.trim(alias)
      else
        specifiers[#specifiers + 1] = util.trim(trimmed)
      end
    end
  end
  return specifiers
end

function M.parse_statement(statement)
  if statement:match "^%s*import%s+type%s" then
    return nil, {}
  end

  local source = statement:match "from%s+['\"](.-)['\"]"
  if not source then
    return nil, {}
  end

  local clause = statement:match "^%s*import%s+(.-)%s+from%s+['\"][^'\"]+['\"]" or ""
  clause = clause:gsub("^type%s+", "")
  clause = util.trim(clause)

  if clause == "" then
    return source, {}
  end

  local specifiers = {}

  local default_name, named_body = clause:match "^([%w_$.]+)%s*,%s*{(.-)}$"
  if default_name then
    specifiers[#specifiers + 1] = default_name
    for _, name in ipairs(split_named_specifiers(named_body)) do
      specifiers[#specifiers + 1] = name
    end
    return source, specifiers
  end

  local named_only = clause:match "^{(.-)}$"
  if named_only then
    for _, name in ipairs(split_named_specifiers(named_only)) do
      specifiers[#specifiers + 1] = name
    end
    return source, specifiers
  end

  local namespace = clause:match "^%*%s+as%s+([%w_$.]+)$"
  if namespace then
    return source, {}
  end

  specifiers[#specifiers + 1] = clause
  return source, specifiers
end

function M.collect_client_components(conf, bufnr, lines)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return {}
  end

  local base_dir = vim.fn.fnamemodify(name, ":h")
  lines = lines or vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local statements = M.gather_import_statements(lines)
  local components = {}

  for _, statement in ipairs(statements) do
    local source, specifiers = M.parse_statement(statement)
    if source and #specifiers > 0 then
      for _, file_path in ipairs(M.resolve_import_paths(conf, base_dir, source)) do
        if directives.file_has_directive(conf, file_path) then
          for _, spec in ipairs(specifiers) do
            components[spec] = true
          end
          break
        end
      end
    end
  end

  return components
end

return M
