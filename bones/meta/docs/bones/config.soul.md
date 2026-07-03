---
title: "⚙️ Configurations Root"
description: "Central validation boundary for project schemas, directory variables, and skipping whitelists."
status: "complete"
---

# ⚙️ Configurations Root

## Architectural Intent
This meta-layer dictates how Rotkeeper evaluates its directories, tracks file lineages, and enforces exclusion rules during automated pruning cycles.

## Directory / File Schema Expectations
- `rotkeeper.yaml`: Defines core pipeline options, template bindings, and project parameters.
- `dip-whitelist.txt`: Contains strict flat-file expressions for files that must never be auto-purged or flagged as obsolete by rc-dip.sh.

## Preservation Notes
Keep this directory strictly offline-first. Schema extensions must pass raw text parsing checks without adding heavy external parser dependencies.
