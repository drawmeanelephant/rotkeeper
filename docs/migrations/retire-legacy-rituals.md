# Retiring Legacy Rituals Migration Document

This document outlines the migration strategy for retiring the following scripts:
- `rc-ingest.sh`
- `rc-sync-inbox.sh`
- `rc-cleanup-bones.sh`
- `rc-reseed.sh`

## `rc-ingest.sh`

**Previous Purpose:** Safely unpack and merge incoming `.tar.gz` payloads from the `messages-from-my-friends/` inbox into `home/content/messages/`.

**Inbound References:**
- `rotkeeper.sh` (dispatcher)
- `README.md`
- `AGENTS.md`
- `home/content/docs/architecture.md`
- `bones/meta/bones/scripts/rc-ingest.soul.md`
- `bones/scripts/rc-status.sh` (mentions `ingest` command)
- `bones/scripts/rc-sync-inbox.sh` (calls `ingest`)

**Replacement Behavior/Rationale:**
Rotkeeper should not own an inbox/message-ingestion workflow. Syncing inbox data should be outside Rotkeeper’s core responsibility. The script will be completely removed.

**Migration/Deprecation Guidance:**
The `ingest` command in `rotkeeper.sh` will be temporarily retained as a deprecation shim that exits nonzero with a message explaining that message ingestion is no longer part of Rotkeeper. The associated inbox directories (`messages-from-my-friends`, `bones/ingested`, `bones/quarantine`) will no longer be created or monitored.

## `rc-sync-inbox.sh`

**Previous Purpose:** Automates the AI documentation ingestion loop (scan → ingest → dip → render).

**Inbound References:**
- `rotkeeper.sh` (dispatcher)
- `README.md`
- `bones/meta/bones/scripts/rc-sync-inbox.soul.md`

**Replacement Behavior/Rationale:**
Same as `rc-ingest.sh`. The workflow is no longer supported. The script will be removed.

**Migration/Deprecation Guidance:**
The `sync-inbox` command in `rotkeeper.sh` will be temporarily retained as a deprecation shim that exits nonzero with an explanatory message.

## `rc-cleanup-bones.sh`

**Previous Purpose:** Backup and prune old unneeded directories (`tmp`, `archive`, `reports`, `book-reports`, `ingested`) and logs from `bones/`.

**Inbound References:**
- `rotkeeper.sh` (dispatcher)
- `README.md`
- `AGENTS.md`
- `bones/meta/bones/scripts/rc-cleanup-bones.soul.md`

**Replacement Behavior/Rationale:**
Rotkeeper should not own an aggressive “cleanup bones” deletion workflow. The script will be removed.

**Migration/Deprecation Guidance:**
The `cleanup` command in `rotkeeper.sh` will be temporarily retained as a deprecation shim that exits nonzero with a message.

## `rc-reseed.sh`

**Previous Purpose:** Reconstruct source files from a `.tar.gz` archive or resurrect from a bound markdown file (`rotkeeper-docbook.md`, etc.).

**Inbound References:**
- `rotkeeper.sh` (dispatcher)
- `README.md`
- `AGENTS.md`
- `bones/scripts/rc-init.sh` (called during `--full` initialization)
- `bones/meta/bones/scripts/rc-reseed.soul.md`

**Replacement Behavior/Rationale:**
Rotkeeper should not require reseeding to establish a usable project. Initialization should be non-destructive and layout-config-driven. The script will be removed.

**Migration/Deprecation Guidance:**
The `reseed` command in `rotkeeper.sh` will be temporarily retained as a deprecation shim that exits nonzero with a message. `rc-init.sh` will be refactored to remove the `rc-reseed.sh` dependency during `--full` execution.
