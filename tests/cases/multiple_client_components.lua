return {
  name = "marks every component exported from a client module",
  files = {
    ["package.json"] = [[{}]],
    ["components/ui/panel.tsx"] = [["use client"
import * as React from 'react'

export function Panel({ children }: React.PropsWithChildren) {
  return <section>{children}</section>
}

export function PanelHeader({ children }: React.PropsWithChildren) {
  return <header>{children}</header>
}

export function PanelBody({ children }: React.PropsWithChildren) {
  return <main>{children}</main>
}

export function PanelFooter({ children }: React.PropsWithChildren) {
  return <footer>{children}</footer>
}
]],
    ["app/page.tsx"] = [[import {
  Panel,
  PanelBody,
  PanelFooter,
  PanelHeader,
} from '@/components/ui/panel'

export default function Page() {
  return (
    <Panel>
      <PanelHeader>Header</PanelHeader>
      <PanelBody>Body</PanelBody>
      <PanelFooter>Footer</PanelFooter>
    </Panel>
  )
}
]],
  },
  setup_opts = {
    auto = false,
    aliases = {
      ["@/"] = "",
    },
  },
  expected_lines = { 10, 11, 12, 13 },
}
