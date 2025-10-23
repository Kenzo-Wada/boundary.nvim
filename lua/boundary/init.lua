local aliases = require "boundary.aliases"
local config = require "boundary.config"
local directives = require "boundary.directives"
local imports = require "boundary.imports"
local markers = require "boundary.markers"
local util = require "boundary.util"

local namespace = vim.api.nvim_create_namespace "boundary.use_client_markers"

local M = {
  config = config.defaults(),
  namespace = namespace,
}

local command_created = false
local augroup_id
local hover_augroup_id
local hover_lines_by_buf = {}

local function filetype_supported(conf, bufnr)
  local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  for _, allowed in ipairs(conf.filetypes) do
    if ft == allowed then
      return true
    end
  end
  return false
end

local function ensure_command()
  if command_created then
    return
  end

  vim.api.nvim_create_user_command("BoundaryRefresh", function(opts)
    local bufnr = opts.buf or vim.api.nvim_get_current_buf()
    M.refresh(bufnr)
  end, {
    desc = "Refresh 'use client' markers in the current buffer.",
    bang = false,
  })

  command_created = true
end

local function clear_autocmd()
  if augroup_id then
    pcall(vim.api.nvim_del_augroup_by_id, augroup_id)
    augroup_id = nil
  end
end

local function create_autocmd()
  clear_autocmd()
  if not M.config.auto then
    return
  end

  augroup_id = vim.api.nvim_create_augroup("BoundaryMarkers", { clear = true })
  vim.api.nvim_create_autocmd(M.config.events, {
    group = augroup_id,
    pattern = "*",
    callback = function(args)
      if filetype_supported(M.config, args.buf) then
        M.refresh(args.buf)
      else
        markers.clear(args.buf, namespace)
        hover_lines_by_buf[args.buf] = nil
      end
    end,
  })
end

local function clear_hover_autocmd()
  if hover_augroup_id then
    pcall(vim.api.nvim_del_augroup_by_id, hover_augroup_id)
    hover_augroup_id = nil
  end
end

local function set_hover_lines(bufnr, lines)
  if not lines or #lines == 0 then
    hover_lines_by_buf[bufnr] = nil
    return
  end

  local set = {}
  for _, line in ipairs(lines) do
    set[line] = true
  end
  hover_lines_by_buf[bufnr] = set
end

local function update_hover(bufnr)
  if not M.config.hover_only then
    return
  end

  if not filetype_supported(M.config, bufnr) then
    markers.clear(bufnr, namespace)
    hover_lines_by_buf[bufnr] = nil
    return
  end

  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(win) ~= bufnr then
    return
  end

  local hover_lines = hover_lines_by_buf[bufnr]
  markers.clear(bufnr, namespace)
  if not hover_lines then
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(win)
  local line = cursor[1] - 1
  if hover_lines[line] then
    markers.set(bufnr, namespace, M.config, line)
  end
end

local function ensure_hover_autocmd()
  clear_hover_autocmd()

  if not M.config.hover_only then
    for bufnr in pairs(hover_lines_by_buf) do
      markers.clear(bufnr, namespace)
    end
    hover_lines_by_buf = {}
    return
  end

  hover_augroup_id = vim.api.nvim_create_augroup("BoundaryMarkersHover", { clear = true })
  for _, event in ipairs { "CursorMoved", "CursorMovedI", "BufEnter" } do
    vim.api.nvim_create_autocmd(event, {
      group = hover_augroup_id,
      callback = function(args)
        update_hover(args.buf)
      end,
    })
  end

  vim.api.nvim_create_autocmd("BufLeave", {
    group = hover_augroup_id,
    callback = function(args)
      if vim.api.nvim_buf_is_valid(args.buf) then
        markers.clear(args.buf, namespace)
      end
    end,
  })
end

function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not filetype_supported(M.config, bufnr) then
    markers.clear(bufnr, namespace)
    hover_lines_by_buf[bufnr] = nil
    return {}
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local components = imports.collect_client_components(M.config, bufnr, lines)
  if util.tbl_is_empty(components) then
    markers.clear(bufnr, namespace)
    hover_lines_by_buf[bufnr] = nil
    return {}
  end

  local marks = markers.find_lines(lines, components)
  local applied = markers.apply(bufnr, namespace, M.config, marks)

  if M.config.hover_only then
    set_hover_lines(bufnr, applied)
    update_hover(bufnr)
  else
    hover_lines_by_buf[bufnr] = nil
  end

  return applied
end

function M.setup(opts)
  M.config = config.merge(opts)
  directives.reset()
  aliases.reset()
  config.ensure_highlight(M.config)
  ensure_command()
  create_autocmd()
  ensure_hover_autocmd()
  return M.config
end

function M.reset()
  clear_autocmd()
  clear_hover_autocmd()
  command_created = false
  directives.reset()
  aliases.reset()
  M.config = config.defaults()
  config.ensure_highlight(M.config)

  hover_lines_by_buf = {}

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    markers.clear(buf, namespace)
  end
end

return M
