---
title: "The Road to Bones"
slug: road-to-bones
subtitle: "Rotkeeper Buildlog & Resurrection Notes"
version: "0.5.0"
updated: "2026-07-23"
description: "An evidence-backed buildlog assembled from CHANGELOG.md and the repository history."
tags:
  - rotkeeper
  - changelog
  - buildlog
  - audit
---

# The Road to Bones

This is the living ledger of Rotkeeper's releases and structural work. Entries
below are transcribed from the repository's `CHANGELOG.md` or identified by
their exact Git commit. Where the source is silent, the ledger stays silent.

## Living Buildlog
<!-- LIVING_BUILDLOG_START -->
* `v0.5.0` - (2026-07-23) - Native Apex renderer integration, link audit tool, spooky theme, and atomic release packaging
* `v0.4.1` - (2026-07-22 13:13) - Release plumbing, cross-platform test safety, and documentation alignment

### 0.4.0.5 — 2026-07-01

`CHANGELOG.md` records parallel `rc-render.sh` processing, smaller `rc-pack.sh`
tarballs, improved `rc-scan.sh` orphan reporting, `rc-ingest.sh` validation,
streamlined `rc-dip.sh` parsing, and removal of redundant `rc-env.sh`
subshells.

### 0.4.0.4 — 2026-07-01

`CHANGELOG.md` records faster `rc-scan.sh`, multiple ingest sources,
configuration-aware packaging, improved render fallback handling, empty-sidecar
stitching in `rc-dip.sh`, and revised `rc-env.sh` resolution order.

### 0.4.0.3 — 2026-06-30 / 2026-07-01

The changelog records valid HTML output, native content packaging, faster scan
reference analysis, checksum validation, reliable ritual-history extraction,
and fewer environment subshells, followed by a release entry.

### 0.4.0.2 — 2026-06-30

Sidecar path-traversal boundaries were hardened and `rc-env.sh` subshell parsing
was optimized.

### 0.4.0.1 — 2026-06-29

Three-tier verbosity, render-backup pruning, and JSON AST packaging were
refined.

### 0.4.0 — 2026-06-26

The changelog records the Inbox Autopilot, Frankenstein document engine,
path-mirrored Necronotes, and comprehensive sidecar documentation.

### 0.3.1.4 through 0.3.0.2 — 2026-06-14 to 2026-06-22

The dated changelog entries record template parsing repair, version flags for
the ritual scripts, todo/test layout changes, CI updates, framework and
documentation stabilization, the test harness, snapshot/agent-handoff
commands, layout and render fixes, autoindex glue, non-destructive glue
updates, archive exclusion, reseed parsing fixes, vendor pruning, theme work,
and the initial decentralized ingestion and documentation rituals.

### 0.2.6-pre — 2025-06-05

`rc-reseed.sh` gained scriptbook/docbook/configbook resurrection and
`rc-book.sh` gained `--all` and YAML-collapse modes. Binder generation was
unified in `rc-book.sh`; the former expansion and webbook rituals were
deprecated or removed; rendering fallback and Bats edge cases were fixed.

## Structural Stabilization (Git evidence)

These changes are recorded by commit because the current `CHANGELOG.md` does
not contain release entries for them:

- `ea10e89` (2026-07-13), **chore: strict-mode safety audit and stability
  fixes** — strict-mode and quoting hardening across `rc-assets.sh`,
  `rc-book.sh`, `rc-dip.sh`, and `rc-glue.sh`.
- `45743da` (2026-07-13), **refactor: Centralize and harden dynamic
  environment loading sequence** — consolidated the canonical
  `rk_init_script`/`rk_load_env` sequence.
- `6de3c7d` (2026-07-13), **refactor: Convert validate_layout_alignment to a
  reliable preflight validator** — hardened layout/path preflight validation.
- `02ce096` (2026-07-15), **fix(rc-dip): stabilize discovery, ownership,
  stitch, and matrix** — ownership collisions and evidence-gated obsolete
  handling were made explicit, and matrix generation was stabilized.
- `3d7e77a` (2026-07-21), **Stabilize DIP stitching and matrix generation** —
  marker stitching became idempotent, authored boundaries are preserved, matrix
  status fallback is accurate, and generated writes remain atomic and bounded.

## Open Graves

The current DIP matrix is the source of truth for remaining documentation
work. Stub rows with real soul sidecars can be reviewed for de-stubbing; rows
without source material remain honest placeholders. The one Missing row and
the Unowned directory/index pages are documented in the review accompanying
this ledger. No history is invented for them here.

<!-- ROTKEEPER-GLUE-START -->
<!-- ROTKEEPER-GLUE-END -->
