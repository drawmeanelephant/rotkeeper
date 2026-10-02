---
title: "Template reference"
description: "Reference pages for HTML wrappers used by Oliver."
reviewed: "2026-10-01"
---

### Purpose

This directory documents the HTML wrappers in the active template directory.
Oliver renders the source body and applies a selected wrapper; templates
are not executed by this reference directory.

### Contents and conventions

Each reference corresponds to a template source. `$body$` and
`$assets_root$` are literal slots; metadata tokens and `$if(...)$` blocks
follow the Oliver contract. Inspect each wrapper and its stylesheet
separately; there is no directory-level enforcement of client-side behavior.
