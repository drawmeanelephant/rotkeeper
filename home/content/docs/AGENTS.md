---
title: "Agent operating manual"
description: "Repository rules for automated agents and required validation."
template: rotkeeper-doc.html
reviewed: "2026-10-01"
---

# Agent operating manual

The root [AGENTS.md](https://github.com/drawmeanelephant/rotkeeper/blob/main/AGENTS.md)
defines repository operating rules. More specific instructions apply within
their scope. `.agentignore` is not a replacement for those instructions.

## Required practices

- Use `bash rotkeeper.sh <command>`, not direct `rc-*.sh` execution.
- Obtain human approval before adding scripts, commands, dependencies, or
  architectural subsystems.
- Preserve Bash strict mode and the `rc-utils.sh` bootstrap.
- Treat generated output and books as artifacts, not source authority.
- Check behavior against scripts and configuration.

## Validation

Run `bash -n` and ShellCheck on modified Bash scripts, then
`bash rotkeeper.sh test`, `bash rotkeeper.sh status`, and the relevant
supported dry-run commands. Report unavailable tools and pre-existing
failures. The [command development guide](new-ritual.html) defines the
help and sidecar contracts.
