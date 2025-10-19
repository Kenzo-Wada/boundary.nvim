return {
  name = "resolves directory imports to index files",
  files = {
    ["components/index.tsx"] = [["use client"
export { default as Widget } from './Widget'
]],
    ["components/Widget.tsx"] = [[export default function Widget() {
  return <span>Widget</span>
}
]],
    ["app/page.tsx"] = [[import { Widget } from '../components'

export default function Page() {
  return (
    <div>
      <Widget />
    </div>
  )
}
]],
  },
  expected_lines = { 6 },
}
