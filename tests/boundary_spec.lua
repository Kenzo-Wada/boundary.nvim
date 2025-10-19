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

suite:add("marks usage of client components", function(t)
  local root = create_temp_dir()
  local old_cwd = uv.cwd()
  uv.chdir(root)
  write_file(join_paths(root, "components/Button.tsx"), "'use client'\nexport default function Button() {}\n")
  write_file(
    join_paths(root, "app/page.tsx"),
    [[import Button from '../components/Button'

export default function Page() {
  return <Button />
}
]]
  )

  require("boundary").reset()
  require("boundary").setup { auto = false }

  local bufnr = setup_buffer(join_paths(root, "app/page.tsx"))
  vim.bo[bufnr].filetype = "typescriptreact"

  local marked = require("boundary").refresh(bufnr)
  t:eq(1, #marked, "one line should be marked")
  t:eq(3, marked[1], "marker should be on the line with <Button />")

  local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, require("boundary").namespace, 0, -1, {})
  t:eq(1, #extmarks, "one extmark should be placed")
  t:eq(3, extmarks[1][2], "extmark should target the JSX line")

  uv.chdir(old_cwd)
  rm_rf(root)
end)

suite:add("does not mark components without use client boundary", function(t)
  local root = create_temp_dir()
  local old_cwd = uv.cwd()
  uv.chdir(root)
  write_file(
    join_paths(root, "components/Button.tsx"),
    [[export default function Button() {
  return null
}
]]
  )
  write_file(
    join_paths(root, "app/page.tsx"),
    [[import Button from '../components/Button'

export default function Page() {
  return <Button />
}
]]
  )

  require("boundary").reset()
  require("boundary").setup { auto = false }

  local bufnr = setup_buffer(join_paths(root, "app/page.tsx"))
  vim.bo[bufnr].filetype = "typescriptreact"

  local marked = require("boundary").refresh(bufnr)
  t:eq(0, #marked, "no lines should be marked")

  local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, require("boundary").namespace, 0, -1, {})
  t:eq(0, #extmarks, "no extmarks should be present")

  uv.chdir(old_cwd)
  rm_rf(root)
end)

suite:add("supports directory imports resolved to index files", function(t)
  local root = create_temp_dir()
  local old_cwd = uv.cwd()
  uv.chdir(root)
  write_file(join_paths(root, "components/index.tsx"), "'use client'\nexport { default as Button } from './Button'\n")
  write_file(join_paths(root, "components/Button.tsx"), "export default function Button() { return null }\n")
  write_file(
    join_paths(root, "app/page.tsx"),
    [[import { Button } from '../components'

export default function Page() {
  return (
    <div>
      <Button />
    </div>
  )
}
]]
  )

  require("boundary").reset()
  require("boundary").setup { auto = false }

  local bufnr = setup_buffer(join_paths(root, "app/page.tsx"))
  vim.bo[bufnr].filetype = "typescriptreact"

  local marked = require("boundary").refresh(bufnr)
  t:eq(1, #marked, "the Button usage should be marked")
  t:eq(5, marked[1], "marker should be applied to the Button line")

  local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, require("boundary").namespace, 0, -1, {})
  t:eq(1, #extmarks, "one extmark should be present")
  t:eq(5, extmarks[1][2], "extmark row matches JSX line")

  uv.chdir(old_cwd)
  rm_rf(root)
end)

suite:add("supports configured path aliases", function(t)
  local root = create_temp_dir()
  local old_cwd = uv.cwd()
  uv.chdir(root)
  write_file(join_paths(root, "package.json"), "{}")
  write_file(
    join_paths(root, "components/Button.tsx"),
    "'use client'\nexport default function Button() { return null }\n"
  )
  write_file(
    join_paths(root, "app/page.tsx"),
    [[import Button from '@/components/Button'

export default function Page() {
  return <Button />
}
]]
  )

  require("boundary").reset()
  require("boundary").setup { auto = false, aliases = { ["@/"] = "" } }

  local bufnr = setup_buffer(join_paths(root, "app/page.tsx"))
  vim.bo[bufnr].filetype = "typescriptreact"

  local marked = require("boundary").refresh(bufnr)
  t:eq(1, #marked, "alias import should be marked")
  t:eq(3, marked[1], "marker should attach to JSX line")

  local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, require("boundary").namespace, 0, -1, {})
  t:eq(1, #extmarks, "one extmark should be present for alias import")
  t:eq(3, extmarks[1][2], "extmark should target JSX line")

  uv.chdir(old_cwd)
  rm_rf(root)
end)

suite:add("resolves aliases when project root is unknown", function(t)
  local root = create_temp_dir()
  local old_cwd = uv.cwd()
  uv.chdir(root)

  write_file(
    join_paths(root, "components/Button.tsx"),
    "'use client'\nexport default function Button() { return null }\n"
  )

  write_file(
    join_paths(root, "app/page.tsx"),
    [[import Button from '@/components/Button'

export default function Page() {
  return <Button />
}
]]
  )

  require("boundary").reset()

  -- simulate a Neovim version without vim.fs by clearing root detection
  local util = require "boundary.util"
  local original_find_project_root = util.find_project_root
  util.find_project_root = function()
    return nil
  end

  require("boundary").setup { auto = false, aliases = { ["@/"] = "" } }

  local bufnr = setup_buffer(join_paths(root, "app/page.tsx"))
  vim.bo[bufnr].filetype = "typescriptreact"

  local marked = require("boundary").refresh(bufnr)
  t:eq(1, #marked, "alias should resolve using cwd fallback")
  t:eq(3, marked[1], "marker should appear on the JSX line")

  util.find_project_root = original_find_project_root

  uv.chdir(old_cwd)
  rm_rf(root)
end)

suite:add("marks shadcn accordion components", function(t)
  local root = create_temp_dir()
  local old_cwd = uv.cwd()
  uv.chdir(root)

  write_file(
    join_paths(root, "components/ui/accordion.tsx"),
    [["use client";

import * as React from "react";
import * as AccordionPrimitive from "@radix-ui/react-accordion";
import { ChevronDownIcon } from "lucide-react";

import { cn } from "@/lib/utils";

function Accordion({
  ...props
}: React.ComponentProps<typeof AccordionPrimitive.Root>) {
  return <AccordionPrimitive.Root data-slot="accordion" {...props} />;
}

function AccordionItem({
  className,
  ...props
}: React.ComponentProps<typeof AccordionPrimitive.Item>) {
  return (
    <AccordionPrimitive.Item
      data-slot="accordion-item"
      className={cn("border-b border-b-background last:border-b-0", className)}
      {...props}
    />
  );
}

function AccordionTrigger({
  className,
  children,
  ...props
}: React.ComponentProps<typeof AccordionPrimitive.Trigger>) {
  return (
    <AccordionPrimitive.Header className="flex">
      <AccordionPrimitive.Trigger
        data-slot="accordion-trigger"
        className={cn(
          "focus-visible:border-ring focus-visible:ring-ring/50 flex flex-1 items-start justify-between gap-4 py-4 rounded-md text-left font-bold transition-all outline-none hover:underline focus-visible:ring-[3px] disabled:pointer-events-none disabled:opacity-50 [&[data-state=open]>svg]:rotate-180 cursor-pointer",
          className,
        )}
        {...props}
      >
        {children}
        <ChevronDownIcon className="text-muted-foreground pointer-events-none size-6 shrink-0 translate-y-0.5 transition-transform duration-200" />
      </AccordionPrimitive.Trigger>
    </AccordionPrimitive.Header>
  );
}

function AccordionContent({
  className,
  children,
  ...props
}: React.ComponentProps<typeof AccordionPrimitive.Content>) {
  return (
    <AccordionPrimitive.Content
      data-slot="accordion-content"
      className="data-[state=closed]:animate-accordion-up data-[state=open]:animate-accordion-down overflow-hidden text-foreground/75"
      {...props}
    >
      <div className={cn("pt-0 pb-4", className)}>{children}</div>
    </AccordionPrimitive.Content>
  );
}

export { Accordion, AccordionItem, AccordionTrigger, AccordionContent };
]]
  )

  write_file(join_paths(root, "package.json"), "{}")

  write_file(
    join_paths(root, "app/page.tsx"),
    [[import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";

export default function Page() {
  return (
    <Accordion>
      <AccordionItem value="item-1">
        <AccordionTrigger>Trigger</AccordionTrigger>
        <AccordionContent>Content</AccordionContent>
      </AccordionItem>
    </Accordion>
  );
}
]]
  )

  require("boundary").reset()
  require("boundary").setup { auto = false, aliases = { ["@/"] = "" } }

  local bufnr = setup_buffer(join_paths(root, "app/page.tsx"))
  vim.bo[bufnr].filetype = "typescriptreact"

  local marked = require("boundary").refresh(bufnr)
  t:eq(4, #marked, "all accordion components should be marked")
  t:eq(9, marked[1], "marker should be placed on the <Accordion> line")
  t:eq(10, marked[2], "marker should be placed on the <AccordionItem> line")
  t:eq(11, marked[3], "marker should be placed on the <AccordionTrigger> line")
  t:eq(12, marked[4], "marker should be placed on the <AccordionContent> line")

  local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, require("boundary").namespace, 0, -1, {})
  t:eq(4, #extmarks, "virtual text markers should be applied to each line")

  uv.chdir(old_cwd)
  rm_rf(root)
end)

return suite
