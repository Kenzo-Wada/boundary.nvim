return {
  name = "marks components created via React.lazy",
  files = {
    ["components/Widget.tsx"] = [["use client"

export default function Widget() {
  return <button>Widget</button>
}
]],
    ["app/page.tsx"] = [[import React from 'react'

const ClientWidget = React.lazy(() => import('../components/Widget'))

export default function Page() {
  return <ClientWidget />
}
]],
  },
  setup_opts = { auto = false },
  expected_lines = { 5 },
}
