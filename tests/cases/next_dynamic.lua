return {
  name = "marks components created via next/dynamic",
  files = {
    ["components/Widget.tsx"] = [["use client"

export default function Widget() {
  return <button>Widget</button>
}
]],
    ["app/page.tsx"] = [[import dynamic from 'next/dynamic'

const ClientWidget = dynamic(() => import('../components/Widget'))

export default function Page() {
  return <ClientWidget />
}
]],
  },
  setup_opts = { auto = false },
  expected_lines = { 5 },
}
