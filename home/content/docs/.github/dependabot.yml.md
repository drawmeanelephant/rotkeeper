---
title: "dependabot.yml"
slug: dependabot
version: "v1.0.0"
updated: 2026-07-03
description: "Reference for Dependabot configuration."
tags:
  - rotkeeper
  - dependencies
  - github
asset_meta:
  name: "dependabot.yml.md"
  version: "v1.0.0"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "All Rights Reserved"
---

# 🤖 dependabot.yml — Dependency Automation

The `dependabot.yml` file configures automated dependency updates for GitHub Actions within the Rotkeeper repository.

This file lives at:

```
.github/dependabot.yml
```

---

## 🛠️ What It Does

1. **Action Monitoring**: Instructs Dependabot to scan `.github/workflows/` for outdated GitHub Actions versions.
2. **Automated PRs**: Generates Pull Requests to bump action versions on a weekly schedule.
3. **Labeling**: Automatically applies `dependencies` and `github-actions` labels to its generated PRs.

---

## 🔁 Behavior

- Runs on a `weekly` interval.
- Only monitors the `github-actions` package ecosystem. It does not monitor apt packages or shell binaries.

---

## ⚠️ Notes & Caveats

- Dependabot PRs still require the standard CI workflow (`ci.yml`) to pass before merging.

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-03T00:00:00Z -->
