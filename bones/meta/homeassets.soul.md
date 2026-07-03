---
title: "Asset Estate Root"
description: "Static resource directory for stylesheets, scripts, and imagery."
status: "complete"
---

### Architectural Intent
The `home/assets/` directory acts as the root CDN layer for compiled Rotkeeper static sites. It strictly houses static assets required by the `bones/templates/` layouts.

### Directory / File Schema Expectations
This directory acts as the top-level container for `css/`, `js/`, and `images/`. No dynamic markdown parsing or template generation targets this folder. It is purely an output dependency.
