---
title: "Common Errors & Ritual Interruptions"
template: rotkeeper-doc.html
subtitle: "Troubleshooting and decay recovery procedures"
tags: [rotkeeper, errors, help, rituals, troubleshooting]
version: "0.2.5-pre"
updated: "2025-06-03"
asset-meta:
  author: "Filed Systems"
  project: "Rotkeeper"
  type: "help-doc"
  tracked: true
  version: "0.2.5-pre"
---

# ❌ Common Errors & Ritual Interruptions

Even in sealed environments, the rot may resist. This page collects common problems encountered during render, verify, or pack phases, and how to exorcise them.

***

## 🔧 Dependency Missing

**Symptom:**
Scripts fail with `command not found: yq` or similar.

**Fix:**
Install missing tool via Homebrew:

```bash
brew install yq jq pandoc
```

***

## 📂 Path or Directory Not Found

**Symptom:**
Errors like `No such file or directory: bones/logs/rc-render.log`

**Fix:**
Ensure `rotkeeper.sh init` has been run. If folders are still missing, create them manually:

```bash
mkdir -p bones/logs home/content output
```

***

## 🔐 Permissions Denied

**Symptom:**
Scripts fail with `Permission denied`.

**Fix:**
Ensure scripts are executable:

```bash
chmod +x scripts/rc-*.sh rotkeeper.sh
```

***

## 🧟 Weird Output or Render Fails

**Symptom:**
HTML output is empty or broken, or Pandoc errors.

**Fix:**
Check the Markdown frontmatter. You may be missing `title`, `template`, or `tomb-version`.

***

## 📉 Logfile Not Rotating

**Symptom:**
Multiple logs pile up in root folder.

**Fix:**
Ensure all `rc-*.sh` scripts are updated to write logs to `bones/logs/`.

***

## 🧪 Unknown Flag or Option

**Symptom:**
A script exits immediately with a usage summary or `unrecognized option` error.

**Fix:**
Double-check spelling of flags like `--dry-run`, `--debug`, `--help`. Most `rc-*.sh` scripts follow consistent GNU-style argument patterns.

***

> *“Every failed ritual is a lesson. Every log a confession.”*

> 🧼 *If you keep hitting the same error, try running `rotkeeper.sh audit` to diagnose deeper rot.*