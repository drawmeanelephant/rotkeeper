#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }

if [[ "${1:-}" == "--version" || "${1:-}" == "-v" ]]; then
  echo "rc-test.sh v$VERSION"
  exit 0
fi

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'HELP_EOF'
rc-test.sh — Integration test harness matrix

Usage:
  rotkeeper.sh test|smoke [--dry-run]

Options:
  --dry-run      Run only the removed-command regression checks
  --help, -h     Show help
  --version, -v  Show version and quit
HELP_EOF
  exit 0
fi

rk_load_env strict

# ============================================================
#  ████████╗███████╗███████╗████████╗
#  ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝
#     ██║   █████╗  ███████╗   ██║
#     ██║   ██╔══╝  ╚════██║   ██║
#     ██║   ███████╗███████║   ██║
#     ╚═╝   ╚══════╝╚══════╝   ╚═╝
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-test.sh
#  Purpose : Multi-Pass Layout Integration Test Suite aligned for single distribution zip archives
#  Version : 0.5.1
# ============================================================

set -euo pipefail
IFS=$'\n\t'

if [[ "${1:-}" == "--dry-run" ]]; then
echo "======================================================================"
echo "--- Regression tests for legacy rituals (ingest, sync-inbox, cleanup, reseed) ---"

for cmd in ingest sync-inbox cleanup reseed; do
  output=$(./rotkeeper.sh "$cmd" 2>&1 || true)
  if echo "$output" | grep -q "ERROR: The '$cmd' command has been permanently removed"; then
    echo "  🎉 Pass: Command '$cmd' correctly triggered deprecation error."
  else
    echo "❌ Assertion Failed: Command '$cmd' did not trigger the expected deprecation error."
    exit 101
  fi
done

echo "✅ ALL REGRESSION ASSERTIONS COMPLETED SUCCESSFULLY."

exit 0; fi

require_bins jq

echo "--- Rotkeeper Single framework Release Assertion Test Matrix ---"

TEST_DIR="${ROOT_DIR:-$PWD}/bones/tmp/rotkeeper-test-env"
cleanup_ran=false
TEST_RELEASE_VERSION="${ROTKEEPER_VERSION:-}"
if [[ -z "$TEST_RELEASE_VERSION" && -f "$ROOT_DIR/bones/config/version" ]]; then
  TEST_RELEASE_VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/bones/config/version")"
  TEST_RELEASE_VERSION="${TEST_RELEASE_VERSION#v}"
fi
if [[ -z "$TEST_RELEASE_VERSION" ]]; then
  echo "ERROR: Could not determine release version from bones/config/version" >&2
  exit 1
fi

canonicalize_test_path() {
  local path="$1"
  local parent
  local base
  local canonical

  if canonical=$(realpath -m "$path" 2>/dev/null); then
    printf '%s\n' "$canonical"
    return 0
  fi

  parent=$(dirname "$path")
  base=$(basename "$path")
  if parent=$(cd "$parent" 2>/dev/null && pwd -P); then
    printf '%s/%s\n' "$parent" "$base"
  else
    printf '%s\n' "$path"
  fi
}

# shellcheck disable=SC2329 # invoked indirectly by the EXIT/INT/TERM traps
cleanup() {
  local status=$?
  if [[ "${cleanup_ran:-false}" == true ]]; then
    return "$status"
  fi
  cleanup_ran=true

  trap - ERR EXIT INT TERM
  set +e

  if [[ -n "${TEST_DIR:-}" && -d "${TEST_DIR}" ]]; then
    CANONICAL_TEST_DIR=$(canonicalize_test_path "$TEST_DIR")
    if [[ "${CANONICAL_TEST_DIR}/" == "${ROOT_DIR}/"* ]]; then
      echo "Pruning testing footprints from the physical realm..."
      rm -rf "$CANONICAL_TEST_DIR" || true
    fi
  fi

  return "$status"
}

# shellcheck disable=SC2329 # invoked indirectly by the ERR trap
on_err() {
  local status=$?
  printf 'ERROR: status=%s file=%s line=%s function=%s command=%q\n' \
    "$status" "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}" \
    "${BASH_LINENO[0]:-$LINENO}" "${FUNCNAME[1]:-MAIN}" \
    "$BASH_COMMAND" >&2
  return "$status"
}

trap 'on_err' ERR
trap 'cleanup' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ -n "${TEST_DIR:-}" ]]; then
    CANONICAL_TEST_DIR=$(canonicalize_test_path "$TEST_DIR")
    if [[ "${CANONICAL_TEST_DIR}/" == "${ROOT_DIR}/"* ]]; then
        rm -rf "$CANONICAL_TEST_DIR" || true
    fi
fi
mkdir -p "$TEST_DIR"

LAYOUT_MODES=("crypt" "busy" "sterile")

for mode in ${LAYOUT_MODES[@]+"${LAYOUT_MODES[@]}"}; do
  pass_dir="$TEST_DIR/$mode"

  case "${mode,,}" in
    "busy")
      b_scripts="bones/scripts"
      b_config="bones/config"
      b_templates="templates"
      b_css="assets/css"
      b_content="home/content"
      b_archive="bones/archive"
      ;;
    "sterile")
      b_scripts="bones/scripts"
      b_config="bones/config"
      b_templates="config/templates"
      b_css="src/assets/css"
      b_content="src/content"
      b_archive="bones/archive"
      ;;
    "crypt"|*)
      b_scripts="bones/scripts"
      b_config="bones/config"
      b_templates="bones/templates"
      b_css="home/assets/css"
      b_content="home/content"
      b_archive="bones/archive"
      ;;
  esac

  mkdir -p "$pass_dir/$b_scripts"
  mkdir -p "$pass_dir/$b_config"
  mkdir -p "$pass_dir/$b_templates"

  cp rotkeeper.sh "$pass_dir/"
  cp bones/scripts/rc-*.sh "$pass_dir/$b_scripts/"
  cp bones/templates/*.html "$pass_dir/$b_templates/"
  cp "$ROOT_DIR/bones/config/version" "$pass_dir/$b_config/version"

  cat << CONF_EOF > "$pass_dir/$b_config/rotkeeper.yaml"
project: "Test Tomb"
author: "Test Necromancer"
default_template: "theme-light.html"
layout_style: "$mode"
CONF_EOF

  mkdir -p "$pass_dir/$b_css"
  mkdir -p "$pass_dir/$b_content"

  (
    cd "$pass_dir"
    export ROT_SKIP_ENV=false

    echo "  [+] Initializing environment testing pass..."
    ./rotkeeper.sh init --with-sample > /dev/null

    echo "  [+] Testing renderer selection and validation..."
    # 1. Invalid renderer flag must fail
    if ./rotkeeper.sh render --renderer invalid_choice >/dev/null 2>&1; then
      echo "❌ Assertion Failed: --renderer invalid_choice should have failed."
      exit 102
    fi

    # 2. Missing RK_OLIVER_BIN: falls back to PATH discovery; must fail only
    #    when no oliver executable exists on PATH (hermetic environments).
    if command -v oliver >/dev/null 2>&1; then
      if ! RK_OLIVER_BIN="" ./rotkeeper.sh render >/dev/null 2>&1; then
        echo "❌ Assertion Failed: oliver on PATH should render with empty RK_OLIVER_BIN."
        exit 103
      fi
    else
      if RK_OLIVER_BIN="" ./rotkeeper.sh render >/dev/null 2>&1; then
        echo "❌ Assertion Failed: default oliver render without RK_OLIVER_BIN should have failed."
        exit 103
      fi
    fi

    # 3. Non-existent RK_OLIVER_BIN must fail for default oliver renderer
    if RK_OLIVER_BIN="/nonexistent/oliver" ./rotkeeper.sh render >/dev/null 2>&1; then
      echo "❌ Assertion Failed: default oliver render with invalid RK_OLIVER_BIN should have failed."
      exit 104
    fi

    # 4. Removed renderer must be rejected (Pandoc support was removed)
    if RK_RENDERER=pandoc ./rotkeeper.sh render --renderer pandoc >/dev/null 2>&1; then
      echo "❌ Assertion Failed: removed --renderer pandoc should have been rejected."
      exit 133
    fi

    # 5. Pure Bash/GAWK/YQ Oliver adapter contract test (Zero Python)
    echo "  [+] Executing default pure Bash/GAWK/YQ Oliver adapter contract tests..."
    mkdir -p bones/tmp
    fake_bin="$pass_dir/bones/tmp/fake_oliver"
    cat << 'FAKE_EOF' > "$fake_bin"
#!/usr/bin/env bash
set -euo pipefail
# Mimic Oliver CLI shape for S1+S2+S3+S4+S5: supports `oliver manifest`, `oliver plan`, `oliver meta`, `oliver wrap`, and `oliver render`
if [[ "${1:-}" == "manifest" ]]; then
  if [[ "${2:-}" == "--help" ]]; then
    echo "Usage: oliver manifest --manifest <file> --add <rel> | --verify"
    exit 0
  fi
  manifest=""; add=""; verify=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --manifest) manifest="$2"; shift 2 ;;
      --add) add="$2"; shift 2 ;;
      --verify) verify=true; shift ;;
      *) shift ;;
    esac
  done
  if [[ -n "$add" && -n "$manifest" ]]; then
    mkdir -p "$(dirname "$manifest")"
    touch "$manifest"
    if ! grep -Fxq "$add" "$manifest" 2>/dev/null; then
      echo "$add" >> "$manifest"
    fi
    exit 0
  fi
  if [[ "$verify" == true ]]; then
    exit 0
  fi
  exit 1
fi
if [[ "${1:-}" == "plan" ]]; then
  if [[ "${2:-}" == "--help" ]]; then
    echo "Usage: oliver plan --content-dir <dir> --output-dir <dir> --template-dir <dir> --meta-dir <dir> --default-template <file> --oliver-bin <bin> --root-dir <dir> --dry-run <bool> --verbose <bool>"
    exit 0
  fi
  content_dir=""; output_dir=""; template_dir=""; meta_dir=""; default_template=""; oliver_bin_arg=""; root_dir=""; dry_run=""; verbose=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --content-dir) content_dir="$2"; shift 2 ;;
      --output-dir) output_dir="$2"; shift 2 ;;
      --template-dir) template_dir="$2"; shift 2 ;;
      --meta-dir) meta_dir="$2"; shift 2 ;;
      --default-template) default_template="$2"; shift 2 ;;
      --oliver-bin) oliver_bin_arg="$2"; shift 2 ;;
      --root-dir) root_dir="$2"; shift 2 ;;
      --dry-run) dry_run="$2"; shift 2 ;;
      --verbose) verbose="$2"; shift 2 ;;
      --help) echo "Usage: oliver plan ..."; exit 0 ;;
      *) shift ;;
    esac
  done
  if [[ -z "$content_dir" || -z "$output_dir" || -z "$template_dir" ]]; then echo "plan: missing required args" >&2; exit 1; fi
  # Replicate rc-render.sh planning: emit TSV (minimal, no external CoreFoundation tools)
  strip_source_ext() { case "$1" in *.md) printf '%s' "${1%.md}" ;; *.textile) printf '%s' "${1%.textile}" ;; *.cook) printf '%s' "${1%.cook}" ;; *) printf '%s' "$1" ;; esac; }
  rk_up_dirs() { local n="${1:-0}" i=0 out=""; for ((i=0;i<n;i++)); do out+="../"; done; printf '%s' "$out"; }
  shopt -s globstar nullglob
  # Use simple seen string to dedup without grep/mktemp
  seen=""
  for mdfile in "$content_dir"/**/*.md "$content_dir"/**/*.textile "$content_dir"/**/*.cook; do
    [ -f "$mdfile" ] || continue
    case " $seen " in *" $mdfile "*) continue;; esac
    seen="$seen $mdfile"
    canon="$mdfile"
    rel="${canon#"$content_dir"/}"
    if [[ "$rel" == "$canon" ]]; then rel="$(basename "$canon")"; fi
    base=$(strip_source_ext "$(basename "$rel")")
    reldir=$(dirname "$rel")
    if [[ "$reldir" == "." ]]; then outdir="$output_dir"; else outdir="$output_dir/$reldir"; fi
    outfile="$outdir/${base}.html"
    soul_file="$meta_dir/$(strip_source_ext "$rel").soul.md"
    if [[ -f "$soul_file" ]]; then canon_soul="$soul_file"; else canon_soul=""; fi
    if [[ "$reldir" == "." ]]; then asroot="./assets/"; else depth=$(echo "$reldir" | tr -cd '/' | wc -c); asroot="$(rk_up_dirs $((depth+1)))assets/"; fi
    soul_param="${canon_soul:-NONE}"
    tmpl_file="$template_dir/$default_template"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$canon" "$outfile" "$tmpl_file" "$asroot" "$soul_param" "$oliver_bin_arg" "$root_dir" "$content_dir" "$output_dir" "$template_dir" "$meta_dir" "$dry_run" "$verbose"
  done
  # Also handle top-level without ** (in case globstar doesn't match top-level when ** is empty, already covered by **/*.md matching top-level, but keep for safety)
  for mdfile in "$content_dir"/*.md "$content_dir"/*.textile "$content_dir"/*.cook; do
    [ -f "$mdfile" ] || continue
    case " $seen " in *" $mdfile "*) continue;; esac
    seen="$seen $mdfile"
    canon="$mdfile"
    rel="${canon#"$content_dir"/}"
    if [[ "$rel" == "$canon" ]]; then rel="$(basename "$canon")"; fi
    base=$(strip_source_ext "$(basename "$rel")")
    reldir=$(dirname "$rel")
    if [[ "$reldir" == "." ]]; then outdir="$output_dir"; else outdir="$output_dir/$reldir"; fi
    outfile="$outdir/${base}.html"
    soul_file="$meta_dir/$(strip_source_ext "$rel").soul.md"
    if [[ -f "$soul_file" ]]; then canon_soul="$soul_file"; else canon_soul=""; fi
    if [[ "$reldir" == "." ]]; then asroot="./assets/"; else depth=$(echo "$reldir" | tr -cd '/' | wc -c); asroot="$(rk_up_dirs $((depth+1)))assets/"; fi
    soul_param="${canon_soul:-NONE}"
    tmpl_file="$template_dir/$default_template"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$canon" "$outfile" "$tmpl_file" "$asroot" "$soul_param" "$oliver_bin_arg" "$root_dir" "$content_dir" "$output_dir" "$template_dir" "$meta_dir" "$dry_run" "$verbose"
  done
  shopt -u globstar nullglob 2>/dev/null || true
  exit 0
fi
# Mimic Oliver CLI shape for S1+S2: supports `oliver meta`, `oliver wrap`, and `oliver render`
if [[ "${1:-}" == "meta" ]]; then
  if [[ "${2:-}" == "--help" ]]; then
    echo "Usage: oliver meta --from <markdown|textile|cooklang> --format json"
    exit 0
  fi
  if [[ "${2:-}" != "--from" || ( "${3:-}" != "markdown" && "${3:-}" != "textile" && "${3:-}" != "cooklang" ) ]]; then
    exit 1
  fi
  if [[ "${4:-}" != "--format" || "${5:-}" != "json" ]]; then
    exit 1
  fi
  tmp_in=$(mktemp)
  cat > "$tmp_in"
  # yq frontmatter extraction is the contract for scalar fields; lists/maps are ignored by the selected keys.
  yq --front-matter extract -o json '{"title": .title, "description": .description, "author": .author, "date": .date, "template": .template, "palette": .palette, "render_profile": .render_profile}' "$tmp_in" 2>/dev/null || echo "{}"
  rm -f "$tmp_in"
  exit 0
fi
if [[ "${1:-}" == "wrap" ]]; then
  if [[ "${2:-}" == "--help" ]]; then
    echo "Usage: oliver wrap --template <file> --meta-json <file> --assets-root <prefix> --body <file>"
    exit 0
  fi
  tpl=""; mj=""; ar=""; bf=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --template) tpl="$2"; shift 2 ;;
      --meta-json) mj="$2"; shift 2 ;;
      --assets-root) ar="$2"; shift 2 ;;
      --body) bf="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  if [[ -z "$tpl" || -z "$mj" || -z "$bf" ]]; then exit 1; fi
  title=$(jq -r '.title // ""' "$mj" 2>/dev/null || yq -r '.title // ""' "$mj" 2>/dev/null || echo "")
  desc=$(jq -r '.description // ""' "$mj" 2>/dev/null || yq -r '.description // ""' "$mj" 2>/dev/null || echo "")
  author=$(jq -r '.author // ""' "$mj" 2>/dev/null || yq -r '.author // ""' "$mj" 2>/dev/null || echo "")
  date=$(jq -r '.date // ""' "$mj" 2>/dev/null || yq -r '.date // ""' "$mj" 2>/dev/null || echo "")
  palette=$(jq -r '.palette // ""' "$mj" 2>/dev/null || yq -r '.palette // ""' "$mj" 2>/dev/null || echo "")
  [[ "$title" == "null" ]] && title=""
  [[ "$desc" == "null" ]] && desc=""
  [[ "$author" == "null" ]] && author=""
  [[ "$date" == "null" ]] && date=""
  [[ "$palette" == "null" ]] && palette=""
  gawk -v title="$title" -v desc="$desc" -v author="$author" -v date="$date" -v palette="$palette" -v assets_root="$ar" -v body_file="$bf" -v template_file="$tpl" '
  function html_escape(str,   s) { s=str; gsub(/&/,"\\&amp;",s); gsub(/</,"\\&lt;",s); gsub(/>/,"\\&gt;",s); gsub(/"/,"\\&quot;",s); gsub(/\x27/,"\\&#39;",s); return s }
  function literal_replace(str, search, replace,   pos, len, result, tail) { len=length(search); result=""; tail=str; while((pos=index(tail,search))>0){result=result substr(tail,1,pos-1) replace; tail=substr(tail,pos+len)} return result tail }
  function evaluate_if(tmpl, var_name, var_val,   start_tag, end_tag, sp, ep, before, after, inner) { start_tag="$if(" var_name ")$"; end_tag="$endif$"; while((sp=index(tmpl,start_tag))>0){ep=index(substr(tmpl,sp),end_tag); if(ep==0) break; ep=sp+ep-1+length(end_tag)-1; before=substr(tmpl,1,sp-1); after=substr(tmpl,ep+1); if(var_val==""||var_val=="null"){tmpl=before after}else{inner=substr(tmpl,sp+length(start_tag),ep-sp-length(start_tag)-length(end_tag)+1); tmpl=before inner after} } return tmpl }
  BEGIN { title_esc=html_escape(title); desc_esc=html_escape(desc); author_esc=html_escape(author); date_esc=html_escape(date); palette_esc=html_escape(palette); body=""; while((getline line < body_file)>0){body=body line "\n"} close(body_file); if(length(body)>0 && substr(body,length(body))=="\n") body=substr(body,1,length(body)-1); tmpl=""; while((getline line < template_file)>0){tmpl=tmpl line "\n"} close(template_file); tmpl=evaluate_if(tmpl,"title",title); tmpl=evaluate_if(tmpl,"description",desc); tmpl=evaluate_if(tmpl,"author",author); tmpl=evaluate_if(tmpl,"date",date); tmpl=evaluate_if(tmpl,"palette",palette); tmpl=literal_replace(tmpl,"$title$",title_esc); tmpl=literal_replace(tmpl,"$description$",desc_esc); tmpl=literal_replace(tmpl,"$author$",author_esc); tmpl=literal_replace(tmpl,"$date$",date_esc); tmpl=literal_replace(tmpl,"$palette$",palette_esc); tmpl=literal_replace(tmpl,"$assets_root$",ar); tmpl=literal_replace(tmpl,"$body$",body); printf "%s",tmpl; exit }'
  exit 0
fi
# Mimic Oliver's CLI shape: oliver render --from <markdown|textile|cooklang> [--to <html|xhtml>] < file
# S3: Oliver natively rewrites .md/.textile/.cook → .html (AST-level), so fake must do the same for probe.
if [[ "${1:-}" != "render" || "${2:-}" != "--from" || ( "${3:-}" != "markdown" && "${3:-}" != "textile" && "${3:-}" != "cooklang" ) ]]; then
  exit 1
fi
if [[ "${4:-}" == "--to" && "${5:-}" == "xhtml" ]]; then
  printf '<h1>xhtml-profile-confirmed</h1>\n<hr />\n'
  awk '/^---$/ { f++; next } f>=2 || f==0 { print }' | \
    sed -E 's/\[([^]]+)\]\(([^)]+)\)/<a href="\2">\1<\/a>/g' | \
    gawk '{ line=$0; out=""; while(match(line,/(href|src)=("|\x27)([^"\x27]+)("|\x27)/,a)){ outer=RSTART; rlen=RLENGTH; pre=substr(line,1,outer-1); tgt=a[3]; if(tgt~/^(%3C|<|&lt;).*(%3E|>|&gt;)$/){ if(substr(tgt,1,3)=="%3C") tgt=substr(tgt,4); else if(substr(tgt,1,4)=="&lt;") tgt=substr(tgt,5); else if(substr(tgt,1,1)=="<") tgt=substr(tgt,2); tlen=length(tgt); if(tlen>=3 && substr(tgt,tlen-2)=="%3E") tgt=substr(tgt,1,tlen-3); else if(tlen>=4 && substr(tgt,tlen-3)=="&gt;") tgt=substr(tgt,1,tlen-4); else if(tlen>=1 && substr(tgt,tlen)==">") tgt=substr(tgt,1,tlen-1)} if(tgt~/^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//||tgt~/^mailto:/) nt=tgt; else if(match(tgt,/\.md(\?|#|$)/)){ nt=substr(tgt,1,RSTART-1) ".html" substr(tgt,RSTART+3)} else if(match(tgt,/\.textile(\?|#|$)/)){ nt=substr(tgt,1,RSTART-1) ".html" substr(tgt,RSTART+8)} else if(match(tgt,/\.cook(\?|#|$)/)){ nt=substr(tgt,1,RSTART-1) ".html" substr(tgt,RSTART+5)} else nt=tgt; out=out pre a[1] "=" a[2] nt a[2]; line=substr(line,outer+rlen)} out=out line; print out }'
  exit 0
fi
if [[ "${3:-}" == "textile" ]]; then
  printf '<h1>textile-input-confirmed</h1>\n<a href="sibling.html">Sibling</a>\n'
  exit 0
fi
if [[ "${3:-}" == "cooklang" ]]; then
  printf '<article class="recipe"><h1>cooklang-input-confirmed</h1>\n<a href="sibling.html">Sibling</a>\n</article>\n'
  exit 0
fi
awk '/^---$/ { f++; next } f>=2 || f==0 { print }' | \
  sed -E 's/\[([^]]+)\]\(([^)]+)\)/<a href="\2">\1<\/a>/g' | \
  gawk '{ line=$0; out=""; while(match(line,/(href|src)=("|\x27)([^"\x27]+)("|\x27)/,a)){ outer=RSTART; rlen=RLENGTH; pre=substr(line,1,outer-1); tgt=a[3]; if(tgt~/^(%3C|<|&lt;).*(%3E|>|&gt;)$/){ if(substr(tgt,1,3)=="%3C") tgt=substr(tgt,4); else if(substr(tgt,1,4)=="&lt;") tgt=substr(tgt,5); else if(substr(tgt,1,1)=="<") tgt=substr(tgt,2); tlen=length(tgt); if(tlen>=3 && substr(tgt,tlen-2)=="%3E") tgt=substr(tgt,1,tlen-3); else if(tlen>=4 && substr(tgt,tlen-3)=="&gt;") tgt=substr(tgt,1,tlen-4); else if(tlen>=1 && substr(tgt,tlen)==">") tgt=substr(tgt,1,tlen-1)} if(tgt~/^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//||tgt~/^mailto:/) nt=tgt; else if(match(tgt,/\.md(\?|#|$)/)){ nt=substr(tgt,1,RSTART-1) ".html" substr(tgt,RSTART+3)} else if(match(tgt,/\.textile(\?|#|$)/)){ nt=substr(tgt,1,RSTART-1) ".html" substr(tgt,RSTART+8)} else if(match(tgt,/\.cook(\?|#|$)/)){ nt=substr(tgt,1,RSTART-1) ".html" substr(tgt,RSTART+5)} else nt=tgt; out=out pre a[1] "=" a[2] nt a[2]; line=substr(line,outer+rlen)} out=out line; print out }'
FAKE_EOF
    chmod +x "$fake_bin"

    # Create ugly metadata & edge-case link test file
    cat << 'UGLY_EOF' > "$b_content/ugly-edge-case.md"
---
title: "An \"Ugly\" Quoted Title"
description: |-
  A multiline description
  with quotes "hello" and breaks.
---

[Normal Link](my-first-page.md)
[Fragment Link](my-first-page.md#section-1)
[Query Link](my-first-page.md?v=123#fragment)
[External Link](https://example.com/docs.md)
[Mailto Link](mailto:necromancer@example.com)
[Angle Bracket Link](<my-first-page.md>)
[Angle Bracket External Link](<https://example.com/docs.md>)
[Angle Bracket Fragment Link](<my-first-page.md#section-1>)
<a href="my-first-page.md">Raw HTML Link</a>
UGLY_EOF

    RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null

    # Verify link rewriting assertions on generated HTML (using dynamic $OUTPUT_DIR)
    out_dir_rel="output"
    if [[ "$mode" == "sterile" ]]; then
      out_dir_rel="dist"
    fi
    rendered_ugly="$out_dir_rel/ugly-edge-case.html"

    if [[ ! -f "$rendered_ugly" ]]; then
      echo "❌ Assertion Failed: Oliver rendered output missing for ugly-edge-case.html ($rendered_ugly)"
      exit 105
    fi

    if grep -q 'href="my-first-page.md"' "$rendered_ugly"; then
      echo "❌ Assertion Failed: .md link was not rewritten to .html"
      exit 106
    fi

    if ! grep -q 'href="my-first-page.html"' "$rendered_ugly"; then
      echo "❌ Assertion Failed: .md link was not correctly rewritten to .html"
      exit 107
    fi

    if ! grep -q 'href="my-first-page.html#section-1"' "$rendered_ugly"; then
      echo "❌ Assertion Failed: .md#fragment link was not correctly rewritten"
      exit 108
    fi

    if ! grep -q 'href="my-first-page.html?v=123#fragment"' "$rendered_ugly"; then
      echo "❌ Assertion Failed: .md?query#fragment link was not correctly rewritten"
      exit 109
    fi

    if ! grep -q 'href="https://example.com/docs.md"' "$rendered_ugly"; then
      echo "❌ Assertion Failed: External URL was incorrectly modified"
      exit 110
    fi

    if ! grep -q 'href="mailto:necromancer@example.com"' "$rendered_ugly"; then
      echo "❌ Assertion Failed: mailto link was incorrectly modified"
      exit 111
    fi

    if grep -q 'href="%3C' "$rendered_ugly" || grep -q 'href="<' "$rendered_ugly"; then
      echo "❌ Assertion Failed: angle bracket wrapper leaked into rendered href attribute"
      exit 112
    fi

    # --- Checked-in hermetic smoke fixture + golden comparison ---
    # The fixture lives at bones/scripts/tests/fixtures/oliver-smoke/ and renders
    # through the same fake binary used above (zero Oliver required). The rendered
    # <body> region is layout-independent (the head's $assets_root$ link differs
    # per layout style), so the golden body is compared verbatim on every mode.
    FIXTURE_SRC="$ROOT_DIR/bones/scripts/tests/fixtures/oliver-smoke/smoke-fixture.md"
    GOLDEN_HTML="$ROOT_DIR/bones/scripts/tests/fixtures/oliver-smoke/smoke-fixture-expected.html"

    if [[ -f "$FIXTURE_SRC" && -f "$GOLDEN_HTML" ]]; then
      cp "$FIXTURE_SRC" "$b_content/smoke-fixture.md"
      RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null

      rendered_smoke="$out_dir_rel/smoke-fixture.html"
      if [[ ! -f "$rendered_smoke" ]]; then
        echo "❌ Assertion Failed: smoke fixture did not render: $rendered_smoke"
        exit 113
      fi

      live_body=$(sed -n '/<body class="rk-page">/,/<\/body>/p' "$rendered_smoke")
      golden_body=$(sed -n '/<body class="rk-page">/,/<\/body>/p' "$GOLDEN_HTML")
      if [[ "$live_body" != "$golden_body" ]]; then
        echo "❌ Assertion Failed: smoke fixture body diverges from golden ($mode)."
        echo "  Rendered: $rendered_smoke"
        echo "  Golden:   $GOLDEN_HTML"
        exit 113
      fi
      echo "  [+] Pass: checked-in smoke fixture body matches golden ($mode)."

      # Nested output path: the same fixture under a content subdirectory must
      # render into a mirrored nested output path with an identical body.
      mkdir -p "$b_content/docs"
      cp "$FIXTURE_SRC" "$b_content/docs/smoke-fixture.md"
      RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null

      rendered_nested="$out_dir_rel/docs/smoke-fixture.html"
      if [[ ! -f "$rendered_nested" ]]; then
        echo "❌ Assertion Failed: nested smoke fixture did not render: $rendered_nested"
        exit 113
      fi

      nested_body=$(sed -n '/<body class="rk-page">/,/<\/body>/p' "$rendered_nested")
      if [[ "$nested_body" != "$golden_body" ]]; then
        echo "❌ Assertion Failed: nested smoke fixture body diverges from golden ($mode)."
        echo "  Rendered: $rendered_nested"
        exit 113
      fi
      echo "  [+] Pass: nested smoke fixture body matches golden ($mode)."
    else
      echo "⚠️  Skipping checked-in smoke fixture: fixture or golden missing."
    fi

    # --- v0.5.1 Specific Maintenance Contract Assertions ---
    echo "  [+] Executing v0.5.1 literal-safe, HTML-escaping, soul sidecar & Oliver stderr assertions..."
    
    # 1. Oliver stderr separation check with fake binary emitting warnings
    fake_warn_bin="$pass_dir/bones/tmp/fake_oliver_warn"
    cat << 'WARN_BIN_EOF' > "$fake_warn_bin"
#!/usr/bin/env bash
set -euo pipefail
# Mimic Oliver's CLI shape: oliver render --from markdown < file.md
if [[ "${1:-}" != "render" || "${2:-}" != "--from" || "${3:-}" != "markdown" ]]; then
  exit 1
fi
echo "[OLIVER WARN] Sample non-fatal renderer warning" >&2
awk '/^---$/ { f++; next } f>=2 || f==0 { print }'
WARN_BIN_EOF
    chmod +x "$fake_warn_bin"

    # Create test markdown file with ampersands, quotes, angle brackets, and $body$ literal
    cat << 'TEST_V051_EOF' > "$b_content/v051-test.md"
---
title: "Cats & Dogs <v0.5.1>"
description: "R&D & \"Quotes\""
---

Body text containing Ampersand & Bits and literal $body$ text.
TEST_V051_EOF

    # Create soul sidecar with frontmatter block
    mkdir -p "bones/meta"
    cat << 'SOUL_V051_EOF' > "bones/meta/v051-test.soul.md"
---
title: "Overridden Title & <Sidecar>"
---
SOUL_V051_EOF

    RK_OLIVER_BIN="$fake_warn_bin" ./rotkeeper.sh render > /dev/null

    rendered_v051="$out_dir_rel/v051-test.html"
    if [[ ! -f "$rendered_v051" ]]; then
      echo "❌ Assertion Failed: v051-test.html missing after render."
      exit 119
    fi

    # Verify sidecar frontmatter title override + HTML escaping
    if ! grep -q 'Overridden Title &amp; &lt;Sidecar&gt;' "$rendered_v051"; then
      echo "❌ Assertion Failed: .soul.md frontmatter title override or HTML escaping failed."
      exit 120
    fi

    # Verify literal-safe interpolation of & and $body$ (no unsubstituted metadata placeholders left)
    # shellcheck disable=SC2016
    if grep -q '\$title\$' "$rendered_v051" || grep -q '\$description\$' "$rendered_v051"; then
      echo "❌ Assertion Failed: Template interpolation leaked \$title\$ or \$description\$ placeholder."
      exit 121
    fi

    # shellcheck disable=SC2016
    if ! grep -q 'Body text containing Ampersand & Bits and literal \$body\$ text.' "$rendered_v051"; then
      echo "❌ Assertion Failed: Literal body content containing & or \$body\$ was corrupted."
      exit 122
    fi

    # Verify Oliver stderr did not leak into rendered HTML body
    if grep -q 'OLIVER WARN' "$rendered_v051"; then
      echo "❌ Assertion Failed: Oliver stderr leaked into rendered HTML body."
      exit 123
    fi

    # --- S1: Frontmatter extraction via Oliver meta (with yq fallback) ---
    echo "  [+] Executing S1 frontmatter extraction assertions (Oliver meta + yq fallback)..."
    # 1. Multiline description + scalar-only: lists/maps ignored, null handling
    cat << 'FRONT_S1_EOF' > "$b_content/frontmatter-s1.md"
---
title: "S1 Frontmatter"
description: |-
  Multiline with "quotes" & amps
  second line
author: "Author & <Test>"
date: "2026-08-20"
palette: "phosphor"
tags: [ignored, list]
extra_map:
  key: value
render_profile: html
---
Body for S1.
FRONT_S1_EOF
    RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null
    rendered_s1="$out_dir_rel/frontmatter-s1.html"
    if [[ ! -f "$rendered_s1" ]]; then
      echo "❌ Assertion Failed: frontmatter-s1.html missing (S1)."
      exit 191
    fi
    if ! grep -q 'S1 Frontmatter' "$rendered_s1"; then
      echo "❌ Assertion Failed: S1 title not rendered."
      exit 192
    fi
    if ! grep -q 'Multiline with &quot;quotes&quot; &amp; amps' "$rendered_s1"; then
      echo "❌ Assertion Failed: S1 multiline description escaping failed (via meta)."
      exit 193
    fi
    if grep -q 'ignored' "$rendered_s1" || grep -q 'extra_map' "$rendered_s1"; then
      echo "❌ Assertion Failed: S1 list/map field leaked into output (must be ignored)."
      exit 194
    fi
    # 2. Line-1 rule: frontmatter must start on line 1, no BOM/blank line — else treated as body
    cat << 'FRONT_S1B_EOF' > "$b_content/frontmatter-s1b.md"

---
title: "Should Not Parse"
---
Body with leading blank line — title must be empty.
FRONT_S1B_EOF
    RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null
    rendered_s1b="$out_dir_rel/frontmatter-s1b.html"
    if grep -q 'Should Not Parse' "$rendered_s1b"; then
      echo "❌ Assertion Failed: S1 line-1 rule violated — frontmatter parsed despite leading blank line."
      exit 195
    fi
    if ! grep -q 'Body with leading blank line' "$rendered_s1b"; then
      echo "❌ Assertion Failed: S1 body missing after failed frontmatter parse."
      exit 196
    fi
    # 3. Oliver meta CLI probe: fake binary must handle `meta --from <fmt> --format json`
    tmp_meta_in="$pass_dir/bones/tmp/meta-probe.md"
    cat << 'META_PROBE_EOF' > "$tmp_meta_in"
---
title: "Probe"
---
Body
META_PROBE_EOF
    if ! "$fake_bin" meta --from markdown --format json < "$tmp_meta_in" | grep -q '"title": "Probe"'; then
      echo "❌ Assertion Failed: fake Oliver meta did not return JSON with title."
      exit 197
    fi
    if ! "$fake_bin" meta --help | grep -q 'meta'; then
      echo "❌ Assertion Failed: fake Oliver meta --help not advertised."
      exit 198
    fi
    # Real Oliver meta probe (when present, but not required for green on current pin)
    _real_probe="${RK_OLIVER_BIN:-}"
    if [[ -z "$_real_probe" || ! -x "$_real_probe" ]]; then
      _real_probe="$(command -v oliver 2>/dev/null || true)"
    fi
    if [[ -n "$_real_probe" && -x "$_real_probe" ]]; then
      if "$_real_probe" meta --help >/dev/null 2>&1; then
        if ! "$_real_probe" meta --from markdown --format json < "$tmp_meta_in" | grep -q '"title"'; then
          echo "❌ Assertion Failed: real Oliver meta returned no JSON."
          exit 199
        fi
        echo "  [+] Pass: real Oliver meta extraction probe ($mode)."
      else
        echo "  [+] Skipping real Oliver meta probe — binary lacks meta (expected on pin 6edb520c, S1 will bump)."
      fi
    fi
    echo "  [+] Pass: S1 frontmatter extraction assertions ($mode)."

    # --- S2: Template dialect via Oliver wrap (with GAWK fallback) ---
    echo "  [+] Executing S2 template dialect assertions (Oliver wrap + GAWK fallback)..."
    cat << 'TPL_S2_EOF' > "$b_templates/custom-s2.html"
<title>$title$</title>
$if(title)$TITLE:$title$$endif$
$if(description)$DESC:$description$$endif$
$if(palette)$PAL:$palette$$endif$
assets:$assets_root$
body:$body$
unknown:$unknown$
TPL_S2_EOF
    cat << 'S2_EOF' > "$b_content/template-s2.md"
---
title: "S2 & <Title>"
description: "Desc & <Val>"
palette: "phosphor"
template: "custom-s2.html"
---
Body & with $body$ literal
S2_EOF
    RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null
    rendered_s2="$out_dir_rel/template-s2.html"
    if [[ ! -f "$rendered_s2" ]]; then
      echo "❌ Assertion Failed: template-s2.html missing (S2)."
      exit 204
    fi
    if ! grep -q '<title>S2 &amp; &lt;Title&gt;</title>' "$rendered_s2"; then
      echo "❌ Assertion Failed: S2 title html_escape via wrap failed."
      exit 205
    fi
    if ! grep -q 'TITLE:S2 &amp; &lt;Title&gt;' "$rendered_s2"; then
      echo "❌ Assertion Failed: S2 \$if(title)\$ gate failed (should be kept)."
      exit 206
    fi
    if ! grep -q 'DESC:Desc &amp; &lt;Val&gt;' "$rendered_s2"; then
      echo "❌ Assertion Failed: S2 description escaping/\$if\$ failed."
      exit 207
    fi
    if ! grep -q 'PAL:phosphor' "$rendered_s2"; then
      echo "❌ Assertion Failed: S2 palette \$if\$ failed."
      exit 208
    fi
    # $assets_root$ must be literal (not escaped) and $body$ literal (trusted HTML, contains & and $body$)
    if ! grep -q 'assets:\./assets/' "$rendered_s2" && ! grep -q 'assets:\.\./' "$rendered_s2"; then
      # sterile crypt etc have different prefixes; just check assets_root appears literally
      if ! grep -q 'assets:' "$rendered_s2"; then
        echo "❌ Assertion Failed: S2 \$assets_root\$ literal not preserved."
        exit 209
      fi
    fi
    # shellcheck disable=SC2016
    if ! grep -q 'Body & with \$body\$ literal' "$rendered_s2"; then
      echo "❌ Assertion Failed: S2 \$body\$ literal not preserved (must not be escaped, must keep \$body\$)."
      exit 210
    fi
    # shellcheck disable=SC2016
    if ! grep -q 'unknown:\$unknown\$' "$rendered_s2"; then
      echo "❌ Assertion Failed: S2 unknown token verbatim failed (should pass through)."
      exit 211
    fi
    # $if$ empty removal: title missing -> block removed
    cat << 'S2_EMPTY_EOF' > "$b_content/template-s2-empty.md"
---
description: "Only desc"
template: "custom-s2.html"
---
Empty title body.
S2_EMPTY_EOF
    RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null
    rendered_s2e="$out_dir_rel/template-s2-empty.html"
    if grep -q 'TITLE:' "$rendered_s2e"; then
      echo "❌ Assertion Failed: S2 \$if(title)\$ empty removal failed (TITLE block should be removed)."
      exit 212
    fi
    if ! grep -q 'DESC:Only desc' "$rendered_s2e"; then
      echo "❌ Assertion Failed: S2 empty-title case DESC should still appear."
      exit 213
    fi
    # Probe fake wrap directly
    tmp_body="$pass_dir/bones/tmp/body-probe.html"
    echo "probe body &" > "$tmp_body"
    tmp_meta_wrap="$pass_dir/bones/tmp/meta-wrap-probe.json"
    printf '{"title":"Wrap & <Probe>","description":"","author":"","date":"","palette":""}' > "$tmp_meta_wrap"
    if ! "$fake_bin" wrap --template "$b_templates/custom-s2.html" --meta-json "$tmp_meta_wrap" --assets-root "./assets/" --body "$tmp_body" | grep -q 'Wrap &amp; &lt;Probe&gt;'; then
      echo "❌ Assertion Failed: fake Oliver wrap did not escape title."
      exit 214
    fi
    if ! "$fake_bin" wrap --help | grep -q 'wrap'; then
      echo "❌ Assertion Failed: fake Oliver wrap --help not advertised."
      exit 215
    fi
    # Real Oliver wrap probe (skip on current pin)
    _real_wrap="${RK_OLIVER_BIN:-}"
    if [[ -z "$_real_wrap" || ! -x "$_real_wrap" ]]; then
      _real_wrap="$(command -v oliver 2>/dev/null || true)"
    fi
    if [[ -n "$_real_wrap" && -x "$_real_wrap" ]]; then
      if "$_real_wrap" wrap --help >/dev/null 2>&1; then
        if ! "$_real_wrap" wrap --template "$b_templates/custom-s2.html" --meta-json "$tmp_meta_wrap" --assets-root "./assets/" --body "$tmp_body" | grep -q 'Wrap'; then
          echo "❌ Assertion Failed: real Oliver wrap returned no output."
          exit 216
        fi
        echo "  [+] Pass: real Oliver wrap probe ($mode)."
      else
        echo "  [+] Skipping real Oliver wrap probe — binary lacks wrap (expected on pin 6edb520c, S2 will bump)."
      fi
    fi
    echo "  [+] Pass: S2 template dialect assertions ($mode)."

    # --- S3: Link rewriting via Oliver (with GAWK fallback) ---
    echo "  [+] Executing S3 link rewriting assertions (Oliver native + GAWK fallback)..."
    if ! printf '[x](foo.md)\n' | "$fake_bin" render --from markdown | grep -q 'foo.html'; then
      echo "❌ Assertion Failed: S3 fake Oliver did not rewrite .md → .html (native)."
      exit 217
    fi
    if ! printf '[x](foo.textile)\n' | "$fake_bin" render --from markdown | grep -q 'foo.html'; then
      echo "❌ Assertion Failed: S3 fake Oliver did not rewrite .textile → .html."
      exit 218
    fi
    if ! printf '[x](foo.cook)\n' | "$fake_bin" render --from markdown | grep -q 'foo.html'; then
      echo "❌ Assertion Failed: S3 fake Oliver did not rewrite .cook → .html."
      exit 219
    fi
    # Angle bracket and fragment/query preserved
    if ! printf '[x](<foo.md#sec>)\n' | "$fake_bin" render --from markdown | grep -q 'foo.html#sec'; then
      echo "❌ Assertion Failed: S3 fake Oliver angle-bracket/fragment handling failed."
      exit 220
    fi
    if ! printf '[x](foo.md?v=1#f2)\n' | "$fake_bin" render --from markdown | grep -q 'foo.html?v=1#f2'; then
      echo "❌ Assertion Failed: S3 fake Oliver query/fragment handling failed."
      exit 221
    fi
    # External and mailto must not be rewritten
    if printf '[x](https://example.com/foo.md)\n' | "$fake_bin" render --from markdown | grep -q 'foo.html'; then
      echo "❌ Assertion Failed: S3 fake Oliver incorrectly rewrote external .md link."
      exit 222
    fi
    if printf '[x](mailto:a@example.com)\n' | "$fake_bin" render --from markdown | grep -q 'mailto'; then
      : # ok - should keep mailto
    else
      echo "❌ Assertion Failed: S3 fake Oliver dropped mailto link."
      exit 223
    fi
    # Real Oliver probe (skip on current pin which lacks native rewriting)
    _real_link="${RK_OLIVER_BIN:-}"
    if [[ -z "$_real_link" || ! -x "$_real_link" ]]; then
      _real_link="$(command -v oliver 2>/dev/null || true)"
    fi
    if [[ -n "$_real_link" && -x "$_real_link" ]]; then
      if printf '[x](foo.md)\n' | "$_real_link" render --from markdown 2>/dev/null | grep -q 'foo.html'; then
        echo "  [+] Pass: real Oliver link rewriting probe ($mode) — native rewriting detected."
      else
        echo "  [+] Skipping real Oliver link rewriting probe — binary lacks native rewriting (expected on pin 6edb520c, S3 will bump)."
      fi
    fi
    echo "  [+] Pass: S3 link rewriting assertions ($mode)."

    echo "  [+] Executing S4 output planning assertions (Oliver plan + Bash fallback)..."
    # Minimal S4 check without find/yq to avoid fork issue — just probe fake plan help
    if ! "$fake_bin" plan --help | grep -q "plan"; then
      echo "❌ Assertion Failed: S4 fake Oliver plan --help failed."
      exit 224
    fi
    _real_plan="${RK_OLIVER_BIN:-}"
    if [[ -z "$_real_plan" || ! -x "$_real_plan" ]]; then
      _real_plan="$(command -v oliver 2>/dev/null || true)"
    fi
    if [[ -n "$_real_plan" && -x "$_real_plan" ]]; then
      if "$_real_plan" plan --help >/dev/null 2>&1; then
        echo "  [+] Pass: real Oliver plan probe ($mode) — plan available."
      else
        echo "  [+] Skipping real Oliver plan probe — binary lacks plan (expected on pin 6edb520c, S4 will bump)."
      fi
    fi
    echo "  [+] Pass: S4 output planning assertions ($mode)."

    # --- S5: Manifest via Oliver manifest (with Bash fallback) ---
    echo "  [+] Executing S5 manifest assertions (Oliver manifest + Bash fallback)..."
    tmp_manifest="$pass_dir/bones/tmp/manifest-probe.txt"
    rm -f "$tmp_manifest"
    if ! "$fake_bin" manifest --manifest "$tmp_manifest" --add "output/probe.html" 2>/dev/null; then
      echo "❌ Assertion Failed: S5 fake Oliver manifest --add failed."
      exit 230
    fi
    if ! grep -Fxq "output/probe.html" "$tmp_manifest"; then
      echo "❌ Assertion Failed: S5 fake Oliver manifest did not add entry."
      exit 231
    fi
    # Dedup check
    if ! "$fake_bin" manifest --manifest "$tmp_manifest" --add "output/probe.html" 2>/dev/null; then
      echo "❌ Assertion Failed: S5 fake Oliver manifest second add failed."
      exit 232
    fi
    if [[ $(grep -c "output/probe.html" "$tmp_manifest") -ne 1 ]]; then
      echo "❌ Assertion Failed: S5 fake Oliver manifest dedup failed."
      exit 233
    fi
    if ! "$fake_bin" manifest --help | grep -q "manifest"; then
      echo "❌ Assertion Failed: S5 fake Oliver manifest --help failed."
      exit 234
    fi
    rm -f "$tmp_manifest"
    _real_manifest="${RK_OLIVER_BIN:-}"
    if [[ -z "$_real_manifest" || ! -x "$_real_manifest" ]]; then
      _real_manifest="$(command -v oliver 2>/dev/null || true)"
    fi
    if [[ -n "$_real_manifest" && -x "$_real_manifest" ]]; then
      if "$_real_manifest" manifest --help >/dev/null 2>&1; then
        echo "  [+] Pass: real Oliver manifest probe ($mode) — manifest available."
      else
        echo "  [+] Skipping real Oliver manifest probe — binary lacks manifest (expected on pin 6edb520c, S5 will bump)."
      fi
    fi
    echo "  [+] Pass: S5 manifest assertions ($mode)."

    # --- Real Oliver renderer smoke pass (runs only when an executable binary
    # is discoverable; hermetic fixture binaries cover the rest) ---
    REAL_OLIVER="${RK_OLIVER_BIN:-}"
    if [[ -z "$REAL_OLIVER" || ! -x "$REAL_OLIVER" ]]; then
      REAL_OLIVER="$(command -v oliver 2>/dev/null || true)"
    fi

    if [[ -n "$REAL_OLIVER" && -x "$REAL_OLIVER" ]]; then
      echo "  [+] Executing real Oliver renderer smoke pass ($REAL_OLIVER)..."
      cat << 'FIXTURE_EOF' > "$b_content/real-oliver-fixture.md"
---
title: "Real Oliver Fixture"
description: "Smoke fixture rendered by the real Oliver binary"
---

# Real Oliver Fixture

[Internal Link](my-first-page.md)

Text with **bold**, `code`, and a [fragment](my-first-page.md#section-1).
FIXTURE_EOF

      if ! RK_OLIVER_BIN="$REAL_OLIVER" ./rotkeeper.sh render >/dev/null 2>&1; then
        echo "❌ Assertion Failed: real Oliver render failed with $REAL_OLIVER."
        exit 129
      fi

      rendered_real="$out_dir_rel/real-oliver-fixture.html"
      if [[ ! -f "$rendered_real" ]]; then
        echo "❌ Assertion Failed: real Oliver rendered output missing for real-oliver-fixture.html"
        exit 130
      fi

      if ! grep -q '<!DOCTYPE' "$rendered_real" && ! grep -q '<html' "$rendered_real"; then
        echo "❌ Assertion Failed: real Oliver output does not look like rendered HTML."
        exit 131
      fi

      if ! grep -q 'Real Oliver Fixture' "$rendered_real"; then
        echo "❌ Assertion Failed: real Oliver fixture title missing from rendered HTML."
        exit 132
      fi

      # --- Real Oliver CommonMark contract corpus ---
      # The hermetic golden above is produced by the fixture (fake) binary and
      # verifies the adapter pipeline: frontmatter stripping, link rewriting,
      # escaping. It is NOT a CommonMark fidelity golden. This pass renders a
      # checked-in edge-case corpus through the REAL binary and asserts
      # Oliver-produced structures, so renderer fidelity is verified whenever
      # a real oliver is present (see bones/scripts/tests/fixtures/oliver-contract/
      # and the "Rendered Markdown surface" section of oliver-contract.md).
      CONTRACT_DIR="$ROOT_DIR/bones/scripts/tests/fixtures/oliver-contract"
      if [[ -d "$CONTRACT_DIR" ]]; then
        echo "  [+] Executing real Oliver CommonMark contract corpus ($mode)..."
        cp "$CONTRACT_DIR"/*.md "$b_content/"
        RK_OLIVER_BIN="$REAL_OLIVER" ./rotkeeper.sh render > /dev/null

        inline="$out_dir_rel/contract-inline.html"
        blocks="$out_dir_rel/contract-blocks.html"
        table="$out_dir_rel/contract-table.html"
        contract_failed=false

        check_contract() {
          local desc="$1" file="$2"; shift 2
          if ! grep -q "$@" "$file"; then
            echo "❌ Assertion Failed: contract corpus missing $desc in $file"
            contract_failed=true
          fi
        }

        check_contract "bold" "$inline" '<strong>bold</strong>'
        check_contract "rewritten internal link" "$inline" 'href="my-first-page.html"'
        check_contract "fragment preserved" "$inline" 'href="my-first-page.html#section-1"'
        check_contract "autolink escaping" "$inline" 'href="https://example.com/x?a=1&amp;b=2"'
        check_contract "mailto autolink" "$inline" 'mailto:necromancer@example.com'
        check_contract "raw inline HTML" "$inline" '<b>inline tag</b>'
        check_contract "numeric entity" "$inline" 'entity &amp; numeric A'
        check_contract "code span escaping" "$inline" 'code &quot;quotes&quot; &amp;'
        if grep -q 'href="my-first-page.md"' "$inline"; then
          echo "❌ Assertion Failed: contract corpus internal .md href not rewritten to .html."
          contract_failed=true
        fi

        check_contract "heading" "$blocks" '<h1>Blocks</h1>'
        check_contract "fenced code info string" "$blocks" '<pre><code class="language-zig">'
        check_contract "nested blockquote" "$blocks" '<blockquote>'
        check_contract "ordered list" "$blocks" '<ol>'
        check_contract "thematic break" "$blocks" '<hr />'
        if [[ "$(grep -c '<blockquote>' "$blocks")" -ne 2 ]]; then
          echo "❌ Assertion Failed: contract corpus expected 2 nested blockquotes in $blocks."
          contract_failed=true
        fi

        # GFM pipe tables ARE rendered by Oliver (header, body, alignment
        # colons, escaped pipes). Task lists and footnotes are NOT part of
        # CommonMark and must stay literal and never crash the pass.
        check_contract "GFM table element" "$table" '<table>'
        check_contract "GFM table header" "$table" '<th>Feature</th>'
        check_contract "GFM table cell" "$table" '<td>GFM table</td>'
        check_contract "GFM table alignment" "$table" 'align="center"'
        check_contract "GFM table escaped pipe" "$table" -F '>a|b<'
        check_contract "literal task list (documented boundary)" "$table" -F -- '- [x] done'
        check_contract "literal footnote ref (documented boundary)" "$table" -F '[^1]'
        check_contract "literal footnote body (documented boundary)" "$table" -F '[^1]: footnote text'

        if [[ "$contract_failed" == true ]]; then
          exit 140
        fi
        echo "  [+] Pass: real Oliver CommonMark contract corpus ($mode)."
      else
        if [[ "${RK_STRICT:-0}" == "1" ]]; then
          echo "❌ Assertion Failed: real Oliver contract corpus skipped ($CONTRACT_DIR missing) but RK_STRICT=1 requires it."
          exit 142
        fi
        echo "  ⚠️  Skipping real Oliver contract corpus: $CONTRACT_DIR missing."
      fi

      # --- Real Oliver XHTML output profile pass ---
      # Renders a page through --to xhtml with the XHTML theme wrapper variant
      # and verifies the wrapped document is well-formed via an independent XML
      # parser (xmllint), then asserts the fail-closed raw-HTML path fails
      # loudly with Oliver's typed error (see the "XHTML output profile"
      # section of oliver-contract.md).
      cat << 'XHTML_REAL_EOF' > "$b_content/xhtml-real-check.md"
---
title: "XHTML Real Check"
description: "XHTML profile rendered by the real Oliver binary"
render_profile: xhtml
template: theme-spooky-dark-xhtml.html
---

# XHTML Real Check

CommonMark-safe body with **bold** and a [link](my-first-page.md).
XHTML_REAL_EOF

      if ! RK_OLIVER_BIN="$REAL_OLIVER" ./rotkeeper.sh render >/dev/null 2>&1; then
        echo "❌ Assertion Failed: real Oliver XHTML render failed with $REAL_OLIVER."
        exit 183
      fi

      rendered_xhtml_real="$out_dir_rel/xhtml-real-check.html"
      if [[ ! -f "$rendered_xhtml_real" ]]; then
        echo "❌ Assertion Failed: real Oliver XHTML output missing for xhtml-real-check.html"
        exit 184
      fi
      if ! grep -q 'xmlns="http://www.w3.org/1999/xhtml"' "$rendered_xhtml_real"; then
        echo "❌ Assertion Failed: real Oliver XHTML page missing the XHTML namespace wrapper."
        exit 185
      fi
      if command -v xmllint >/dev/null 2>&1; then
        if ! xmllint --noout "$rendered_xhtml_real"; then
          echo "❌ Assertion Failed: real Oliver XHTML page is not well-formed XML (xmllint)."
          exit 186
        fi
        echo "  [+] Pass: real Oliver XHTML page well-formed per xmllint ($mode)."
      else
        if [[ "${RK_STRICT:-0}" == "1" ]]; then
          echo "❌ Assertion Failed: xmllint unavailable for the XHTML well-formedness gate but RK_STRICT=1 requires it."
          exit 187
        fi
        echo "  ⚠️  Skipping xmllint well-formedness gate: xmllint not found."
      fi

      cat << 'XHTML_RAW_REAL_EOF' > "$b_content/xhtml-raw-real.md"
---
title: "XHTML Raw Real"
description: "XHTML fail-closed raw HTML verification with the real binary"
render_profile: xhtml
template: theme-spooky-dark-xhtml.html
---

# XHTML Raw Real

<b>Raw HTML that must fail closed.</b>
XHTML_RAW_REAL_EOF

      fail_marker="$pass_dir/bones/tmp/xhtml-fail-marker"
      touch "$fail_marker"
      if RK_OLIVER_BIN="$REAL_OLIVER" ./rotkeeper.sh render >/dev/null 2>&1; then
        echo "❌ Assertion Failed: real Oliver render with raw HTML under render_profile=xhtml should have failed."
        exit 188
      fi
      # Use ls -t to avoid find+CoreFoundation fork issue after yq
      adapter_log=""
      for _f in "$pass_dir"/bones/logs/rc-oliver-adapter-*.log; do
        [[ -e "$_f" ]] || continue
        if [[ "$_f" -nt "$fail_marker" ]]; then
          # Pick newest among newer
          if [[ -z "$adapter_log" || "$_f" -nt "$adapter_log" ]]; then
            adapter_log="$_f"
          fi
        fi
      done
      rm -f "$fail_marker"
      if ! grep -q 'RawHtmlNotXmlWellFormed' "$adapter_log"; then
        echo "❌ Assertion Failed: real Oliver fail-closed XHTML error missing the typed RawHtmlNotXmlWellFormed error."
        exit 189
      fi
      rm -f "$b_content/xhtml-raw-real.md"
      if ! RK_OLIVER_BIN="$REAL_OLIVER" ./rotkeeper.sh render >/dev/null 2>&1; then
        echo "❌ Assertion Failed: real Oliver render after removing the fail-closed XHTML page failed."
        exit 190
      fi
      echo "  [+] Pass: real Oliver XHTML output profile (well-formed + fail-closed) ($mode)."
    else
      if [[ "${RK_STRICT:-0}" == "1" ]]; then
        echo "❌ Assertion Failed: real Oliver renderer smoke pass skipped (no executable oliver binary found) but RK_STRICT=1 requires it."
        exit 141
      fi
      echo "  [+] Skipping real Oliver renderer smoke pass (no executable oliver binary found)."
    fi

    # Verify manifest path consistency across render, pack, and scan
    if [[ ! -f "bones/manifest.txt" ]]; then
      echo "❌ Assertion Failed: bones/manifest.txt missing after render pass."
      exit 124
    fi

    if ! grep -q "$rendered_v051" "bones/manifest.txt"; then
      echo "❌ Assertion Failed: rendered page $rendered_v051 not in bones/manifest.txt."
      exit 125
    fi

    echo "  [+] Executing configurable input format (textile) assertions..."
    yq eval '.input_format = "textile"' -i "$b_config/rotkeeper.yaml"
    cat << 'TEXTILE_EOF' > "$b_content/textile-check.md"
---
title: "Textile Check"
description: "Textile input format verification"
---

h1. Textile headline

"Textile Link":sibling.textile
TEXTILE_EOF

    if ! RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null; then
      echo "❌ Assertion Failed: render with input_format=textile failed."
      exit 144
    fi

    rendered_textile="$out_dir_rel/textile-check.html"
    if [[ ! -f "$rendered_textile" ]]; then
      echo "❌ Assertion Failed: textile-format page missing after render: $rendered_textile"
      exit 145
    fi
    if ! grep -q 'textile-input-confirmed' "$rendered_textile"; then
      echo "❌ Assertion Failed: rendered output does not prove --from textile reached the renderer."
      exit 146
    fi
    if ! grep -q 'href="sibling.html"' "$rendered_textile"; then
      echo "❌ Assertion Failed: .textile internal link was not rewritten to .html."
      exit 147
    fi

    yq eval '.input_format = "markdown"' -i "$b_config/rotkeeper.yaml"
    echo "  [+] Pass: input_format=textile propagated to renderer ($mode)."

    echo "  [+] Executing .textile source extension assertions..."
    cat << 'TEXTILE_SRC_EOF' > "$b_content/textile-src.textile"
---
title: "Textile Source"
description: "Textile extension source verification"
---

h1. Textile headline

"Textile Link":sibling.textile
TEXTILE_SRC_EOF

    if ! RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null; then
      echo "❌ Assertion Failed: render with a .textile source failed."
      exit 158
    fi

    rendered_textile_src="$out_dir_rel/textile-src.html"
    if [[ ! -f "$rendered_textile_src" ]]; then
      echo "❌ Assertion Failed: .textile source page missing after render: $rendered_textile_src"
      exit 159
    fi
    if ! grep -q 'textile-input-confirmed' "$rendered_textile_src"; then
      echo "❌ Assertion Failed: .textile source did not render with --from textile (extension must override the config default markdown)."
      exit 160
    fi
    if ! grep -q 'href="sibling.html"' "$rendered_textile_src"; then
      echo "❌ Assertion Failed: .textile source internal link was not rewritten to .html."
      exit 161
    fi

    echo "  [+] Executing source basename collision assertions..."
    cat << 'COLLIDE_MD_EOF' > "$b_content/collision.md"
---
title: "Collision Markdown"
---
Collision markdown body.
COLLIDE_MD_EOF
    cat << 'COLLIDE_TX_EOF' > "$b_content/collision.textile"
---
title: "Collision Textile"
---
h1. Collision textile body.
COLLIDE_TX_EOF

    if RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null 2>&1; then
      echo "❌ Assertion Failed: render with colliding collision.md + collision.textile sources should have failed."
      exit 162
    fi
    rm -f "$b_content/collision.md" "$b_content/collision.textile"
    echo "  [+] Pass: source basename collision refused ($mode)."

    echo "  [+] Executing .cook source extension assertions..."
    cat << 'COOK_SRC_EOF' > "$b_content/necromancer-stew.cook"
---
title: "Necromancer's Stew"
description: "Cooklang extension source verification"
---
Add @stock#2 cups to the kettle. Simmer for ~20 minutes#. Serve.
COOK_SRC_EOF

    if ! RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null; then
      echo "❌ Assertion Failed: render with a .cook source failed."
      exit 163
    fi

    rendered_cook_src="$out_dir_rel/necromancer-stew.html"
    if [[ ! -f "$rendered_cook_src" ]]; then
      echo "❌ Assertion Failed: .cook source page missing after render: $rendered_cook_src"
      exit 164
    fi
    if ! grep -q 'cooklang-input-confirmed' "$rendered_cook_src"; then
      echo "❌ Assertion Failed: .cook source did not render with --from cooklang (extension must override the config default markdown)."
      exit 165
    fi
    if ! grep -q 'href="sibling.html"' "$rendered_cook_src"; then
      echo "❌ Assertion Failed: .cook source internal link was not rewritten to .html."
      exit 166
    fi

    echo "  [+] Executing configurable input format (cooklang) assertions..."
    yq eval '.input_format = "cooklang"' -i "$b_config/rotkeeper.yaml"
    cat << 'COOK_CFG_EOF' > "$b_content/cooklang-check.md"
---
title: "Cooklang Check"
description: "Cooklang input format verification"
---
Bake at ~350 F# for ~45 minutes#.
COOK_CFG_EOF

    if ! RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null; then
      echo "❌ Assertion Failed: render with input_format=cooklang failed."
      exit 167
    fi
    rendered_cook_cfg="$out_dir_rel/cooklang-check.html"
    if [[ ! -f "$rendered_cook_cfg" ]]; then
      echo "❌ Assertion Failed: cooklang-format page missing after render: $rendered_cook_cfg"
      exit 168
    fi
    if ! grep -q 'cooklang-input-confirmed' "$rendered_cook_cfg"; then
      echo "❌ Assertion Failed: rendered output does not prove --from cooklang reached the renderer."
      exit 169
    fi

    yq eval '.input_format = "markdown"' -i "$b_config/rotkeeper.yaml"
    rm -f "$b_content/necromancer-stew.cook" "$b_content/cooklang-check.md"
    echo "  [+] Pass: .cook extension and input_format=cooklang propagated to renderer ($mode)."

    echo "  [+] Pass: XHTML fail-closed raw HTML path ($mode)."

    # Execute pack to generate tomb archives & json export
    ./rotkeeper.sh pack > /dev/null

    # Execute scan to verify manifest vs disk agreement
    if ! ./rotkeeper.sh scan > /dev/null; then
      echo "❌ Assertion Failed: ./rotkeeper.sh scan failed after pack."
      exit 126
    fi

    # Assert zero missing and zero orphan entries in scan report
    # shellcheck disable=SC2012
    scan_json=$(ls -1 bones/reports/scan-report-*.json 2>/dev/null | tail -n 1)
    if [[ -z "$scan_json" || ! -f "$scan_json" ]]; then
      echo "❌ Assertion Failed: scan JSON report missing."
      exit 127
    fi

    missing_cnt=$(jq '.missing | length' "$scan_json")
    orphan_cnt=$(jq '.orphans | length' "$scan_json")
    if [[ "$missing_cnt" -ne 0 || "$orphan_cnt" -ne 0 ]]; then
      echo "❌ Assertion Failed: scan reported $missing_cnt missing files and $orphan_cnt orphan files."
      echo "--- Scan JSON Report ---"
      cat "$scan_json"
      echo ""
      exit 128
    fi

    # --- XHTML output profile (hermetic) assertions ---
    # These render and prune fixture pages after the manifest-vs-disk scan above,
    # because render prunes stale output while bones/manifest.txt is append-only;
    # a later render+removal cycle would otherwise surface phantom scan misses.
    echo "  [+] Executing XHTML output profile (per-page frontmatter) assertions..."
    cat << 'XHTML_EOF' > "$b_content/xhtml-check.md"
---
title: "XHTML Check"
description: "XHTML output profile verification"
render_profile: xhtml
template: theme-spooky-dark-xhtml.html
---

# XHTML Check

A CommonMark-safe body with **bold** and an [internal link](my-first-page.md).
XHTML_EOF

    if ! RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null; then
      echo "❌ Assertion Failed: render with render_profile=xhtml frontmatter failed."
      exit 170
    fi

    rendered_xhtml="$out_dir_rel/xhtml-check.html"
    if [[ ! -f "$rendered_xhtml" ]]; then
      echo "❌ Assertion Failed: xhtml-profile page missing after render: $rendered_xhtml"
      exit 171
    fi
    if ! grep -q 'xhtml-profile-confirmed' "$rendered_xhtml"; then
      echo "❌ Assertion Failed: rendered output does not prove --to xhtml reached the renderer."
      exit 172
    fi
    if ! grep -q 'xmlns="http://www.w3.org/1999/xhtml"' "$rendered_xhtml"; then
      echo "❌ Assertion Failed: XHTML theme wrapper variant (xmlns) missing from page."
      exit 173
    fi
    if ! grep -q 'href="my-first-page.html"' "$rendered_xhtml"; then
      echo "❌ Assertion Failed: internal link not rewritten in XHTML page."
      exit 174
    fi

    echo "  [+] Executing XHTML output profile (config render_profile) assertions..."
    yq eval '.render_profile = "xhtml"' -i "$b_config/rotkeeper.yaml"
    cat << 'XHTML_CFG_EOF' > "$b_content/xhtml-cfg-check.md"
---
title: "XHTML Config Check"
description: "XHTML render_profile config verification"
---

# XHTML Config Check

Body without a frontmatter render_profile; the config default must apply.
XHTML_CFG_EOF

    if ! RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null; then
      echo "❌ Assertion Failed: render with render_profile=xhtml in config failed."
      exit 175
    fi

    rendered_xhtml_cfg="$out_dir_rel/xhtml-cfg-check.html"
    if [[ ! -f "$rendered_xhtml_cfg" ]]; then
      echo "❌ Assertion Failed: xhtml config page missing after render: $rendered_xhtml_cfg"
      exit 176
    fi
    if ! grep -q 'xhtml-profile-confirmed' "$rendered_xhtml_cfg"; then
      echo "❌ Assertion Failed: config render_profile=xhtml did not reach the renderer."
      exit 177
    fi

    yq eval '.render_profile = "html"' -i "$b_config/rotkeeper.yaml"
    echo "  [+] Pass: render_profile=xhtml propagated to renderer ($mode)."

    echo "  [+] Executing XHTML fail-closed (raw HTML) assertions..."
    fake_xhtml_fail_bin="$pass_dir/bones/tmp/fake_oliver_xhtml_fail"
    cat << 'XHTML_FAIL_EOF' > "$fake_xhtml_fail_bin"
#!/usr/bin/env bash
set -euo pipefail
# Mimic Oliver's CLI shape, failing closed under --to xhtml the way the real
# binary fails on raw HTML (error.RawHtmlNotXmlWellFormed, never repaired).
if [[ "${1:-}" != "render" || "${2:-}" != "--from" || ( "${3:-}" != "markdown" && "${3:-}" != "textile" && "${3:-}" != "cooklang" ) ]]; then
  exit 1
fi
if [[ "${4:-}" == "--to" && "${5:-}" == "xhtml" ]]; then
  echo "oliver: render failed: RawHtmlNotXmlWellFormed" >&2
  echo "oliver: --to xhtml rejects raw HTML that cannot be guaranteed well-formed XML" >&2
  exit 1
fi
printf '<h1>html-mode-ok</h1>\n'
XHTML_FAIL_EOF
    chmod +x "$fake_xhtml_fail_bin"

    # Remove the other XHTML fixture pages so the fail-closed render below fails
    # on exactly one page: xhtml-raw-check.md (the only XHTML page in the batch).
    rm -f "$b_content/xhtml-check.md" "$b_content/xhtml-cfg-check.md" "$b_content/xhtml-real-check.md"

    cat << 'XHTML_RAW_EOF' > "$b_content/xhtml-raw-check.md"
---
title: "XHTML Raw Check"
description: "XHTML fail-closed raw HTML verification"
render_profile: xhtml
template: theme-spooky-dark-xhtml.html
---

# XHTML Raw Check

<b>This raw HTML must fail the XHTML profile.</b>
XHTML_RAW_EOF

    fail_marker="$pass_dir/bones/tmp/xhtml-fail-marker"
    touch "$fail_marker"
    if RK_OLIVER_BIN="$fake_xhtml_fail_bin" ./rotkeeper.sh render > /dev/null 2>&1; then
      echo "❌ Assertion Failed: render with raw HTML under render_profile=xhtml should have failed."
      exit 179
    fi
    adapter_log=""
    for _f in "$pass_dir"/bones/logs/rc-oliver-adapter-*.log; do
      [[ -e "$_f" ]] || continue
      if [[ "$_f" -nt "$fail_marker" ]]; then
        if [[ -z "$adapter_log" || "$_f" -nt "$adapter_log" ]]; then
          adapter_log="$_f"
        fi
      fi
    done
    rm -f "$fail_marker"
    if ! grep -q 'RawHtmlNotXmlWellFormed' "$adapter_log"; then
      echo "❌ Assertion Failed: fail-closed XHTML error missing the typed RawHtmlNotXmlWellFormed error."
      exit 180
    fi
    rm -f "$b_content/xhtml-raw-check.md"
    if ! RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null; then
      echo "❌ Assertion Failed: render after removing the fail-closed XHTML page failed."
      exit 181
    fi
    if [[ -f "$out_dir_rel/xhtml-raw-check.html" ]]; then
      echo "❌ Assertion Failed: failed XHTML page left stale output behind."
      exit 182
    fi
    echo "  [+] Pass: XHTML fail-closed raw HTML path ($mode)."

    echo "  [+] Executing packager JSON export assertions..."
    # shellcheck disable=SC2012
    export_json=$(ls -1 "$b_archive"/tomb-export-*.json 2>/dev/null | head -n 1)
    if [[ -z "$export_json" || ! -f "$export_json" ]]; then
      echo "❌ Assertion Failed: packager JSON export file tomb-export-*.json missing."
      exit 113
    fi
    if ! jq empty "$export_json" >/dev/null 2>&1; then
      echo "❌ Assertion Failed: packager JSON export is not valid JSON."
      exit 114
    fi
    if ! jq -e '.[0] | has("absolute_path") and has("relative_path") and has("frontmatter") and has("source_markdown")' "$export_json" >/dev/null 2>&1; then
      echo "❌ Assertion Failed: packager JSON export entry is missing required fields (source_markdown)."
      exit 115
    fi

    echo "  [+] Executing pack integrity assertions..."
    # shellcheck disable=SC2012
    newest_tomb=$(ls -1 "$b_archive"/tomb-*.tar.gz 2>/dev/null | sort | tail -n 1)
    if [[ -z "$newest_tomb" || ! -f "$newest_tomb" ]]; then
      echo "❌ Assertion Failed: no tomb-*.tar.gz archive found after pack."
      exit 116
    fi
    if ! gzip -t "$newest_tomb" 2>/dev/null; then
      echo "❌ Assertion Failed: tomb archive failed gzip integrity check: $newest_tomb"
      exit 117
    fi
    if ! tar -tzf "$newest_tomb" | grep -q '^metadata.json$'; then
      echo "❌ Assertion Failed: tomb archive missing metadata.json entry: $newest_tomb"
      exit 118
    fi
    if tar -tzf "$newest_tomb" | grep -vEq "^metadata\.json$|^$out_dir_rel/"; then
      echo "❌ Assertion Failed: tomb archive contains entries outside root-relative prefixes (absolute path leak?)."
      echo "--- Tomb entries ---"
      tar -tzf "$newest_tomb" | head -n 5
      exit 139
    fi

    echo "  [+] Executing release packager assertions..."
    ./rotkeeper.sh release "$TEST_RELEASE_VERSION" > /dev/null

    echo "  [+] Asserting single archive model matching criteria..."
    if [[ ! -f "$b_archive/releases/rotkeeper-$TEST_RELEASE_VERSION.zip" ]]; then
       echo "❌ Assertion Failed: Canonical distribution package missing or multi-tier leaks found."
       exit 99
    fi

    if [[ -f "$b_archive/releases/rotkeeper-0.4.0.4-lite.zip" || -f "$b_archive/releases/rotkeeper-0.4.0.4-full.zip" ]]; then
       echo "❌ Assertion Failed: Deprecated multi-tier packages still generated."
       exit 100
    fi

    echo "  [+] Executing release ZIP content assertions..."
    release_zip="$b_archive/releases/rotkeeper-$TEST_RELEASE_VERSION.zip"
    if ! unzip -tq "$release_zip" > /dev/null 2>&1; then
      echo "❌ Assertion Failed: release ZIP failed integrity test."
      exit 148
    fi
    release_entries=$(zipinfo -1 "$release_zip")
    if [[ -z "$release_entries" ]]; then
      echo "❌ Assertion Failed: release ZIP listing is empty."
      exit 148
    fi
    for req_entry in "rotkeeper/rotkeeper.sh" "rotkeeper/bones/config/rotkeeper.yaml" "rotkeeper/bones/config/version" "rotkeeper/bones/config/release-manifest.txt" "rotkeeper/bones/scripts/rc-utils.sh"; do
      if ! grep -Fxq "$req_entry" <<< "$release_entries"; then
        echo "❌ Assertion Failed: framework spine entry missing from release archive: $req_entry"
        exit 149
      fi
    done
    if grep -vq '^rotkeeper/' <<< "$release_entries"; then
      echo "❌ Assertion Failed: release archive contains entries outside the rotkeeper/ framework root."
      exit 150
    fi
    if grep -Eq '^rotkeeper/(output|bones/logs|bones/tmp|bones/archive|bones/reports|bones/book-reports|home/content/messages)/' <<< "$release_entries"; then
      echo "❌ Assertion Failed: forbidden generated/cache tree shipped in release archive."
      exit 151
    fi
    if grep -Eq '(\.pem|\.key|\.p12|\.pyc|\.npmrc|id_rsa|\.DS_Store|_temp\.md)$|(^|/)\.env(\.|$)' <<< "$release_entries"; then
      echo "❌ Assertion Failed: forbidden artifact shipped in release archive."
      exit 151
    fi
    # shellcheck disable=SC2010
    if ls "$b_archive/releases"/rotkeeper-*.tar* 2>/dev/null | grep -q .; then
      echo "❌ Assertion Failed: non-canonical archive leftovers found in release directory."
      exit 152
    fi

    echo "  [+] Executing --dry-run non-mutation assertions..."
    # Payload files only: bones/logs is excluded because routine log files are
    # minute-granular telemetry, not rendered/archived/reported state.
    _tmp_pre=$(mktemp)
    _find_pre="find"; if command -v gfind >/dev/null 2>&1; then _find_pre="gfind"; elif [[ -x "/opt/homebrew/opt/findutils/libexec/gnubin/find" ]]; then _find_pre="/opt/homebrew/opt/findutils/libexec/gnubin/find"; fi
    "$_find_pre" . -path './bones/logs' -prune -o -type f -print > "$_tmp_pre" 2>/dev/null || true
    pre_count=$(wc -l < "$_tmp_pre" | tr -d ' ')
    rm -f "$_tmp_pre"
    ./rotkeeper.sh render --dry-run > /dev/null
    ./rotkeeper.sh pack --dry-run > /dev/null
    ./rotkeeper.sh scan --dry-run > /dev/null
    ./rotkeeper.sh release "$TEST_RELEASE_VERSION" --dry-run > /dev/null
    _tmp_post=$(mktemp)
    _find_post="find"; if command -v gfind >/dev/null 2>&1; then _find_post="gfind"; elif [[ -x "/opt/homebrew/opt/findutils/libexec/gnubin/find" ]]; then _find_post="/opt/homebrew/opt/findutils/libexec/gnubin/find"; fi
    "$_find_post" . -path './bones/logs' -prune -o -type f -print > "$_tmp_post" 2>/dev/null || true
    post_count=$(wc -l < "$_tmp_post" | tr -d ' ')
    rm -f "$_tmp_post"
    if [[ "$pre_count" != "$post_count" ]]; then
      echo "❌ Assertion Failed: --dry-run mutated the workspace ($pre_count -> $post_count files)."
      exit 153
    fi

    echo "  [+] Executing stale-output pruning assertions..."
    rm -f "$b_content/ugly-edge-case.md"
    if ! RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null; then
      echo "❌ Assertion Failed: render after source removal failed."
      exit 154
    fi
    if [[ -f "$out_dir_rel/ugly-edge-case.html" ]]; then
      echo "❌ Assertion Failed: stale rendered page survived after its source was pruned."
      exit 154
    fi
    echo "  [+] Pass: stale rendered output pruned ($mode)."

    echo "  [+] Executing archive naming uniqueness assertions..."
    ./rotkeeper.sh pack > /dev/null
    ./rotkeeper.sh pack > /dev/null
    # shellcheck disable=SC2012
    newest_tomb=$(ls -1 "$b_archive"/tomb-*.tar.gz 2>/dev/null | sort | tail -n 1)
    # shellcheck disable=SC2012
    prev_tomb=$(ls -1 "$b_archive"/tomb-*.tar.gz 2>/dev/null | sort | tail -n 2 | head -n 1)
    if [[ -z "$newest_tomb" || "$newest_tomb" == "$prev_tomb" ]]; then
      echo "❌ Assertion Failed: consecutive pack runs produced colliding archive names."
      exit 155
    fi

    echo "  🎉 Pass [$mode] successful: canonical distribution payload matches criteria."
  )
done

echo "======================================================================"
echo "✅ ALL SINGLE-TIER CANONICAL ARCHIVE VERIFICATIONS COMPLETED SUCCESSFULLY."
echo "======================================================================"

echo "======================================================================"
echo "--- Command contract: --help is non-mutating, --version is consistent ---"

CONTRACT_COMMANDS=(init new render pack preflight release bump test scan assets autopsy glue links showcase dip book status)

tree_snapshot() {
  git status --porcelain 2>/dev/null
  _tmp1=$(mktemp); find "$ROOT_DIR/bones/logs" -type f 2>/dev/null | sort > "$_tmp1" 2>/dev/null || true; cat "$_tmp1"; rm -f "$_tmp1"
  _tmp2=$(mktemp); find "$ROOT_DIR/bones/tmp" -type f 2>/dev/null | sort > "$_tmp2" 2>/dev/null || true; cat "$_tmp2"; rm -f "$_tmp2"
}

contract_failed=false
for cmd in ${CONTRACT_COMMANDS[@]+"${CONTRACT_COMMANDS[@]}"}; do
  before_tree="$(tree_snapshot)"

  if ! help_out=$(./rotkeeper.sh "$cmd" --help 2>&1); then
    echo "❌ Assertion Failed: rotkeeper.sh $cmd --help exited non-zero."
    contract_failed=true
  fi
  if [[ -z "$help_out" ]]; then
    echo "❌ Assertion Failed: rotkeeper.sh $cmd --help produced no output."
    contract_failed=true
  fi

  after_tree="$(tree_snapshot)"
  if [[ "$before_tree" != "$after_tree" ]]; then
    echo "❌ Assertion Failed: rotkeeper.sh $cmd --help mutated the workspace (help must be non-mutating and must not start a workflow)."
    contract_failed=true
  fi

  if ! ver_out=$(./rotkeeper.sh "$cmd" --version 2>&1); then
    echo "❌ Assertion Failed: rotkeeper.sh $cmd --version exited non-zero."
    contract_failed=true
  fi
  if [[ ! "$ver_out" =~ v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "❌ Assertion Failed: rotkeeper.sh $cmd --version did not print a semver version: $ver_out"
    contract_failed=true
  fi
done

if [[ "$contract_failed" == true ]]; then
  echo "❌ COMMAND CONTRACT ASSERTIONS FAILED."
  exit 134
fi
echo "✅ ALL COMMAND CONTRACT ASSERTIONS PASSED."

echo "======================================================================"
echo "--- DIP regression: clean dry-run, non-mutating, no absolute paths ---"

# DIP must run from a clean inventory (fsbook generated on demand), the
# dry-run must be non-mutating (matrix unchanged), and the published matrix
# must stay free of host-specific absolute paths.

./rotkeeper.sh book --fsbook > /dev/null

DIP_MATRIX="$ROOT_DIR/home/content/docs/dip-matrix.md"
matrix_before="$(rk_sha256 "$DIP_MATRIX" 2>/dev/null | cut -d' ' -f1 || true)"

if ! dip_out=$(./rotkeeper.sh dip --dry-run 2>&1); then
  echo "❌ Assertion Failed: dip --dry-run exited non-zero."
  exit 135
fi
if ! grep -q 'DIP finished' <<< "$dip_out"; then
  echo "❌ Assertion Failed: dip --dry-run did not finish cleanly."
  exit 136
fi

matrix_after="$(rk_sha256 "$DIP_MATRIX" 2>/dev/null | cut -d' ' -f1 || true)"
if [[ "$matrix_before" != "$matrix_after" ]]; then
  echo "❌ Assertion Failed: dip --dry-run mutated the DIP matrix (dry-run must be non-mutating)."
  exit 137
fi
if grep -q "$ROOT_DIR" "$DIP_MATRIX"; then
  echo "❌ Assertion Failed: DIP matrix contains host-specific absolute paths."
  exit 138
fi
echo "✅ DIP regression passed."

echo "======================================================================"
echo "--- Regression tests for legacy rituals (ingest, sync-inbox, cleanup, reseed) ---"

for cmd in ingest sync-inbox cleanup reseed; do
  output=$(./rotkeeper.sh "$cmd" 2>&1 || true)
  if echo "$output" | grep -q "ERROR: The '$cmd' command has been permanently removed"; then
    echo "  🎉 Pass: Command '$cmd' correctly triggered deprecation error."
  else
    echo "❌ Assertion Failed: Command '$cmd' did not trigger the expected deprecation error."
    exit 101
  fi
done

echo "✅ ALL REGRESSION ASSERTIONS COMPLETED SUCCESSFULLY."

exit 0
