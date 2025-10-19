NVIM ?= nvim
TEST_INIT ?= tests/minimal_init.lua
TEST_COMMAND ?= lua require('tests.run').run()

.PHONY: fmt
## Format Lua sources with stylua.
fmt:
	@command -v stylua >/dev/null || { echo "Error: stylua not found on PATH"; exit 1; }
	@stylua lua tests

.PHONY: test
## Run the automated test suite via Neovim.
test:
	@command -v $(NVIM) >/dev/null || { echo "Error: $(NVIM) not found on PATH"; exit 1; }
	@$(NVIM) --headless -u $(TEST_INIT) -c "$(TEST_COMMAND)" -c qa
