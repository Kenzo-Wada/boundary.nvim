return {
  name = "skips components without client directive",
  files = {
    ["components/Widget.tsx"] = [[export default function Widget() {
  return <button>Widget</button>
}
]],
    ["app/page.tsx"] = [[import Widget from '../components/Widget'

export default function Page() {
  return <Widget />
}
]],
  },
  expected_lines = {},
}
