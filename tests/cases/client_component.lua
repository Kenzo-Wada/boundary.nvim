return {
  name = "marks simple client component usage",
  files = {
    ["components/Widget.tsx"] = [["use client"

export default function Widget() {
  return <button>Widget</button>
}
]],
    ["app/page.tsx"] = [[import Widget from '../components/Widget'

export default function Page() {
  return <Widget />
}
]],
  },
  setup_opts = { auto = false },
  expected_lines = { 4 },
}
