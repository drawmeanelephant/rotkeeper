#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  Project : Rotkeeper
#  Script  : bones/scripts/rc-a11y.sh
#  Purpose : Accessibility audit for theme stylesheets — WCAG contrast
#            over palette scopes, focus-state presence, narrow-viewport
#            table/code legibility — recorded per theme
#  Version : 0.5.1
#  Updated : 2026-08-25
# ============================================================
# Env assumptions: reads ASSETS_DIR, BONES_DIR, CONFIG_DIR, DRY_RUN, LOG_DIR, LOG_FILE, REPORT_DIR, ROOT_DIR, SCRIPT_DIR, TEMPLATE_DIR, TMP_DIR, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.
# CWD assumptions: No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.
# Input/Output contracts: CLI args and env vars in; files and stdout/stderr out; respects --dry-run (no writes) and --verbose.

# ---
# show_help: Print accessibility audit usage and exit.
# Inputs: none (reads VERSION)
# Outputs: Prints help and exits 0
# Env: Reads ASSETS_DIR, BONES_DIR, CONFIG_DIR, DRY_RUN, LOG_DIR, QUIET ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
show_help() {
  cat << EOF
rc-a11y.sh — Theme accessibility audit (v$VERSION)

Usage: rotkeeper.sh a11y [options]

Audits every theme stylesheet reachable from bones/templates/*.html:
  1. WCAG 2.x contrast ratios for semantic color pairs (body text on page
     background and surface, code text on code background, secondary text
     and accent links on the page background) across every palette scope
     the stylesheet declares: default, prefers-color-scheme: dark
     overrides, and opt-in .palette-* terminal variants.
  2. Focus states for interactive elements (:focus / :focus-visible rules
     that paint a visible indicator).
  3. Narrow-viewport legibility spot-checks for wide tables and code
     blocks (overflow-x or pre-wrap strategy).

Results are recorded per theme under bones/reports/. Exit status is
nonzero when any theme fails, so new themes can be gated on passing.

Options:
  --css-dir DIR    Theme CSS directory; defaults to ASSETS_DIR/css
  --report FILE    Report destination; defaults to bones/reports/a11y-report-*.md
  --json           Emit machine-readable JSON instead of the markdown report
  --dry-run        Run the audit without writing the report
  --verbose        Show detailed log output
  --help, -h       Show this help message
EOF
  exit 0
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-a11y" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR TEMPLATE_DIR ASSETS_DIR REPORT_DIR

CSS_DIR="$ASSETS_DIR/css"
REPORT_FILE=""
JSON_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --css-dir)
      CSS_DIR="$2"
      shift 2
      ;;
    --report)
      REPORT_FILE="$2"
      shift 2
      ;;
    --json)
      JSON_MODE=true
      shift
      ;;
    --dry-run|--verbose|--help|-h)
      shift
      ;;
    *)
      log "ERROR" "Unknown option: $1"
      exit 1
      ;;
  esac
done

# ---
# main: Audit theme CSS for contrast, focus, and narrow-viewport legibility.
# Inputs: $@ (--css-dir, --report, --json, --dry-run, --verbose)
# Outputs: Writes report under REPORT_DIR or emits JSON; exits 1 if any theme fails
# Env: Reads ASSETS_DIR, DRY_RUN, REPORT_DIR, ROOT_DIR, TEMPLATE_DIR, TMP_DIR (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
main() {
  require_bins python3
  mkdir -p "$TMP_DIR"

  # Resolve the CSS directory and keep it inside the assets boundary.
  if [[ "$CSS_DIR" == /* ]]; then
    CSS_DIR=$(rk_canonical_path "$CSS_DIR" 2>/dev/null || true)
  else
    CSS_DIR=$(rk_canonical_path "$ROOT_DIR/$CSS_DIR" 2>/dev/null || true)
  fi
  local canon_assets
  canon_assets=$(rk_canonical_path "$ASSETS_DIR" 2>/dev/null || echo "$ASSETS_DIR")
  if [[ -z "$CSS_DIR" || ( "$CSS_DIR" != "$canon_assets" && "$CSS_DIR" != "$canon_assets/"* ) ]]; then
    log "ERROR" "--css-dir must resolve under ASSETS_DIR: $CSS_DIR"
    exit 1
  fi
  if [[ ! -d "$CSS_DIR" ]]; then
    log "ERROR" "Theme CSS directory does not exist: $CSS_DIR"
    exit 1
  fi

  if [[ -z "$REPORT_FILE" ]]; then
    REPORT_FILE="$REPORT_DIR/a11y-report-$(date +%Y%m%d_%H%M%S).md"
  elif [[ "$REPORT_FILE" != /* ]]; then
    REPORT_FILE="$ROOT_DIR/$REPORT_FILE"
  fi

  local mode="md"
  local out_file="$REPORT_FILE"
  if [[ "$JSON_MODE" == true || "$DRY_RUN" == true ]]; then
    # SIDE EFFECT (write): mktemp creates a bones/tmp scratch file holding the JSON/dry-run result (removed after emit)
    out_file=$(mktemp "$TMP_DIR/a11y-result.XXXXXX")
    if [[ "$JSON_MODE" == true ]]; then
      mode="json"
    fi
  fi

  local summary
  summary=$(python3 - "$CSS_DIR" "$TEMPLATE_DIR" "$mode" "$out_file" <<'A11Y_PY'
import json
import os
import re
import sys

css_dir, tpl_dir, mode, out_path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

AA_NORMAL = 4.5
AA_LARGE = 3.0

# Ordered candidate custom properties per semantic role. First present wins.
ROLES = {
    "bg": ["--bg-color", "--bg", "--paper", "--txp-page-bg"],
    "surface": ["--surface-color", "--surface", "--slab", "--txp-paper-bg"],
    "text": ["--text-primary", "--text-color", "--text", "--ink", "--txp-text-main"],
    "muted": ["--text-secondary", "--dim-text", "--muted-color", "--muted", "--txp-text-muted"],
    "accent": ["--accent-color", "--accent-hover", "--accent", "--txp-crimson"],
    "code_bg": ["--code-bg", "--code-bg-color", "--txp-pre-bg", "--txp-code-bg"],
    "code_text": ["--code-text", "--txp-pre-text", "--txp-code-text"],
}

# (label, fg role, bg role, hard pair). Hard pairs must meet AA normal-text
# contrast; soft pairs warn inside the 3.0-4.5 band and fail below 3.0.
PAIRS = [
    ("body text / page bg", "text", "bg", True),
    ("body text / surface", "text", "surface", True),
    ("secondary text / page bg", "muted", "bg", False),
    ("accent link / page bg", "accent", "bg", False),
]


def strip_comments(css):
    return re.sub(r"/\*.*?\*/", "", css, flags=re.S)


def norm_hex(hexv):
    h = hexv.lower()
    if len(h) == 4:
        h = "#" + "".join(ch * 2 for ch in h[1:])
    return h


def parse_vars(body):
    found = {}
    for name, val in re.findall(r"(--[A-Za-z0-9-]+)\s*:\s*([^;]+)", body):
        m = re.search(r"#(?:[0-9a-fA-F]{6}\b|[0-9a-fA-F]{3}\b)", val)
        if m:
            found[name.lower()] = norm_hex(m.group(0))
    return found


MEDIA_RE = re.compile(r"@media([^{]*)\{((?:[^{}]|\{[^{}]*\})*)\}")


def parse_scopes(full_css):
    base, dark, palettes = {}, {}, {}
    for guard, body in MEDIA_RE.findall(full_css):
        if "prefers-color-scheme" in guard and "dark" in guard:
            for root_body in re.findall(r":root\s*\{([^{}]*)\}", body):
                dark.update(parse_vars(root_body))
    plain = MEDIA_RE.sub("", full_css)
    for root_body in re.findall(r":root\s*\{([^{}]*)\}", plain):
        base.update(parse_vars(root_body))
    for name, body in re.findall(r"\.(palette-[A-Za-z0-9_-]+)\s*\{([^{}]*)\}", plain):
        palettes.setdefault(name, {}).update(parse_vars(body))
    return base, dark, palettes


def resolve_chain(start):
    # Depth-first so a stylesheet's @import rules land BEFORE the importer's
    # own declarations, matching how browsers splice imported sheets into the
    # cascade. Later entries therefore override earlier ones, last-wins.
    ordered, seen = [], set()

    def visit(path):
        path = os.path.normpath(path)
        real = os.path.realpath(path)
        if real in seen or not os.path.isfile(path):
            return
        seen.add(real)
        text = strip_comments(open(path, encoding="utf-8", errors="replace").read())
        for target in re.findall(r"@import\s+url\(\s*[\"']?([^\"')]+)[\"']?\s*\)", text):
            visit(os.path.join(os.path.dirname(path), target.strip()))
        ordered.append(path)

    visit(start)
    return ordered


def lin_channel(c):
    c /= 255.0
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4


def luminance(hexv):
    r, g, b = int(hexv[1:3], 16), int(hexv[3:5], 16), int(hexv[5:7], 16)
    return 0.2126 * lin_channel(r) + 0.7152 * lin_channel(g) + 0.0722 * lin_channel(b)


def contrast(a, b):
    la, lb = luminance(a), luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def pick_role(scope, role):
    for cand in ROLES[role]:
        if cand in scope:
            return cand, scope[cand], None
    return None, None, None


def pick_code_pair(base_scope):
    bg_name, bg_hex, _ = pick_role(base_scope, "code_bg")
    text_name, text_hex, _ = pick_role(base_scope, "code_text")
    fallback = None
    if text_hex is None:
        text_name, text_hex, _ = pick_role(base_scope, "accent")
        if text_hex is not None:
            fallback = "accent fallback (no code-text token)"
    if text_hex is None:
        text_name, text_hex, _ = pick_role(base_scope, "text")
        if text_hex is not None:
            fallback = "body text fallback (no code-text token)"
    return (bg_name, bg_hex), (text_name, text_hex), fallback


def verdict_for(ratio, hard):
    if ratio >= AA_NORMAL:
        return "PASS"
    if hard:
        return "FAIL"
    return "WARN" if ratio >= AA_LARGE else "FAIL"


def audit_contrast(label, fg, bg, hard, fg_role="", bg_role=""):
    if fg[1] is None or bg[1] is None:
        missing = []
        if fg[1] is None:
            missing.append(fg_role or fg[0] or "foreground")
        if bg[1] is None:
            missing.append(bg_role or bg[0] or "background")
        return {
            "pair": label, "ratio": None, "verdict": "SKIP",
            "note": "missing token(s): %s" % ", ".join(missing),
        }
    ratio = round(contrast(fg[1], bg[1]), 2)
    v = verdict_for(ratio, hard)
    note = ""
    if v == "WARN":
        note = "below AA normal-size %.1f:1; acceptable only as large text (>= %.1f:1)" % (AA_NORMAL, AA_LARGE)
    return {
        "pair": label,
        "fg": "%s %s" % (fg[0], fg[1]),
        "bg": "%s %s" % (bg[0], bg[1]),
        "ratio": ratio,
        "threshold": AA_NORMAL if hard else AA_LARGE,
        "verdict": v,
        "note": note,
    }


def audit_focus(css):
    rules = re.findall(r"([^{}]*:focus[^{}]*)\{([^{}]*)\}", css)
    if ":focus" not in css:
        return "FAIL", "no :focus rules found for interactive elements"
    painted = [
        (sel.strip(), body)
        for sel, body in rules
        if re.search(r"(outline|box-shadow|background|border|text-decoration|color)\s*:", body)
    ]
    if not painted:
        return "FAIL", ":focus rules exist but none paints a visible indicator"
    kill = any(
        re.search(r"outline\s*:\s*(none|0)\s*(;|$)", body)
        and not re.search(r"outline(-color|-width|-style)?\s*:\s*(?!none\b|0\b)[^;]+", body)
        for _, body in rules
    )
    fv = ":focus-visible" in css
    if kill and not fv:
        return "WARN", "outline suppressed without a :focus-visible replacement"
    detail = "%d focus rule(s)%s" % (
        len(painted),
        "; :focus-visible present" if fv else "",
    )
    return "PASS", detail


def audit_narrow(css):
    table_ovf = pre_ovf = wrap = False
    for sel, body in re.findall(r"([^{}]+)\{([^{}]*)\}", css):
        if re.search(r"overflow-x\s*:\s*(auto|scroll)", body):
            if re.search(r"(^|[\s,])table([\s,.:{[]|$)", sel):
                table_ovf = True
            if "pre" in sel:
                pre_ovf = True
    if re.search(r"(pre|code)[^{},]*\{[^{}]*white-space\s*:\s*(pre-wrap|break-spaces)", css):
        wrap = True
    narrow_media = len(re.findall(r"@media[^{]*max-width", css))
    notes = []
    verdict = "PASS"
    if not (table_ovf or pre_ovf or wrap):
        verdict = "FAIL"
        notes.append("no overflow-x or pre-wrap strategy for wide tables/code")
    else:
        if not table_ovf:
            notes.append("wide tables lack an overflow-x strategy")
            verdict = "WARN"
        if not (pre_ovf or wrap):
            notes.append("code blocks lack an overflow-x/pre-wrap strategy")
            verdict = "WARN"
    notes.append("%d max-width media quer%s" % (narrow_media, "y" if narrow_media == 1 else "ies"))
    return verdict, "; ".join(notes)


RANK = {"PASS": 0, "SKIP": 0, "WARN": 1, "FAIL": 2}


def audit_inline_pairs(css):
    # Heuristic sweep for hardcoded color/background pairs declared in the
    # same rule — token-level checks cannot see these. Verdicts stop at WARN
    # because rendered font size is unknown here.
    seen, results = set(), []
    for sel, body in re.findall(r"([^{}]+)\{([^{}]*)\}", css):
        sel = sel.strip()
        if not sel or sel.startswith("@"):
            continue
        color = re.search(r"(?:^|;)\s*color\s*:\s*(#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3})\s*(?:;|$)", body)
        bg = re.search(r"(?:^|;)\s*background(?:-color)?\s*:\s*(#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3})\s*(?:;|$)", body)
        if not (color and bg):
            continue
        fg_hex, bg_hex = norm_hex(color.group(1)), norm_hex(bg.group(1))
        key = (fg_hex, bg_hex)
        if key in seen:
            continue
        seen.add(key)
        ratio = round(contrast(fg_hex, bg_hex), 2)
        results.append({
            "selector": " ".join(sel.split())[:60],
            "fg": fg_hex, "bg": bg_hex, "ratio": ratio,
            "verdict": "PASS" if ratio >= AA_NORMAL else ("WARN" if ratio >= AA_LARGE else "FAIL"),
            "note": "" if ratio >= AA_NORMAL else "hardcoded pair below AA; verify rendered font size",
        })
    return results


def worst(verdicts):
    rank = 0
    for v in verdicts:
        rank = max(rank, RANK.get(v, 0))
    return {0: "PASS", 1: "WARN", 2: "FAIL"}[rank]


# --- Discover themes from template stylesheet links -----------------------
link_re = re.compile(r"<link\b[^>]*rel=[\"']stylesheet[\"'][^>]*>", re.I)
href_re = re.compile(r"href=[\"']([^\"']+\.css)[\"']", re.I)

theme_map = {}
skipped_templates = []
for fname in sorted(os.listdir(tpl_dir)):
    if not fname.endswith(".html"):
        continue
    html = open(os.path.join(tpl_dir, fname), encoding="utf-8", errors="replace").read()
    css_names = []
    for tag in link_re.findall(html):
        for href in href_re.findall(tag):
            m = re.search(r"css/([A-Za-z0-9._-]+\.css)$", href)
            if m:
                css_names.append(m.group(1))
    if not css_names:
        skipped_templates.append(fname)
        continue
    chain = resolve_chain(os.path.join(css_dir, css_names[0]))
    if not chain:
        skipped_templates.append(fname)
        continue
    key = tuple(os.path.realpath(p) for p in chain)
    theme_map.setdefault(key, {"entry": os.path.join(css_dir, css_names[0]),
                               "chain": chain, "templates": []})
    theme_map[key]["templates"].append(fname)

# --- Audit each unique stylesheet -----------------------------------------
report = {"standard": "WCAG 2.x AA", "aa_normal": AA_NORMAL, "aa_large": AA_LARGE,
          "themes": [], "skipped_templates": skipped_templates}
markers = []

for info in sorted(theme_map.values(), key=lambda t: t["entry"]):
    # Name the theme after its entry stylesheet (what templates link), while
    # the cascade-ordered chain keeps imported rules first.
    chain_paths = [os.path.relpath(p, css_dir) for p in info["chain"]]
    css_name = os.path.basename(info["entry"])
    import_names = [os.path.relpath(p, css_dir) for p in info["chain"] if p != info["entry"]]
    texts = [strip_comments(open(p, encoding="utf-8", errors="replace").read()) for p in info["chain"]]
    full_css = "\n".join(texts)
    base, dark, palettes = parse_scopes(full_css)

    scopes = [("default", dict(base))]
    if dark:
        merged = dict(base)
        merged.update(dark)
        scopes.append(("prefers-dark", merged))
    for pal_name in sorted(palettes):
        merged = dict(base)
        merged.update(palettes[pal_name])
        scopes.append((pal_name, merged))

    theme_entry = {
        "css": css_name,
        "imports": import_names,
        "templates": info["templates"],
        "scopes": [],
    }
    scope_marks = []
    for scope_label, scope in scopes:
        pairs = []
        for label, fg_role, bg_role, hard in PAIRS:
            pairs.append(audit_contrast(label, pick_role(scope, fg_role), pick_role(scope, bg_role),
                                        hard, fg_role=fg_role, bg_role=bg_role))
        (cbg, ctxt, fb) = pick_code_pair(scope)
        pair = audit_contrast("code text / code bg", ctxt, cbg, True,
                              fg_role="code_text", bg_role="code_bg")
        if fb and pair["verdict"] != "SKIP":
            pair["note"] = (pair["note"] + "; " if pair["note"] else "") + fb
        pairs.append(pair)
        inv_fg, inv_bg = scope.get("--inverse-ink"), scope.get("--inverse-paper")
        if inv_fg and inv_bg:
            pairs.append(audit_contrast(
                "inverse ink / inverse paper",
                ("--inverse-ink", inv_fg), ("--inverse-paper", inv_bg), True))
        if scope.get("--bg-color") or scope.get("--bg"):
            bg_name, bg_hex, _ = pick_role(scope, "bg")
            acc_name, acc_hex, _ = pick_role(scope, "accent")
            if acc_hex:
                pairs.append(audit_contrast(
                    "page text on accent fill", (bg_name, bg_hex), (acc_name, acc_hex), False))

        focus_v, focus_note = audit_focus(full_css)
        narrow_v, narrow_note = audit_narrow(full_css)
        scope_verdict = worst([p["verdict"] for p in pairs] + [focus_v, narrow_v])
        ratios = [p["ratio"] for p in pairs if p["ratio"] is not None]
        theme_entry["scopes"].append({
            "scope": scope_label,
            "pairs": pairs,
            "contrast_worst": min(ratios) if ratios else None,
            "focus": {"verdict": focus_v, "note": focus_note},
            "narrow": {"verdict": narrow_v, "note": narrow_note},
            "verdict": scope_verdict,
        })
        scope_marks.append((scope_verdict, scope_label, pairs, focus_v, narrow_v))

    # Hardcoded color/background pairs are file-level findings, reported once.
    inline_pairs = audit_inline_pairs(full_css)
    theme_entry["inline_pairs"] = inline_pairs

    theme_verdict = worst([s["verdict"] for s in theme_entry["scopes"]] +
                          [p["verdict"] for p in inline_pairs])
    theme_entry["verdict"] = theme_verdict
    report["themes"].append(theme_entry)

    icon = {"PASS": "\u2713", "WARN": "\u26a0\ufe0f", "FAIL": "\u2717"}[theme_verdict]
    fails = []
    warns = []
    for sv, sl, prs, fv, nv in scope_marks:
        for p in prs:
            item = "%s [%s]: %s (%s)" % (
                css_name, sl, p["pair"],
                "%.2f:1" % p["ratio"] if p["ratio"] else "token missing")
            if p["verdict"] == "FAIL":
                fails.append(item)
            elif p["verdict"] == "WARN":
                warns.append(item)
        if fv == "FAIL":
            fails.append("%s [%s]: focus states failing" % (css_name, sl))
        elif fv == "WARN":
            warns.append("%s [%s]: %s" % (css_name, sl, "focus warning"))
        if nv == "FAIL":
            fails.append("%s [%s]: no wide-table/code legibility strategy" % (css_name, sl))
        elif nv == "WARN":
            warns.append("%s [%s]: wide table/code legibility gaps" % (css_name, sl))
    for p in inline_pairs:
        item = "%s: %s `%s` on `%s` (%.2f:1)" % (
            css_name, p["selector"], p["fg"], p["bg"], p["ratio"])
        if p["verdict"] == "FAIL":
            fails.append(item)
        elif p["verdict"] == "WARN":
            warns.append(item)
    if theme_verdict == "PASS":
        markers.append("\u2713 %s \u2014 all scopes pass" % css_name)
    else:
        issues = fails + warns
        markers.append("%s %s \u2014 %d issue(s): %s" % (icon, css_name, len(issues), "; ".join(issues)))

fail_count = sum(1 for t in report["themes"] if t["verdict"] == "FAIL")
warn_count = sum(1 for t in report["themes"] if t["verdict"] == "WARN")
report["summary"] = {
    "themes": len(report["themes"]),
    "pass": sum(1 for t in report["themes"] if t["verdict"] == "PASS"),
    "warn": warn_count,
    "fail": fail_count,
}

with open(out_path, "w", encoding="utf-8") as fh:
    if mode == "json":
        json.dump(report, fh, indent=2)
        fh.write("\n")
    else:
        fh.write("# Theme Accessibility Audit\n\n")
        fh.write("- Standard: WCAG 2.x AA contrast (%.1f:1 normal text, %.1f:1 large-text floor for soft pairs)\n" % (AA_NORMAL, AA_LARGE))
        fh.write("- Themes audited: %d (discovered from template stylesheet links)\n" % len(report["themes"]))
        fh.write("- Verdicts: %d pass, %d warn, %d fail\n" % (
            report["summary"]["pass"], warn_count, fail_count))
        if skipped_templates:
            fh.write("- Templates without stylesheet links (skipped): %s\n" % ", ".join(skipped_templates))
        fh.write("\n## Summary\n\n")
        fh.write("| Theme | Templates | Scopes | Worst ratio | Focus | Narrow | Verdict |\n")
        fh.write("| --- | --- | --- | --- | --- | --- | --- |\n")
        for t in report["themes"]:
            worst_ratio = min(
                s["contrast_worst"] for s in t["scopes"] if s["contrast_worst"] is not None
            ) if any(s["contrast_worst"] is not None for s in t["scopes"]) else None
            focus_worst = worst([s["focus"]["verdict"] for s in t["scopes"]])
            narrow_worst = worst([s["narrow"]["verdict"] for s in t["scopes"]])
            fh.write("| `%s` | %s | %d | %s | %s | %s | %s |\n" % (
                t["css"],
                ", ".join("`%s`" % x for x in t["templates"]),
                len(t["scopes"]),
                "%.2f:1" % worst_ratio if worst_ratio else "-",
                focus_worst, narrow_worst, t["verdict"]))
        fh.write("\n## Detail\n\n")
        for t in report["themes"]:
            chain_desc = "`%s`" % t["css"]
            if t["imports"]:
                chain_desc += " <- " + ", ".join("`%s`" % i for i in t["imports"])
            fh.write("### %s (%s)\n\n" % (t["css"], chain_desc))
            fh.write("Templates: %s\n\n" % ", ".join("`%s`" % x for x in t["templates"]))
            for s in t["scopes"]:
                fh.write("#### scope `%s` — %s\n\n" % (s["scope"], s["verdict"]))
                fh.write("| Pair | Foreground | Background | Ratio | Threshold | Verdict | Note |\n")
                fh.write("| --- | --- | --- | --- | --- | --- | --- |\n")
                for p in s["pairs"]:
                    fh.write("| %s | %s | %s | %s | %s | %s | %s |\n" % (
                        p["pair"], p.get("fg", "-"), p.get("bg", "-"),
                        ("%.2f:1" % p["ratio"]) if p["ratio"] else "-",
                        ("%.1f:1" % p["threshold"]) if p.get("threshold") else "-",
                        p["verdict"], p.get("note", "")))
                fh.write("\nFocus: **%s** — %s\n\n" % (s["focus"]["verdict"], s["focus"]["note"]))
                fh.write("Narrow viewport: **%s** — %s\n\n" % (s["narrow"]["verdict"], s["narrow"]["note"]))
            if t.get("inline_pairs"):
                fh.write("#### hardcoded color/background pairs\n\n")
                fh.write("| Selector | Foreground | Background | Ratio | Verdict | Note |\n")
                fh.write("| --- | --- | --- | --- | --- | --- |\n")
                for p in t["inline_pairs"]:
                    fh.write("| `%s` | `%s` | `%s` | %.2f:1 | %s | %s |\n" % (
                        p["selector"], p["fg"], p["bg"], p["ratio"],
                        p["verdict"], p.get("note", "")))
                fh.write("\n")

print("SUMMARY themes=%d pass=%d warn=%d fail=%d" % (
    len(report["themes"]), report["summary"]["pass"], warn_count, fail_count))
for line in markers:
    print("MARKER\t%s" % line)
A11Y_PY
)

  if [[ -z "$summary" ]]; then
    log "ERROR" "Accessibility audit produced no summary (see $LOG_FILE)"
    exit 1
  fi

  # Relay per-theme MARKER lines collected by the auditor. Suppressed in JSON
  # mode so stdout carries machine-readable output only.
  if [[ "$JSON_MODE" == false ]]; then
    local line
    while IFS= read -r line; do
      case "$line" in
        MARKER*)
          log "MARKER" "${line:7}"
          ;;
      esac
    done <<< "$summary"
  fi

  local themes=0 pass=0 warns=0 fails=0
  if [[ "$summary" =~ SUMMARY\ themes=([0-9]+)\ pass=([0-9]+)\ warn=([0-9]+)\ fail=([0-9]+) ]]; then
    themes="${BASH_REMATCH[1]}"
    pass="${BASH_REMATCH[2]}"
    warns="${BASH_REMATCH[3]}"
    fails="${BASH_REMATCH[4]}"
  fi

  if [[ "$JSON_MODE" == true ]]; then
    cat "$out_file" >&3 2>/dev/null || cat "$out_file"
    # SIDE EFFECT (delete): removes the bones/tmp result scratch file after emit
    rm -f "$out_file"
    log "INFO" "Accessibility audit JSON emitted: $fails theme(s) failing"
  elif [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would write accessibility report to $REPORT_FILE"
    log "MARKER" "📄 Accessibility audit preview written to $out_file (dry-run; removed with next tmp clean)"
  else
    log "INFO" "Accessibility report written to $REPORT_FILE"
    if [[ "$fails" -eq 0 && "$warns" -eq 0 ]]; then
      log "MARKER" "✓ a11y: all $themes themes pass WCAG AA contrast, focus, and legibility checks"
    elif [[ "$fails" -eq 0 ]]; then
      log "MARKER" "⚠️ a11y: no failures, $warns theme(s) with warnings — see $REPORT_FILE"
    else
      log "MARKER" "✗ a11y: $fails theme(s) failing — see $REPORT_FILE"
    fi
  fi

  [[ "$fails" -eq 0 ]]
}

main "$@"
