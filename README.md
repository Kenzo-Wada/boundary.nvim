# 🌐 boundary.nvim

boundary.nvim surfaces `'use client'` boundaries in your React code by displaying inline markers next to component usages. Inspired by the [RSC Boundary Marker VS Code extension](https://github.com/mimifuwacc/rsc-boundary-marker), it brings the same visibility to Neovim workflows.

## ✨ Features

- Detects imports that resolve to components declaring `'use client'`.
- Shows a `'use client'` marker next to every JSX usage of those components via virtual text (default: `'use client'`).
- Watches buffers automatically so markers stay in sync while you edit, or expose a manual refresh command if you prefer.
- Understands default, named, and aliased imports, as well as directory imports that resolve to an `index` file.

## 📦 Installation

Install the plugin with your favourite manager. Example using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'Kenzo-Wada/boundary.nvim',
  branch='release',
  config = function()
    require('boundary').setup({
      auto = true, -- Optional: enable automatic refreshing (see below for more options)
    })
  end,
}
```

When `auto` is disabled you can refresh manually with:

```vim
:BoundaryRefresh
```

## 🛠️ Configuration

`require('boundary').setup()` accepts the following options:

| Option              | Type       | Default                                                                        | Description                                                                 |
| ------------------- | ---------- | ------------------------------------------------------------------------------ | --------------------------------------------------------------------------- |
| `marker_text`       | `string`   | `'use client'`                                                                 | Virtual text displayed next to each matching component usage.               |
| `marker_hl_group`   | `string`   | `BoundaryMarker`                                                               | Highlight group applied to the virtual text. Links to `Comment` by default. |
| `directives`        | `string[]` | `{ "'use client'", '"use client"' }`                                           | Directive strings recognised in imported files.                             |
| `search_extensions` | `string[]` | `{ '.tsx', '.ts', '.jsx', '.js' }`                                             | Extensions appended when resolving bare relative imports.                   |
| `filetypes`         | `string[]` | `{'javascript', 'javascriptreact', 'typescript', 'typescriptreact'}`           | Filetypes that trigger scanning.                                            |
| `max_read_bytes`    | `number`   | `4096`                                                                         | Maximum bytes read from each import when looking for directives.            |
| `auto`              | `boolean`  | `true`                                                                         | Enable automatic refreshing via autocommands.                               |
| `events`            | `string[]` | `{ 'BufEnter', 'BufWritePost', 'TextChanged', 'TextChangedI', 'InsertLeave' }` | Events used to refresh when `auto` is true.                                 |

## 🔄 Usage Flow

1. Open a supported React file (`.tsx`, `.jsx`, …) that imports local components.
2. Ensure the imported component contains a `'use client'` directive at the top of its file.
3. Save or edit the buffer (with `auto = true`) or run `:BoundaryRefresh` to populate the inline markers.

Each line containing a JSX usage of a matching component gets a right-aligned `'use client'` boundary marker, making it easy to visualise client boundaries from the caller's perspective.

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
      <Button /> 'use client' // virtual text marker provided by boundary.nvim
    </div>
  );
}
```
