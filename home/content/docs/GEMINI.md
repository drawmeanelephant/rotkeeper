---
title: "Gemini agent guide reference"
description: "Agent context and the limits of historical guidance."
template: rotkeeper-doc.html
reviewed: "2026-10-01"
---

# Gemini agent guide reference

[GEMINI.md](https://github.com/drawmeanelephant/rotkeeper/blob/main/GEMINI.md)
provides agent-specific project context, directory roles, commands, and
workflow examples. Its still-current guidance includes using the dispatcher,
preserving strict mode, and changing source rather than generated output.

## Check historical claims

The guide still describes a `lite` distribution and an auto-committing bump.
Current release packaging produces one canonical ZIP, and bump commits only
when `--commit` is supplied. The test harness uses Bash fixtures, not Bats. The canonical version
comes from `bones/config/version`, not the guide's version stamp.

## Current authority

Follow the root
[AGENTS.md](https://github.com/drawmeanelephant/rotkeeper/blob/main/AGENTS.md),
script source, static help, and the
[command development guide](new-ritual.html). Historical examples do not
authorize new scripts or dependencies without human approval.
