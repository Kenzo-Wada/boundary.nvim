return {
  name = "hover-only markers appear under cursor",
  files = {
    ["components/Button.tsx"] = [["use client"

export default function Button() {
  return <button>Button</button>
}
]],
    ["app/page.tsx"] = [[import Button from '../components/Button'

export default function Page() {
  return (
    <div>
      <Button />
    </div>
  )
}
]],
  },
  setup_opts = { auto = false, hover_only = true },
  expected_lines = { 5 },
  expected_extmark_count = 0,
  after_refresh = function(t, bufnr)
    local boundary = require "boundary"
    vim.api.nvim_win_set_buf(0, bufnr)
    vim.api.nvim_win_set_cursor(0, { 6, 0 })
    vim.api.nvim_exec_autocmds("CursorMoved", { buffer = bufnr })

    local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, boundary.namespace, 0, -1, {})
    t:eq(1, #extmarks, "hovering line should show a single extmark")
    t:eq(5, extmarks[1][2], "hover extmark should target expected line")

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.api.nvim_exec_autocmds("CursorMoved", { buffer = bufnr })
    extmarks = vim.api.nvim_buf_get_extmarks(bufnr, boundary.namespace, 0, -1, {})
    t:eq(0, #extmarks, "moving away should hide extmarks")
  end,
}
