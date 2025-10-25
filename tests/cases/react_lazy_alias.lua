return {
  name = "marks React.lazy components using aliased imports",
  files = {
    ["tsconfig.json"] = [[{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/component/*": ["app/component/*"]
    }
  }
}
]],
    ["app/component/client-component.tsx"] = [["use client"

export function ClientComponent() {
  return <button>Client</button>
}
]],
    ["app/page.tsx"] = [[import React from "react"

const LazyClientComponent = React.lazy(() =>
  import("@/component/client-component").then((mod) => ({
    default: mod.ClientComponent,
  })),
)

export function Example() {
  return <LazyClientComponent />
}
]],
  },
  setup_opts = { auto = false },
  expected_lines = { 9 },
}
