local Suite = require("boundary.test_suite")
local suite = Suite.new("boundary.ensure_use_client")

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

suite:add("adds directive when importing client component", function(t)
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

	local added = require("boundary").ensure_use_client(bufnr)
	t:ok(added, "directive should be added when client component detected")

	local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
	t:eq("'use client'", first_line)

	uv.chdir(old_cwd)
	rm_rf(root)
end)

suite:add("does not add directive when not required", function(t)
	local root = create_temp_dir()
	local old_cwd = uv.cwd()
	uv.chdir(root)
	write_file(
		join_paths(root, "components/Button.tsx"),
		[[export default function Button() {}
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

	local added = require("boundary").ensure_use_client(bufnr)
	t:eq(false, added, "directive should not be added when dependency is not client")

	local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
	t:neq("'use client'", first_line)

	uv.chdir(old_cwd)
	rm_rf(root)
end)

return suite
