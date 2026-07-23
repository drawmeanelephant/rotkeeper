import os, re

def normalize_html(html_str):
    html_str = re.sub(r'id="[^"]+"', '', html_str)
    html_str = re.sub(r'<meta name="generator"[^>]+>', '', html_str)
    lines = [line.strip() for line in html_str.splitlines() if line.strip()]
    return chr(10).join(lines)

files = [
    'golden-spooky-dark.html',
    'golden-spooky-light.html',
    'golden-blog.html',
    'golden-doc.html',
    'coastal-radio/golden-nested.html'
]

print('=== HTML Comparison (Pandoc Baseline vs Apex Adapter) ===')
for f in files:
    p_path = os.path.join('apex-spike/pandoc_baseline_output', f)
    a_path = os.path.join('apex-spike/apex_output', f)
    
    with open(p_path, 'r', encoding='utf-8') as pf:
        p_html = normalize_html(pf.read())
    with open(a_path, 'r', encoding='utf-8') as af:
        a_html = normalize_html(af.read())
        
    if p_html == a_html:
        print(f'✓ {f}: Identical normalized HTML')
    else:
        print(f'~ {f}: Differences detected')
        p_lines = p_html.splitlines()
        a_lines = a_html.splitlines()
        print(f'  Pandoc line count: {len(p_lines)}, Apex line count: {len(a_lines)}')
