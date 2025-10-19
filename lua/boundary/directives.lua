local uv = vim.loop

local util = require("boundary.util")

local M = {}

local directive_cache = {}

local function read_file_header(path, max_bytes)
	local fd = uv.fs_open(path, "r", 438)
	if not fd then
		return nil
	end
	local data = uv.fs_read(fd, max_bytes, 0)
	uv.fs_close(fd)
	return data or ""
end

local function matches_directive(conf, line)
	local trimmed = util.trim(line)
	if trimmed == "" then
		return false
	end
	trimmed = trimmed:gsub(";$", "")
	for _, directive in ipairs(conf.directives) do
		if trimmed == directive then
			return true
		end
	end
	return false
end

function M.file_has_directive(conf, path)
	local stat = uv.fs_stat(path)
	if not stat or stat.type ~= "file" then
		directive_cache[path] = nil
		return false
	end

	local mtime_sec = stat.mtime and stat.mtime.sec or 0
	local size = stat.size or 0
	local cached = directive_cache[path]
	if cached and cached.mtime == mtime_sec and cached.size == size then
		return cached.has_directive
	end

	local content = read_file_header(path, conf.max_read_bytes)
	if not content then
		directive_cache[path] = nil
		return false
	end

	local has = false
	local in_block_comment = false
	for line in content:gmatch("([^\n]+)") do
		local trimmed_line = util.trim(line)
		if trimmed_line ~= "" then
			if in_block_comment then
				if trimmed_line:find("%*/") then
					in_block_comment = false
				end
			else
				if matches_directive(conf, trimmed_line) then
					has = true
					break
				end
				if trimmed_line:sub(1, 2) == "//" then
					goto continue
				end
				if trimmed_line:match("^/%*") then
					if not trimmed_line:find("%*/") then
						in_block_comment = true
					end
					goto continue
				end
				if trimmed_line:find("%*/") then
					goto continue
				end
				break
			end
		end
		::continue::
	end

	directive_cache[path] = {
		has_directive = has,
		mtime = mtime_sec,
		size = size,
	}

	return has
end

function M.reset()
	directive_cache = {}
end

return M
