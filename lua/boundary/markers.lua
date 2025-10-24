local util = require "boundary.util"

local M = {}

local function set_extmark(bufnr, namespace, conf, line)
  vim.api.nvim_buf_set_extmark(bufnr, namespace, line, 0, {
    virt_text = { { conf.marker_text, conf.marker_hl_group } },
    virt_text_pos = "eol",
  })
end

function M.clear(bufnr, namespace)
  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
end

function M.find_lines(lines, components)
  local marks = {}
  if util.tbl_is_empty(components) then
    return marks
  end

  local component_names = {}
  for name, value in pairs(components) do
    if name ~= "__namespaces" and value then
      component_names[#component_names + 1] = name
    end
  end

  local namespace_names = {}
  local namespaces = components.__namespaces
  if namespaces then
    for name, value in pairs(namespaces) do
      if value then
        namespace_names[#namespace_names + 1] = name
      end
    end
  end

  for line_idx, line in ipairs(lines) do
    local matched = false

    for _, name in ipairs(component_names) do
      local pattern = "<%s*" .. vim.pesc(name) .. "%f[^%w_]"
      if line:find(pattern) then
        marks[line_idx - 1] = true
        matched = true
        break
      end
    end

    if not matched then
      for _, namespace in ipairs(namespace_names) do
        local pattern = "<%s*" .. vim.pesc(namespace) .. "%.[%w_$.]+%f[^%w_$.]"
        if line:find(pattern) then
          marks[line_idx - 1] = true
          break
        end
      end
    end
  end

  return marks
end

function M.apply(bufnr, namespace, conf, marks)
  M.clear(bufnr, namespace)

  local lines = {}
  for line in pairs(marks) do
    lines[#lines + 1] = line
  end
  table.sort(lines)

  if conf.hover_only then
    return lines
  end

  for _, line in ipairs(lines) do
    set_extmark(bufnr, namespace, conf, line)
  end

  return lines
end

function M.set(bufnr, namespace, conf, line)
  set_extmark(bufnr, namespace, conf, line)
end

return M
