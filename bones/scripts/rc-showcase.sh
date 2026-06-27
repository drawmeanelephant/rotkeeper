#!/usr/bin/env bash

# Source environment
source "$(dirname "${BASH_SOURCE[0]}")/rc-env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"

SHOWCASE_DIR="$CONTENT_DIR/showcase"

mkdir -p "$SHOWCASE_DIR"

if [[ -d "$TEMPLATE_DIR" ]]; then
    for template_file in "$TEMPLATE_DIR"/*.html; do
        if [[ -f "$template_file" ]]; then
            template_name=$(basename "$template_file")
            theme_name="${template_name%.html}"
            theme_name="${theme_name#theme-}"

            output_file="$SHOWCASE_DIR/showcase-${theme_name}.md"

            cat << MD_EOF > "$output_file"
---
title: "Showcase: $theme_name"
date: $(date +%Y-%m-%d)
template: "$template_name"
---

# Heading 1
Through a terminal-driven, proactive embalming approach we can remain tomb-focused and artifact-directed, innovate and be an offline-first necropolis which facilitates static bash-readiness.

## Heading 2
Transforming turnkey phylacteries to dead-code 24/365 paradigms with benchmark archival channels implementing viral bash-rituals and flat-file action-items.

### Heading 3
While we take that action item strictly off-line and raise a fatal trap_err and remember to touch base as you think about the markdown fences outside of the crypt.

#### Heading 4
And seize B2B (Bash-to-Bone) orchestrators and re-envisioneer necromantic partnerships that evolve zero-hydration initiatives delivering synergistic dead-drops.

##### Heading 5
To incentivize CI/CD deliverables that leverage Pandoc solutions to synergize bash-and-bone dropzones while facilitating one-to-one shell-scripts.

###### Heading 6
With revolutionary Frankenstein stitching that deliver viral payloads and grow decentralized supply-chains that expedite seamless embalming.

---

**Bold Text**: Transform back-end shell dependencies withthrough a terminal-driven, proactive embalming approach we can remain tomb-focused and artifact-directed.

*Italic Text*: Innovate and be an offline-first necropolis which facilitates static bash-readiness transforming turnkey phylacteries to dead-code 24/365 paradigms.

> Blockquote:
> With benchmark archival channels implementing viral bash-rituals and flat-file action-items while we take that action item strictly off-line and raise a fatal trap_err.
>
> And remember to touch base as you think about the markdown fences outside of the crypt and seize B2B (Bash-to-Bone) orchestrators.

---

### Unordered List
* Re-envisioneer necromantic partnerships
* Evolve zero-hydration initiatives delivering synergistic dead-drops
* Incentivize CI/CD deliverables that leverage Pandoc solutions

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
MD_EOF
            echo "Generated showcase file: $output_file"
        fi
    done
else
    echo "Template directory not found: $TEMPLATE_DIR"
fi
