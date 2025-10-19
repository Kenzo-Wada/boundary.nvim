local Suite = {}
Suite.__index = Suite

local function new_context()
	local ctx = {}
	function ctx:ok(condition, message)
		if not condition then
			error(message or "assertion failed: expected truthy value", 2)
		end
	end
	function ctx:eq(expected, actual, message)
		if expected ~= actual then
			local inspect = vim.inspect or function(value)
				return tostring(value)
			end
			local msg = message or string.format("expected %s but received %s", inspect(expected), inspect(actual))
			error(msg, 2)
		end
	end
	function ctx:neq(expected, actual, message)
		if expected == actual then
			error(message or "values should not be equal", 2)
		end
	end
	return ctx
end

function Suite.new(name)
	return setmetatable({ name = name, tests = {} }, Suite)
end

function Suite:add(name, fn)
	table.insert(self.tests, { name = name, fn = fn })
end

function Suite:run()
	print(string.format("Running %s", self.name))
	local results = { passed = 0, failed = 0 }
	for _, test in ipairs(self.tests) do
		local ok, err = xpcall(function()
			local ctx = new_context()
			test.fn(ctx)
		end, debug.traceback)
		if ok then
			results.passed = results.passed + 1
			print(string.format("  ✓ %s", test.name))
		else
			results.failed = results.failed + 1
			print(string.format("  ✗ %s", test.name))
			print(err)
		end
	end
	return results
end

return Suite
