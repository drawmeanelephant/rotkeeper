---
title: "Rotkeeper"
slug: docs-index
template: rotkeeper-doc.html
version: "0.2.3-pre"
updated: "2025-06-01"
description: "Central index for Rotkeeper documentation, CLI usage, philosophy, and subroutine references."
tags:
  - rotkeeper
  - documentation
  - markdown
  - shell
  - decay
asset_meta:
  name: "index.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🪦 Rotkeeper

**Version**: `v0.2.0-dev`
**Status**: 🩸 Actively decaying
**License**: ✝️ BYOR (Bring Your Own Rot)
**Dogfood Sites**:
- [filed.fyi](https://filed.fyi)
- [tbuddy.org](https://tbuddy.org)
- [thermalextractiondevices.com](https://thermalextractiondevices.com)
- [fullonrogues.org](http://www.fullonrogues.org)
- [corgifever.com](https://www.corgifever.com)

> Rotkeeper is a ritual CLI for building, versioning, and preserving digital tombs.
> It tracks decay, embeds metadata, and renders the last good state of a flat-file system.
> It is not optimized. It is not scalable. It is designed to rot beautifully.

## 🧰 Capabilities

- 🏗️ Scaffold and initialize new tomb environments
- 📦 Pack reproducible `.tar.gz` tombs from versioned files
- 🧬 Apply `asset-meta` headers to every tracked script, template, and config
- 🕵️ Scan for missing assets, file drift, and forgotten metadata
- 🪞 Emit ritual logs and self-documenting playback scripts
- 📜 Dogfood itself across forgotten sites

## 🔩 Script Architecture

Rotkeeper is composed of a central CLI (`rk`) and sorted subroutines prefixed with `rc-`, e.g.:

- `rc-init.sh` — Initialize environment
- `rc-render.sh` — Render tomb content (Markdown → HTML via Pandoc)
- `rc-assets.sh` — Copy static assets into output folder
- `rc-scan.sh` — Detect unversioned or missing files
- `rc-pack.sh` — Pack all files into an archive
- `rc-bless.sh` — Finalize a version and write a changelog

## 🧱 Project Philosophy

- Every file is treated as a tombstone.
- Every version is tracked in YAML.
- Every project is assumed to be on its last legs.

Rotkeeper is a system for maintaining end-of-life software with clarity, finality, and documentation as ritual.

## 📂 Documentation Suite

1. [📁 Introduction & Overview](introduction-overview.md)
<!--
haiku:
(initiation)

Tomb rites begin here.
Flat files awaken slowly—
Rotkeeper takes root.
-->
2. [⚡ Quickstart Guide](quickstart-guide.md)
<!--
haiku:
(quickstart)

Bootstrapped in one breath.
A tomb is born from nothing—
Packed in ritual.
-->
3. [⚙️ Configuration Reference](configuration-reference.md)
<!--
haiku:
(configuration)

YAML spells are cast.
Options etched in silence—
The tomb obeys them.
-->
4. [🧪 Migration Test Walkthrough](migration-test-walkthrough.md)
<!--
haiku:
(migration)

Old bones shift and crack.
Migration rites test the seams—
Nothing rots alone.
-->
5. [📦 Asset Pipeline](asset-pipeline.md)
<!--
haiku:
(assets)

Each file carried forth,
Pipeline ferries offerings—
Payloads for the tomb.
-->
6. [🧱 Template Library](template-library.md)
<!--
haiku:
(templates)

Patterns set in stone,
Library of blank markers—
Ritual repeats.
-->
7. [📐 Content Structure](content-structure.md)
<!--
haiku:
(structure)

Bones align in rows,
Folders nested, files in place—
Order before rot.
-->
8. [🗿 Limericks & Creative Corner](limericks-creative-corner.md)
<!--
haiku:
(creative)

Whimsy breaks the mold,
Rhyme and rot in harmony—
Decay can still sing.
-->
9. [📉 Logging & Diagnostics](logging-diagnostics.md)
<!--
haiku:
(logging)

Silent rot betrayed,
Logs whisper of subtle change—
Diagnose the end.
-->
10. [🧑‍🎤 Persona Management](persona-management.md)
<!--
haiku:
(persona)

Masks behind the veil,
Each persona leaves a trace—
The tomb keeps their names.
-->
11. [🩹 Troubleshooting FAQ](troubleshooting-faq.md)
<!--
haiku:
(troubleshooting)

Glitches in the crypt,
Questions echo, answers rise—
Decay finds its cure.
-->
12. [🔁 CI/CD Integration](ci-cd-integration.md)
<!--
haiku:
(ci-cd)

Pipelines on repeat,
Automated rites persist—
Decay, then rebirth.
-->
13. [🧨 Advanced Usage](advanced-usage.md)
<!--
haiku:
(advanced)

Secrets in the scripts,
Advanced hands invoke the deep—
The tomb yields its core.
-->
14. [🗺️ Roadmap & Contribution](roadmap-contribution.md)
<!--
haiku:
(roadmap)

Paths fork in the dusk,
Contributors chart the way—
Rotkeeper marches.
-->
15. [🔍 Scan & Verify Tools](scan-verify-tools.md)
<!--
haiku:
(scan)

Hidden rot revealed,
Scanners sweep the tomb for truth—
Integrity lives.
-->
    *Detect rot, validate assets, confirm changelog eligibility.*

16. [📓 Changelog & Version Blessing](changelog-blessing.md)
<!--
haiku:
(changelog)

History entombed,
Bless each change with sacred ink—
Freeze the rot in time.
-->
    *Emit diffs, freeze versions, and record tomb integrity.*

17. [🧃 Ritual Record Generator](ritual-record.md)
<!--
haiku:
(ritual-record)

Rituals replay,
Scripts echo the ancient steps—
Records never die.
-->
    *Dump reproducible shell scripts from recorded ritual logs.*

18. [📜 CLI & Subroutine Reference](rotkeeper-help.md)
<!--
haiku:
(cli)

Commands guide the hand,
Subroutines perform the rites—
Rotkeeper obeys.
-->