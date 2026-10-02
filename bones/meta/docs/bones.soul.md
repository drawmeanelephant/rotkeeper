---
title: "System reference"
description: "Reference pages for configuration, scripts, templates, and generated system artifacts."
reviewed: "2026-10-01"
---

### Purpose

`docs/bones` contains documentation about the system root. It is not the
runtime `bones` directory. Scripts can write documentation under the
content root, so the layout separation is not a guarantee of no writes.

### Contents and conventions

The reference tree includes configuration, script, and template sections,
plus pages about archives and logs. Runtime release archives belong under
`bones/archive/releases`, not `bones/releases`. Generated reports and
archives must be checked against their source commands.
