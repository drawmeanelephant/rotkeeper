# Apex Renderer Spike & Reproduction Guide

This directory contains the isolated, reproducible investigation of the **Apex C Markdown Renderer** ([ApexMarkdown/apex](https://github.com/ApexMarkdown/apex.git)) as a potential alternative to Pandoc in Rotkeeper.

---

## Provenance & Build Specifications

- **Apex Repository:** `https://github.com/ApexMarkdown/apex.git`
- **Pinned Commit SHA:** `10509a11fe5032e1d157204927678e66c94f83c2` (Apex v1.1.13)
- **Target OS / Arch Tested:** macOS 27.0 (Apple Silicon `arm64`)
- **Binary Size:** `882 KB` (fully static C binary, dynamically linking only system C `libSystem.B.dylib`)

---

## Directory Structure

```text
apex-spike/
├── .gitignore               # Ignores cloned source (apex/), builds, and rendered outputs
├── README.md                # Reproduction guide (this file)
├── APEX-REPORT.md          # Full investigation report and verdict
├── golden_corpus/          # 5 sample Markdown test pages
│   ├── golden-spooky-dark.md
│   ├── golden-spooky-light.md
│   ├── golden-blog.md
│   ├── golden-doc.md
│   └── coastal-radio/golden-nested.md
└── adapters/               # Explicit, standalone Python adapter & tool scripts
    ├── apex_adapter.py     # HTML template substitution & link rewriting adapter
    ├── benchmark.py        # Multi-run performance benchmark timer
    ├── compare_output.py   # Normalized line-by-line HTML comparison script
    └── link_audit.py       # Standalone HTML link & asset auditor
```

---

## Step-by-Step Reproduction Guide

### 1. Clone & Build Apex
The Apex C source tree is ignored by Git to avoid repo bloat. Clone and compile it locally:

```bash
# Clone Apex into the ignored apex-spike/apex directory
git clone https://github.com/ApexMarkdown/apex.git apex-spike/apex
cd apex-spike/apex
git checkout 10509a11fe5032e1d157204927678e66c94f83c2
git submodule update --init --recursive

# Build via CMake
cmake -S . -B build
cmake --build build
cd ../..
```

The compiled binary will be placed at `apex-spike/apex/build/apex`.

### 2. Run Performance Benchmark
Runs 3 iterations comparing Pandoc CLI, Native Apex C Binary, and Apex Adapter on the Golden Corpus:

```bash
python3 apex-spike/adapters/benchmark.py
```

### 3. Generate HTML Outputs & Compare
Render the Golden Corpus via Pandoc baseline and Apex adapter into temporary output directories, then perform a normalized HTML comparison:

```bash
# Generate baseline Pandoc HTML outputs
mkdir -p apex-spike/outputs/pandoc_baseline/coastal-radio apex-spike/outputs/apex/coastal-radio

pandoc apex-spike/golden_corpus/golden-spooky-dark.md --template=bones/templates/theme-spooky-dark.html --lua-filter=bones/scripts/rewrite-links.lua -V assets_root=./assets/ -o apex-spike/outputs/pandoc_baseline/golden-spooky-dark.html
pandoc apex-spike/golden_corpus/golden-spooky-light.md --template=bones/templates/theme-spooky-light.html --lua-filter=bones/scripts/rewrite-links.lua -V assets_root=./assets/ -o apex-spike/outputs/pandoc_baseline/golden-spooky-light.html
pandoc apex-spike/golden_corpus/golden-blog.md --template=bones/templates/rotkeeper-blog.html --lua-filter=bones/scripts/rewrite-links.lua -V assets_root=./assets/ -o apex-spike/outputs/pandoc_baseline/golden-blog.html
pandoc apex-spike/golden_corpus/golden-doc.md --template=bones/templates/rotkeeper-doc.html --lua-filter=bones/scripts/rewrite-links.lua -V assets_root=./assets/ -o apex-spike/outputs/pandoc_baseline/golden-doc.html
pandoc apex-spike/golden_corpus/coastal-radio/golden-nested.md --template=bones/templates/theme-spooky-dark.html --lua-filter=bones/scripts/rewrite-links.lua -V assets_root=../assets/ -o apex-spike/outputs/pandoc_baseline/coastal-radio/golden-nested.html

# Render Apex Adapter HTML outputs
python3 apex-spike/adapters/apex_adapter.py apex-spike/golden_corpus/golden-spooky-dark.md apex-spike/outputs/apex/golden-spooky-dark.html bones/templates/theme-spooky-dark.html ./assets/
python3 apex-spike/adapters/apex_adapter.py apex-spike/golden_corpus/golden-spooky-light.md apex-spike/outputs/apex/golden-spooky-light.html bones/templates/theme-spooky-light.html ./assets/
python3 apex-spike/adapters/apex_adapter.py apex-spike/golden_corpus/golden-blog.md apex-spike/outputs/apex/golden-blog.html bones/templates/rotkeeper-blog.html ./assets/
python3 apex-spike/adapters/apex_adapter.py apex-spike/golden_corpus/golden-doc.md apex-spike/outputs/apex/golden-doc.html bones/templates/rotkeeper-doc.html ./assets/
python3 apex-spike/adapters/apex_adapter.py apex-spike/golden_corpus/coastal-radio/golden-nested.md apex-spike/outputs/apex/coastal-radio/golden-nested.html bones/templates/theme-spooky-dark.html ../assets/

# Compare normalized HTML output
python3 apex-spike/adapters/compare_output.py
```

### 4. Run Link Audit
Verify internal links and asset references across both outputs:

```bash
python3 apex-spike/adapters/link_audit.py apex-spike/outputs/apex
python3 apex-spike/adapters/link_audit.py apex-spike/outputs/pandoc_baseline
```
