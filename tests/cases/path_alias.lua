return {
  name = "marks components imported through configured aliases",
  files = {
    ["package.json"] = [[{}]],
    ["tsconfig.json"] = [[{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./*"]
    }
  }
}]],
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
  },
  expected_lines = { 3 },
}
