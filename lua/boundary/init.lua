local uv = vim.loop

local default_config = {
	directive = "'use client'",
	directives = { "'use client'", '"use client"' },
	search_extensions = { ".tsx", ".ts", ".jsx", ".js" },
	auto = false,
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
	},
	max_read_bytes = 4096,
}

local M = {
	config = vim.deepcopy(default_config),
}

local command_created = false
local augroup_id

local function trim(value)
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function matches_directive(line)
	local trimmed = trim(line)
	if trimmed == "" then
		return false
	end
	trimmed = trimmed:gsub(";$", "")
	for _, directive in ipairs(M.config.directives) do
		if trimmed == directive then
			return true
		end
	end
	return false
end

local function buffer_has_directive(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 20, false)
	for _, line in ipairs(lines) do
		if line:match("%S") then
			return matches_directive(line)
		end
	end
	return false
end

local function read_file_header(path)
	local fd = uv.fs_open(path, "r", 438)
	if not fd then
		return nil
	end
	local data = uv.fs_read(fd, M.config.max_read_bytes, 0)
	uv.fs_close(fd)
	return data or ""
end

local function file_has_directive(path)
	local content = read_file_header(path)
	if not content then
		return false
	end
	local lines = vim.split(content, "\n", { plain = true })
	for _, line in ipairs(lines) do
		if line:match("%S") then
			return matches_directive(line)
		end
	end
	return false
end

local function has_extension(import_path)
	return import_path:match("%.[^/]+$") ~= nil
end

local function resolve_import_paths(base_dir, import_path)
	if not import_path:match("^%.") then
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

	local absolute = vim.fn.fnamemodify(base_dir .. "/" .. import_path, ":p")
	add(absolute)

	if not has_extension(import_path) then
		for _, ext in ipairs(M.config.search_extensions) do
			add(absolute .. ext)
		end
		local stat = uv.fs_stat(absolute)
		if stat and stat.type == "directory" then
			for _, ext in ipairs(M.config.search_extensions) do
				add(absolute .. "/index" .. ext)
			end
		end
	end

	return resolved
end

local function extract_imports(lines)
	local imports = {}
	for _, line in ipairs(lines) do
		local from_match = line:match("import%s+.-from%s+['\"](.-)['\"]")
		if from_match then
			imports[#imports + 1] = from_match
		else
			local bare_match = line:match("import%s+['\"](.-)['\"]")
			if bare_match then
				imports[#imports + 1] = bare_match
			end
		end
	end
	return imports
end

local function filetype_supported(bufnr)
	local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
	for _, allowed in ipairs(M.config.filetypes) do
		if ft == allowed then
			return true
		end
	end
	return false
end

local function collect_client_dependencies(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		return false
	end
	local base_dir = vim.fn.fnamemodify(name, ":h")
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local imports = extract_imports(lines)
	for _, import_path in ipairs(imports) do
		for _, file_path in ipairs(resolve_import_paths(base_dir, import_path)) do
			if file_has_directive(file_path) then
				return true
			end
		end
	end
	return false
end

local function ensure_command()
	if command_created then
		return
	end
	vim.api.nvim_create_user_command("BoundaryEnsureUseClient", function(opts)
		local bufnr = opts.buf or vim.api.nvim_get_current_buf()
		M.ensure_use_client(bufnr)
	end, {
		desc = 'Ensure the current buffer declares a "use client" directive when required.',
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
	augroup_id = vim.api.nvim_create_augroup("BoundaryUseClient", { clear = true })
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = augroup_id,
		pattern = "*",
		callback = function(args)
			if filetype_supported(args.buf) then
				M.ensure_use_client(args.buf)
			end
		end,
	})
end

function M.ensure_use_client(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not filetype_supported(bufnr) then
		return false
	end
	if buffer_has_directive(bufnr) then
		return false
	end
	if not collect_client_dependencies(bufnr) then
		return false
	end
	vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, { M.config.directive, "" })
	return true
end

function M.setup(opts)
	opts = opts or {}
	local new_config = vim.tbl_deep_extend("force", {}, default_config, opts)
	M.config = new_config
	ensure_command()
	if M.config.auto then
		create_autocmd()
	else
		clear_autocmd()
	end
	return M.config
end

function M.reset()
	clear_autocmd()
	command_created = false
	M.config = vim.deepcopy(default_config)
end

return M
