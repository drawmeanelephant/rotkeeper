---
title: "🎨 Presentation Layer Layouts"
description: "Zero-hydration layout targets. Standard Pandoc placeholders ($body$, $assets_root$, $title$) required."
status: "complete"
---

# 🎨 Presentation Layer Layouts

## Architectural Intent
Manages the visual bones of the compiled estate. This directory forces a strict zero-hydration rule across all generated pages.

## Directory / File Schema Expectations
- Layout files must be plain valid HTML containing valid Pandoc variables (e.g., `$title$`, `$description$`, `$body$`).
- BANNED: client-side reactive hydration scripts, framework runtimes, tracking bloat, or blocking assets.

## Preservation Notes
Templates are designed to outlive modern browser specifications. Stick to native CSS variables and standard layout flows.
