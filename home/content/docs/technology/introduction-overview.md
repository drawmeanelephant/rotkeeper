---
title: "Introduction & Overview"
slug: introduction-overview
template: rotkeeper-doc.html
---

# 🪦 Introduction to Rotkeeper

> “Rotkeeper is what you use when the version you’re saving might be the last one.”

***

## What Is Rotkeeper?

Rotkeeper is a ritual CLI system for building, preserving, and archiving flat-file sites and static artifacts. It is a final-draft builder for projects nearing entropy. It exists not to optimize, but to contain and document decay.

This project assumes you are working with collapsing sites, Markdown relics, digital zines, or static content that needs to be versioned and preserved with intent. It uses shell scripts, YAML, and minimal dependencies to produce `.tar.gz` tombs: bundled, reproducible site states you can carry across versions, projects, or eras.

***

## Who Is It For?

Rotkeeper is for archivists, solo builders, weird site maintainers, necroweb mystics, and those allergic to CMS sprawl. It is for end-of-life projects, long-tail repositories, and hand-authored pages that deserve dignity.

If you're looking for SEO scores, database backends, or React hydration—you are in the wrong graveyard.

***

## Why Rot? Why Ritual?

Because flat-file collapse is coming anyway.
Because your last deploy might be the only one that survives.
Because version control belongs in the file, not in an external repo you forgot to push.

Rotkeeper is built around ritual—not optimization. Each file contains metadata. Each render is an invocation. Each archive is a tomb.

***

## What Does It Replace?

Rotkeeper replaces:
- Half-maintained static site generators
- Git-based versioning with unclear scope
- Build tools with config rot and no self-awareness
- Bash hacks with no changelog or metadata trail

It gives you:
- Script headers with `asset-meta`
- `asset-manifest.yaml` to track file-level versions
- `rotkeeper` and `rc-*` tools for consistent behavior
- A repeatable archive cycle that doesn't require a repo

***

## Core Concepts and Ritual Structure

- **Tombs**: Bundled `.tar.gz` archives representing a complete site state
- **Ritual Scripts**: Bash files prefixed with `rc-` that handle rendering, scanning, versioning, and asset management
- **Rotkeeper CLI**: The central entry point (`rotkeeper`) that orchestrates the ritual
- **Asset Metadata**: Embedded YAML-style headers in every tracked file
- **Manifests**: Version maps (`asset-manifest.yaml`) showing what changed, when, and why

***

## Ready to Begin?

Start with the [Quickstart Guide](quickstart-guide.md) to render your first tomb.
Or jump to the [Configuration Reference](configuration-reference.md) to define your project's structure.

Rotkeeper is not here to scale. It is here to rot well.

Back to [Documentation Index](index.md)

<!--
LIMERICK

A keeper once built in despair,
Stored scripts with meticulous care.
Each folder a curse,
Each asset a hearse—
But the tombshell was perfectly bare.

SORA PROMPT

"a file archivist constructing a collapsing digital tomb, surrounded by obsolete shell scripts, monochrome glyphs, and hollow echoing logs"
-->