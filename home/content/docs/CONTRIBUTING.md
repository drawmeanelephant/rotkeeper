---
title: "Contributing reference"
description: "Contribution guidance and the current repository rules."
template: rotkeeper-doc.html
reviewed: "2026-10-01"
---

# Contributing reference

[CONTRIBUTING.md](https://github.com/drawmeanelephant/rotkeeper/blob/main/CONTRIBUTING.md)
contains contribution guidance for content, templates, commits, and
generated artifacts. Use the root
[AGENTS.md](https://github.com/drawmeanelephant/rotkeeper/blob/main/AGENTS.md)
and the [command development guide](new-ritual.html) for current requirements.

## Current conventions

Keep generated output, logs, and release archives out of source commits.
Use the active layout's content and template directories. Content
frontmatter uses `---` delimiters. Scripts are Bash, not POSIX shell.

## Older instructions

The root contribution guide still includes historical examples using
`verify` and `record`; neither is a dispatcher command. Its `***`
frontmatter example is not the current YAML contract. Use
`bash rotkeeper.sh help` for supported commands and run the validation
required by the operating manual before submitting a change.
