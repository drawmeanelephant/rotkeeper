#!/usr/bin/env python3
import time
import os
import subprocess

APEX_ADAPTER = os.path.abspath('apex-spike/clean-run/adapters/apex_adapter.py')
APEX_BIN = os.path.abspath('apex-spike/clean-run/apex/build/apex')
PANDOC_BIN = "pandoc"

golden_files = [
    ('apex-spike/clean-run/golden_corpus/golden-spooky-dark.md', 'apex-spike/clean-run/apex_output/golden-spooky-dark.html', 'apex-spike/clean-run/templates/theme-spooky-dark.html', './assets/'),
    ('apex-spike/clean-run/golden_corpus/golden-spooky-light.md', 'apex-spike/clean-run/apex_output/golden-spooky-light.html', 'apex-spike/clean-run/templates/theme-spooky-light.html', './assets/'),
    ('apex-spike/clean-run/golden_corpus/golden-blog.md', 'apex-spike/clean-run/apex_output/golden-blog.html', 'apex-spike/clean-run/templates/rotkeeper-blog.html', './assets/'),
    ('apex-spike/clean-run/golden_corpus/golden-doc.md', 'apex-spike/clean-run/apex_output/golden-doc.html', 'apex-spike/clean-run/templates/rotkeeper-doc.html', './assets/'),
    ('apex-spike/clean-run/golden_corpus/coastal-radio/golden-nested.md', 'apex-spike/clean-run/apex_output/coastal-radio/golden-nested.html', 'apex-spike/clean-run/templates/theme-spooky-dark.html', '../assets/'),
]

ITERATIONS = 3

print("=== Golden Corpus Performance Timings (3 Runs) ===")

# 1. Pandoc
pandoc_runs = []
for r in range(ITERATIONS):
    t0 = time.perf_counter()
    for src, dst, tmpl, assets in golden_files:
        subprocess.run([
            PANDOC_BIN, src,
            "--template=" + tmpl,
            "--lua-filter=apex-spike/clean-run/rotkeeper-baseline/bones/scripts/rewrite-links.lua",
            "-V", "assets_root=" + assets,
            "-o", "/dev/null"
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    t1 = time.perf_counter()
    pandoc_runs.append((t1 - t0) * 1000)

# 2. Apex Adapter
adapter_runs = []
for r in range(ITERATIONS):
    t0 = time.perf_counter()
    for src, dst, tmpl, assets in golden_files:
        subprocess.run(["python3", APEX_ADAPTER, src, dst, tmpl, assets], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    t1 = time.perf_counter()
    adapter_runs.append((t1 - t0) * 1000)

# 3. Native Apex Direct
apex_direct_runs = []
for r in range(ITERATIONS):
    t0 = time.perf_counter()
    for src, dst, tmpl, assets in golden_files:
        subprocess.run([APEX_BIN, src], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    t1 = time.perf_counter()
    apex_direct_runs.append((t1 - t0) * 1000)

print("Pandoc CLI Runs (ms):", [round(x, 2) for x in pandoc_runs])
print(f"Pandoc Average: {sum(pandoc_runs)/ITERATIONS:.2f} ms")

print("Apex Adapter Runs (ms):", [round(x, 2) for x in adapter_runs])
print(f"Apex Adapter Average: {sum(adapter_runs)/ITERATIONS:.2f} ms")

print("Native Apex Direct C Binary Runs (ms):", [round(x, 2) for x in apex_direct_runs])
print(f"Native Apex Direct Average: {sum(apex_direct_runs)/ITERATIONS:.2f} ms")
