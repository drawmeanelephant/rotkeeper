---
title: "ci.yml"
slug: ci-workflow
version: "v1.0.0"
updated: 2026-07-03
description: "Reference for the main CI workflow execution."
tags:
  - rotkeeper
  - ci
  - github
asset_meta:
  name: "ci.yml.md"
  version: "v1.0.0"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "All Rights Reserved"
---

# ⚙️ ci.yml — Continuous Integration

The `ci.yml` file defines the primary GitHub Actions workflow for the Rotkeeper repository, orchestrating automated checks on pull requests and pushes to the main branch.

This file lives at:

```
.github/workflows/ci.yml
```

---

## 🛠️ What It Does

1. **Environment Setup**: Provisions an Ubuntu runner and installs required dependencies using `scripts/setup-jules.sh`.
2. **Smoke Testing**: Executes the core `./rotkeeper.sh smoke` ritual to verify system integrity.
3. **Test Suite**: Runs the full bats-core test suite via `./rotkeeper.sh test`.

---

## 🔁 Behavior

- Triggers automatically on `push` to `main` and on `pull_request`.
- Fails the workflow immediately if any ritual (smoke or test) returns a non-zero exit code.

---

## ⚠️ Notes & Caveats

- Requires external network access to download the `yq` binary during the setup phase.

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-03T00:00:00Z -->
