#!/usr/bin/env bash
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-showcase.sh
#  Purpose : Auto-scaffolds test pages for all HTML themes
# ============================================================

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/rc-env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"

rk_init_script "rc-showcase" "$@"

main() {
  log "INFO" "Initializing Gallery of the Damned showcase scanner..."

  local showcase_dir="$CONTENT_DIR/showcase"
  mkdir -p "$showcase_dir"
  log "INFO" "Ensured showcase directory exists: $showcase_dir"

  # Find all files matching theme-*.html in the template directory
  for theme_file in "$TEMPLATE_DIR"/theme-*.html; do
    if [[ ! -f "$theme_file" ]]; then
      log "INFO" "No themes found."
      return 0
    fi

    local filename=$(basename "$theme_file")
    # Extract the vibe name: theme-vampire.html -> vampire
    local vibe=$(echo "$filename" | sed -E 's/^theme-(.*)\.html$/\1/')

    local target_file="$showcase_dir/showcase-${vibe}.md"

    log "INFO" "Scaffolding showcase page for theme: $filename -> $target_file"

    cat << 'MARKDOWN_EOF' > "$target_file"
---
title: "Showcase: $VIBE"
template: "$FILENAME"
---

# Header 1: The Crypt
## Header 2: Embalming Logs
### Header 3: Necromantic Devops

> "Every file dies. Not every file decays with style." - Rotkeeper Ritual Council

Through a terminal-driven, proactive embalming approach we can remain tomb-focused and artifact-directed, innovate and be an offline-first necropolis which facilitates static bash-readiness transforming turnkey phylacteries to dead-code 24/365 paradigms with benchmark archival channels implementing viral bash-rituals and flat-file action-items while we take that action item strictly off-line and raise a fatal `trap_err` and remember to touch base as you think about the markdown fences outside of the crypt and seize B2B (Bash-to-Bone) orchestrators and re-envisioneer necromantic partnerships that evolve zero-hydration initiatives delivering synergistic dead-drops to incentivize CI/CD deliverables that leverage Pandoc solutions to synergize bash-and-bone dropzones while facilitating one-to-one shell-scripts with revolutionary Frankenstein stitching that deliver viral payloads.

*   **Pillar 1:** Anatomy
*   **Pillar 2:** History
*   **Pillar 3:** The Soul
*   **Pillar 4:** Environment
MARKDOWN_EOF

    # Replace variables in the heredoc (since we used 'MARKDOWN_EOF' to prevent bash expansion of trap_err)
    sed -i "s/\$VIBE/${vibe^}/g" "$target_file"
    sed -i "s/\$FILENAME/$filename/g" "$target_file"

  done

  log "INFO" "Showcase generation complete!"
}

main "$@"
