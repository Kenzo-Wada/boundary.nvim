local M = {}

local unpack = table.unpack or unpack
local path_sep = package.config:sub(1, 1)

local function filter_empty(parts)
  local filtered = {}
  for _, part in ipairs(parts) do
    if part and part ~= "" then
      filtered[#filtered + 1] = part
    end
  end
  return filtered
end

function M.trim(value)
  if vim.trim then
    return vim.trim(value)
  end
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.tbl_is_empty(value)
  if value == nil then
    return true
  end
  if vim.tbl_isempty then
    return vim.tbl_isempty(value)
  end
  return next(value) == nil
end

function M.join_paths(...)
  local parts = filter_empty { ... }
  if #parts == 0 then
    return ""
  end
  if vim.fs and vim.fs.joinpath then
    return vim.fs.joinpath(unpack(parts))
  end
  return table.concat(parts, path_sep)
end

function M.is_absolute(path)
  if not path or path == "" then
    return false
  end
  if path_sep == "\\" then
    return path:match "^%a:[\\/]" ~= nil or path:match "^[\\/]" ~= nil
  end
  return path:sub(1, 1) == "/"
end

function M.normalize_path(path)
  if vim.fs and vim.fs.normalize then
    return vim.fs.normalize(path)
  end
  return vim.fn.fnamemodify(path, ":p")
end

function M.dirname(path)
  if not path or path == "" then
    return nil
  end
  if vim.fs and vim.fs.dirname then
    return vim.fs.dirname(path)
  end
  local parent = vim.fn.fnamemodify(path, ":h")
  if parent == path then
    return nil
  end
  return parent
end

function M.find_project_root(start_dir, patterns)
  if not (vim.fs and vim.fs.find) then
    return nil
  end
  local found = vim.fs.find(patterns, { path = start_dir, upward = true })
  if #found == 0 then
    return nil
  end
  return vim.fs.dirname(found[1])
end

return M
