---
title: "Theme Families"
slug: themes
template: "rotkeeper-doc.html"
version: "1.3"
updated: "2026-08-28"
description: "The three Rotkeeper theme families — terminal-forward, balanced, reading-first — their members, the readability guarantee each family carries, and the special-purpose 404 theme (necropolis)."
tags:
  - rotkeeper
  - themes
  - templates
  - accessibility
---

# Theme Families

Every template in `bones/templates/` belongs to one of three families — with one special-purpose exception, the dedicated 404 theme (`theme-necropolis.html`, below), and one prototype that is deliberately *not yet* a family member: `theme-daisy.html` / `theme-daisy-vanilla.html`, the DaisyUI presentation-layer prototype (#248) and its zero-dependency twin (#250), whose primitive/token map lives in [DaisyUI Primitive Map](daisyui-map.md). The family describes what the template puts *first*; the readability guarantee describes what it must never surrender to get there. All members (including the prototype pair) are registered in the config-driven theme registry (`theme_registry` in `bones/config/rotkeeper.yaml`, #252) and enforced by the static accessibility gate (`bash rotkeeper.sh a11y`, #258).

## The families

| Family | Members | Stated readability guarantee |
| --- | --- | --- |
| **terminal-forward** | `theme-phosphor.html`, `theme-brutal.html` (+ `mac` / `unix` / `pwsh` palette scopes) | Body text meets WCAG AA (4.5:1) on every shipped palette scope, CRT and prompt ornament stays outside the text column, and monospace-first typography never drops below the shared audit bar. |
| **balanced** | `theme-spooky-dark.html` (+ xhtml profile variant), `theme-dark.html`, `theme-light.html`, `theme-kawaii.html` | General-purpose rendering with decoration kept subordinate: AA contrast for body, secondary, link, and code pairs; visible keyboard focus; wide tables and code scroll instead of overflowing. |
| **reading-first** | `theme-spooky-light.html`, `theme-overgrown.html`, `theme-textpattern.html` | Longform comfort leads: serif or high-legibility prose faces, a capped measure (`--max-width` ≤ 900px), and the same AA contrast/focus/legibility bar as every other family. |
| **special-purpose** | `theme-necropolis.html` | Dedicated Tomb-Not-Found page, not a general content renderer: the signature 404 treatment (looming ghost numeral, blood-red entry, cracked slab) keys off the `$page_type$` token (v3 generic hook, #269). Still carries the shared asset-meta footer slot and must pass the same a11y gate. |
| **prototype (gate 2026-08-28: stays prototype)** | `theme-daisy.html`, `theme-daisy-vanilla.html` | DaisyUI presentation-layer prototype (#248) plus its zero-dependency vanilla twin (#250): `theme-daisy` renders the dracula-skinned skeleton through vendored compiled DaisyUI 5.7.22 CSS (on-prem, no CDN/Node); `theme-daisy-vanilla` shares a byte-identical DOM (only the stylesheet href differs) styled entirely by hand-written CSS. Both carry the navbar + config-driven `<site-nav>` nav, badge metadata, and card article surface, and both pass the same a11y gate. The decision gate ran 2026-08-28 and kept the pair in prototype status — the vendored build's ~1.16 MB payload and raw-HTML-in-content model don't clear family-grade weight or markdown-first bars — while naming the vanilla twin the graduation candidate (family-weight ~16 KB, zero deps). Both remain registered in the theme registry (`daisy` / `daisy-vanilla`) and selectable per-site; reopen conditions are in the [DaisyUI Primitive Map](daisyui-map.md). |

## What the guarantee means

All three families carry the same mechanical floor, verified per stylesheet scope by `rotkeeper.sh a11y`:

1. **Contrast** — hard pairs (body text on page background and surface, code text on code background) at **≥ 4.5:1**; soft pairs (secondary text, accent links, accent fills) at **≥ 3.0:1**, warned below 4.5:1. Checked for the default tokens, any `prefers-color-scheme: dark` overrides, and every opt-in `.palette-*` variant.
2. **Focus** — interactive elements declare a visible `:focus` indicator; suppressed outlines require a `:focus-visible` replacement.
3. **Narrow viewports** — wide tables and code blocks declare an overflow-x or pre-wrap strategy.

A template that fails the audit cannot call itself a member in good standing. New themes gate on passing before they join a family; CI runs the gate on every change to the tree.

## Family notes

### terminal-forward

Phosphor wears a scanline overlay and titles itself like a prompt (`> title_`). Brutal is a two-token ink-on-paper shell whose identity ships through its opt-in Terminal palettes — macOS Basic, classic xterm green, PowerShell blue — selected with `palette:` frontmatter. Its default ink/paper scope is the neutral base those palettes recolor; all scopes pass the audit independently.

### balanced

The site default (`theme-spooky-dark.html`) lives here alongside the XHTML profile variant, which changes the serialization, not the family. Kawaii proves decoration is welcome in this family — as long as it decorates borders and surfaces rather than sitting under body text.

### reading-first

Overgrown and Textpattern set Georgia-family serifs against muted grounds; Spooky-light is the declared light reading variant of the persistent Spooky experience. Each caps the measure so prose lines stay in the comfortable band on wide screens.

### special-purpose

Necropolis renders only the 404 page today: its `data-page-type` body hook is `$page_type$`, fed through the v3 generic hook (#269) — any frontmatter key the adapter merges into `wrap_meta` becomes an interpolatable token (see the [Oliver contract](oliver-contract.md)), so `page_type: 404` on the 404 page drives the haunting effects. It wears the same footer slot and passes the same gate as every other theme, but its readability guarantee is the 404 page's, not a general document's. Point any other page at the theme with its own `page_type` (or none) and the treatment scopes accordingly.

## Shared skeleton (all members)

Every template follows the same base skeleton — the variation between themes lives in CSS, ornament, and surface treatment, not in divergent HTML structure:

- **Header** — site/page title (`$title$`) plus optional deck (`$if(description)$`), per theme.
- **Nav** — optional; `theme-textpattern` and the `theme-daisy` / `theme-daisy-vanilla` prototypes ship one, driven from the `navigation:` block in `bones/config/rotkeeper.yaml` via the raw-HTML `<site-nav></site-nav>` slot (see `oliver-contract.md`). Templates without a nav simply omit the region.
- **Main/article** — `$body$` wrapped in the theme's article element.
- **Footer** — the standardized asset-meta slot, present on every theme:

```html
<footer class="<theme-footer>">
  <p class="footer-credit">Rendered by Rotkeeper · v$version$</p>
$if(asset_meta)$      <p class="footer-asset-meta">$asset_meta$</p>
$endif$$if(tags)$      <p class="footer-tags">$tags$</p>
$endif$    </footer>
```

`v$version$` is live from `bones/config/version` (the same single source `--version` uses); `$asset_meta$` and `$tags$` render the page's frontmatter asset meta and tags when present and are cleanly removed otherwise (the `$if$` markers sit at column 0 so a removed block leaves no blank line — keep that convention when adding gated lines). Lore lines (e.g. spooky's †-line, textpattern's colophon) are ornament and live above the slot. Because the footer is live, rendered goldens are version-sensitive: regenerate template goldens with `RK_REGEN_TEMPLATE_GOLDENS=1 bash rotkeeper.sh test` and update the smoke golden (`smoke-fixture-expected.html`) on version bumps.

## Shared identity primitives (#251)

The house voice — haunted, necrotic, candle-lit — is expressed through shared primitives in `home/assets/css/rk-identity.css` instead of copy-pasted CSS per theme. A theme opts in with one line at the top of its stylesheet (an `@import` must precede all other rules):

```css
@import url("rk-identity.css");
```

The primitives are token-driven: every color falls back to `inherit`/`currentColor`, and each theme re-skins by mapping the `--rk-*` tokens on its own `:root`. Because the a11y gate splices `@import` chains depth-first (importer-last), the shared file adds no contrast pairs of its own — the gate keeps reading the theme's own tokens.

**Divider** — `.rk-divider` base, `.rk-divider--ornate` (rule + icon between lines) and `.rk-divider--bones` (crossed bone ends around a skull). Markup is pure ornament: keep `aria-hidden="true"` on the container.

```html
<div class="rk-divider rk-divider--ornate" aria-hidden="true">
  <span class="rk-divider__line"></span>
  <span class="rk-divider__icon">💀</span>
  <span class="rk-divider__line"></span>
</div>
```

**Lore blocks** — `.rk-lore` / `.rk-lore--sub` / `.rk-lore-icon` carry the standard colophon voice ("The Rotkeeper tends the necropolis…") with a candle-flicker on the icons:

```html
<p class="rk-lore">⚗ <em>The Rotkeeper tends the necropolis — what is buried here is not lost.</em> ⚗</p>
<p class="rk-lore rk-lore--sub">
  <span class="rk-lore-icon" aria-hidden="true">🕯️</span>
  Abandon all hope, ye who enter here
</p>
```

**Icon set** — the house glyphs `† ⚗ 🕯️ 💀 🦇 ✝ ☠`, wrapped in `.rk-icon` (static) or `.rk-lore-icon` (flicker), always `aria-hidden="true"` — ornament, never read aloud.

**Token map** (`:root`, defaults shown; override only what you skin):

| Token | Default | Role |
| --- | --- | --- |
| `--rk-line-color` | `currentColor` | divider rule / bone body |
| `--rk-line-soft` | `currentColor` | gradient fade / bone knobs |
| `--rk-glow` | `currentColor` | divider line midpoint glow |
| `--rk-glow-aura` | `transparent` | skull-glow drop-shadow (opt-in) |
| `--rk-icon-size` | `1.5rem` | glyph size |
| `--rk-lore-color` | `inherit` | lore body text |
| `--rk-lore-sub-color` | `inherit` | lore sub-line text |

**Current consumers:** `theme-necropolis.css` (both dividers + full lore, mapped to the graveyard palette) and `theme-spooky.css` (lore block, mapped to the spooky dim tokens — covers spooky-dark, spooky-light, and the XHTML variant via its `@import`). A theme that doesn't want the haunted voice simply doesn't import the file.

## Choosing and comparing

Render the same content through every member with the showcase scaffolder (`bash rotkeeper.sh showcase`), or browse the [preview gallery](../showcase/showcase-preview.html) for the side-by-side wall. Set a page's template with `template:` frontmatter; the site default comes from `default_template` in `bones/config/rotkeeper.yaml`.

---

*Back to*: [Documentation overview](index.md)
