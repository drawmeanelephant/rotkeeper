import time
import os
import subprocess

APEX_ADAPTER = os.path.abspath('apex-spike/adapters/adapter.py')
PANDOC_BIN = "pandoc"

golden_files = [
    ('apex-spike/golden_corpus/golden-spooky-dark.md', 'apex-spike/templates/theme-spooky-dark.html', './assets/'),
    ('apex-spike/golden_corpus/golden-spooky-light.md', 'apex-spike/templates/theme-spooky-light.html', './assets/'),
    ('apex-spike/golden_corpus/golden-blog.md', 'apex-spike/templates/rotkeeper-blog.html', './assets/'),
    ('apex-spike/golden_corpus/golden-doc.md', 'apex-spike/templates/rotkeeper-doc.html', './assets/'),
    ('apex-spike/golden_corpus/coastal-radio/golden-nested.md', 'apex-spike/templates/theme-spooky-dark.html', '../assets/'),
]

ITERATIONS = 5

print("=== Running Performance Benchmark (5 Iterations) ===")

# 1. Pandoc Benchmark
pandoc_times = []
for i in range(ITERATIONS):
    t0 = time.perf_counter()
    for src, tmpl, assets in golden_files:
        subprocess.run([
            PANDOC_BIN, src,
            "--template=" + tmpl,
            "--lua-filter=apex-spike/rotkeeper-baseline/bones/scripts/rewrite-links.lua",
            "-V", "assets_root=" + assets,
            "-o", "/dev/null"
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    t1 = time.perf_counter()
    pandoc_times.append(t1 - t0)

avg_pandoc = sum(pandoc_times) / ITERATIONS
print(f"Pandoc Average Time (5 files): {avg_pandoc*1000:.2f} ms")

# 2. Apex Adapter Benchmark
apex_times = []
for i in range(ITERATIONS):
    t0 = time.perf_counter()
    subprocess.run(["python3", APEX_ADAPTER], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    t1 = time.perf_counter()
    apex_times.append(t1 - t0)

avg_apex = sum(apex_times) / ITERATIONS
print(f"Apex Adapter Average Time (5 files, including Python overhead & subprocess spawn): {avg_apex*1000:.2f} ms")

# 3. Native Apex Direct Benchmark (C binary alone, no Python/Subprocess wrapper)
apex_direct_times = []
APEX_BIN = os.path.abspath('apex-spike/apex/build/apex')
for i in range(ITERATIONS):
    t0 = time.perf_counter()
    for src, tmpl, assets in golden_files:
        subprocess.run([APEX_BIN, src], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    t1 = time.perf_counter()
    apex_direct_times.append(t1 - t0)

avg_apex_direct = sum(apex_direct_times) / ITERATIONS
print(f"Native Apex Direct C Binary Average Time (5 files): {avg_apex_direct*1000:.2f} ms")
