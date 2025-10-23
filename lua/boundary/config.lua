local M = {}

local default_config = {
  marker_text = "'use client'",
  marker_hl_group = "BoundaryMarker",
  hover_only = false,
  directives = { "'use client'", '"use client"' },
  search_extensions = { ".tsx", ".ts", ".jsx", ".js" },
  aliases = {},
  root_patterns = {
    "package.json",
    "tsconfig.json",
    "jsconfig.json",
    ".git",
  },
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  },
  max_read_bytes = 4096,
  auto = true,
  events = {
    "BufEnter",
    "BufWritePost",
    "TextChanged",
    "InsertLeave",
  },
}

function M.defaults()
  return vim.deepcopy(default_config)
end

function M.merge(opts)
  return vim.tbl_deep_extend("force", M.defaults(), opts or {})
end

function M.ensure_highlight(conf)
  if conf.marker_hl_group == "BoundaryMarker" then
    vim.api.nvim_set_hl(0, conf.marker_hl_group, { default = true, link = "Comment" })
  end
end

return M
