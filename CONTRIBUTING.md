# 🤝 Contributing

Thank you for your interest in improving **boundary.nvim**! This document explains how to set up a local development environment and run the test suite.

## 📋 Requirements

- [Neovim](https://neovim.io/) 0.9 or later with Lua support.
- A POSIX-compatible shell (`bash`, `zsh`, etc.).
- Git.
- [Stylua](https://github.com/JohnnyMorganz/StyLua) for formatting Lua files.

## 🧰 Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/mimifuwacc/boundary.nvim.git
   cd boundary.nvim
   ```
2. Ensure `nvim` is on your `PATH` and matches the minimum version.
3. (Optional) Add this plugin directory to your Neovim `runtimepath` for manual testing:
   ```vim
   :set rtp^=/path/to/boundary.nvim
   ```

## 🧪 Running Tests

The project includes a lightweight Lua-based test harness that executes via Neovim. Use `make` to trigger it:

```bash
make test
```

Override the Neovim binary if you have multiple versions installed:

```bash
NVIM=/path/to/nvim-nightly make test
```

If any tests fail, the command will exit with a non-zero status and print the failing assertions.

## 🧹 Formatting

Run Stylua to keep the Lua sources consistent:

```bash
make fmt
```

The Makefile target ensures `stylua` is available and formats files under `lua/` and `tests/` according to `stylua.toml`.

## ✅ Continuous Integration

Every pull request runs two GitHub Actions workflows:

- **Format Check** installs Stylua and executes `make fmt`, failing if formatting changes are required.
- **Test Suite** installs Neovim and executes `make test`, failing if any assertions break.

Use these commands locally before pushing so your branch matches the automated checks.

## 🚀 Development Workflow

1. Create a new branch for your change.
2. Add or update tests to describe the behaviour you want to modify.
3. Implement the change, use `make fmt` to format your patches, call `:BoundaryRefresh` inside a sample project to confirm the markers look correct, and ensure the headless tests pass.
4. Submit a pull request describing the change and test coverage.

We value TDD and appreciate contributions that include thorough tests. Happy hacking!
