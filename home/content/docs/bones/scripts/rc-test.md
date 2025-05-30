

---
title: "✅ rc-test.sh Reference"
slug: rc-test
template: rotkeeper-doc.html
version: "0.2.1"
updated: "2025-05-29"
---

# rc-test.sh

**Purpose:** Smoke‑test the Rotkeeper scripts suite by running each command under `--dry-run` and reporting PASS/FAIL.

## CLI Interface

```bash
rc-test.sh [--help] [--verbose]
```

Supported flags:

- `--help`, `-h`
  Show usage information and exit.
- `--verbose`, `-v`
  Show detailed logs for each script test.

## Workflow Steps

1. **Parse Flags & Setup**
   - Handle `--help` and `--verbose`.
   - Initialize a log file under `bones/logs/rc-test-<timestamp>.log`.

2. **Test Loop**
   - Iterate over each `rc-*.sh` in `bones/scripts/`, skipping `rc-api.sh`, `rc-unpack.sh`, and `rc-test.sh` itself.
   - For each script, run `bash <script> --dry-run`; capture exit status.
   - Log `PASS` or `FAIL` per script in both console and log file.

3. **Summary**
   - After testing all scripts, report the total number of PASS and FAIL counts.
   - Exit with status `0` if all passed, or `1` if any failed.

## Examples

```bash
# Run smoke tests
./bones/scripts/rc-test.sh

# Verbose mode for detailed logs
./bones/scripts/rc-test.sh --verbose

# Show help
./bones/scripts/rc-test.sh --help

<!-- 🎴 Limerick 1:
In scripts tested with failsafe so clever,
rc-test ensures all scripts live forever.
It loops through each file,
With a cheeky green smile,
And marks PASS when the run ends in never.
-->

<!-- 🎴 Limerick 2:
When flags dry-run or verbose arise,
rc-test logs each script’s compromise.
It reports every pass,
And each minor impasse,
Then exits with truth in its eyes.
-->
```