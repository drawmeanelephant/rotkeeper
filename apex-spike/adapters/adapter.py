import os
import subprocess
import re

APEX_BIN = os.path.abspath('apex-spike/apex/build/apex')

def extract_metadata(src_path):
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

def render_file(src_path, dst_path, template_name, assets_root):
    res = subprocess.run([APEX_BIN, src_path], capture_output=True, text=True)
    if res.returncode != 0:
        print('Error running Apex on', src_path, res.stderr)
        return False
    body_html = res.stdout

    meta = extract_metadata(src_path)

    template_path = os.path.join('apex-spike/templates', template_name)
    with open(template_path, 'r', encoding='utf-8') as f:
        tmpl = f.read()

    # Link rewriting: .md -> .html, .md# -> .html#
    body_html = re.sub(r'href=([\'"])(.+?)\.md([#\'"])', r'href=\1\2.html\3', body_html)

    title = meta.get('title', '')
    description = meta.get('description', '')
    author = meta.get('author', '')
    date = meta.get('date', '')

    # 1. Conditionals
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

    # 2. Variables
    tmpl = tmpl.replace('$title$', title)
    tmpl = tmpl.replace('$description$', description)
    tmpl = tmpl.replace('$author$', author)
    tmpl = tmpl.replace('$date$', date)
    tmpl = tmpl.replace('$assets_root$', assets_root)
    tmpl = tmpl.replace('$body$', body_html)

    with open(dst_path, 'w', encoding='utf-8') as f:
        f.write(tmpl)

    print('Apex adapter rendered:', src_path, '->', dst_path)
    return True

golden_files = [
    ('apex-spike/golden_corpus/golden-spooky-dark.md', 'apex-spike/apex_output/golden-spooky-dark.html', 'theme-spooky-dark.html', './assets/'),
    ('apex-spike/golden_corpus/golden-spooky-light.md', 'apex-spike/apex_output/golden-spooky-light.html', 'theme-spooky-light.html', './assets/'),
    ('apex-spike/golden_corpus/golden-blog.md', 'apex-spike/apex_output/golden-blog.html', 'rotkeeper-blog.html', './assets/'),
    ('apex-spike/golden_corpus/golden-doc.md', 'apex-spike/apex_output/golden-doc.html', 'rotkeeper-doc.html', './assets/'),
    ('apex-spike/golden_corpus/coastal-radio/golden-nested.md', 'apex-spike/apex_output/coastal-radio/golden-nested.html', 'theme-spooky-dark.html', '../assets/'),
]

for src, dst, tmpl, assets in golden_files:
    render_file(src, dst, tmpl, assets)
