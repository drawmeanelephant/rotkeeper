# Rotkeeper Apex Renderer Spike Report

**Date:** 2026-07-23  
**Target Project:** Rotkeeper (`v0.3.1.3` / `v0.4.1`)  
**Apex Repository:** [ApexMarkdown/apex](https://github.com/ApexMarkdown/apex.git) (Pinned Commit: `10509a11`)  
**Spike Directory:** `apex-spike/`  

---

## 1. Executive Summary & Verdict

### Final Verdict: `CONDITIONAL`

Apex is a modern, C-native Markdown renderer that delivers **2.18x faster raw Markdown conversion** compared to Pandoc. However, because Rotkeeper relies on Pandoc's native `--template` interpolation engine and embedded Lua filter runtime (`rewrite-links.lua`), replacing Pandoc directly with Apex is **not a drop-in replacement**.

An Apex integration into Rotkeeper is viable **CONDITIONAL** upon:
1. Adopting a lightweight adapter/wrapper layer (e.g. `apex_adapter.py` or bash wrapper) to handle HTML template variable substitution (`$title$`, `$body$`, `$if(...)`) and internal link rewriting (`.md` -> `.html`).
2. Ensuring build toolchain availability (`cmake`, C compiler, `libcurl`, `libssl`) or distributing prebuilt Apex binaries across target platforms.

---

## 2. Baseline Metrics & Environment

- **Host System:** macOS (Darwin arm64)
- **Pandoc Version:** `pandoc 3.10` (Lua 5.4)
- **Rotkeeper Baseline Harness:** `bash rotkeeper.sh test` passed successfully in isolated worktree `apex-spike/rotkeeper-baseline`.
- **Rotkeeper Render Pass Timing:**
  - Full `rotkeeper.sh render` (Pandoc): ~11.5 seconds across full content directory.
  - Golden Corpus (5 representative sample files): **156.73 ms** (average over 5 runs).

---

## 3. Apex Build & Installation Analysis

- **Apex Version:** `1.1.13` (Commit `10509a11`)
- **Build Toolchain:** `cmake` + `clang` / `gcc`
- **Binary Output:** `build/apex` (Executable size: **882 KB**)
- **Build Steps:**
  ```bash
  git clone https://github.com/ApexMarkdown/apex.git apex-spike/apex
  cd apex-spike/apex
  git checkout 10509a11
  mkdir build && cd build
  cmake ..
  make -j$(nproc)
  ```
- **Portability & Sandbox Notes:**
  - Building Apex from source on macOS required linking against system libraries (`libcurl`, `libssl.3.dylib`). In restricted sandbox environments, `BypassSandbox: true` was required for `cmake`/`make`.
  - **Portability Assessment:** Pandoc is universally packaged in standard OS package managers (`brew`, `apt`, `pacman`). Apex is not yet broadly packaged, meaning adoption requires bundling a binary or compiling on-host.

---

## 4. Parity & Compatibility Matrix

| Evaluation Category | Pandoc (Baseline) | Apex (Spike) | Parity / Compatibility Analysis |
| :--- | :--- | :--- | :--- |
| **YAML Frontmatter** | Native parsing into `$meta$` AST/template variables | Native `--extract-meta` & inline `[%key]` substitution | **High Parity**. Extracts key-value metadata cleanly. |
| **HTML Templates** | Native `--template` flag with `$var$` & `$if$` logic | No `--template` flag for external HTML files | **Incompatible Natively**. Requires adapter script to populate Rotkeeper HTML templates. |
| **Lua Filters** | Embedded Lua 5.4 interpreter (`rewrite-links.lua`) | Spawns external system `lua` binary via `sh -c` | **Incompatible Natively**. Requires system `lua` binary and AST JSON filter script; native Pandoc Lua filters do not run directly. |
| **AST JSON Output** | `-t json` exports full AST including populated `meta` block | `-t json` exports Pandoc-compatible block AST (`meta` empty) | **Partial Parity**. Block structure matches Pandoc AST [1,23,1], but `meta` block in JSON is empty. |
| **HTML Element Rendering** | Standard HTML elements, wrapped paragraph lines | Standard HTML elements, single-line paragraphs | **High Parity**. Apex wraps images in `<figure>` and uses `<pre lang="..."><code>`, whereas Pandoc uses `<div class="sourceCode">`. |

---

## 5. Performance Comparison

Benchmark measured across **5 iterations** on the 5-file Golden Corpus:

| Renderer | Average Time (5 files) | Per-File Avg | Speedup vs Pandoc |
| :--- | :--- | :--- | :--- |
| **Pandoc (Native CLI)** | 156.73 ms | 31.35 ms | 1.00x (Baseline) |
| **Apex Adapter (Python + Apex)** | 106.81 ms | 21.36 ms | **1.46x faster** |
| **Native Apex Direct (C Binary)** | 71.80 ms | 14.36 ms | **2.18x faster** |

*Note:* Native Apex direct conversion is **2.18x faster** than Pandoc. Even with Python subprocess and regex overhead, the Apex adapter remains **1.46x faster** overall.

---

## 6. Architecture & Maintenance Impact

1. **Bash System Impact (`bones/scripts/rc-render.sh`):**
   - Rotkeeper currently calls `pandoc` directly with `--template` and `--lua-filter`.
   - Adopting Apex requires replacing the `pandoc` invocation in `rc-render.sh` with a call to an Apex wrapper script (e.g. `bones/scripts/rc-apex-render.py` or similar).
2. **Dependency Overhead:**
   - Adds C build or binary distribution dependency to Rotkeeper.
   - If an adapter is used, Python 3 (already present on macOS/Linux) or a lightweight shell wrapper handles template merging.
3. **Packaging (`rc-pack.sh`):**
   - `rc-pack.sh` extracts Markdown AST to JSON using `pandoc -t json`. Apex's `-t json` produces valid AST JSON accepted by `jq`, but lacks frontmatter in the `meta` key (Rotkeeper's `rc-pack.sh` extracts frontmatter via `yq` separately, so this is non-breaking).

---

## 7. Recommendations & Action Items

### Strategic Recommendation
Keep Pandoc as Rotkeeper's primary default renderer due to its zero-adapter template engine and broad OS package manager availability. Consider Apex as an optional **high-performance secondary renderer** or custom build option for large tombs where render speed is paramount.

### Next Steps (If Pursuing Integration)
1. **Maintain Disposable Adapter:** Retain `apex-spike/adapters/adapter.py` as a reference prototype.
2. **Upstream Feature Requests for Apex:**
   - Support for external HTML template flags (`--template`).
   - Built-in link extension transformation (e.g. `--rewrite-links md:html`).
3. **Cleanup:** Delete `apex-spike/` worktree when spike evaluation is complete.
