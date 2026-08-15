---
title: "ci.yml"
description: "Metadata for the primary Continuous Integration GitHub workflow."
target_file: .github/workflows/ci.yml
source: generated
generated: 2026-07-03
version: 0.1.0
status: final
---

### Architectural Intent
The `ci.yml` workflow acts as the automated gatekeeper for code quality in the Rotkeeper repository. It guarantees that no broken shell scripts or failing rituals merge into the `main` branch by enforcing the execution of `setup.sh`, `./rotkeeper.sh smoke`, and `./rotkeeper.sh test` in an isolated GitHub-hosted runner.

### Directory / File Schema Expectations
Located at `.github/workflows/ci.yml`, it adheres to standard GitHub Actions YAML syntax. It expects `scripts/setup.sh` to exist and cleanly provision the required environment dependencies without user interaction.

### Restless Spirits
The workflow heavily depends on `scripts/setup.sh`, meaning any failure in downloading the remote `yq` binary will crash the entire CI pipeline, halting deployments.

### Ritual Warnings
Do not add complex logic or custom shell blocks directly into this YAML file. All execution logic should be housed within `rotkeeper.sh` or the `scripts/` directory to maintain local testability.

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 0000-00-00T00:00:00Z -->
TODO: Stitch necromancer notes.
