---
title: "DaisyUI Primitive Map"
slug: daisyui-map
template: "rotkeeper-doc.html"
version: "1.1"
updated: "2026-08-28"
description: "Reference table mapping Rotkeeper UI primitives to DaisyUI components and tokens, consumed by the DaisyUI prototype theme (#248) and the vanilla DOM-sharing fallback (#250)."
tags:
  - daisyui
  - themes
  - templates
  - prototype
  - accessibility
---

# DaisyUI Primitive Map

This is the reference table for issue #249: which DaisyUI component or token implements each Rotkeeper UI primitive. Its consumers are the [DaisyUI prototype theme](https://github.com/drawmeanelephant/rotkeeper/issues/248) (`theme-daisy.html`) and the vanilla fallback that shares the exact same DOM (#250, `theme-daisy-vanilla.html`). The map records what the prototype does today, so the fallback (and any later theme) can target the same primitives with the same markup.

The live proof is the [showcase page for the theme](../showcase/showcase-daisy.html) and its [zero-dependency twin](../showcase/showcase-daisy-vanilla.html) — the same scaffolded body every theme renders, through the DaisyUI presentation layer and through hand-written CSS respectively.

## The catch-22, resolved on-prem

DaisyUI is normally consumed through a Tailwind + Node build step. The hard constraints in #248 forbid both a CDN dependency and Node build tooling in the runtime, which looks like a catch-22 — DaisyUI ships compiled CSS, not source-only.

The prototype resolves it by **vendoring the precompiled build**: `daisyUI` publishes `daisyui.css` (base reset, `light`/`dark` themes, every component, and the color utility set) plus `themes.css` (all 35 themes) ready-made. Rotkeeper checks them into `home/assets/css/vendor/` and serves them like any other local asset — zero CDN requests, zero Node, no framework runtime. What Rotkeeper gives up is *configuration*: the vendored build is the full DaisyUI surface (~1.16 MB across the two files), not a tree-shaken subset, and any component styling that needs Tailwind utility classes in the markup must be expressed as plain CSS against DaisyUI's tokens instead (see the notes below).

Refreshing the vendor is a deliberate, documented act (checksums below), the same discipline the project applies to the Oliver pin.

## Primitive → component map

| Rotkeeper primitive | Where it appears | DaisyUI component / token | Prototype implementation (`theme-daisy`) | Vanilla fallback (#250) |
| --- | --- | --- | --- | --- |
| **Nav** | `bones/config/rotkeeper.yaml` `navigation:` → `<site-nav>` slot | `navbar` + horizontal `menu` look | Navbar chrome in the template; the generated `<nav><ul><li><a>` (which cannot carry component classes from the shared config slot) is styled with DaisyUI tokens in `theme-daisy.css` | Same DOM, hand-written flex/menu CSS |
| **Cards** | Article surface, content callouts | `card`, `card-body`, `card-title` | Article wrapped in `card card-body`; content cards use the same classes in raw HTML | Same classes, plain CSS surfaces |
| **Alerts** | Rendered blockquotes (`> **Note:** …`) | `alert`, `alert-warning` | Blockquote styled as an alert: `--color-warning` inset border + tinted `base-200` fill, `--radius-field` | Same box, no warning tint |
| **Tables** | GFM pipe tables in `$body$` | `table` (+ zebra striping) | Content tables restyled with `base-300` borders and even-row striping | Same borders, no radius system |
| **Metadata blocks** | `date` / `author` / frontmatter meta in the page header | `badge`, `badge-outline` | `Filed:`/author badges in `.daisy-meta-row` | Same badges, plain pill borders |
| **Warnings** | Docs warning paragraphs, renderer warnings surface (reserved `$warnings$`, oliver-contract) | `alert-error`, `--color-error` token | Error/warning text uses `--color-error` / `--color-warning` tokens; a full `alert` variant is one class away in content HTML | Same tokens, plain borders |
| **Badges** | Tech tags, status pills | `badge`, `badge-primary`, `badge-outline` | Navbar `Oliver-native` badge + meta badges | Same pills, no component fill |
| **Pagination** | Not yet rendered by Rotkeeper (planned primitive) | `join` + `btn` (`join-item`) | No implementation yet — mapped for implementers; a `join`-grouped row of `btn`s is the target markup | Same `join`-shaped DOM, plain buttons |
| **Code panels** | Fenced code blocks in `$body$` | `mockup-code` (or `pre` + tokens) | `pre` styled as a code panel: `--code-bg`, `--radius-box`, `overflow-x: auto` | Same panel, no mockup chrome |
| **Dividers** | `hr` between content sections | `divider` | `hr` as `base-300` rule; `divider` component available in content HTML | Same rule, plain border |
| **Inline links** | Body links, nav links | `.link` / `link-hover`, `--color-primary` | Body `a` uses `--color-primary` with underline + hover mix | Same link color, no hover mix |
| **Focus** | All interactive elements | component `:focus-visible` rules | Global `:focus` / `:focus-visible` outline on DaisyUI tokens | Same focus contract, plain outline |

## Token map (dracula, the prototype default)

`theme-daisy.html` renders with `data-theme="dracula"`. The a11y gate (`rotkeeper.sh a11y`) reads hex values from `:root`, so the oklch theme tokens DaisyUI ships are mirrored as sRGB hex in `theme-daisy.css`. These hex values are the gate's ground truth and must stay in sync with the vendored theme definitions:

| DaisyUI token (oklch) | Audit role (`theme-daisy.css` `:root`) | sRGB hex |
| --- | --- | --- |
| `--color-base-100` | `--bg-color` (page background) | `#050609` |
| `--color-base-200` | `--surface-color` | `#040507` |
| `--color-base-300` | `--code-bg` | `#030406` |
| `--color-base-content` | `--text-primary` / `--code-text` | `#efefe4` |
| `--color-base-content` @ ~60% on base-100 | `--text-secondary` (muted) | `#91928c` |
| `--color-primary` | `--accent-color` (links) | `#ff3190` |
| `--color-error` | (warnings surface) | `#ff1717` |
| `--color-warning` | (alert blockquotes) | `#e0f443` |

All audited pairs pass WCAG AA on the default scope: body 17.5:1, surface 17.6:1, secondary 6.5:1, accent links 5.9:1, code 17.7:1.

Because every surface keys off DaisyUI's `--color-*` tokens, re-skinning is a one-attribute change — and it is now wired to `palette:` frontmatter (the same field the terminal-forward family uses for its palette scopes). The daisy templates emit `data-theme="$palette$"` when `palette:` is present, so any of the **35 vendored theme names** is selectable per page:

`light`, `dark`, `cupcake`, `bumblebee`, `emerald`, `corporate`, `synthwave`, `retro`, `cyberpunk`, `valentine`, `halloween`, `garden`, `forest`, `aqua`, `lofi`, `pastel`, `fantasy`, `wireframe`, `black`, `luxury`, `dracula`, `cmyk`, `autumn`, `business`, `acid`, `lemonade`, `night`, `coffee`, `winter`, `dim`, `nord`, `sunset`, `caramellatte`, `abyss`, `silk`

```yaml
---
title: "Synthwave Interlude"
template: "theme-daisy.html"
palette: "synthwave"
---
```

No `palette:` means the page keeps the dracula default (the `html:not([data-theme])` guard in `theme-daisy.css` redeclares dracula so an absent attribute never falls through to the vendored build's bare light base). An unknown palette name falls back to that base palette. The vanilla twin accepts the same frontmatter but ships only its hand-written dracula palette — any other value still renders dracula, since registering a palette there is a hand-written exercise.

## Vanilla fallback (#250) — implemented

`theme-daisy-vanilla.html` is the zero-dependency twin of the prototype: its template is **byte-identical to `theme-daisy.html` except the stylesheet href** (one line), and `theme-daisy-vanilla.css` is entirely hand-written — no vendored daisyUI, no `@import`, no CDN, no build step. Rendering the same source through both themes diffs to a single line (the `<link>`). The hand-written stylesheet defines the same `--color-*` token names with the dracula hex values, hand-rolls the component classes the shared DOM carries (`.navbar`, `.btn`, `.badge`, `.card`), and passes the same a11y gate. Swap the template link and the page keeps its look with zero dependencies — the "internet thing that doesn't need the internet" counterpart to the prototype.

## Prototype status — decision gate run 2026-08-28

What the prototype proves, and what it costs:

- **Proves:** the vendored build works with zero CDN/Node; the a11y gate passes; the full harness stays green; the shared skeleton (nav slot, live footer) carries through; body content from plain Markdown renders without any DaisyUI classes — only the chrome and opt-in raw HTML use components.
- **Costs:** ~1.16 MB of vendored CSS served on every page (unavoidable without a build step); authors who want component styling *inside* content must write raw HTML with DaisyUI classes (Markdown cannot emit them); full utility-class coverage is not available (the vendored build ships color utilities only).

### The comparison (measured)

| Dimension | `theme-daisy` (vendored) | `theme-daisy-vanilla` (twin) | Family themes |
| --- | --- | --- | --- |
| **CSS payload per page** | ~1.16 MB (1,164,091 B across the two vendored files + 14 KB theme layer) | ~15.7 KB (15,745 B) | ~10–36 KB (spooky 10,076 B · textpattern 16,324 B · necropolis 35,590 B) |
| **Dependencies** | vendored compiled daisyUI 5.7.22, pinned with checksums | none | none |
| **Palettes** | 35 via `data-theme` / `palette:` frontmatter | 1 (dracula, hand-written) | per-theme scope sets (`palette:` where offered) |
| **Components in content** | via raw HTML with DaisyUI classes | same DOM, plain CSS only | not offered — markdown-first |
| **a11y gate** | pass (body 17.5:1, links 5.9:1, code 17.7:1) | pass (same ratios) | pass |
| **DOM contract** | shared skeleton + navbar/card chrome | byte-identical to daisy (href-only diff) | per-theme, shared skeleton |
| **Supply chain** | external upstream, manual pin + refresh procedure | none | none |

### Verdict: stays prototype — no graduation at this gate

The pair **does not join a family** in this gate run, and the vendored twin's open question is answered: 1.16 MB is **not** acceptable family-grade weight for a system whose identity is lean, on-prem, and node-free — the prototype's job was to prove the catch-22 was breakable, and it did. Three reasons drive the verdict:

1. **Weight.** The vendored build is ~75× a typical family theme's payload, served on every page. Family membership is a default-grade commitment; 1.16 MB doesn't clear that bar when the same DOM renders at ~16 KB.
2. **Content model.** DaisyUI's value is component styling, which requires raw HTML inside Markdown. Rotkeeper content is markdown-first — the prototype's own showcase renders fully from plain Markdown, with components only in the chrome. The map's component rows stay reference material for opt-in raw HTML, not a content contract.
3. **Family fit.** The pair matches none of the three family guarantees (terminal-forward, balanced, reading-first). Graduation would mean inventing a fourth family, which this gate doesn't authorize without broader adoption demand.

**What the gate does confirm:** both members stay registered and selectable per-site (`theme_registry`: `daisy` / `daisy-vanilla`), the palette mechanism works (35 names, verified `synthwave` live), and the vanilla twin is the **designated graduation candidate** — it is family-weight (~16 KB), zero-dependency, byte-identical DOM — pending the conditions below.

**Reopen conditions (any one triggers a re-gate):**

- A **trimmed vendored build** committed as the artifact — e.g. a one-time build that drops unused `themes.css` entries and unshipped components, checksum-pinned like today — removes the weight blocker and reopens the gate for `theme-daisy`.
- **Multi-palette coverage** in the vanilla twin (each hand-written palette is a documented exercise; the `html:not([data-theme])` guard and `palette:` plumbing are already in place) — reopens for `theme-daisy-vanilla`.
- Explicit **adoption demand** for a component-forward family — e.g. a consumer site that needs the component surface and accepts the weight — reopens both.

## Refreshing the vendored CSS

Pin the version deliberately — the prototype targets `daisyui@5.7.22`:

```bash
curl -sL -o /tmp/daisyui.css \
  "https://cdn.jsdelivr.net/npm/daisyui@5.7.22/daisyui.css"
curl -sL -o /tmp/daisyui-themes.css \
  "https://cdn.jsdelivr.net/npm/daisyui@5.7.22/themes.css"
# verify against the pins below, prepend the provenance header,
# then re-run: bash rotkeeper.sh a11y && bash rotkeeper.sh test
```

Pinned checksums (of the pristine upstream files, before the provenance header):

- `daisyui-5.7.22.css`: `bf1dcfbf41ece82e12f74264efb8a5c618b05a8daaf76bd8232f1ecf9c67fe46`
- `daisyui-5.7.22-themes.css`: `60b66a7bb2c94584bd22be63ada6140a5447a3448fb6eb2ec2de6623bc2d3ece`

---

*Back to*: [Theme Families](themes.md) · [Documentation overview](index.md)
