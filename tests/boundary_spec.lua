local Suite = require("boundary.test_suite")
local suite = Suite.new("boundary.markers")

local uv = vim.loop

local function join_paths(...)
	return table.concat({ ... }, "/")
end

local function mkdir_p(path)
	if not path or path == "" then
		return
	end
	vim.fn.mkdir(path, "p")
end

local function write_file(path, contents)
	local dir = path:match("(.+)/[^/]+$")
	if dir then
		mkdir_p(dir)
	end
	local fd = assert(io.open(path, "w"))
	fd:write(contents)
	fd:close()
end

local function rm_rf(path)
	local stat = uv.fs_stat(path)
	if not stat then
		return
	end
	if stat.type == "file" then
		uv.fs_unlink(path)
		return
	end
	for name in vim.fs.dir(path) do
		rm_rf(join_paths(path, name))
	end
	uv.fs_rmdir(path)
end

local function create_temp_dir()
	local tmp_base = vim.loop.os_tmpdir() or "/tmp"
	local temp_path = join_paths(tmp_base, "boundary-" .. tostring(vim.loop.hrtime()))
	mkdir_p(temp_path)
	return temp_path
end

local function setup_buffer(path)
	vim.cmd("silent! %bwipeout!")
	vim.cmd("edit " .. path)
	return vim.api.nvim_get_current_buf()
end

suite:add("marks usage of client components", function(t)
	local root = create_temp_dir()
	local old_cwd = uv.cwd()
	uv.chdir(root)
	write_file(join_paths(root, "components/Button.tsx"), "'use client'\nexport default function Button() {}\n")
	write_file(
		join_paths(root, "app/page.tsx"),
		[[import Button from '../components/Button'

export default function Page() {
  return <Button />
}
]]
	)

	require("boundary").reset()
	require("boundary").setup({ auto = false })

	local bufnr = setup_buffer(join_paths(root, "app/page.tsx"))
	vim.bo[bufnr].filetype = "typescriptreact"

	local marked = require("boundary").refresh(bufnr)
	t:eq(1, #marked, "one line should be marked")
	t:eq(3, marked[1], "marker should be on the line with <Button />")

	local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, require("boundary").namespace, 0, -1, {})
	t:eq(1, #extmarks, "one extmark should be placed")
	t:eq(3, extmarks[1][2], "extmark should target the JSX line")

	uv.chdir(old_cwd)
	rm_rf(root)
end)

suite:add("does not mark components without use client boundary", function(t)
	local root = create_temp_dir()
	local old_cwd = uv.cwd()
	uv.chdir(root)
	write_file(
		join_paths(root, "components/Button.tsx"),
		[[export default function Button() {
  return null
}
]]
	)
	write_file(
		join_paths(root, "app/page.tsx"),
		[[import Button from '../components/Button'

export default function Page() {
  return <Button />
}
]]
	)

	require("boundary").reset()
	require("boundary").setup({ auto = false })

	local bufnr = setup_buffer(join_paths(root, "app/page.tsx"))
	vim.bo[bufnr].filetype = "typescriptreact"

	local marked = require("boundary").refresh(bufnr)
	t:eq(0, #marked, "no lines should be marked")

	local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, require("boundary").namespace, 0, -1, {})
	t:eq(0, #extmarks, "no extmarks should be present")

	uv.chdir(old_cwd)
	rm_rf(root)
end)

suite:add("supports directory imports resolved to index files", function(t)
	local root = create_temp_dir()
	local old_cwd = uv.cwd()
	uv.chdir(root)
	write_file(join_paths(root, "components/index.tsx"), "'use client'\nexport { default as Button } from './Button'\n")
	write_file(join_paths(root, "components/Button.tsx"), "export default function Button() { return null }\n")
	write_file(
		join_paths(root, "app/page.tsx"),
		[[import { Button } from '../components'

export default function Page() {
  return (
    <div>
      <Button />
    </div>
  )
}
]]
	)

	require("boundary").reset()
	require("boundary").setup({ auto = false })

	local bufnr = setup_buffer(join_paths(root, "app/page.tsx"))
	vim.bo[bufnr].filetype = "typescriptreact"

	local marked = require("boundary").refresh(bufnr)
	t:eq(1, #marked, "the Button usage should be marked")
	t:eq(5, marked[1], "marker should be applied to the Button line")

	local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, require("boundary").namespace, 0, -1, {})
	t:eq(1, #extmarks, "one extmark should be present")
	t:eq(5, extmarks[1][2], "extmark row matches JSX line")

	uv.chdir(old_cwd)
	rm_rf(root)
end)

return suite
