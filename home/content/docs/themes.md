---
title: "Theme Families"
slug: themes
template: "rotkeeper-doc.html"
version: "1.0"
updated: "2026-08-25"
description: "The three Rotkeeper theme families — terminal-forward, balanced, reading-first — their members, and the readability guarantee each family carries."
tags:
  - rotkeeper
  - themes
  - templates
  - accessibility
---

# Theme Families

Every template in `bones/templates/` belongs to one of three families. The family describes what the template puts *first*; the readability guarantee describes what it must never surrender to get there. Families feed the config-driven theme registry (#252) and are enforced by the static accessibility gate (`bash rotkeeper.sh a11y`, #258).

## The families

| Family | Members | Stated readability guarantee |
| --- | --- | --- |
| **terminal-forward** | `theme-phosphor.html`, `theme-brutal.html` (+ `mac` / `unix` / `pwsh` palette scopes) | Body text meets WCAG AA (4.5:1) on every shipped palette scope, CRT and prompt ornament stays outside the text column, and monospace-first typography never drops below the shared audit bar. |
| **balanced** | `theme-spooky-dark.html` (+ xhtml profile variant), `theme-dark.html`, `theme-light.html`, `theme-kawaii.html` | General-purpose rendering with decoration kept subordinate: AA contrast for body, secondary, link, and code pairs; visible keyboard focus; wide tables and code scroll instead of overflowing. |
| **reading-first** | `theme-spooky-light.html`, `theme-overgrown.html`, `theme-textpattern.html` | Longform comfort leads: serif or high-legibility prose faces, a capped measure (`--max-width` ≤ 900px), and the same AA contrast/focus/legibility bar as every other family. |

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

## Choosing and comparing

Render the same content through every member with the showcase scaffolder (`bash rotkeeper.sh showcase`), or browse the [preview gallery](../showcase/showcase-preview.html) for the side-by-side wall. Set a page's template with `template:` frontmatter; the site default comes from `default_template` in `bones/config/rotkeeper.yaml`.

---

*Back to*: [Documentation overview](index.md)
