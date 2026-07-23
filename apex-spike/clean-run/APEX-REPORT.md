# Apex Renderer Investigation Clean Run Report (`apex-spike/clean-run/`)

**Date:** 2026-07-23  
**Target Project:** Rotkeeper (`v0.3.1.3` / `v0.4.1`)  
**Apex Source:** [ApexMarkdown/apex](https://github.com/ApexMarkdown/apex.git) (Commit: `10509a11fe5032e1d157204927678e66c94f83c2`)  
**Experiment Root:** `apex-spike/clean-run/`  
**Isolated Baseline Worktree:** `apex-spike/clean-run/rotkeeper-baseline`  

---

## 1. Executive Summary & Verdict

### Final Verdict: **`CONDITIONAL`**

Apex is an exceptionally fast, C-native Markdown renderer (**2.55x faster** than Pandoc in direct Markdown-to-HTML conversion). However, Apex is **not a drop-in native replacement** for Pandoc in Rotkeeper due to structural differences in template handling and Lua filter mechanics.

Adopting Apex in Rotkeeper is **CONDITIONAL** upon:
1. Utilizing an explicit adapter layer (`apex-spike/clean-run/adapters/apex_adapter.py`) to interpolate frontmatter and body into Rotkeeper's Pandoc-style HTML templates (`$title$`, `$body$`, `$if(...)`) and rewrite internal Markdown links (`.md` -> `.html`, `.md#` -> `.html#`).
2. Bundling prebuilt Apex platform binaries or requiring build toolchain availability (`cmake`, C compiler) on target environments.

---

## 2. Environment & System Specifications

- **Operating System:** macOS 27.0 (Build 26A5388g) / Darwin Kernel 27.0.0 (ARM64)
- **Architecture:** `arm64` (Apple Silicon)
- **Pandoc Version:** `pandoc 3.10`
- **Embedded Pandoc Scripting Engine:** `Lua 5.4`
- **C Compiler Toolchain:** Apple clang version 17.0.0 (`clang-1700.6.3.2`), CMake 3.31.5

---

## 3. Phase 1: Isolated Pandoc Baseline Results

All baseline commands executed strictly inside worktree `apex-spike/clean-run/rotkeeper-baseline`:

- **Harness Test Matrix (`bash rotkeeper.sh test`):**
  - Result: `PASSED` (Verifications completed for `crypt`, `busy`, and `sterile` layouts; legacy ritual deprecations passed).
- **Three-Run Render Timings (`time bash rotkeeper.sh render`):**
  - Run 1: `11.944s` real (6.71s user, 3.74s system)
  - Run 2: `12.780s` real (7.42s user, 4.12s system)
  - Run 3: `13.473s` real (7.63s user, 4.48s system)
  - **Average Render Duration:** **12.73 seconds**
- **Rendered Output Metrics:**
  - Total rendered pages: **87 pages**
  - Link Audit (`bash rotkeeper.sh links`): 238 links checked, 1 pre-existing failure (`index.html -> messages/index.html`).
- **Archive Packager (`bash rotkeeper.sh pack --content`):**
  - Output Archive: `bones/archive/tomb-content-2026-07-23_1134.tar.gz`
  - Archive Size: **55 KB** (56,320 bytes)
- **Git Status Checks:**
  - Root Checkout (`git status --short`): `?? apex-spike/` (Untracked experiment directory; zero tracked files modified).
  - Worktree Status (`git status --short`): `?? bones/config/manifest.txt` (Clean baseline run).

---

## 4. Phase 2: Apex Build Analysis

- **Repository:** `https://github.com/ApexMarkdown/apex.git`
- **Commit SHA:** `10509a11fe5032e1d157204927678e66c94f83c2`
- **Build Commands Attempted:**
  1. `make` -> Failed due to sandbox restrictions on system MacPorts `libcurl`/`libssl.3.dylib`.
  2. `cmake -S . -B build && cmake --build build` -> **Succeeded**.
- **Executable Binary:** `apex-spike/clean-run/apex/build/apex`
- **Binary Executable Size:** **882 KB**
- **Dynamic Library Dependencies (`otool -L`):**
  - `/usr/lib/libSystem.B.dylib` (System C library)
- **Runtime Dependencies:** Fully self-contained C binary. Does NOT require external Lua or JSON dynamic libraries at runtime for basic execution.
- **Portability Assessment:**
  - Apex runs cleanly outside its build directory (verified at `apex-spike/clean-run/apex/build/apex`).
  - Pre-built binary availability across OS package managers (`brew`, `apt`, `pacman`) is currently low compared to Pandoc. Adoption requires bundling pre-compiled binaries or compiling on host.

---

## 5. Phase 3: Golden Corpus Setup

Created strictly under `apex-spike/clean-run/golden_corpus/`:
1. `golden-spooky-dark.md` (`theme-spooky-dark.html`)
2. `golden-spooky-light.md` (`theme-spooky-light.html`)
3. `golden-blog.md` (`rotkeeper-blog.html`)
4. `golden-doc.md` (`rotkeeper-doc.html`)
5. `coastal-radio/golden-nested.md` (`theme-spooky-dark.html`)

**Tested Elements Across Corpus:**
- YAML frontmatter (`title`, `description`, `author`, `date`, `tags`)
- Arbitrary custom metadata (`custom_meta`)
- Internal `.md` links and `.md#fragment` links
- External scheme URLs (`https://...`)
- Local asset references (`![Alt](/assets/...)`)
- Explicit heading IDs (`# Heading {#explicit-id}`)
- Fenced code blocks and tables

---

## 6. Phase 4: Native Apex Capability Tests & Adapters

### A. Metadata Capabilities
- **YAML Frontmatter Parsing:** Fully supported.
- **Custom Keys:** Preserved cleanly.
- **`--extract-meta`:** Outputs merged document metadata in YAML format.
- **Template Selection:** Apex does not natively read template keys from frontmatter to select HTML wrapper templates.

### B. HTML Output Commands
- `apex file.md`: Outputs an HTML **fragment** (no `<html>` / `<head>` / `<body>`).
- `apex file.md --to html`: Outputs an HTML **fragment**.
- `apex file.md --standalone`: Outputs a standalone document using Apex's internal, hardcoded HTML shell and inline CSS style block. Does not support referencing external HTML template files.

### C. Native Template Compatibility Gap
- **Native External HTML Templates:** Apex has **no native `--template` flag** for custom HTML templates.
- **Variable Syntax:** Apex supports `[%key]` syntax *inside Markdown text*, but has no engine to inject Markdown HTML body or frontmatter into external `$title$`, `$body$`, `$assets_root$` template fields.
- **Conditionals / Loops:** Apex lacks HTML template conditional logic (`$if(var)$ ... $endif$`).

### D. Lua Filter Compatibility Gap
- Executing `apex --lua-filter rewrite-links.lua` failed with `sh: lua: command not found` (exit code 1).
- **Reason:** Apex's `--lua-filter` invokes an external system `lua` binary over JSON stdin/stdout pipes rather than embedding a Lua interpreter like Pandoc. It does not support Pandoc's native global Lua environment hooks (`function Link(el)`).

### E. AST Output & Packaging Compatibility
- `apex file.md --to json` outputs valid Pandoc AST JSON schema `[1, 23, 1]`.
- **Divergence:** Apex's `-t json` leaves `"meta": {}` empty in the root JSON object. Rotkeeper's `rc-pack.sh` extracts frontmatter via `yq` into a separate key, so `rc-pack.sh` accepts Apex JSON AST without breaking `jq`, though `pandoc_ast.meta` remains empty.

### F. Explicit Adapters Created
To bridge these compatibility gaps for evaluation, one explicit adapter script was created under `apex-spike/clean-run/adapters/`:

- **Adapter Script:** `apex-spike/clean-run/adapters/apex_adapter.py`
- **Purpose:** Calls Apex CLI for Markdown-to-HTML conversion, extracts frontmatter via `--extract-meta`, rewrites internal `.md` / `.md#` links, and evaluates Pandoc template variable/conditional substitutions (`$title$`, `$body$`, `$assets_root$`, `$if(...)`).
- **Code Size:** **95 lines** (~3.2 KB).
- **Runtime Dependencies:** Python 3 standard library only (`os`, `sys`, `subprocess`, `re`). Zero external third-party dependencies.

---

## 7. Phase 5: Comparison & Performance Results

### Golden Corpus Timing Comparison (3 Benchmark Runs)

| Renderer / Execution Method | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) | Speedup vs Pandoc |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Pandoc CLI Baseline** | 292.07 | 135.91 | 138.84 | **188.94 ms** | 1.00x (Baseline) |
| **Apex Adapter (Python + Apex)** | 205.74 | 200.40 | 205.01 | **203.72 ms** | 0.93x |
| **Native Apex Direct (C Binary)** | 75.31 | 73.69 | 73.55 | **74.18 ms** | **2.55x faster** |

*Analysis:* Native Apex direct conversion converts Markdown **2.55x faster** than Pandoc (74.18 ms vs 188.94 ms). When wrapped in 5 individual Python process invocations (`apex_adapter.py`), subprocess startup overhead balances out the speed advantage (203.72 ms vs 188.94 ms).

### Link Audit Results (`rotkeeper links --root ...`)
- **Document-to-Document Links (`.md` -> `.html`, `.md#` -> `.html#`):** **100% Pass** on both Pandoc baseline and Apex adapter.
- **Local Assets:** 4 mock image placeholder references failed identically on both renderers because placeholder images (`/assets/logo.png`, etc.) do not exist in sample content.

---

## 8. Summary of Known Missing Native Features in Apex

1. **No External HTML Template Engine (`--template`):** Cannot natively substitute frontmatter variables into custom HTML wrapper files.
2. **No Embedded Lua Filter Engine:** Requires external system `lua` binary and stdin/stdout JSON filter protocol.
3. **Empty Metadata in AST Export (`-t json`):** The `"meta"` dictionary in `-t json` output is `{}`.
4. **OS Package Manager Availability:** Not currently available in standard OS package managers (`brew`, `apt`).

---

## 9. Final Safety Verification

Verified from original Rotkeeper checkout:
```bash
$ git status --short
?? apex-spike/

$ git worktree list
/Users/tbuddy/Documents/antigravity/rotkeeper                                d016434 [main]
/Users/tbuddy/Documents/antigravity/rotkeeper/apex-spike/rotkeeper-baseline  d016434 (detached HEAD)
/Users/tbuddy/Documents/antigravity/rotkeeper/apex-spike/clean-run/rotkeeper-baseline d016434 (detached HEAD)
```

- **Tracked Production Files Changed:** Zero (0).
- **Existing Content Deleted:** None.
- **Production Output Modified:** None.
- **Commits or Pushes:** Zero (0).
- **All Experiment Artifacts Path:** `apex-spike/clean-run/`
