---
title: "Rotkeeper Reference (Dry)"
slug: rotkeeper-reference
template: rotkeeper-doc.html
description: "A neutral, boring reference manual for Rotkeeper."
---

# Rotkeeper Reference

This document serves as a straightforward reference for the Rotkeeper toolkit, detailing the scripts, configuration files, and standard operating procedures.

## Default Pipeline

The standard lifecycle of managing content in Rotkeeper follows this sequence:

1. **`init`**: Initialize the workspace (reseeds, installs assets, renders, scans).
2. **`new`**: Scaffold a new markdown page with required YAML frontmatter.
3. **`render`**: Convert markdown files into HTML tombs and package a timestamped backup.
4. **`assets`**: Generate the asset manifest and copy static files to output.
5. **`pack`**: Archive the rendered HTML into a shareable versioned tarball.
6. **`scan`**: Audit manifest integrity to ensure nothing is missing or orphaned.

## Core Scripts (`bones/scripts/`)

| Script | Purpose | Inputs | Outputs |
|---|---|---|---|
| `rc-init.sh` | Initializes the environment. | Repo state | Reseeded files, initial render, logs |
| `rc-new.sh` | Scaffolds a new markdown file. | Filename | `home/content/<filename>.md` |
| `rc-render.sh` | Converts markdown into HTML tombs. | `home/content/*.md` | HTML in `output/`, backup tarball |
| `rc-pack.sh` | Archives output into a versioned tarball. | `output/` HTML files | `bones/archive/tomb-*.tar.gz` |
| `rc-scan.sh` | Verifies manifest entries. | `bones/manifest.txt` | Scan reports, console warnings |
| `rc-assets.sh` | Generates asset manifest and copies assets. | `home/assets/` | `output/assets/`, `bones/asset-manifest.yaml` |
| `rc-book.sh` | Aggregates files into markdown binders. | Rendered/Config files | `bones/reports/*-book.md` |
| `rc-bump.sh` | Logs micro-update and bumps version. | Commit message | `CHANGELOG.md`, git commit |

## Configuration Files (`bones/config/`)

- **`rotkeeper.yaml`**: Canonical configuration file defining templates, asset management rules, and toggle behavior.
- **`rotkeeper-bom.yaml`**: Bill of materials for releases and distributions.
- **`asset-manifest.yaml`**: Generated checksums for static assets.
