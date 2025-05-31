---
title: "Configuration Reference"
slug: configuration-reference
template: rotkeeper-doc.html
---

<!-- asset-meta: { name: "configuration-reference.md", version: "v0.1.0" } -->


# ⚙️ Configuration Reference

Rotkeeper uses a structured configuration file to initialize the project environment.
This reference explains the available fields, default values, and usage patterns for `init-config.yaml`.

***

## 📄 File: `init-config.yaml`

This YAML file is consumed by `rc-init.sh` (and indirectly by `rotkeeper init`) to determine which directories, templates, placeholders, and files to scaffold.

***

## 📁 Key Sections

### `dirs`
A list of directories to create if they don’t exist.

```yaml
dirs:
  - content
  - output
  - logs
  - templates
  - scripts
```

***

### `placeholders`
Touch files added to empty directories to keep them in version control.

```yaml
placeholders:
  - logs/.keep
  - output/.keep
```

***

### `templates`
Seed templates placed in `templates/` during init.
You can customize or override them later.

```yaml
templates:
  - templates/stackburger.html
  - templates/rot-notice.html
```

***

### `yamls`
YAML-based files to seed during init—includes config stubs and asset-metadata files.

```yaml
yamls:
  - init-config.yaml
  - asset-manifest.yaml
```

***

### `scripts`
Scripts seeded during init—should match your `rc-` naming convention.

```yaml
scripts:
  - scripts/rc-render.sh
  - scripts/rc-pack.sh
  - scripts/rc-bless.sh
```

***

## 🧬 Asset-Meta Integration

All config files should include an embedded asset-meta block like:

```yaml
# --- asset-meta ---
# file: init-config.yaml
# version: 0.1.3
# tomb-version: 0.1.7.5
# tracked: true
# updated: 2025-05-13
# --- end-meta ---
```

These fields are used by `rotkeeper`, `rc-bless.sh`, and `rc-scan.sh` to track decay, update status, and log file lifecycle changes.

***

## 🪦 Example Full `init-config.yaml`

```yaml
dirs:
  - content
  - output
  - logs
  - templates
  - scripts

placeholders:
  - logs/.keep
  - output/.keep

templates:
  - templates/stackburger.html
  - templates/rot-notice.html

yamls:
  - init-config.yaml
  - asset-manifest.yaml

scripts:
  - scripts/rc-render.sh
  - scripts/rc-pack.sh
  - scripts/rc-bless.sh
```

***

## 🧠 Tips

- Use `.keep` files to preserve empty folders across tombs
- Keep all paths relative to root unless otherwise noted
- The order of entries doesn't matter, but grouping improves legibility
- You can override templates and scripts by placing newer files in the tree before running `rotkeeper init` again

***

Back to [Documentation Index](index.md)
Continue to [Asset Pipeline](asset-pipeline.md)

<!--
LIMERICK

A config once typed in a daze
Defined all the folders and ways.
Its YAML was neat,
Its init complete—
And it bootstrapped the tomb through a haze.

SORA PROMPT

"a decaying yaml scroll outlining a tomb ritual, folders glowing as they are created, a ritual shell script reciting the keys into being"
-->