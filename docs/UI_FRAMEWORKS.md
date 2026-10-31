# UI Framework Options & Modernization Plan

## Where we are

The React client uses **Tailwind CSS** with a **shadcn/ui-compatible token
layer** (`src/index.css` defines `--background`, `--card`, `--primary`,
`--border`, `--radius`, … for `:root` and `.dark`, mapped in
`tailwind.config.js`). Primitives live in `src/components/ui.tsx` (Button,
Card, Input, Select, Textarea, Field, Modal, ConfirmDialog, Tabs, Badge,
Slider, Progress, Spinner, Skeleton, EmptyState) plus a small toast system and
an app shell with a desktop sidebar and mobile bottom nav.

Because the tokens already match shadcn's conventions, adopting shadcn/ui is a
drop-in rather than a rewrite.

## Options evaluated

| Option | What it is | Pros | Cons | Fit |
|---|---|---|---|---|
| **shadcn/ui** | Copy-in components (Radix + Tailwind), CSS-variable theming | Owned code, accessible, Tailwind-native, huge ecosystem, AI tooling (skill + MCP) | You vendor ~30 small files; some discipline needed to stay consistent | **Best** |
| Radix Themes | Pre-styled Radix | Fast, polished, good a11y | Less control; another styling layer on top of Tailwind | Good |
| Mantine | Batteries-included component kit | Lots of components/hooks | Large, own styling system, less Tailwind-native | Meh |
| MUI / Chakra | Mature design systems | Complete, stable | Heavy, opinionated, fights Tailwind | No |
| DaisyUI | Tailwind plugin of classes | Very quick | Fewer primitives, weaker a11y, class soup | Meh |
| Park UI / Base UI | Unstyled, a11y-first | Modern, flexible | Younger ecosystem | Watch |
| Custom (current) | Our own primitives | Zero deps, already themed | We maintain everything | Fine baseline |

## Recommendation

**Adopt shadcn/ui incrementally**, keeping our token layer. It gives us a large
library of accessible components we own (no lock-in), matches the Tailwind +
CSS-variable setup we already use, and has first-class AI tooling.

Suggested order: `Dialog`/`Sheet` (mobile drawers), `DropdownMenu`, `Tabs`,
`Toast` (replace ours), `Form` (+ React Hook Form + Zod validation),
`DataTable` (History), `Calendar`/`DatePicker` (day editing), `Switch`,
`Select`, `Command` (station picker).

### How to set it up

```bash
cd apps/web
npx shadcn@latest init          # writes components.json, aligns CSS variables
npx shadcn@latest add button dialog card tabs toast select switch
```

**AI tooling (what you linked):**

- **Skills** — project-aware context so an assistant generates correct shadcn
  code (`npx skills add shadcn/ui`, or `pnpm dlx skills add shadcn/ui`).
- **MCP server** — lets an assistant browse/search/install registry components
  by name (`npx shadcn@latest mcp init --client claude`).

Both are optional developer-experience add-ons; the app does not depend on them
at runtime.

## Modernization plan

1. **Foundation (done)** — design tokens, light/dark, shell, primitives, toasts.
2. **shadcn/ui adopted (done)** — `components.json`, `@/` alias, `class-variance-authority`,
   Radix `Dialog`/`Tabs`/`Switch`, `tailwindcss-animate`, and a `components/ui/`
   module. The old hand-rolled primitives file is gone; the barrel keeps imports stable.
4. **More shadcn components (done)** — `Sonner` (toasts), `Tooltip`,
   `DropdownMenu` (sidebar account menu), `Sheet` (mobile account drawer),
   Radix `Select` (`SelectField`) and Table primitives (sortable History table).
5. **Forms (next)** — React Hook Form + Zod for the day, preset and settings
   forms, with shadcn `Form` and `Calendar`/`DatePicker`.
6. **Motion & polish** — subtle transitions, skeleton loading states, empty
   states, responsive sheets on mobile.
7. **Accessibility** — Radix primitives give focus management and ARIA; verify
   with the Playwright suite.

Add more components any time with:

```bash
cd apps/web
npx shadcn@latest add dropdown-menu sheet tooltip table sonner form
```
