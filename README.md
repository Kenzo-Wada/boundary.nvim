# 🌐 boundary.nvim — Visualize `'use client'` boundaries in Neovim

See React/RSC `'use client'` boundaries **at the call site**.
Inspired by the VS Code extension [RSC Boundary Marker](https://github.com/mimifuwacc/rsc-boundary-marker), brought to Neovim.

> If this helps, please ⭐ star the repo!

---

## 📸 Examples

### default
<img width="1280" height="720" alt="Screenshot" src="https://github.com/user-attachments/assets/e8438b87-3264-42b1-96b4-a4201d1062c7" />

### custom marker text
<img width="1280" height="720" alt="Screenshot from 2025-10-20 11-37-52" src="https://github.com/user-attachments/assets/58f370f1-9f12-46cc-9b58-732bb5e0b6af" />

### custom hl color
<img width="1280" height="720" alt="Screenshot from 2025-10-20 11-42-47" src="https://github.com/user-attachments/assets/34f84fc9-5e8c-4606-8cb1-8cf4524f6462" />

---

## ✨ Features

- Detects components that declare `'use client'`.
- Shows a right-aligned `'use client'` marker as virtual text next to each JSX usage.
- Auto-watches buffers to keep markers in sync (or use a manual refresh).
- Handles default / named / aliased imports and directory imports resolving to `index`.

---

## 🚀 Quick Start

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "Kenzo-Wada/boundary.nvim",
  branch = "release",
  opts = {
    auto = true, -- automatic refresh enabled by default
    -- marker_text = "'use client'",
  },
}
```

Manual refresh:

```vim
:BoundaryRefresh
```

---

## 📦 Installation

Works with any plugin manager. Once on your `runtimepath`, just:

```lua
require("boundary").setup()
```

All options are optional; sensible defaults are provided.

---

## ⚙️ Configuration

`require("boundary").setup({ ... })` accepts:

| Option              | Type       | Default                                                                | Description                                                     |
| ------------------- | ---------- | ---------------------------------------------------------------------- | --------------------------------------------------------------- |
| `marker_text`       | `string`   | `'use client'`                                                         | Virtual text displayed next to each matching JSX usage.         |
| `marker_hl_group`   | `string`   | `BoundaryMarker`                                                       | Highlight group for the marker (links to `Comment` by default). |
| `directives`        | `string[]` | `{ "'use client'", '"use client"' }`                                   | Directive strings recognized in imported files.                 |
| `search_extensions` | `string[]` | `{ ".tsx", ".ts", ".jsx", ".js" }`                                     | File extensions tried when resolving bare relative imports.     |
| `filetypes`         | `string[]` | `{ "javascript", "javascriptreact", "typescript", "typescriptreact" }` | Filetypes that trigger scanning.                                |
| `max_read_bytes`    | `number`   | `4096`                                                                 | Max bytes read from each import when scanning for directives.   |
| `auto`              | `boolean`  | `true`                                                                 | Enable automatic refresh via autocommands.                      |
| `events`            | `string[]` | `{ "BufEnter", "BufWritePost", "TextChanged", "InsertLeave" }`         | Events used to refresh when `auto` is `true`.                   |

---

## 🔄 Usage

1. Import a local component in a supported React file (`.tsx`, `.jsx`, …).
2. Ensure the component’s file begins with a `'use client'` (or `"use client"`).
3. Edit or save (with `auto = true`) or run `:BoundaryRefresh` to populate markers.

```tsx
// components/Button.tsx
"use client";

export default function Button() {
  return <button>Click me</button>;
}

// app/page.tsx
import Button from "../components/Button";

export default function Page() {
  return (
    <div>
      <Button /> 'use client' // boundary.nvim shows virtual text here
    </div>
  );
}
```

---

## 📡 Auto-refresh events

Default `events`:

- `BufEnter` — when entering a buffer
- `BufWritePost` — after saving
- `TextChanged` / `InsertLeave` — during edits / leaving insert mode

Tune this list to balance responsiveness and cost.

---

## 🧰 Commands

- `:BoundaryRefresh` — Re-scan the current buffer.

---

## 🤝 Contributing

Issues and PRs are welcome!
We label `good first issue` to help newcomers get started.

---

## 📜 License

MIT
