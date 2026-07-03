---
title: "🔧 Execution Scripts Root"
description: "Central repository for bash-based automation rituals (rc-*.sh)."
status: "complete"
---

### Architectural Intent
The `scripts/` directory is the core operational engine of Rotkeeper. It isolates executable bash logic from configuration and templates.

### Directory / File Schema Expectations
All operational logic must be implemented in strictly POSIX-compliant bash. Files follow the `rc-*.sh` naming convention and are tightly coupled to the dispatcher (`rotkeeper.sh`). External binaries should be avoided in favor of coreutils, `gawk`, and `grep`.
