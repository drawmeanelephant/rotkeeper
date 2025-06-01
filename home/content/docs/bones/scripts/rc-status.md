---
title: "rc-status.sh"
slug: rc-status
template: rotkeeper-doc.html
subtitle: "Reports the current rotkeeper project state, including logs, active version, and tomb status."
version: "v0.2.3-pre"
updated: "2025-06-01"
description: "Provides a snapshot of the rotkeeper environment including changelog info, log count, manifest state, and current archive status."
tags:
  - rotkeeper
  - status
  - logs
  - version
  - audit
  - script
asset_meta:
  name: "rc-status.md"
  version: "v0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  type: "script-doc"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---
---

# `rc-status.sh`

This script provides a snapshot of the current Rotkeeper environment. It displays the active version, the latest changelog entry, recent logs, archive size summaries, and other system signals.

---

## 🧠 Purpose

To get a quick overview of the current tomb state without triggering full renders or validations. Useful for pre-deploy audits, post-pack confirmation, or ritual postmortems.

---

## 🌀 Usage

```bash
./scripts/rc-status.sh
```

No flags required. It operates read-only and emits to STDOUT.

---

## 📦 Example Output

```
Rotkeeper Version: 0.2.0
Last Blessing: 2025-05-28 03:14 UTC
Latest Tomb: bones/archive/tomb-0.2.0.tar.gz
Log Count: 37
Unblessed Files: 0
Manifest: bones/asset-manifest.yaml (valid)
```

---



<!-- 🎴 Limerick 1:
To query the bones with a glance so wise,
rc-status lets no secret disguise.
It shows you the state,
Before it’s too late,
And warns of decays in disguise.
-->

<!-- 🎴 Limerick 2:
In the hush of the script’s midnight tune,
status reveals what lurks in the tomb.
With version in line,
And logs all in time,
It guides your next ritual by noon.
-->
