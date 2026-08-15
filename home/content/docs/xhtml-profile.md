---
title: "XHTML Output Profile"
slug: xhtml-profile
template: theme-spooky-dark-xhtml.html
render_profile: xhtml
version: "1.0"
updated: "2026-08-14"
description: "Rotkeeper's opt-in XHTML page render mode: Oliver's --to xhtml profile, the theme wrapper variant this page is built with, and the fail-closed raw-HTML boundary."
tags:
  - rotkeeper
  - oliver
  - xhtml
  - rendering
  - reference
---

# XHTML Output Profile

This page is itself an XHTML document. It rendered through Oliver's `--to xhtml` output profile, and its wrapper is the `theme-spooky-dark-xhtml.html` theme variant — an XML declaration plus `<html xmlns="http://www.w3.org/1999/xhtml">` in place of the usual `<!DOCTYPE html>`.

## How to opt in

Two knobs, mirroring how `input_format` works:

- **Per page (recommended):** add `render_profile: xhtml` to the source's YAML frontmatter. This page does exactly that.
- **Site-wide default:** set `render_profile: "xhtml"` in `bones/config/rotkeeper.yaml`. Per-page frontmatter still overrides it for individual pages.

The default is `html`, and when the profile is `html` the adapter invokes Oliver byte-identically to the pre-XHTML contract — no `--to` flag is appended at all.

## What changes on the wire

Oliver's XHTML profile is the same document, same semantics, different bytes:

- Void elements always use the XML form: `<hr />`, `<br />`, `<img ... />`.
- Attributes stay double-quoted in the existing fixed order.
- Escaping is the existing policy (XML predefined escapes, NUL replaced, raw Unicode preserved).
- The output is a **fragment only** — no DOCTYPE, no `<html>`/`<head>`/`<body>` wrappers. Rotkeeper's themes own the document wrapper, which is why an XHTML page needs an XHTML-aware theme variant like the one wrapping this page.

Most documents render byte-identically in both profiles; the suite asserts that.

## The raw-HTML boundary (fail-closed)

Markdown raw HTML (`.raw_html` and `.html_block` leaves, and Textile `pre.`) passes through verbatim under `html` but **fails closed** under `xhtml` with Oliver's typed `error.RawHtmlNotXmlWellFormed` — never repaired, never rewritten. A page selected for XHTML that contains raw HTML aborts the render loudly with that error and an actionable hint on stderr. That is intended behavior: convert the raw HTML (or drop the profile) rather than ship XML that cannot be guaranteed well-formed.

This page is deliberately CommonMark-safe — no raw HTML — so it survives its own profile.

## Verification

The XHTML document you are reading is well-formed: the render pipeline checked it with an independent XML parser (`xmllint`), and the harness's real-binary pass does the same for its own XHTML fixture. The full contract lives in [Oliver Renderer Contract](oliver-contract.md).