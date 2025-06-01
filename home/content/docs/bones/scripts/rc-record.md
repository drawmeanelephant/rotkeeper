---
title: "📜 rc-record.sh Reference"
slug: rc-record
template: rotkeeper-doc.html
version: "v0.2.3-pre"
updated: "2025-06-01"
description: "Record current git commit, timestamp, user, and host as part of a reproducible rotkeeper session dump."
tags:
  - rotkeeper
  - scripts
  - logging
  - git
asset_meta:
  name: "rc-record.md"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---
<!--
🎨 Sora Prompt:
"A ghostly scribe in a candlelit vault, recording every command, env var, and manifest whisper as the rotkeeper’s session unfolds."
-->
<!-- Begin Ritual Script Documentation -->
# 📜 rc-record.sh
<!-- The sacred objectives of rc-record.sh -->

## Purpose

<!-- The sacred objectives of rc-record.sh -->

- Emit a full ritual script from the current environment, capturing session commands, environment variables, manifest states, and log snapshots.
- Provide a reproducible dump of the Rotkeeper session as a sacred record.

## CLI Interface

<!-- How to invoke the recorder ceremony -->

```bash
rc-record.sh [--dry-run] [--verbose] [--help]
```

Supported flags:

- `--help`, `-h`
  Show usage information and exit.
- `--dry-run`
  Preview the record action without writing to file.
- `--verbose`
  Show detailed logs.

## Workflow Steps

<!-- Sequential rites performed by the recorder -->

1. **Setup & Configuration**: Ensure `bones/logs/` exists, parse flags.
2. **State Capture**: Collect Git SHA, timestamp, user, and host.
3. **Write or Preview**: Append to `bones/logs/record.log` or preview under dry-run.

## Exit Codes

<!-- Symbolic outcomes of incantation -->

- `0` — Record generated successfully.
- `1` — Error writing to output or missing directories.
- `2` — Invalid flag usage or missing manifest/logs when requested.

## Examples

<!-- Sample invocations for celebratory rites -->

```bash
# Record current state
./bones/scripts/rc-record.sh

# Preview recording without writing
./bones/scripts/rc-record.sh --dry-run --verbose

# Show help
./bones/scripts/rc-record.sh --help
```

## Roadmap

<!-- Aspirational rites to come -->

- Add a `--dry-run` mode to preview sections without writing.
- Support JSON-formatted output for machine-readable archives.
- Integrate with CI to auto-record each pipeline run.
- Emit colored terminal banners with ritual icons.
- Automated tests (bats/shunit2) to guard capture integrity.

## 🛣️ Navigation
<!-- Quick navigation links -->
- [Scripts Index](scripts/index.html)
- [Record Reference](scripts/rc-record.html)
- [Bones Home](index.html)


<!-- 🎴 Limerick 1:
A keeper of commits in midnight's deep shore,
rc-record scribed details galore.
With SHA and with time,
It preserved every rhyme,
So no ghostly command is ignored.
-->

<!-- 🎴 Limerick 2:
When sessions unravel with commands spread wide,
this script stands as your faithful guide.
It logs every state,
With a timestamped slate,
And keeps every record beside.
-->
