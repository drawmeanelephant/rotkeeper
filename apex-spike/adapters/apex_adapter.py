#!/usr/bin/env python3
# ==============================================================================
#  EXPLICIT ADAPTER: apex_adapter.py
#
#  Purpose: Bridges compatibility gaps between Apex CLI and Rotkeeper templates.
#  - Apex CLI lacks native --template flag support for external HTML templates.
#  - Apex CLI lacks embedded Pandoc Lua filter runtime (rewrite-links.lua).
#
#  Dependencies: Python 3 standard library only (os, sys, subprocess, re, pathlib)
# ==============================================================================

import os
import sys
import subprocess
import re
from pathlib import Path

# Resolve base apex-spike directory relative to script
ADAPTER_DIR = Path(__file__).resolve().parent
SPIKE_DIR = ADAPTER_DIR.parent
DEFAULT_APEX_BIN = SPIKE_DIR / "apex" / "build" / "apex"

def find_apex_binary(explicit_bin=None):
    if explicit_bin and os.path.isfile(explicit_bin):
        return os.path.abspath(explicit_bin)
    if DEFAULT_APEX_BIN.is_file():
        return str(DEFAULT_APEX_BIN)
    # Check PATH
    try:
        res = subprocess.run(["which", "apex"], capture_output=True, text=True)
        if res.returncode == 0 and res.stdout.strip():
            return res.stdout.strip()
    except Exception:
        pass
    return str(DEFAULT_APEX_BIN)

def extract_metadata(apex_bin, src_path):
    """Extract YAML metadata key-value pairs using apex --extract-meta."""
    meta = {}
    res = subprocess.run([apex_bin, '--extract-meta', src_path], capture_output=True, text=True)
    if res.returncode == 0:
        for line in res.stdout.splitlines():
            line = line.strip()
            if line.startswith('---') or not line:
                continue
            if ':' in line:
                key, val = line.split(':', 1)
                key = key.strip()
                val = val.strip().strip('"')
                meta[key] = val
    return meta

def render_file(src_path, dst_path, template_path, assets_root, apex_bin=None):
    """Render markdown via Apex, rewrite links, and apply template substitution."""
    apex_bin = find_apex_binary(apex_bin)
    if not os.path.isfile(apex_bin):
        print(f"ERROR: Apex binary not found at '{apex_bin}'. Please build Apex first.", file=sys.stderr)
        return False

    # 1. Convert Markdown to HTML snippet using Apex
    res = subprocess.run([apex_bin, src_path], capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Error running Apex on {src_path}: {res.stderr}", file=sys.stderr)
        return False
    body_html = res.stdout

    # 2. Extract metadata
    meta = extract_metadata(apex_bin, src_path)

    # 3. Load HTML Template
    with open(template_path, 'r', encoding='utf-8') as f:
        tmpl = f.read()

    # 4. Link Rewriting Adapter (.md -> .html and .md# -> .html#)
    body_html = re.sub(r'href=([\'"])(.+?)\.md([#\'"])', r'href=\1\2.html\3', body_html)

    title = meta.get('title', '')
    description = meta.get('description', '')
    author = meta.get('author', '')
    date = meta.get('date', '')

    # 5. Template Conditional Evaluation ($if(var)$ ... $endif$)
    for key, val in [('description', description), ('author', author), ('date', date)]:
        pattern = rf'\$if\({key}\)\$(.*?)\$endif\$'
        if val:
            tmpl = re.sub(pattern, r'\1', tmpl, flags=re.DOTALL)
        else:
            tmpl = re.sub(pattern, '', tmpl, flags=re.DOTALL)

    # 6. Template Variable Substitution ($var$)
    tmpl = tmpl.replace('$title$', title)
    tmpl = tmpl.replace('$description$', description)
    tmpl = tmpl.replace('$author$', author)
    tmpl = tmpl.replace('$date$', date)
    tmpl = tmpl.replace('$assets_root$', assets_root)
    tmpl = tmpl.replace('$body$', body_html)

    os.makedirs(os.path.dirname(dst_path), exist_ok=True)
    with open(dst_path, 'w', encoding='utf-8') as f:
        f.write(tmpl)

    return True

if __name__ == '__main__':
    if len(sys.argv) < 5:
        print("Usage: apex_adapter.py <src_path> <dst_path> <template_path> <assets_root> [apex_bin]")
        sys.exit(1)
    apex_bin_arg = sys.argv[5] if len(sys.argv) > 5 else None
    success = render_file(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], apex_bin_arg)
    sys.exit(0 if success else 1)
