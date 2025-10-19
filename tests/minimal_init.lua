vim.opt.runtimepath:append(vim.fn.getcwd())

local cwd = vim.fn.getcwd()
package.path = table.concat({
	cwd .. "/?.lua",
	cwd .. "/?/init.lua",
	cwd .. "/lua/?.lua",
	cwd .. "/lua/?/init.lua",
	cwd .. "/tests/?.lua",
	cwd .. "/tests/?/init.lua",
	package.path,
}, ";")

vim.cmd("filetype off")
vim.cmd("syntax off")
