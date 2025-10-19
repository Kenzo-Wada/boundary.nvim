local util = require("boundary.util")

local M = {}

function M.clear(bufnr, namespace)
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
end

function M.find_lines(lines, components)
	local marks = {}
	if util.tbl_is_empty(components) then
		return marks
	end

	local component_names = {}
	for name in pairs(components) do
		component_names[#component_names + 1] = name
	end

	for line_idx, line in ipairs(lines) do
		for _, name in ipairs(component_names) do
			local pattern = "<%s*" .. vim.pesc(name) .. "%f[^%w_]"
			if line:find(pattern) then
				marks[line_idx - 1] = true
				break
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

	for _, line in ipairs(lines) do
		vim.api.nvim_buf_set_extmark(bufnr, namespace, line, 0, {
			virt_text = { { conf.marker_text, conf.marker_hl_group } },
			virt_text_pos = "eol",
		})
	end

	return lines
end

return M
