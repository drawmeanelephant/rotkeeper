---
title: "🟢 theme-phosphor Layout Soul"
description: "CRT overlay interface configuration utilizing VT323 monospaced arrays for terminal emulation."
status: "complete"
target_file: "bones/templates/theme-phosphor.html"
source: "agent"
generated: true
model: "claude"
version: "1.0"
---

## Bones of the Code

### Architectural Intent
The aesthetic and functional objective of the phosphor theme is absolute utilitarian nostalgia. It ruthlessly emulates a vintage green-phosphor CRT terminal, forcing users into a retro CLI-like reading environment. This is not for comfort; it is for immersion in the terminal decay. No bloat, no hydration, just raw phosphor burn on cold glass.

### Directory / File Schema Expectations
The template enforces a strict architectural layout:
- CSS dependencies must map exactly to `css/theme-phosphor.css`, strictly loaded via the `$assets_root$` Pandoc variable.
- Imports the `VT323` monospaced font family via Google Fonts to enforce terminal aesthetics.
- The DOM requires a `.crt-overlay` overlay div to synthesize scanline and screen flicker degradation.
- The header injects the `$title$` variable behind a fake console prompt: `> $title$_`.
- Pandoc variable bindings (`$title$` and `$body$`) must remain unbroken in the HTML scaffolding to ensure proper payload delivery.

## Restless Spirits

The ghosts of terminals past are satisfied with this static layout. Do not attempt to animate the scanlines with JavaScript; such hydration will be treated as heresy.

## Ritual Warnings

### Preservation Notes
Maintain a minimal CSS footprint to simulate the CRT visual style without unnecessary DOM overhead. The external Google Fonts dependency (`VT323`) must remain functionally optional; the stylesheet must fallback to system monospaced fonts (`Courier`, `Monaco`, `monospace`) to guarantee usability in offline, post-network environments. The structure must survive terminal conditions without external dependencies.
