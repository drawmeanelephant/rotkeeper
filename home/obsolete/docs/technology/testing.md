


---
title: Rotkeeper Testing Guide
updated: 2025-06-05
status: draft
version: 0.2.6-pre
---

# 🧪 Rotkeeper Testing Rituals

This document outlines the testing framework used within Rotkeeper. All testing is CLI- and Bats-based — no web UI, no test runners, no frameworks beyond Bash and blood.

---

## 🔨 Test Types

### 🔧 Shell Script Tests (`bats`)
Located in `bones/tests/`, each test targets a specific `rc-*.sh` script.

Run all tests:
```bash
./rotkeeper.sh test
```

Or run directly:
```bash
bats bones/tests/rc-utils.bats
```

---

### 🧪 Integration Test Flow

The `init → reseed → render → scan` ritual is considered the minimal integration pipeline. Validate with:

```bash
./rotkeeper.sh init
./rotkeeper.sh render
./rotkeeper.sh scan
```

---

## 📁 Directory Structure

| Path | Purpose |
|------|---------|
| `bones/tests/` | Bats test scripts |
| `bones/logs/` | Output logs (should be auto-cleaned per test) |
| `bones/reports/` | Reports to verify against |
| `output/` | Rendered tombs to inspect |
| `home/content/` | Raw markdown tombs and assets |

---

## 📓 Notes

- Tests are logged automatically — check `bones/logs/test-*.log`
- Avoid mixing test artifacts with production assets
- Scripts that require internet access should be skipped or mocked
- Bats tests should use `run` + `assert` — not echo and hope

---

*Rotkeeper never dies. It verifies.*