#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'EOF'
rc-showcase.sh — Generate showcase content for every HTML template

Usage: rotkeeper.sh showcase [options]

Options:
  --dry-run        Preview generated showcase pages without writing
  --verbose        Show detailed logs
  --help, -h       Show this help message
EOF
  exit 0
}
IFS=$'\n\t'
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-showcase.sh
#  Purpose : Auto-scaffolds test pages for all HTML templates
# ============================================================

set -euo pipefail


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-showcase" "$@"

main() {
  log "INFO" "Initializing Gallery of the Damned showcase scanner..."

  local showcase_dir="$CONTENT_DIR/showcase"
  mkdir -p "$showcase_dir"
  log "INFO" "Ensured showcase directory exists: $showcase_dir"

  if [[ ! -d "$TEMPLATE_DIR" ]]; then
    log "ERROR" "Template directory not found: $TEMPLATE_DIR"
    exit 1
  fi

  local count=0
  for template_file in "$TEMPLATE_DIR"/*.html; do
    if [[ ! -f "$template_file" ]]; then
      continue
    fi

    local template_name=$(basename "$template_file")
    local theme_name="${template_name%.html}"
    theme_name="${theme_name#theme-}"

    local target_file="$showcase_dir/showcase-${theme_name}.md"

    log "INFO" "Scaffolding showcase page for template: $template_name -> $target_file"
    log "INFO" "Auditing template: $(basename "$template_file")"

    mapfile -t found_vars < <(grep -oE '\$[a-zA-Z_]+\$' "$template_file" | tr -d '$' | sort -u)

    local frontmatter="---
title: \"Showcase: $theme_name\"
slug: \"showcase-${theme_name}\"
template: \"$template_name\""

    for var in ${found_vars[@]+"${found_vars[@]}"}; do
      if [[ "$var" == "title" || "$var" == "slug" || "$var" == "template" || "$var" == "body" || "$var" == "endif" || "$var" == "date" || "$var" == "palette" || "$var" == "assets_root" ]]; then
        continue
      fi

      if [[ "$var" == "description" ]]; then
        if (( count % 2 == 0 )); then
          frontmatter+=$'\n'"description: \"Programmatic description for $theme_name\""
        fi
        continue
      fi

      frontmatter+=$'\n'"$var: \"Dummy value for $var\""
    done
    frontmatter+=$'\n'"---"

    if [[ "$DRY_RUN" == true ]]; then
      log "DRY-RUN" "Would scaffold showcase page: $target_file"
      count=$((count + 1))
      continue
    fi

    echo "$frontmatter" > "$target_file"

    cat << MD_EOF >> "$target_file"

# Heading 1
Through a terminal-driven, proactive embalming approach we can remain tomb-focused and artifact-directed, innovate and be an offline-first necropolis which facilitates static bash-readiness.

## Heading 2
Transforming turnkey phylacteries to dead-code 24/365 paradigms with benchmark archival channels implementing viral bash-rituals and flat-file action-items.

### Heading 3
While we take that action item strictly off-line and raise a fatal \`trap_err\` and remember to touch base as you think about the markdown fences outside of the crypt.

#### Heading 4
And seize B2B (Bash-to-Bone) orchestrators and re-envisioneer necromantic partnerships that evolve zero-hydration initiatives delivering synergistic dead-drops.

##### Heading 5
To incentivize CI/CD deliverables that leverage Oliver rituals to synergize bash-and-bone dropzones while facilitating one-to-one shell-scripts.

###### Heading 6
With revolutionary Frankenstein stitching that deliver viral payloads and grow decentralized supply-chains that expedite seamless embalming.

---

**Bold Text**: Transform back-end shell dependencies through a terminal-driven, proactive embalming approach we can remain tomb-focused and artifact-directed.

*Italic Text*: Innovate and be an offline-first necropolis which facilitates static bash-readiness transforming turnkey phylacteries to dead-code 24/365 paradigms.

> Blockquote:
> With benchmark archival channels implementing viral bash-rituals and flat-file action-items while we take that action item strictly off-line and raise a fatal \`trap_err\`.
>
> And remember to touch base as you think about the markdown fences outside of the crypt and seize B2B (Bash-to-Bone) orchestrators.

---

### Unordered List
* Re-envisioneer necromantic partnerships
* Evolve zero-hydration initiatives delivering synergistic dead-drops
* Incentivize CI/CD deliverables that leverage Oliver rituals

### Ordered List
1. Synergize bash-and-bone dropzones
2. Facilitating one-to-one shell-scripts with revolutionary Frankenstein stitching
3. Deliver viral payloads

---

### Code Block
\`\`\`bash
echo "Transforming turnkey phylacteries to dead-code 24/365 paradigms."
echo "With benchmark archival channels implementing viral bash-rituals."
\`\`\`

### Table
| Feature | Status | Impact |
|---|---|---|
| Terminal-driven | Active | Proactive embalming |
| Offline-first | Enabled | Static bash-readiness |
| B2B Orchestrators | Seized | Zero-hydration initiatives |

---

## Stress Testing

### Nested Blockquotes & Fences

> Level 1 blockquote
>
> > Level 2 blockquote
> >
> > \`\`\`bash
> > echo "Nested fence!"
> > \`\`\`
> >
> > > Level 3 blockquote

### Side-by-Side Content Overflows

#### Deeply Nested Lists
* Level 1
  * Level 2
    * Level 3
      * Level 4

#### Massive Technical Table

| Col 1 | Col 2 | Col 3 | Col 4 | Col 5 | Col 6 |
|---|---|---|---|---|---|
| A very long string that might cause overflow | Data | Data | Data | Data | Data |
| Data | A very long string that might cause overflow | Data | Data | Data | Data |

MD_EOF

    # Validate template is parseable by Oliver adapter (no external renderer dependency).
    # If RK_OLIVER_BIN is available and executable, confirm the template file is
    # non-empty and syntactically sane by checking it can be read by yq / gawk.
    # This is a lightweight structural probe — full rendering is handled by rc-render.sh.
    OLIVER_BIN="${RK_OLIVER_BIN:-$(command -v oliver 2>/dev/null || true)}"
    if [[ -n "$OLIVER_BIN" && -x "$OLIVER_BIN" ]]; then
      if [[ ! -s "$template_file" ]]; then
        log "ERROR" "Template $(basename "$template_file") is empty or missing — Oliver cannot render against it."
        trap_err $LINENO
      else
        log "INFO" "Template $(basename "$template_file") passed Oliver structural check (non-empty, readable)."
      fi
    else
      log "WARN" "RK_OLIVER_BIN is unset or not executable; skipping live template validation for $(basename "$template_file"). Set RK_OLIVER_BIN to enable."
    fi

    count=$((count + 1))
  done

  # Generate gallery index (source + output) — keeps it static, mortuary-cozy
  local gallery_src="$showcase_dir/index.md"
  local gallery_out="$OUTPUT_DIR/showcase/index.html"
  local gallery_count=$count

  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would generate gallery index: $gallery_src and $gallery_out ($gallery_count themes)"
  else
    # Source gallery (markdown) — will be rendered to output/showcase/index.html on next render
    # Use hand-written CSS grid via raw HTML (Oliver passes raw HTML through for html profile)
    {
      echo "---"
      echo "title: \"Theme Gallery — $gallery_count themes\""
      echo "template: \"rotkeeper-doc.html\""
      echo "description: \"Preview gallery comparing every theme side by side\""
      echo "---"
      echo ""
      echo "# Theme Gallery"
      echo ""
      echo "Preview every theme through the same content. Each card links to its full showcase page."
      echo ""
      echo "<div style=\"display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 1.2rem; margin: 1.5rem 0;\">"
      for tmpl in "$TEMPLATE_DIR"/*.html; do
        [[ -f "$tmpl" ]] || continue
        local tname
        tname=$(basename "$tmpl")
        local theme="${tname%.html}"
        theme="${theme#theme-}"
        # For theme-*.html, show theme name; for others, show full basename without .html
        local display="$tname"
        if [[ "$tname" == theme-*.html ]]; then
          display="$theme"
        else
          display="${tname%.html}"
        fi
        local swatch="#2a2a2a"
        case "$theme" in
          brutal) swatch="#111" ;;
          dark) swatch="#1a1a2e" ;;
          kawaii) swatch="#ffccf5" ;;
          light) swatch="#fafafa" ;;
          overgrown) swatch="#1e3a1e" ;;
          phosphor) swatch="#0a0f0a" ;;
          spooky-dark) swatch="#0f0f0f" ;;
          spooky-light) swatch="#f5f0eb" ;;
          spooky) swatch="#1a0f0f" ;;
          textpattern) swatch="#ffffcc" ;;
          *) swatch="#2a2a2a" ;;
        esac
        # Use showcase page name: showcase-<theme>.html (from earlier loop)
        local showcase_page="showcase-${theme}.html"
        # For non-theme templates like rotkeeper-blog.html, showcase page is showcase-rotkeeper-blog.html etc. Use same logic as earlier.
        # Re-derive showcase page name consistently
        local tmpl_base
        tmpl_base=$(basename "$tmpl" .html)
        local sc_page="showcase-${tmpl_base#theme-}.html"
        if [[ "$tname" != theme-*.html ]]; then
          sc_page="showcase-${tmpl_base}.html"
        else
          sc_page="showcase-${theme}.html"
        fi
        # Fallback to showcase-<theme>.html if file exists, else use sc_page
        # We know the earlier loop created showcase-<theme>.html for each template
        echo "  <div style=\"border: 1px solid #333; border-radius: 8px; overflow: hidden; background: #fff;\">"
        echo "    <div style=\"height: 80px; background: $swatch; border-bottom: 1px solid #333;\"></div>"
        echo "    <div style=\"padding: 0.8rem;\">"
        echo "      <div style=\"font-weight: 600; font-family: monospace;\">$display</div>"
        echo "      <div style=\"font-size: 0.85em; color: #666;\">$tname</div>"
        echo "      <a href=\"$sc_page\" style=\"display: inline-block; margin-top: 0.5rem; font-size: 0.9em;\">View →</a>"
        echo "    </div>"
        echo "  </div>"
      done
      echo "</div>"
      echo ""
      echo "> Generated by \`rotkeeper.sh showcase\` — $gallery_count themes. Run \`bash rotkeeper.sh render\` to refresh."
    } > "$gallery_src"
    log "INFO" "Gallery source written to $gallery_src"

    # Also write static output gallery directly for immediate viewing (no render needed)
    mkdir -p "$(dirname "$gallery_out")"
    {
      echo "<!DOCTYPE html>"
      echo "<html lang=\"en\">"
      echo "<head>"
      echo "  <meta charset=\"utf-8\">"
      echo "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
      echo "  <title>Theme Gallery — $gallery_count themes</title>"
      echo "  <style>"
      echo "    body { font-family: system-ui, -apple-system, sans-serif; max-width: 1100px; margin: 2rem auto; padding: 0 1rem; color: #222; }"
      echo "    h1 { font-size: 1.8rem; margin-bottom: 0.2rem; }"
      echo "    .sub { color: #666; margin-bottom: 1.5rem; }"
      echo "    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 1.2rem; }"
      echo "    .card { border: 1px solid #333; border-radius: 8px; overflow: hidden; background: #fff; }"
      echo "    .swatch { height: 80px; border-bottom: 1px solid #333; }"
      echo "    .card-body { padding: 0.8rem; }"
      echo "    .name { font-weight: 600; font-family: monospace; }"
      echo "    .tmpl { font-size: 0.85em; color: #666; }"
      echo "    a { display: inline-block; margin-top: 0.5rem; font-size: 0.9em; color: #0366d6; text-decoration: none; }"
      echo "    a:hover { text-decoration: underline; }"
      echo "    .foot { margin-top: 2rem; font-size: 0.9em; color: #666; border-top: 1px solid #ddd; padding-top: 1rem; }"
      echo "  </style>"
      echo "</head>"
      echo "<body>"
      echo "  <h1>Theme Gallery</h1>"
      echo "  <div class=\"sub\">$gallery_count themes — preview every theme through the same content. Each card links to its full showcase page.</div>"
      echo "  <div class=\"grid\">"
      for tmpl in "$TEMPLATE_DIR"/*.html; do
        [[ -f "$tmpl" ]] || continue
        local tname2
        tname2=$(basename "$tmpl")
        local theme2="${tname2%.html}"
        theme2="${theme2#theme-}"
        local display2="$tname2"
        if [[ "$tname2" == theme-*.html ]]; then
          display2="$theme2"
        else
          display2="${tname2%.html}"
        fi
        local swatch2="#2a2a2a"
        case "$theme2" in
          brutal) swatch2="#111" ;;
          dark) swatch2="#1a1a2e" ;;
          kawaii) swatch2="#ffccf5" ;;
          light) swatch2="#fafafa" ;;
          overgrown) swatch2="#1e3a1e" ;;
          phosphor) swatch2="#0a0f0a" ;;
          spooky-dark) swatch2="#0f0f0f" ;;
          spooky-light) swatch2="#f5f0eb" ;;
          spooky) swatch2="#1a0f0f" ;;
          textpattern) swatch2="#ffffcc" ;;
          *) swatch2="#2a2a2a" ;;
        esac
        local sc_page2="showcase-${theme2}.html"
        local tmpl_base2
        tmpl_base2=$(basename "$tmpl" .html)
        if [[ "$tname2" != theme-*.html ]]; then
          sc_page2="showcase-${tmpl_base2}.html"
        else
          sc_page2="showcase-${theme2}.html"
        fi
        echo "    <div class=\"card\">"
        echo "      <div class=\"swatch\" style=\"background: $swatch2;\"></div>"
        echo "      <div class=\"card-body\">"
        echo "        <div class=\"name\">$display2</div>"
        echo "        <div class=\"tmpl\">$tname2</div>"
        echo "        <a href=\"$sc_page2\">View →</a>"
        echo "      </div>"
        echo "    </div>"
      done
      echo "  </div>"
      echo "  <div class=\"foot\">Generated by <code>rotkeeper.sh showcase</code> — $gallery_count themes. Run <code>bash rotkeeper.sh render</code> to refresh. No JS, no CDN.</div>"
      echo "</body>"
      echo "</html>"
    } > "$gallery_out"
    log "INFO" "Gallery output written to $gallery_out"
  fi

  # shellcheck disable=SC2295
  log "MARKER" "✓ showcase: $gallery_count themes — open ${gallery_out#$ROOT_DIR/}"
}

main "$@"
