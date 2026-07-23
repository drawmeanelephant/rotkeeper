#!/usr/bin/env python3
# ==============================================================================
#  BENCHMARK SCRIPT: benchmark.py
#  Purpose: Runs multi-iteration timing benchmarks across Pandoc, Native Apex,
#           and Apex Adapter on the Golden Corpus.
# ==============================================================================

import time
import os
import sys
import subprocess
from pathlib import Path

ADAPTER_DIR = Path(__file__).resolve().parent
SPIKE_DIR = ADAPTER_DIR.parent
CORPUS_DIR = SPIKE_DIR / "golden_corpus"
TEMPLATES_DIR = SPIKE_DIR / "clean-pr-baseline" / "bones" / "templates"
APEX_BIN = SPIKE_DIR / "apex" / "build" / "apex"
APEX_ADAPTER = ADAPTER_DIR / "apex_adapter.py"
LUA_FILTER = SPIKE_DIR / "clean-pr-baseline" / "bones" / "scripts" / "rewrite-links.lua"

def find_templates_dir():
    # Look for templates in clean-pr worktree or repo root
    clean_pr_root = SPIKE_DIR.parent
    if (clean_pr_root / "bones" / "templates").exists():
        return clean_pr_root / "bones" / "templates"
    return SPIKE_DIR / "templates"

def find_lua_filter():
    clean_pr_root = SPIKE_DIR.parent
    filter_path = clean_pr_root / "bones" / "scripts" / "rewrite-links.lua"
    if filter_path.exists():
        return filter_path
    return None

def run_benchmark(iterations=3):
    templates_dir = find_templates_dir()
    lua_filter = find_lua_filter()

    golden_files = [
        (CORPUS_DIR / 'golden-spooky-dark.md', templates_dir / 'theme-spooky-dark.html', './assets/'),
        (CORPUS_DIR / 'golden-spooky-light.md', templates_dir / 'theme-spooky-light.html', './assets/'),
        (CORPUS_DIR / 'golden-blog.md', templates_dir / 'rotkeeper-blog.html', './assets/'),
        (CORPUS_DIR / 'golden-doc.md', templates_dir / 'rotkeeper-doc.html', './assets/'),
        (CORPUS_DIR / 'coastal-radio' / 'golden-nested.md', templates_dir / 'theme-spooky-dark.html', '../assets/'),
    ]

    print(f"=== Golden Corpus Performance Timings ({iterations} Runs) ===")

    # 1. Pandoc CLI
    pandoc_runs = []
    for r in range(iterations):
        t0 = time.perf_counter()
        for src, tmpl, assets in golden_files:
            cmd = ["pandoc", str(src), "--template=" + str(tmpl), "-V", "assets_root=" + assets, "-o", os.devnull]
            if lua_filter and lua_filter.exists():
                cmd.extend(["--lua-filter=" + str(lua_filter)])
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        t1 = time.perf_counter()
        pandoc_runs.append((t1 - t0) * 1000)

    print(f"Pandoc CLI Runs (ms): {[round(x, 2) for x in pandoc_runs]}")
    print(f"Pandoc Average: {sum(pandoc_runs)/iterations:.2f} ms")

    # 2. Native Apex Direct
    if APEX_BIN.is_file():
        apex_direct_runs = []
        for r in range(iterations):
            t0 = time.perf_counter()
            for src, tmpl, assets in golden_files:
                subprocess.run([str(APEX_BIN), str(src)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
            t1 = time.perf_counter()
            apex_direct_runs.append((t1 - t0) * 1000)

        print(f"Native Apex Direct Runs (ms): {[round(x, 2) for x in apex_direct_runs]}")
        print(f"Native Apex Direct Average: {sum(apex_direct_runs)/iterations:.2f} ms")
    else:
        print(f"Native Apex binary not found at '{APEX_BIN}'. Build Apex to include in benchmark.")

    # 3. Apex Adapter
    if APEX_BIN.is_file():
        adapter_runs = []
        tmp_dst = SPIKE_DIR / "outputs" / "tmp_benchmark"
        for r in range(iterations):
            t0 = time.perf_counter()
            for src, tmpl, assets in golden_files:
                dst = tmp_dst / src.name
                subprocess.run(["python3", str(APEX_ADAPTER), str(src), str(dst), str(tmpl), assets, str(APEX_BIN)],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
            t1 = time.perf_counter()
            adapter_runs.append((t1 - t0) * 1000)

        print(f"Apex Adapter Runs (ms): {[round(x, 2) for x in adapter_runs]}")
        print(f"Apex Adapter Average: {sum(adapter_runs)/iterations:.2f} ms")

if __name__ == '__main__':
    iters = int(sys.argv[1]) if len(sys.argv) > 1 else 3
    run_benchmark(iters)
