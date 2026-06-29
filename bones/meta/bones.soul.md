---
title: "💀 Bones Engine Root"
description: "Internal system directory coordinating configuration, scripts, templates, archives, and reporting metrics."
status: "complete"
---

## Architectural Intent
The `bones/` directory acts as the secluded nervous system of the Rotkeeper engine. It enforces a strict isolation boundary between the execution machinery—system configurations, bash rituals, HTML templates, execution logs, and reports—and the content estate (`home/content/`). This segregation guarantees that the user-facing content remains pristine and immune to operational side-effects. By confining all logic, orchestration, and build artifacts to `bones/`, the engine ensures a deterministic environment free from state contamination.

## Directory / File Schema Expectations
This directory operates under a rigid, immutable schema. User content markdown must never be placed here or within any operational subfolders.

- `scripts/`: The execution layer containing modular bash rituals.
- `config/`: The deterministic YAML configuration layer controlling engine behavior.
- `templates/`: Brutalist, framework-less HTML structural templates.
- `archive/`: Immutable storage for compressed execution artifacts.
- `releases/`: Deployment-ready static outputs.
- `ingested/`: Processed staging area for absorbed data sources.
- `reports/`: Automated compliance trackers, metric matrices, and diagnostic reports.
- `logs/`: Append-only execution and error traces.
- `tmp/`: Volatile workspace for ephemeral operations. Assumed destroyed between runs.
- `meta/`: The soul structure. Path-mirrored `.soul.md` files defining architectural intent and operational state.

## Preservation Notes
The survival of the Rotkeeper engine across decades relies on absolute hygiene within the `bones/` directory.
- Ruthlessly prune operational cruft from `tmp/` and `logs/`.
- Rely on automated, deterministic cleanup procedures to maintain directory integrity.
- Assume all execution state is ephemeral; never store unversioned, critical manual data within functional output directories.
- The separation of engine and content guarantees that even if the rendering system is replaced in the future, the content estate remains intact and the operational logic is distinctly portable.
