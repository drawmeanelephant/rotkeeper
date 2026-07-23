#!/usr/bin/env python3
# ==============================================================================
#  EXPLICIT ADAPTER: apex_adapter.py
#
#  Purpose: Bridges the compatibility gaps between Apex and Rotkeeper.
#  - Apex lacks native --template flag support for HTML templates.
#  - Apex lacks embedded Lua filter runtime (rewrite-links.lua).
#
#  Runtime Dependencies: Python 3 standard library only (os, sys, subprocess, re)
# ==============================================================================

import os
import sys
import subprocess
import re

APEX_BIN = os.path.abspath('apex-spike/clean-run/apex/build/apex')

def extract_metadata(src_path):
    """Extract YAML metadata key-value pairs using apex --extract-meta."""
    meta = {}
    res = subprocess.run([APEX_BIN, '--extract-meta', src_path], capture_output=True, text=True)
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

def render_file(src_path, dst_path, template_path, assets_root):
    """Render markdown via Apex, rewrite links, and apply template substitution."""
    # 1. Convert Markdown to HTML snippet using Apex
    res = subprocess.run([APEX_BIN, src_path], capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Error running Apex on {src_path}: {res.stderr}", file=sys.stderr)
        return False
    body_html = res.stdout

    # 2. Extract metadata
    meta = extract_metadata(src_path)

    # 3. Load HTML Template
    with open(template_path, 'r', encoding='utf-8') as f:
        tmpl = f.read()

    # 4. Link Rewriting Adapter (.md -> .html and .md# -> .html#)
    # Exclude external scheme URLs (http://, https://, mailto:)
    body_html = re.sub(r'href=([\'"])(.+?)\.md([#\'"])', r'href=\1\2.html\3', body_html)

    title = meta.get('title', '')
    description = meta.get('description', '')
    author = meta.get('author', '')
    date = meta.get('date', '')

    # 5. Pandoc Template Conditional Evaluation ($if(var)$ ... $endif$)
    if description:
        tmpl = re.sub(r'\$if\(description\)\$(.*?)\$endif\$', r'\1', tmpl, flags=re.DOTALL)
    else:
        tmpl = re.sub(r'\$if\(description\)\$(.*?)\$endif\$', '', tmpl, flags=re.DOTALL)

    if author:
        tmpl = re.sub(r'\$if\(author\)\$(.*?)\$endif\$', r'\1', tmpl, flags=re.DOTALL)
    else:
        tmpl = re.sub(r'\$if\(author\)\$(.*?)\$endif\$', '', tmpl, flags=re.DOTALL)

    if date:
        tmpl = re.sub(r'\$if\(date\)\$(.*?)\$endif\$', r'\1', tmpl, flags=re.DOTALL)
    else:
        tmpl = re.sub(r'\$if\(date\)\$(.*?)\$endif\$', '', tmpl, flags=re.DOTALL)

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

    print(f"Apex Adapter Rendered: {src_path} -> {dst_path}")
    return True

if __name__ == '__main__':
    if len(sys.argv) < 5:
        print("Usage: apex_adapter.py <src_path> <dst_path> <template_path> <assets_root>")
        sys.exit(1)
    render_file(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
