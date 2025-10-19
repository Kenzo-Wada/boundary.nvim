local M = {}

local function aggregate(results, summary)
  summary = summary or { passed = 0, failed = 0 }
  summary.passed = summary.passed + (results.passed or 0)
  summary.failed = summary.failed + (results.failed or 0)
  return summary
end

function M.run()
  local suites = {
    require "tests.boundary_spec",
  }

  local summary = { passed = 0, failed = 0 }
  for _, suite in ipairs(suites) do
    local results = suite:run()
    summary = aggregate(results, summary)
  end

  print(string.format("\nSummary: %d passed, %d failed", summary.passed, summary.failed))
  if summary.failed > 0 then
    error(string.format("%d test(s) failed", summary.failed))
  end
end

return M
