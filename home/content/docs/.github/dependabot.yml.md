---
title: "Dependabot configuration"
description: "Weekly GitHub Actions update requests."
template: rotkeeper-doc.html
reviewed: "2026-10-01"
---

# Dependabot configuration

Source:
[.github/dependabot.yml](https://github.com/drawmeanelephant/rotkeeper/blob/main/.github/dependabot.yml).

The configuration uses Dependabot version 2 and monitors the
`github-actions` ecosystem at `/` on a weekly schedule. It applies
`dependencies` and `github-actions` labels to its update pull requests.

## Limits

It does not update apt packages, Homebrew packages, Oliver, or other shell
binaries. An update request is not evidence that a new action version works
with Rotkeeper. Review the diff and CI results before merging.

This page is authored because DIP excludes `.github` from core discovery.
