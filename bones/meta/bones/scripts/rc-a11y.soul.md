---
target_file: "bones/scripts/rc-a11y.sh"
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

The command runs an embedded Python 3 auditor. It discovers stylesheet
links in HTML templates, follows `@import url(...)` chains in import-first
order, and groups templates that share the same resolved stylesheet chain.
Findings describe CSS scopes, not rendered pages.

The auditor reads hexadecimal custom properties for semantic contrast pairs,
checks hardcoded color/background pairs, and looks for focus and overflow
rules. Its report separates passing, warning, failing, and skipped checks.
See [theme guidance](../../themes.html) and
[creating themes](../../creating-themes.html).

### Limits

This is a static, regex-based check, not a browser or full WCAG conformance
test. Missing semantic color tokens are skipped. A passing audit does not
establish that every element has usable focus, that every palette is
covered, or that a particular viewport renders correctly.

Discovery uses only the first recognized CSS link in each template. Templates
without a resolvable stylesheet chain are listed as skipped. The color parser
does not evaluate arbitrary CSS expressions or DaisyUI's oklch palettes.

Warnings alone do not produce a failing exit status. Put `--dry-run` and
`--verbose` before command-specific options: the shared flag parser stops at
the first unrecognized option.

### Cautions

`--css-dir` must resolve inside `ASSETS_DIR`, but imported paths are not
checked against that boundary. Audit trusted stylesheets.

`--report` is not restricted to `REPORT_DIR` by the implementation. Relative
report paths resolve from `ROOT_DIR`; an existing destination is overwritten.
The command does not create a missing report parent directory.

`--dry-run` runs the audit and keeps its Markdown preview in a temporary file
under `TMP_DIR`; it does not write the selected report. JSON mode removes
its result scratch file after emitting it. Both modes still write bootstrap
logs.
