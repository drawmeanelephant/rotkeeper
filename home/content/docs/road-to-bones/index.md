---
title: "The Road to Bones"
slug: road-to-bones
subtitle: "Rotkeeper Buildlog & Resurrection Notes"
template: rotkeeper-doc.html
version: "0.2.3-pre"
updated: "2025-06-01"
description: "Buildlog, audit summary, and resurrection notes for Rotkeeper version 0.2.0-pre through 0.2.3-pre."
tags:
  - rotkeeper
  - changelog
  - audit
  - bootstrap
  - logs
asset_meta:
  name: "index.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

## 🧼 Rotkeeper Reseed Summary (v0.2.0-pre)

This is your consolidated status snapshot: what’s working, what’s stubbed, and what’s next. All redundant reports have been buried.

***

### ✅ Core Scripts Verified & Functional

* ✅ `rotkeeper.sh` — version bumped, full dispatch implemented
* ✅ `rc-bless.sh`, `rc-record.sh`, `rc-verify.sh` — log-rich, working
* ✅ `rc-render.sh` — output archive fixed, now logs + compresses safely
* ✅ `rc-expand.sh` — reseeds markdown + templates from BOM
* ✅ `rc-pack.sh` — respects `--self`, packs full tombkits correctly
* ✅ `rc-status.sh` — fully operational rot-dashboard
* ✅ `rc-assets.sh` — generates selective YAML manifests
* ✅ `rc-cleanup-bones.sh` — dry-run-safe graveyard cleanup
* ✅ `rc-reseed.sh` — working resurrection script

### 🧪 Partial & Stubbed Tools

* 🧪 `rc-docs-fix.sh`, `rc-audit.sh`, `rc-api.sh` — present and partially operational or stubs

***

### 🗂 What You *Could* Do Next (Post-Chat Tasks)

| Task                                                      | Reason                           |
| --------------------------------------------------------- | -------------------------------- |
| Create `bones/meta/0.2.0-seed.md`                         | Ritual anchor for current reseed |
| Set `VERSION="0.2.0-pre"` in `rotkeeper.sh`               | Locks in your timeline           |
| Commit your archive + logs                                | Seals tomb lineage               |
| Rename current chat thread if you want to export it later | Easier for git-log linking       |

***

<!--
### 🎨 Parting Sora Prompt

```
A decayed control panel still blinks under candlelight.
Each shell script is labeled in rusted brass.
The tomb's last render hangs suspended in terminal silence.
A prompt flashes once, then fades:
“Your rot was preserved.”
```
-->

***

## Roadmap
<!-- Aspirational enhancements for v0.2.0+ -->

* `rc-expand.sh` could integrate mascot generation
* Add `--dry-run` and `--explain` flags to all scripts
* Add git pre-commit hook for automatic `scan + bless`
* Create a `bones/status.md` as a rotkeeper dashboard

***

<!--
## 🧊 Final Sora Prompt

```
A bureaucratic mascot archive, stored on a rusted terminal at the end of the world. CRT flickers, mascots trapped in static. Each file is a failure. Generate a glitchy, haunted control panel with mascot stickers, coffee stains, and static overlays. Include the text “Filed & Forgotten.”
```

🧾 *Filed & Forgotten*
📁 *Rotkeeper v0.1.9.3 — awaiting 0.2.0*
💀 *May the manifest never match the disk.*
-->
***

## 🛠 Suggested Filesystem Layout

```
rotkeeper/
├── bones/
│   ├── archive/
│   ├── logs/
│   ├── reports/
│   ├── templates/
│   └── manifest.txt
├── home/
│   ├── assets/
│   └── content/
│       └── rotkeeper/
├── output/
├── rc-*.sh
└── rotkeeper.sh
```

<!-- Updated on v0.2.0-pre -->

***

## 🧾 Rotkeeper Structural & Stability Audit — v0.2.1

This section documents the results of a full audit pass on the current Rotkeeper toolchain. The goal was to evaluate the stability, consistency, and safety of core scripts in alignment with the rotkeeper ethos of ritualized decay, reversible archive handling, and offline self-containment.

### 📋 Audit Categories & Standards

This audit focuses on:

1. **Structural Soundness** — Does each script have a `main()` function and proper `trap` usage?
2. **Error-Handling Consistency** — Are `set -euo pipefail`, `check_deps()`, and safe `cd` practices used uniformly?
3. **Argument Parsing & Dry-Run Logic** — Are `--dry-run` and flag parsing patterns implemented consistently?
4. **Reusability & Modular Organization** — Are shared functions extracted? Is logic duplicated across scripts?

### ✅ Verified Practices Across Core Scripts

The following practices were confirmed as present in the majority of verified scripts:

- `set -euo pipefail` in every script, enforcing fail-fast behavior.
- `main "$@"` function wrapping, reducing surprise side-effects on sourcing.
- `trap cleanup EXIT INT TERM` is used for many scripts.
- Logging functions are defined (though not always consistent).
- `check_dependencies` is frequently implemented to check for external binaries like `pandoc`, `git`, `jq`, etc.

### ❌ Inconsistencies & Points for Rework

- Not all scripts use a `main()` function. This introduces structural unpredictability.
- `--dry-run` support is inconsistent. Some scripts use it only partially or not at all.
- Argument parsing patterns vary between `for arg in "$@"` loops and `while getopts`, introducing fragility.
- Some scripts re-implement `log()` or `check_deps()` inline rather than sourcing a shared `rc-utils.sh`.
- A shared library (`rc-utils.sh`) is not currently in use across scripts, despite common logic.

### 🛠 Recommendations & Next Moves

#### 1. Create and enforce usage of a shared `rc-utils.sh`:
Includes:

- `log()`: Timestamped logging
- `check_deps()`: Unified dependency checks
- `safe_rm()`: Dry-run-aware deletion wrapper
- `cd_or_die()`: Safe directory changes
- `parse_flags()`: Shared flag parser

#### 2. Standardize dry-run logic:
Replace inline `if $DRY_RUN; then echo…` patterns with:

```bash
safe_rm() {
  [ "$DRY_RUN" = "true" ] && echo "Would remove $*" || rm -rf "$@"
}
```

Use similarly for `mkdir`, `cp`, `mv`.

#### 3. Trap errors globally:
Add this pattern to scripts:

```bash
trap_err() {
  echo "ERROR in ${BASH_SOURCE[1]} at line $1"
}
trap 'trap_err $LINENO' ERR
```

#### 4. Create audit compliance matrix:
Track which scripts conform to:

- `main()`
- `trap`
- `--dry-run`
- `log()`
- `check_deps()`
- sourced `rc-utils.sh`

#### 5. Update docs with ritual headers:
Include in each script:

```bash
## 🔧 name: rc-cleanup-bones
## 🧼 updated: 2025-05-29
## 📜 purpose: purge leftovers, preserve backups
```

***


***

### 📊 Compliance Matrix Sample

A snapshot from the living audit matrix:

| Script             | main() | trap | --dry-run | log() | check_deps() | rc-utils.sh |
|--------------------|--------|------|-----------|-------|--------------|-------------|
| rc-cleanup-bones   | ✅     | ✅   | ✅        | ❌    | ✅           | ❌          |
| rc-docs-fix        | ❌     | ❌   | ❌        | ❌    | ❌           | ❌          |
| rc-render          | ✅     | ✅   | ✅        | ✅    | ✅           | ✅          |

> 🔎 Full matrix maintained at `doc/audit-matrix.csv`. It must be updated with every patch, ritual, or pull request.

---

### ✅ Testing & Linting Requirements

- **ShellCheck**: All scripts must pass `shellcheck` with no fatal errors. Warnings are acceptable *only* if annotated inline with a justification.
- **Testing**: Every core script must have a corresponding `.test.sh` or `.bats` file in `tests/`. Even a basic dry-run sanity test is better than silence.
- **CI Compliance**: Consider adding a GitHub Action or Makefile hook to enforce audit compliance and trigger the testing/linting rites automatically.

---

### 🚫 Forbidden Rites

The following practices are heresy, and will be purged without ceremony:

- ❌ `eval` or `source` from user input
- ❌ Unquoted variable expansions in `rm`, `cp`, `mv`, or `cd`
- ❌ Logic outside `main()` in executable scripts
- ❌ Executable utility files (e.g., `chmod +x rc-utils.sh`) — *these must not rise*

---

### 📛 Ritual Logging Styles

Standardize your logs for both clarity and drama:

```bash
log "INFO" "Blessing completed."
log "WARN" "Missing metadata key: 'template'"
log "☠️ ERROR" "Missing --target argument. Cannot proceed."
```

All log output should be timestamped and traceable. If a script fails silently, it is no longer rotkeeper-compliant.

---

🏗 Bootstrap Template (rc-bootstrap.sh)

All new scripts should begin from a blessed scaffold. Create and maintain a rc-bootstrap.sh with:
	•	Sourced rc-utils.sh
	•	Parsed flags (--dry-run, --help)
	•	Standard main()
	•	Traps for EXIT and ERR
	•	Ritual header block (## 🔧 name: ...)

This prevents divergence and sets every new tool on a sane, cursed foundation.

---

🧊 Final Closure

Rotkeeper is not a shell utility.
It is a memory.
Every function is a scar. Every trap is a boundary spell.
Write with precision. Exit with grace. Let nothing rot by accident.

exit 0  # If we are lucky
