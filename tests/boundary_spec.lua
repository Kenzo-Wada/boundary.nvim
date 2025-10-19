local Suite = require "boundary.test_suite"
local suite = Suite.new "boundary.markers"

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
  local dir = path:match "(.+)/[^/]+$"
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
  vim.cmd "silent! %bwipeout!"
  vim.cmd("edit " .. path)
  return vim.api.nvim_get_current_buf()
end

local cases = {
  require "tests.cases.client_component",
  require "tests.cases.no_client_boundary",
  require "tests.cases.directory_import",
  require "tests.cases.path_alias",
  require "tests.cases.alias_without_root",
  require "tests.cases.alias_from_buffer_ancestor",
  require "tests.cases.multiple_client_components",
}

local function run_case(case)
  return function(t)
    local root = create_temp_dir()
    local cleanup_dirs = { root }
    local old_cwd = uv.cwd()

    if case.chdir ~= "none" then
      if case.chdir == "external" then
        local external = create_temp_dir()
        uv.chdir(external)
        cleanup_dirs[#cleanup_dirs + 1] = external
      else
        uv.chdir(root)
      end
    end

    for relative, contents in pairs(case.files or {}) do
      write_file(join_paths(root, relative), contents)
    end

    require("boundary").reset()

    local util = require "boundary.util"
    local original_find_project_root
    if case.stub_project_root ~= nil then
      original_find_project_root = util.find_project_root
      if type(case.stub_project_root) == "function" then
        util.find_project_root = case.stub_project_root
      else
        util.find_project_root = function()
          return case.stub_project_root
        end
      end
    end

    local opts = vim.tbl_extend("force", { auto = false }, case.setup_opts or {})
    require("boundary").setup(opts)

    local bufnr = setup_buffer(join_paths(root, case.entry or "app/page.tsx"))
    vim.bo[bufnr].filetype = case.filetype or "typescriptreact"

    local marked = require("boundary").refresh(bufnr)
    t:eq(#case.expected_lines, #marked, case.description or "unexpected marker count")
    for index, line in ipairs(case.expected_lines) do
      t:eq(line, marked[index], string.format("marker %d should target line %d", index, line))
    end

    local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, require("boundary").namespace, 0, -1, {})
    t:eq(#case.expected_lines, #extmarks, "extmark count should match expected markers")
    for index, line in ipairs(case.expected_lines) do
      t:eq(line, extmarks[index][2], string.format("extmark %d should target line %d", index, line))
    end

    if case.stub_project_root ~= nil then
      util.find_project_root = original_find_project_root
    end

    uv.chdir(old_cwd)
    for _, dir in ipairs(cleanup_dirs) do
      rm_rf(dir)
    end
  end
end

for _, case in ipairs(cases) do
  suite:add(case.name, run_case(case))
end

return suite
