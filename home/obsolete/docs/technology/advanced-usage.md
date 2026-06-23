---
title: "🧠 Advanced Usage"
slug: advanced-usage
version: "0.2.3-pre"
updated: "2025-06-01"
description: "Collection of power-user techniques and advanced rituals for flexible Rotkeeper integration."
tags:
  - rotkeeper
  - advanced
  - tips
  - usage
asset_meta:
  name: "advanced-usage.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🧨 Advanced Usage

This section covers non-standard and experimental features of Rotkeeper. If you’ve built your first tomb and want more control, this page is your gateway to deeper rot.

***

## 🔁 Multi-Project Setup

You can create multiple tombs in parallel using separate config directories.
Each config folder should contain its own `init-config.yaml`, `asset-manifest.yaml`, and optionally templates/scripts:

```
projects/
├── site-a/
│   └── init-config.yaml
├── site-b/
│   └── init-config.yaml
```

Use:

```bash
cd projects/site-a
../../rotkeeper all
```

***

## ⚙️ Manual Subroutine Invocation

If you want to bypass the main CLI, you can invoke `rc-*` scripts directly:

```bash
./scripts/rc-init.sh
./scripts/rc-assets.sh
./scripts/rc-render.sh
./scripts/rc-pack.sh
```

Useful for scripting and CI environments.

***

## 🧪 Using `rc-scan.sh` to Detect Drift

`rc-scan.sh` compares your active filesystem to the current manifest. It surfaces:

- Missing files declared in `bones/manifest.txt`
- Orphan files that aren't tracked by any config or rendered output
- Assets referenced in HTML that no longer exist
- Markdown tombs missing required `asset-meta:` headers

Use `--json-only` or `--dry-run` for integration with audits or CI pipelines.

***

## 📜 Theming with External CSS

To override HiQ styling or use a different layout system:

1. Create a new CSS file (e.g., `themes/my-theme.css`)
2. Update your template’s `<head>` to point to the new stylesheet
3. Add the stylesheet to `init-config.yaml` and ensure it’s injected by `rc-assets.sh`

***

## 🧪 Future Feature: `inject.d/` Overrides

A planned feature (`rc-inject.sh`) would allow runtime injection of content from an `inject.d/` directory. This could include:

- Custom mascot metadata
- Pre-seeded logs or override scripts
- Local patches not tracked in version control

For now, this feature is speculative and not implemented.

***

## 🧠 Tips

- You can override the default layout by using `--template` when calling Pandoc
- Use environment variables (like `$TOMB_VERSION`) to inject version info into logs or output
- Experiment with file order in `manifest.txt` to control packing priorities

***


***

Back to [CI/CD Integration](ci-cd-integration.md)
Continue to [Roadmap & Contribution](roadmap-contribution.md)

<!--
LIMERICK

An override buried too deep
Caused scripts to awaken from sleep.
The template was glitched,
The CSS switched—
And the pipeline continued to creep.

SORA PROMPT

"an experimental static site generator branching into multiple tomb environments, procedural rot drifting between configs, spectral CSS threads binding templates"
-->