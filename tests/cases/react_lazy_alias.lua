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
    ["app/page.tsx"] = [[import { ClientComponent } from "./component/client-component"
import { ClientComponent as WithAliasClientComponent } from "@/component/client-component"
import * as AstarickImport from "@/component/client-component"
import React from "react"

const LazyClientComponent = React.lazy(() =>
  import("@/component/client-component").then((mod) => ({
    default: mod.ClientComponent,
  })),
)

export function Example() {
  return (
    <>
      <ClientComponent />
      <WithAliasClientComponent />
      <AstarickImport.ClientComponent />
      <LazyClientComponent />
    </>
  )
}
]],
  },
  setup_opts = { auto = false },
  expected_lines = { 14, 15, 16, 17 },
}
