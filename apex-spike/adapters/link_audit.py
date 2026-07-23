#!/usr/bin/env python3
# ==============================================================================
#  LINK AUDITOR: link_audit.py
#  Purpose: Audits rendered HTML files for broken internal links and assets.
# ==============================================================================

import os
import sys
import re
from pathlib import Path

def audit_directory(html_dir):
    html_dir = Path(html_dir).resolve()
    if not html_dir.exists():
        print(f"Error: Target directory '{html_dir}' does not exist.", file=sys.stderr)
        return False

    html_files = list(html_dir.glob("**/*.html"))
    if not html_files:
        print(f"No HTML files found in '{html_dir}'.", file=sys.stderr)
        return False

    links_checked = 0
    failures = 0

    print(f"=== Link Audit for '{html_dir}' ({len(html_files)} pages) ===")

    for html_file in html_files:
        with open(html_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Extract href="..." and src="..."
        urls = re.findall(r'(?:href|src)=[\'"]([^\'"]+)[\'"]', content)
        for url in urls:
            # Skip external links
            if url.startswith(('http://', 'https://', 'mailto:', 'javascript:')):
                continue

            links_checked += 1
            # Split path and anchor
            target_path = url.split('#')[0]
            if not target_path:
                continue # Pure fragment link on same page

            if target_path.startswith('/'):
                # Absolute asset reference relative to html_dir
                resolved = html_dir / target_path.lstrip('/')
            else:
                # Relative link
                resolved = (html_file.parent / target_path).resolve()

            if not resolved.exists():
                failures += 1
                rel_page = html_file.relative_to(html_dir)
                print(f"  [MISSING] {rel_page} -> {url} (Resolved: {resolved})")

    print(f"Audit Complete: Checked {links_checked} links across {len(html_files)} pages. Failures: {failures}")
    return failures == 0

if __name__ == '__main__':
    target = sys.argv[1] if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent / "outputs" / "apex"
    audit_directory(target)
