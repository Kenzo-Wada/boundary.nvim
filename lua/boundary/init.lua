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
      end
    end,
  })
end

function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not filetype_supported(M.config, bufnr) then
    markers.clear(bufnr, namespace)
    return {}
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local components = imports.collect_client_components(M.config, bufnr, lines)
  if util.tbl_is_empty(components) then
    markers.clear(bufnr, namespace)
    return {}
  end

  local marks = markers.find_lines(lines, components)
  return markers.apply(bufnr, namespace, M.config, marks)
end

function M.setup(opts)
  M.config = config.merge(opts)
  directives.reset()
  config.ensure_highlight(M.config)
  ensure_command()
  create_autocmd()
  return M.config
end

function M.reset()
  clear_autocmd()
  command_created = false
  directives.reset()
  M.config = config.defaults()
  config.ensure_highlight(M.config)

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    markers.clear(buf, namespace)
  end
end

return M
