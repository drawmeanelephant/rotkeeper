# Apex Renderer Investigation Report

**Date:** 2026-07-23  
**Target System:** Rotkeeper Static Site Generator  
**Apex Repository:** [ApexMarkdown/apex](https://github.com/ApexMarkdown/apex.git)  
**Pinned Commit SHA:** `10509a11fe5032e1d157204927678e66c94f83c2` (Apex v1.1.13)  
**Experiment Root:** `apex-spike/`  

---

## 1. Executive Summary & Verdict

### Final Verdict: **`CONDITIONAL`**

Apex is an exceptionally fast C-native Markdown renderer (**2.41x faster** direct Markdown-to-HTML conversion than Pandoc). However, Apex is **not a drop-in native replacement** for Pandoc in Rotkeeper due to structural differences in template handling and Lua filter execution mechanics.

Adopting Apex in Rotkeeper is **CONDITIONAL** upon:
1. Maintaining an explicit adapter layer (`apex-spike/adapters/apex_adapter.py`) to interpolate frontmatter and body into Rotkeeper's Pandoc-style HTML templates (`$title$`, `$body$`, `$assets_root$`, `$if(...)`) and rewrite internal Markdown links (`.md` -> `.html`, `.md#` -> `.html#`).
2. Bundling pre-compiled platform binaries or requiring a build toolchain (`cmake`, C compiler) on target author environments.

---

## 2. Tested Capabilities Breakdown

### A. Native Apex Capabilities
*Verified command:* `apex-spike/apex/build/apex --extract-meta <file.md>` and `apex-spike/apex/build/apex -s <file.md>`

- **Fast C Parsing:** Converts Markdown to HTML snippet or standalone document in ~84 ms on the 5-file Golden Corpus (2.41x faster than Pandoc's 202 ms).
- **YAML Frontmatter Extraction:** Parses document frontmatter and exposes merged key-value pairs via `--extract-meta`.
- **AST JSON Output:** `apex -t json` outputs valid Pandoc AST JSON schema `[1, 23, 1]`.
- **Standalone Documents:** `-s` flag generates a standalone HTML page using Apex's internal hardcoded HTML shell and inline CSS.

### B. Apex + Adapter Capabilities
*Verified script:* `python3 apex-spike/adapters/apex_adapter.py <src> <dst> <template> <assets>`

- **Rotkeeper HTML Template Integration:** Interpolates frontmatter variables (`$title$`, `$description$`, `$author$`, `$date$`, `$assets_root$`) and body into Rotkeeper Pandoc templates (`theme-spooky-dark.html`, etc.).
- **Template Conditional Evaluation:** Evaluates `$if(description)$...$endif$`, `$if(author)$...$endif$`, and `$if(date)$...$endif$` blocks.
- **Link Rewriting:** Rewrites internal `.md` and `.md#fragment` links to `.html` and `.html#fragment` without requiring an external Lua runtime.

### C. Capabilities Merely Simulated by the Adapter
- **Native External HTML Templates:** Apex has **no native `--template FILE` CLI option**. The adapter simulates this by rendering a raw HTML body snippet via Apex, extracting frontmatter via `apex --extract-meta`, and doing string substitution in Python.
- **Embedded Lua Filters:** Apex has **no embedded Lua runtime**. Apex's `--lua-filter` attempts to execute system `lua FILE` via stdin/stdout JSON pipes (`sh: lua: command not found` if system `lua` is absent). The adapter simulates link rewriting in Python regex instead.

### D. Unsupported Native Behavior & Compatibility Gaps
- **Empty `"meta"` in AST Export:** `apex -t json` leaves `"meta": {}` empty in the root JSON object (unlike Pandoc which populates AST metadata nodes).
- **Custom Template Variable Engine:** Apex supports `[%key]` substitution inside Markdown text, but has no native conditional/loop engine for HTML layout templates.

---

## 3. Environment & Pandoc Baseline Metrics

- **Operating System:** macOS 27.0 (Build 26A5388g) / Darwin Kernel 27.0.0 (`arm64`)
- **Pandoc Version:** `pandoc 3.10` (Scripting engine: `Lua 5.4`)
- **Rotkeeper Test Matrix (`bash rotkeeper.sh test`):** **100% Passed** across `crypt`, `busy`, and `sterile` layouts.
- **Pandoc Render Timings (`time bash rotkeeper.sh render`):**
  - Run 1: `12.029s`
  - Run 2: `13.263s`
  - Run 3: `12.457s`
  - **Average Render Duration:** **12.58 seconds** (87 pages)
- **Content Packaging (`bash rotkeeper.sh pack --content`):** `bones/archive/tomb-content-2026-07-23_1209.tar.gz` (**55 KB**).

---

## 4. Apex Build Metrics & Portability

- **Build Toolchain:** Apple clang 17.0.0 (`clang-1700.6.3.2`), CMake 3.31.5
- **Build Command:** `cmake -S . -B build && cmake --build build`
- **Binary Path:** `apex-spike/apex/build/apex`
- **Binary Size:** **882 KB**
- **Dynamic Library Dependencies (`otool -L`):**
  - `/usr/lib/libSystem.B.dylib` (System C library only)
- **Portability:** Fully self-contained C executable. Executes standalone outside build directory.
- **Install Requirements:** Requires host build tools (`cmake`, C compiler) or prebuilt platform binaries. Not currently packaged in standard OS package managers (`brew`, `apt`).

---

## 5. Performance Benchmark (3 Benchmark Iterations)

*Verified script:* `python3 apex-spike/adapters/benchmark.py 3`

| Renderer / Execution Method | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) | Speedup vs Pandoc |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Pandoc CLI Baseline** | 295.58 | 156.64 | 156.44 | **202.89 ms** | 1.00x (Baseline) |
| **Native Apex Direct (C Binary)** | 86.60 | 82.84 | 82.85 | **84.10 ms** | **2.41x faster** |
| **Apex Adapter (`apex_adapter.py`)** | 235.30 | 233.48 | 233.92 | **234.23 ms** | 0.87x |

*Analysis:* Direct native Apex Markdown conversion is **2.41x faster** than Pandoc (84.10 ms vs 202.89 ms). When wrapped in 5 individual Python process invocations (`apex_adapter.py`), Python process startup overhead offsets the speed gain (234.23 ms vs 202.89 ms).

---

## 6. Output Comparison & Link Audit

- **Normalized HTML Structure (`compare_output.py`):** Structural differences in line count exist between Pandoc standalone output and Apex adapter output due to minor whitespace and HTML container tag differences.
- **Link Audit (`link_audit.py`):**
  - Internal `.html` document links and `#fragment` targets: **100% Pass** on both renderers.
  - Local asset references: 4 placeholder image references (`/assets/logo.png`, etc.) failed identically on both renderers because placeholder images do not exist in sample content.

---

## 7. Reproducibility Limitations & Recommendations

1. **Adapter Overhead:** For Apex to deliver net performance gains in production, the adapter should operate in batch mode (processing multiple files in a single Python process) rather than invoking `python3` per file.
2. **Binary Distribution:** To adopt Apex in Rotkeeper without forcing authors to compile C source, Rotkeeper would need to distribute prebuilt Apex binaries for macOS (ARM64/x86_64) and Linux.
