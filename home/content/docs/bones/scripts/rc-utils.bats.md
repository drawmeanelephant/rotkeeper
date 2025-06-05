title: rc-utils.bats
description: Bats test suite for utility functions in rc-utils.sh
template: rotkeeper-doc.html
updated: 2025-06-04
version: "0.2.6-dev"
status: stable
asset_meta:
  name: rc-utils.bats
  type: test-suite
  version: "0.2.6-dev"
  author: Rotkeeper
  tracked: true
  license: CC-BY-SA-4.0
  source: bones/scripts/rc-utils.bats
  tags: [testing, bats, utility, cli]
---

# 🧪 `rc-utils.bats`

This file contains the test suite for verifying core utility functions defined in `rc-utils.sh`.

It is written using [Bats](https://bats-core.readthedocs.io/en/stable/), the Bash Automated Testing System, and lives at:

```
bones/scripts/rc-utils.bats
```

---

## ✅ Covered Functions

- `log()`: Ensures timestamped log output to stdout and optional `$LOG_FILE`
- `run()`: Executes or logs commands based on `DRY_RUN` setting
- `require_bins()`: Fails gracefully when binaries are missing
- `trap_err()`: Logs the error line number and exits with status 2
- `resolve_script_dir()`: Returns the source path of the script calling it

---

## 🧫 Notes

- The `run()` function is not available in subshells, so tests that call `run run ...` are skipped.
- `trap_err()` forcibly exits the shell, which interferes with Bats output capture — this test is also skipped.
- All test logs are written to `bones/logs/test-YYYY-MM-DD.log`.

---

## 📦 Running Tests

You can run the test suite manually:

```bash
./bones/scripts/rc-utils.bats
```

Or integrate into your CI pipeline via a wrapper like `rc-test.sh`.

---

*This test suite is part of the Rotkeeper v0.2.6-dev ritual hardening effort.*