---
title: "🔁 CI/CD Integration"
slug: ci-cd-integration
template: rotkeeper-doc.html
version: "0.2.3-pre"
updated: "2025-06-01"
description: "Outlines how to automate Rotkeeper rituals using cron or external pipelines. Focuses on render scheduling and tomb archiving."
tags:
  - rotkeeper
  - ci
  - automation
  - pipelines
asset_meta:
  name: "ci-cd-integration.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🔁 CI/CD Integration

Use Rotkeeper in CI/CD to auto-render, pack, and verify your markdown tombs on every commit, schedule, or push.

Rotkeeper automates file decay and HTML rendering for flat-file sites. While it's built for local rituals, it works smoothly in modern automation setups. This guide shows how to run Rotkeeper in cron-based or external scheduling systems.

These examples assume your repository includes all Rotkeeper scripts in `bones/scripts/` and that `rotkeeper.sh` is set as your CLI entrypoint.

A typical pipeline performs these steps in order:
- Initialize or expand the content tree
- Render HTML tombs from Markdown
- Generate a `.tar.gz` archive of the output
- Log actions to `bones/logs/`

***

## 📆 Cron Scheduling Example

To automate tomb generation weekly:

```bash
0 3 * * 1 /path/to/rotkeeper all >> /var/log/rotkeeper.log 2>&1
```

- Runs every Monday at 3:00 AM
- Appends stdout/stderr to `/var/log/rotkeeper.log`
- Assumes `rotkeeper all` handles init → render → pack

If you prefer more control, replace `all` with:

```bash
./rotkeeper init && ./rotkeeper render && ./rotkeeper pack
```

***

## 🧠 Checklist for Smooth CI Rituals

- 🪵 Inspect `bones/logs/` after every run

***

## 📦 Expected Output

Expect these outputs after each CI run:

- ✅ Rendered HTML in `/output/`
- 📦 Archive in `bones/archive/tomb-YYYY-MM-DD_HHMM.tar.gz`
- 🪵 Log entry in `bones/logs/rc-pack-*.log`
- 🧾 Optional: JSON export of all markdown tombs if `pandoc` and `jq` are installed

***

## 🔁 Full Ritual Pipeline (Manual or CI)

To run every major step in order, use:

```bash
./rotkeeper init
./rotkeeper expand
./rotkeeper render
./rotkeeper assets
./rotkeeper pack
./rotkeeper verify
./rotkeeper status
```

Add or remove steps depending on your tomb cycle or validation needs.

***

Back to [Troubleshooting FAQ](troubleshooting-faq.md)
Continue to [Advanced Usage](advanced-usage.md)


<!--
LIMERICK 1
The pipeline was built out of spite,
To render and pack tombs each night.
It looped through each phase,
With ritual haze—
And zipped them up sealed, out of fright.

LIMERICK 2
A cron job awoke at the hour of three,
To carve tombs in binary glee.
With echo and chmod,
It chanted a psalm,
And mailed all the logs back to me.

LIMERICK 3
In GitHub Actions, the workers convened,
As scripts ran in spectral ravine.
They checked asset-meta,
Then gave a wet pat—
And archived each build in routine.

SORA PROMPT 1
"An otherworldly CI/CD pipeline under moonlight, ghostly terminals chanting rituals, spectral GitHub Actions forging tomb archives in an abandoned server room"

SORA PROMPT 2
"A sepia-toned, vintage automation dashboard, with cron glyphs and tombstone icons, lit by flickering console output and haunted by versioned asset-manifests"
-->