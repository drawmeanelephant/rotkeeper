---
title: "Continuous integration"
description: "Linux and macOS validation in the GitHub Actions test matrix."
template: rotkeeper-doc.html
reviewed: "2026-10-01"
---

# Continuous integration

Source:
[.github/workflows/ci.yml](https://github.com/drawmeanelephant/rotkeeper/blob/main/.github/workflows/ci.yml).

The workflow runs on pushes to `main` or `master`, pull requests targeting
those branches, and manual dispatch. The matrix uses `ubuntu-latest` and
`macos-latest` with `fail-fast: false`.

## Checks

- Install Zig 0.16.0 using the OS/architecture-specific archive and checksum.
- Install Bash 5 and ShellCheck on macOS.
- Run `scripts/setup.sh`, under sudo on Linux but not on macOS.
- Prove Oliver runs with a Markdown smoke render.
- Run ShellCheck on the dispatcher, Rotatui, and `rc-*.sh` scripts.
- Run `bash rotkeeper.sh test` with `RK_STRICT=1`.
- Run the theme accessibility gate with `bash rotkeeper.sh a11y`.

The final `test` job depends on the matrix. `test` and `smoke` select the
same Bash fixture harness; this workflow does not run a separate Bats suite.

## Limits

Provisioning requires network access and system installs. CI results do not
guarantee every behavior is correct, and this file does not establish
repository branch-protection settings. This page is authored because DIP
excludes `.github` from core discovery.
