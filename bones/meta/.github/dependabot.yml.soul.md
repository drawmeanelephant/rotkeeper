---
title: "dependabot.yml"
description: "Metadata for the Dependabot automated dependency update configuration."
target_file: .github/dependabot.yml
source: generated
generated: 2026-07-03
version: 0.1.0
status: final
---

### Architectural Intent
The `dependabot.yml` file is designed to automate the maintenance of external GitHub Actions used in CI workflows. By strictly limiting the scope to `github-actions` on a weekly cadence, it ensures the CI pipeline remains secure and up-to-date without overwhelming maintainers with daily alerts or attempting to manage system-level bash dependencies.

### Directory / File Schema Expectations
Located at `.github/dependabot.yml`, it follows GitHub's standard YAML configuration schema for Dependabot. It must specify the `github-actions` ecosystem, the target directory (`/`), and apply specific labels (`dependencies`, `github-actions`) to generated PRs.

### Restless Spirits
If an upstream Action introduces a breaking change in a minor version bump, Dependabot will blindly create a PR for it. The system relies entirely on `ci.yml` catching the breakage.

### Ritual Warnings
Do not expand this to monitor arbitrary ecosystems (like npm or pip) since Rotkeeper strictly avoids frameworks and non-bash dependencies.

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 0000-00-00T00:00:00Z -->
TODO: Stitch necromancer notes.
