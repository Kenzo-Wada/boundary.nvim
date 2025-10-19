return {
  name = "walks buffer ancestors to resolve alias targets",
  files = {
    ["components/Widget.tsx"] = [["use client"

export default function Widget() {
  return <div>Widget</div>
}
]],
    ["app/page.tsx"] = [[import Widget from '@/components/Widget'

export default function Page() {
  return <Widget />
}
]],
  },
  setup_opts = {
    auto = false,
    aliases = {
      ["@/"] = "",
    },
  },
  stub_project_root = function()
    return nil
  end,
  chdir = "external",
  expected_lines = { 3 },
}
