local M = {}

function M.trim(value)
	if vim.trim then
		return vim.trim(value)
	end
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.tbl_is_empty(value)
	if vim.tbl_isempty then
		return vim.tbl_isempty(value)
	end
	return next(value) == nil
end

return M
