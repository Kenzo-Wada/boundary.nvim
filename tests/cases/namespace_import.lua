return {
  name = "marks namespace import usage",
  files = {
    ["components/Button.tsx"] = [["use client"

export function Button() {
  return <button>Button</button>
}
]],
    ["app/page.tsx"] = [[import * as Client from '../components/Button'

export function Page() {
  return <Client.Button />
}
]],
  },
  setup_opts = { auto = false },
  expected_lines = { 3 },
}
