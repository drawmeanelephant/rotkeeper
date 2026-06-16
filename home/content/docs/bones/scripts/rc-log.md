---
title: "📝 rc-log.sh Reference"
slug: rc-log
version: "0.3.0.15"
updated: "2026-06-15"
description: "Shared logging utility functions for all rc-*.sh scripts."
tags:
  - rotkeeper
  - scripts
  - logging
  - utility
asset_meta:
  name: "rc-log.md"
  version: "0.3.0.15"
  author: "Rotkeeper Ritual Council"
---

# `rc-log.sh`

**Script Path:** `bones/scripts/rc-log.sh`

**Purpose:** Provides standardized logging functions across the Rotkeeper ritual scripts. This utility is sourced internally by other scripts rather than executed directly by the user.

## Core Functions
- Auto-initializes log files in `bones/logs/` using the script's name.
- Standardizes log output formatting with timestamps and severity levels (INFO, WARN, ERROR, DEBUG).

## Usage
Sourced at the top of a script:
```bash
source "$(dirname "${BASH_SOURCE[0]}")/rc-log.sh"
```
