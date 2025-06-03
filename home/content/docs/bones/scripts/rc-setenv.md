---
title: "🧱 rc-setenv.sh Reference"
slug: rc-setenv
template: rotkeeper-doc.html
version: "v0.2.5-pre"
updated: "2025-06-02"
description: "Environment validation and path scaffolding utility for Rotkeeper."
tags:
  - rotkeeper
  - scripts
  - env
  - setup
asset_meta:
  name: "rc-setenv.md"
  version: "v0.2.5-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# `rc-setenv.sh`

This script sets up the environment by creating all directories defined in `rc-env.sh`. It also verifies dependencies required across the Rotkeeper ritual scripts. Use this script when bootstrapping a new Rotkeeper workspace or validating structure after changes.

## 🔍 Behavior

- Sources `rc-env.sh` to load all `_DIR` and `_PATH` variables.
- Creates any missing directories, skipping:
  - System paths (e.g. `/usr/`, `/System/`)
  - Paths that point to `.sh` files
- Uses `require_bins()` from `rc-utils.sh` to verify required tools:
  - `bash`, `awk`, `grep`, `sed`, `tar`, `date`, `yq`, `htmlq`, `pandoc`
- Logs all actions using `log()` from `rc-utils.sh`

## ⚠️ Notes

- Script expects to be run from within the project root.
- If `rc-utils.sh` is not found, it will fail loudly.
- BASH_LOADABLES_PATH and other inherited variables may trigger false mkdir attempts without correct exclusions.

## 💀 Example

```bash
./bones/scripts/rc-setenv.sh
```

## 📁 Affected Paths

| Variable         | Directory Path                            |
|------------------|--------------------------------------------|
| OUTPUT_DIR       | `output/`                                  |
| REPORTS_DIR      | `bones/reports/`                           |
| ARCHIVE_DIR      | `bones/archive/`                           |
| ASSETS_DIR       | `home/assets/`                             |
| DOCS_DIR         | `home/docs/`                               |
| WEB_DIR          | `home/web/`                                |
| TEMPLATES_DIR    | `bones/templates/`                         |

---

This script does not mutate content — it only prepares your ritual site for life... or death.