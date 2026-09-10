#!/usr/bin/env bash
# ============================================================
#  ██████╗  ██████╗ ████████╗ █████╗ ████████╗██╗   ██╗██╗
#  ██╔══██╗██╔═══██╗╚══██╔══╝██╔══██╗╚══██╔══╝██║   ██║██║
#  ██████╔╝██║   ██║   ██║   ███████║   ██║   ██║   ██║██║
#  ██╔══██╗██║   ██║   ██║   ██╔══██║   ██║   ██║   ██║██║
#  ██║  ██║╚██████╔╝   ██║   ██║  ██║   ██║   ╚██████╔╝██║
#  ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝
# ============================================================
#  Script  : rotatui.sh
#  Purpose : Standalone Gum-powered interactive TUI companion for Rotkeeper
#  Aesthetic: Spooky Dark / Necropolis terminal
# ============================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"
DISPATCHER="$ROOT_DIR/rotkeeper.sh"

# Spooky Dark Palette
COLOR_VIOLET="141"
COLOR_GREEN="78"
COLOR_AMBER="214"
COLOR_SLATE="242"
COLOR_WHITE="254"
COLOR_CRIMSON="196"

# Framing — every panel shares one double-ruled necropolis border
BORDER="double"
PANEL_WIDTH=72
RITUAL_STATUS=0

# Check for gum dependency
if ! command -v gum >/dev/null 2>&1; then
  printf '\033[1;35m'
  printf '╔═══════════════════════════════════════════════════════════════╗\n'
  printf '║                 💀  R O T A T U I  💀                         ║\n'
  printf '║           Static Necropolis & Content Terminal                ║\n'
  printf '╚═══════════════════════════════════════════════════════════════╝\n'
  printf '\033[0m\n'
  printf '\033[31m[ERROR]\033[0m Charm Gum is required to run this TUI companion.\n'
  printf 'Install Gum via Homebrew:\n'
  printf '  \033[32mbrew install gum\033[0m\n\n'
  printf 'Or download from Charm:\n'
  printf '  https://github.com/charmbracelet/gum#installation\n\n'
  exit 1
fi

# Soft-check optional Charm stack companions (graceful degradation)
missing_stack=()
command -v glow >/dev/null 2>&1 || missing_stack+=("glow")
command -v skate >/dev/null 2>&1 || missing_stack+=("skate")

show_stack_notice() {
  [[ ${#missing_stack[@]} -eq 0 ]] && return 0
  gum log --level warn --prefix "rotatui" \
    --level.foreground "$COLOR_AMBER" --prefix.foreground "$COLOR_VIOLET" \
    --message.foreground "$COLOR_WHITE" \
    "Optional Charm companions not found: ${missing_stack[*]}"
  gum log --level info --prefix "rotatui" \
    --level.foreground "$COLOR_SLATE" --prefix.foreground "$COLOR_VIOLET" \
    --message.foreground "$COLOR_SLATE" \
    "glow → tomb peek (falls back to gum format)   skate → remember last scaffold choices"
  gum log --level info --prefix "rotatui" \
    --level.foreground "$COLOR_SLATE" --prefix.foreground "$COLOR_VIOLET" \
    --message.foreground "$COLOR_SLATE" \
    "Install the missing bones:  brew install ${missing_stack[*]}"
  echo ""
}

# Verify root dispatcher exists
if [[ ! -f "$DISPATCHER" ]]; then
  gum style --foreground "$COLOR_CRIMSON" --border double --border-foreground "$COLOR_CRIMSON" \
    "ERROR: Rotkeeper dispatcher not found at $DISPATCHER"
  exit 1
fi

cleanup_tui() {
  # Clean terminal cursor and restore default colors
  printf '\033[?25h'
}
trap cleanup_tui EXIT
trap 'cleanup_tui; echo ""; exit 0' INT TERM

# --- UI Helpers ---

# Double-ruled panel with a colored border; an optional numeric width follows <color>,
# then any extra gum style flags.
panel() {
  local color="$1"
  shift
  local width="$PANEL_WIDTH"
  if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
    width="$1"
    shift
  fi
  gum style \
    --border "$BORDER" \
    --border-foreground "$color" \
    --padding "0 2" \
    --margin "0 1" \
    --width "$width" \
    "$@"
}

# Centered double-ruled section header shown at the top of every ritual screen.
section_header() {
  gum style \
    --border "$BORDER" \
    --border-foreground "$COLOR_VIOLET" \
    --foreground "$COLOR_GREEN" \
    --bold \
    --align center \
    --padding "0 2" \
    --margin "0 1" \
    --width "$PANEL_WIDTH" \
    "$1"
}

# Map a Rotkeeper template name to a shared glow + gum-format (glamour) style.
theme_style_for() {
  case "$1" in
    *light*) echo "light" ;;
    *pride*|*kawaii*|*flash*|*daisy*) echo "pink" ;;
    *spooky*|*necropolis*|*dark*|*brutal*|*phosphor*|*overgrown*) echo "dracula" ;;
    *) echo "dark" ;;
  esac
}

show_banner() {
  clear 2>/dev/null || true
  panel "$COLOR_VIOLET" \
    --align center \
    "💀  R O T A T U I  💀" \
    "Static Necropolis & Content Terminal"

  local pulse
  pulse=$("$DISPATCHER" status --short 2>/dev/null || echo "Rotkeeper status unavailable")
  gum style \
    --foreground "$COLOR_SLATE" \
    --align center \
    --width "$PANEL_WIDTH" \
    --margin "0 1" \
    "⚰️  $pulse"
  echo ""
}

drain_input() {
  local discard
  if [[ -t 0 ]]; then
    while read -r -t 0.05 -n 1000 discard 2>/dev/null; do :; done
  elif [[ -r /dev/tty ]]; then
    while read -r -t 0.05 -n 1000 discard < /dev/tty 2>/dev/null; do :; done
  fi
}

# Short-lived Bubble Tea programs (notably `gum spin`) probe terminal capabilities
# and can leave the reply in flight after they exit; once echo is restored the tty
# prints it as junk like ^[[?1u (bubbletea #1627/#1749). Turn echo off briefly and
# drain so those late replies are swallowed.
settle_terminal() {
  local tty_dev="/dev/tty"
  if [[ ! -r "$tty_dev" ]]; then
    if [[ -t 0 ]]; then
      tty_dev="/dev/stdin"
    else
      return 0
    fi
  fi

  local saved
  saved=$( { stty -g < "$tty_dev"; } 2>/dev/null ) || return 0

  (
    trap 'stty "$saved" < "$tty_dev" 2>/dev/null || true' EXIT
    trap 'stty "$saved" < "$tty_dev" 2>/dev/null || true; exit 130' INT TERM
    stty -echo < "$tty_dev" 2>/dev/null || exit 0
    sleep 0.15
    local discard
    while read -r -t 0.05 -n 1000 discard < "$tty_dev" 2>/dev/null; do :; done
  )
}

skate_get() {
  if command -v skate >/dev/null 2>&1; then
    skate get "$1" 2>/dev/null || true
  fi
}

skate_set() {
  if command -v skate >/dev/null 2>&1; then
    skate set "$1" "$2" 2>/dev/null || true
  fi
}

pause_prompt() {
  drain_input
  echo ""
  gum style --foreground "$COLOR_SLATE" "Press [Enter] to return to the necropolis menu..."
  if [[ -t 0 ]]; then
    read -r _ || true
  elif [[ -r /dev/tty ]]; then
    read -r _ < /dev/tty 2>/dev/null || true
  fi
  drain_input
}

spooky_spin() {
  local title="$1"
  shift
  local log_tmp="$1"
  shift

  # Pick a spinner that fits the ritual; RK_SPINNER overrides.
  local spinner="moon"
  case "$title" in
    *"test matrix"*|*assertions*) spinner="meter" ;;
    *"Binding retrieval"*|*"bound report"*) spinner="ellipsis" ;;
    *Initializ*|*initializ*|*Scaffolding*) spinner="globe" ;;
    *asset*|*Asset*) spinner="pulse" ;;
    *autopsy*|*Autopsy*) spinner="monkey" ;;
  esac
  spinner="${RK_SPINNER:-$spinner}"

  # gum spin owns the cursor and the animation; the command's output is captured
  # to the log through an exported path so it does not fight the spinner.
  export RK_SPIN_LOG="$log_tmp"
  local exit_code=0
  # shellcheck disable=SC2016  # $@/$RK_SPIN_LOG must expand inside the child bash
  gum spin \
    --spinner "$spinner" \
    --spinner.foreground "$COLOR_VIOLET" \
    --title.foreground "$COLOR_WHITE" \
    --title "$title" \
    --align left \
    --padding "0 0" \
    -- bash -c '"$@" > "$RK_SPIN_LOG" 2>&1' _ "$@" || exit_code=$?
  unset RK_SPIN_LOG

  settle_terminal
  return "$exit_code"
}

run_with_spin() {
  local title="$1"
  shift
  local log_tmp
  log_tmp=$(mktemp)

  local exit_code=0
  spooky_spin "$title" "$log_tmp" "$@" || exit_code=$?
  RITUAL_STATUS=$exit_code

  if [[ $exit_code -eq 0 ]]; then
    panel "$COLOR_GREEN" --foreground "$COLOR_GREEN" "✓ RITUAL COMPLETE"
    if [[ -s "$log_tmp" ]]; then
      echo ""
      tail -n 12 "$log_tmp"
    fi
  else
    panel "$COLOR_CRIMSON" --foreground "$COLOR_CRIMSON" "❌ RITUAL FAILED (exit code: $exit_code)"
    echo ""
    tail -n 15 "$log_tmp"
    if gum confirm --prompt.foreground "$COLOR_AMBER" --affirmative "Inspect" --negative "Dismiss" \
      "Open complete log in pager?"; then
      gum pager < "$log_tmp"
    fi
  fi

  rm -f "$log_tmp"
  return 0
}

# --- Action Handlers ---

handle_peek() {
  show_banner
  section_header "👁️  Peek At A Tomb"

  local tomb
  tomb=$(gum file --file --cursor "☠ " \
    --header "Select a markdown tomb" \
    --cursor.foreground "$COLOR_VIOLET" \
    --directory.foreground "$COLOR_GREEN" \
    --file.foreground "$COLOR_WHITE" \
    --height 15 \
    "$ROOT_DIR/home/content" || true)

  if [[ -z "$tomb" ]]; then
    return 0
  fi

  # Match the preview style to the tomb's template (frontmatter wins, then config).
  local tpl style
  tpl=$(sed -n '1,20p' "$tomb" | grep -m1 '^template:' | sed -E 's/^template:[[:space:]]*//' | tr -d '"' || true)
  if [[ -z "$tpl" ]]; then
    tpl=$(sed -n 's/^default_template:[[:space:]]*//p' "$ROOT_DIR/bones/config/rotkeeper.yaml" | head -n1 | tr -d '"')
  fi
  style=$(theme_style_for "$tpl")

  echo ""
  if command -v glow >/dev/null 2>&1; then
    glow -p -s "$style" "$tomb"
  else
    # Graceful degradation: gum (glamour) renders markdown when glow is absent.
    gum format --type markdown --theme "$style" < "$tomb" | gum pager
  fi
  pause_prompt
}

handle_render() {
  show_banner
  section_header "🔨  Render Site"

  local mode
  mode=$(gum choose --header "Select Render Mode:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚡ Standard Render         (Compile all content to output/)" \
    "🔍 Dry-Run Preview        (Preview render actions without writing)" \
    "📜 Verbose Render         (Detailed execution telemetry)" \
    "🔙 Return to Main Menu" || true)

  case "$mode" in
    "⚡ Standard Render"*)
      run_with_spin "Summoning Oliver to render markdown tombs..." "$DISPATCHER" render
      ;;
    "🔍 Dry-Run Preview"*)
      run_with_spin "Previewing Oliver render ritual..." "$DISPATCHER" render --dry-run
      ;;
    "📜 Verbose Render"*)
      run_with_spin "Summoning Oliver with verbose telemetry..." "$DISPATCHER" render --verbose
      ;;
    *) return 0 ;;
  esac
  pause_prompt
}

handle_new() {
  show_banner
  section_header "📝 Scaffold New Tomb"

  # 1. Slug
  local slug
  slug=$(gum input --placeholder "tomb-filename-or-slug (e.g. cemetery-dispatch)" \
    --prompt.foreground "$COLOR_VIOLET" \
    --prompt "Slug / Filename > " \
    --char-limit 80 \
    --width 60 || true)
  if [[ -z "$slug" ]]; then
    gum log --level warn --prefix "rotatui" --level.foreground "$COLOR_AMBER" \
      "Scaffold cancelled: slug cannot be empty."
    pause_prompt
    return 0
  fi

  # 2. Title
  local title
  title=$(gum input --placeholder "Document Title (Leave blank to auto-derive from slug)" \
    --prompt.foreground "$COLOR_VIOLET" \
    --prompt "Title > " \
    --char-limit 120 \
    --width 60 || true)

  # 3. Template
  local raw_templates=()
  while IFS= read -r line; do
    [[ "$line" =~ \.html ]] && raw_templates+=("${line%% *}")
  done < <("$DISPATCHER" new --list 2>/dev/null || true)
  if [[ ${#raw_templates[@]} -eq 0 ]]; then
    while IFS= read -r tpl; do
      raw_templates+=("$(basename "$tpl")")
    done < <(find "$ROOT_DIR/bones/templates" -maxdepth 1 -name '*.html' 2>/dev/null | sort || true)
  fi
  if [[ ${#raw_templates[@]} -eq 0 ]]; then
    gum log --level error --prefix "rotatui" --level.foreground "$COLOR_CRIMSON" \
      "No theme templates found under bones/templates/."
    pause_prompt
    return 0
  fi

  local template
  template=$(gum filter --placeholder "Filter theme templates..." \
    --prompt "> " \
    --prompt.foreground "$COLOR_VIOLET" \
    --indicator.foreground "$COLOR_VIOLET" \
    --match.foreground "$COLOR_GREEN" \
    --select-if-one \
    --fuzzy \
    --height 10 \
    "${raw_templates[@]}" || true)

  # 4. Target Directory
  local target_dir
  target_dir=$(gum choose --header "Choose Content Subdirectory:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "root (home/content)" \
    "docs" \
    "recipes" \
    "journal" \
    "custom..." || true)

  local subdir_arg=""
  local last_subdir
  last_subdir=$(skate_get "rotatui/last_subdir")
  if [[ "$target_dir" == "custom..." ]]; then
    local custom_dir
    custom_dir=$(gum input --placeholder "e.g. lore/whispers" \
      --value "$last_subdir" \
      --prompt.foreground "$COLOR_VIOLET" \
      --prompt "Subdirectory > " || true)
    [[ -n "$custom_dir" ]] && subdir_arg="$custom_dir"
  elif [[ -n "$target_dir" && "$target_dir" != "root (home/content)" ]]; then
    subdir_arg="$target_dir"
  fi

  # 5. Tags
  local tags
  tags=$(gum input --placeholder "e.g. necropolis, occult, dispatch" \
    --prompt.foreground "$COLOR_VIOLET" \
    --prompt "Tags (comma-separated) > " \
    --char-limit 200 \
    --width 60 || true)

  # 6. Description
  local desc
  desc=$(gum input --placeholder "Brief frontmatter description / abstract" \
    --prompt.foreground "$COLOR_VIOLET" \
    --prompt "Description > " \
    --char-limit 200 \
    --width 60 || true)

  # 7. Soul Sidecar
  local -a soul_flag=()
  if gum confirm --prompt.foreground "$COLOR_AMBER" --affirmative "Add sidecar" --negative "Skip" \
    "Scaffold companion .soul.md sidecar metadata?"; then
    soul_flag=("--soul")
  fi

  # 8. Initial Body Content
  echo ""
  gum style --foreground "$COLOR_SLATE" "Enter starting body content (Ctrl+D to submit, Esc to skip):"
  local body
  body=$(gum write --placeholder "Markdown body content begins here..." \
    --prompt.foreground "$COLOR_VIOLET" \
    --width 72 \
    --height 6 || true)

  # Build command
  local -a cmd=("$DISPATCHER" "new" "$slug")
  [[ -n "$title" ]] && cmd+=("--title" "$title")
  [[ -n "$template" ]] && cmd+=("--template" "$template")
  [[ -n "$subdir_arg" ]] && cmd+=("--subdir" "$subdir_arg")
  [[ -n "$tags" ]] && cmd+=("--tags" "$tags")
  [[ -n "$desc" ]] && cmd+=("--description" "$desc")
  [[ -n "$body" ]] && cmd+=("--body" "$body")
  [[ ${#soul_flag[@]} -gt 0 ]] && cmd+=("${soul_flag[@]}")

  echo ""
  if gum confirm --prompt.foreground "$COLOR_GREEN" --affirmative "Engrave" --negative "Abort" \
    "Create new tomb '$slug'?"; then
    run_with_spin "Engraving tomb into home/content/..." "${cmd[@]}"
    if [[ $RITUAL_STATUS -eq 0 ]]; then
      [[ -n "$subdir_arg" ]] && skate_set "rotatui/last_subdir" "$subdir_arg"
      skate_set "rotatui/last_slug" "$slug"
    fi
  else
    gum log --level warn --prefix "rotatui" --level.foreground "$COLOR_AMBER" "Scaffold aborted."
  fi
  pause_prompt
}

handle_pack() {
  show_banner
  section_header "📦  Pack Archive"

  local mode
  mode=$(gum choose --header "Select Pack Archive Target:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚰️  Output Tomb Archive   (Pack rendered HTML into bones/archive/tomb-*.tar.gz)" \
    "📜 Source Content Only    (--content: archive markdown/textile/cook source)" \
    "🏰 Full System Bundle     (--self: archive complete Rotkeeper framework)" \
    "🔍 Dry-Run Preview        (--dry-run: simulate archive packaging)" \
    "🔙 Return to Main Menu" || true)

  case "$mode" in
    "⚰️  Output Tomb Archive"*)
      run_with_spin "Compressing output HTML into tomb tarball..." "$DISPATCHER" pack
      ;;
    "📜 Source Content Only"*)
      run_with_spin "Preserving source content into archive..." "$DISPATCHER" pack --content
      ;;
    "🏰 Full System Bundle"*)
      run_with_spin "Packaging full system archive bundle..." "$DISPATCHER" pack --self
      ;;
    "🔍 Dry-Run Preview"*)
      run_with_spin "Simulating tomb packaging..." "$DISPATCHER" pack --dry-run
      ;;
    *) return 0 ;;
  esac
  pause_prompt
}

handle_status() {
  show_banner
  section_header "📊  Necropolis State & Health"

  # Fetch JSON status
  local json_raw
  json_raw=$("$DISPATCHER" status --json 2>/dev/null || true)

  if [[ -n "$json_raw" ]] && command -v jq >/dev/null 2>&1; then
    local version branch commit total_md total_textile total_cook html_fresh html_status
    version=$(echo "$json_raw" | jq -r '.environment.canonical_version // "unknown"')
    branch=$(echo "$json_raw" | jq -r '.environment.branch // "unknown"')
    commit=$(echo "$json_raw" | jq -r '.environment.commit // "unknown"')
    total_md=$(echo "$json_raw" | jq -r '.content_pulse.total_md // 0')
    total_textile=$(echo "$json_raw" | jq -r '.content_pulse.total_textile // 0')
    total_cook=$(echo "$json_raw" | jq -r '.content_pulse.total_cook // 0')
    html_fresh=$(echo "$json_raw" | jq -r '.render_freshness.message // "unknown"')
    html_status=$(echo "$json_raw" | jq -r '.render_freshness.status // "unknown"')

    # Two double-ruled cards, joined side by side (Lip Gloss under the hood).
    local left right fresh_color fresh_line
    left=$(panel "$COLOR_VIOLET" 32 \
      "Environment" \
      "v$version" \
      "$branch @ $commit")
    right=$(panel "$COLOR_GREEN" 32 \
      "Content Pulse" \
      "$total_md markdown" \
      "$total_textile textile · $total_cook cook")
    gum join --horizontal "$left" "$right"

    fresh_color="$COLOR_GREEN"
    [[ "$html_status" != "ok" && "$html_status" != "fresh" ]] && fresh_color="$COLOR_AMBER"
    # Interpolated into the template, so strip template-breaking characters first.
    fresh_line="${html_fresh//\\/}"
    fresh_line="${fresh_line//\"/}"
    gum format --type template \
      "{{ Bold \"Freshness\" }} {{ Color \"$fresh_color\" \"$fresh_line\" }}"
  else
    "$DISPATCHER" status --short
  fi

  echo ""
  local sub_action
  sub_action=$(gum choose --header "Status Actions:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "📜 View Full Formatted Status Report in Pager" \
    "🩺 Inspect Script Health Table" \
    "🔙 Return to Main Menu" || true)

  case "$sub_action" in
    "📜 View Full Formatted Status Report"*)
      "$DISPATCHER" status | gum pager
      ;;
    "🩺 Inspect Script Health Table"*)
      if [[ -n "$json_raw" ]] && command -v jq >/dev/null 2>&1; then
        # Interactive: pick a script to open its doc page (or source) in the pager.
        local rows selected doc src
        rows=$(echo "$json_raw" | jq -r '.script_health.scripts[] | "\(.script),\(.version),\(if .matches_canonical then "MATCH" else "DRIFT" end)"')
        selected=$(printf '%s\n' "$rows" | gum table \
          --columns "Script,Version,Status" \
          --return-column 1 \
          --border "$BORDER" --border.foreground "$COLOR_VIOLET" --header.foreground "$COLOR_GREEN" || true)
        if [[ -n "$selected" ]]; then
          doc="$ROOT_DIR/home/content/docs/bones/scripts/${selected%.sh}.md"
          src="$ROOT_DIR/bones/scripts/$selected"
          if [[ -f "$doc" ]]; then
            gum pager < "$doc"
          elif [[ -f "$src" ]]; then
            gum pager < "$src"
          else
            gum log --level warn --prefix "rotatui" --level.foreground "$COLOR_AMBER" \
              "No doc or source found for $selected"
          fi
        fi
        pause_prompt
      else
        "$DISPATCHER" status | gum pager
      fi
      ;;
    *) return 0 ;;
  esac
}

handle_assets() {
  show_banner
  section_header "🎨  Asset Pipeline"

  local mode
  mode=$(gum choose --header "Asset Pipeline Actions:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚡ Sync Assets & Generate Manifest  (assets)" \
    "🔍 Dry-Run Preview                 (assets --dry-run)" \
    "🔙 Return to Main Menu" || true)

  case "$mode" in
    "⚡ Sync Assets"*)
      run_with_spin "Auditing & synchronizing assets to output/..." "$DISPATCHER" assets
      ;;
    "🔍 Dry-Run Preview"*)
      run_with_spin "Simulating asset manifest build..." "$DISPATCHER" assets --dry-run
      ;;
    *) return 0 ;;
  esac
  pause_prompt
}

handle_links() {
  show_banner
  section_header "🔗  Link Audit"

  local mode
  mode=$(gum choose --header "Link & Asset Audit Actions:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚡ Audit Rendered HTML Links       (links)" \
    "🔍 Dry-Run Preview                 (links --dry-run)" \
    "🔙 Return to Main Menu" || true)

  case "$mode" in
    "⚡ Audit Rendered HTML Links"*)
      run_with_spin "Auditing internal & external links in output/..." "$DISPATCHER" links
      ;;
    "🔍 Dry-Run Preview"*)
      run_with_spin "Simulating link audit..." "$DISPATCHER" links --dry-run
      ;;
    *) return 0 ;;
  esac
  pause_prompt
}

handle_a11y() {
  show_banner
  section_header "♿  Theme Accessibility Audit"

  local tmp_a11y
  tmp_a11y=$(mktemp)

  local code=0
  spooky_spin "Auditing theme WCAG contrast and focus states..." "$tmp_a11y" "$DISPATCHER" a11y || code=$?

  if [[ $code -eq 0 ]]; then
    panel "$COLOR_GREEN" --foreground "$COLOR_GREEN" "✓ ALL THEME CONTRAST & FOCUS CHECKS PASSED"
  else
    panel "$COLOR_AMBER" --foreground "$COLOR_AMBER" "⚠️ ACCESSIBILITY WARNINGS DETECTED"
  fi

  echo ""
  tail -n 14 "$tmp_a11y"

  if gum confirm --prompt.foreground "$COLOR_AMBER" --affirmative "Scroll" --negative "Done" \
    "Scroll complete accessibility report in pager?"; then
    gum pager < "$tmp_a11y"
  fi
  rm -f "$tmp_a11y"
  pause_prompt
}

handle_preflight() {
  show_banner
  section_header "🧪  Oliver Renderer Preflight"

  local tmp_pf
  tmp_pf=$(mktemp)
  local code=0
  spooky_spin "Checking Oliver binary & smoke render..." "$tmp_pf" "$DISPATCHER" preflight || code=$?

  if [[ $code -eq 0 ]]; then
    panel "$COLOR_GREEN" --foreground "$COLOR_GREEN" "✓ OLIVER RENDERER DISCOVERY: PASS"
    echo ""
    cat "$tmp_pf"
  else
    panel "$COLOR_CRIMSON" --foreground "$COLOR_CRIMSON" "❌ OLIVER PREFLIGHT FAILED"
    echo ""
    cat "$tmp_pf"
  fi
  rm -f "$tmp_pf"
  pause_prompt
}

handle_glue() {
  show_banner
  section_header "🧭  Navigation Glue"

  local mode
  mode=$(gum choose --header "Navigation Glue Actions:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚡ Generate Navigation Glue         (glue)" \
    "🔍 Dry-Run Preview                 (glue --dry-run)" \
    "🔙 Return to Main Menu" || true)

  case "$mode" in
    "⚡ Generate Navigation Glue"*)
      run_with_spin "Generating directory index glue..." "$DISPATCHER" glue
      ;;
    "🔍 Dry-Run Preview"*)
      run_with_spin "Simulating navigation glue generation..." "$DISPATCHER" glue --dry-run
      ;;
    *) return 0 ;;
  esac
  pause_prompt
}

handle_showcase() {
  show_banner
  section_header "🎭  Theme Showcase"

  local theme_count
  theme_count=$(find "$ROOT_DIR/bones/templates" -maxdepth 1 -name 'theme-*.html' 2>/dev/null | wc -l | tr -d ' ')
  if gum confirm --prompt.foreground "$COLOR_VIOLET" --affirmative "Generate" --negative "Cancel" \
    "Generate preview pages under home/content/showcase/ for all $theme_count themes?"; then
    run_with_spin "Generating showcase previews..." "$DISPATCHER" showcase
  fi
  pause_prompt
}

handle_book() {
  show_banner
  section_header "📖  Book Binders"

  local -a selected=()
  while IFS= read -r line; do
    case "$line" in
      "📚 All Retrieval"*) selected+=("--all") ;;
      "📖 Documentation"*) selected+=("--docbook") ;;
      "🧹 Clean Doc"*) selected+=("--docbook-clean") ;;
      "📜 Full Active"*) selected+=("--scriptbook-full") ;;
      "⚙️  Config &"*) selected+=("--configbook") ;;
      "🗂️  Filesystem"*) selected+=("--fsbook") ;;
      "📝 Content Pages"*) selected+=("--contentbook") ;;
      "🧬 Content Meta"*) selected+=("--contentmeta") ;;
    esac
  done < <(gum choose --no-limit \
    --header "Select Book Targets (space toggles, enter binds):" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "📚 All Retrieval Binders           (--all)" \
    "📖 Documentation Book              (--docbook)" \
    "🧹 Clean Documentation             (--docbook-clean)" \
    "📜 Full Active Scripts Binder      (--scriptbook-full)" \
    "⚙️  Config & Templates Binder       (--configbook)" \
    "🗂️  Filesystem Catalog Book        (--fsbook)" \
    "📝 Content Pages Binder            (--contentbook)" \
    "🧬 Content Metadata Matrix         (--contentmeta)" \
    "🔙 Return to Main Menu" || true)

  if [[ ${#selected[@]} -eq 0 ]]; then
    return 0
  fi

  local last_log=""
  local flag code
  for flag in "${selected[@]}"; do
    [[ -n "$last_log" ]] && rm -f "$last_log"
    last_log=$(mktemp)
    code=0
    spooky_spin "Binding retrieval volume ($flag)..." "$last_log" "$DISPATCHER" book "$flag" || code=$?

    if [[ $code -eq 0 ]]; then
      panel "$COLOR_GREEN" --foreground "$COLOR_GREEN" "✓ BOUND $flag IN bones/book-reports/"
    else
      panel "$COLOR_CRIMSON" --foreground "$COLOR_CRIMSON" "❌ BINDER FAILED $flag (exit code: $code)"
    fi
    echo ""
    tail -n 8 "$last_log"
  done

  if gum confirm --prompt.foreground "$COLOR_AMBER" --affirmative "Open" --negative "Done" \
    "Open the last bound report in pager?"; then
    gum pager < "$last_log"
  fi
  rm -f "$last_log"
  pause_prompt
}

handle_scan() {
  show_banner
  section_header "🔎  Manifest Scan"

  local mode
  mode=$(gum choose --header "Manifest Scan Actions:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚡ Full Manifest & Orphan Audit    (scan)" \
    "📜 Manifest Check Only             (scan --manifest-only)" \
    "🔍 Dry-Run Preview                 (scan --dry-run)" \
    "🔙 Return to Main Menu" || true)

  local -a args=()
  case "$mode" in
    "⚡ Full Manifest"*) args=() ;;
    "📜 Manifest Check"*) args=("--manifest-only") ;;
    "🔍 Dry-Run Preview"*) args=("--dry-run") ;;
    *) return 0 ;;
  esac

  local tmp_scan
  tmp_scan=$(mktemp)
  local code=0
  spooky_spin "Scanning render ledger against disk..." "$tmp_scan" "$DISPATCHER" scan "${args[@]}" || code=$?

  tail -n 12 "$tmp_scan"
  if gum confirm --prompt.foreground "$COLOR_AMBER" --affirmative "Inspect" --negative "Done" \
    "Inspect full scan audit report in pager?"; then
    gum pager < "$tmp_scan"
  fi
  rm -f "$tmp_scan"
  pause_prompt
}

handle_autopsy() {
  show_banner
  section_header "🩺  Script Autopsy"

  local mode
  mode=$(gum choose --header "Script Autopsy Actions:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚡ Catalog Script Help & Writes    (autopsy)" \
    "🔍 Dry-Run Preview                 (autopsy --dry-run)" \
    "🔙 Return to Main Menu" || true)

  case "$mode" in
    "⚡ Catalog Script"*)
      run_with_spin "Performing ritual autopsy..." "$DISPATCHER" autopsy
      ;;
    "🔍 Dry-Run Preview"*)
      run_with_spin "Simulating ritual autopsy..." "$DISPATCHER" autopsy --dry-run
      ;;
    *) return 0 ;;
  esac
  pause_prompt
}

handle_dip() {
  show_banner
  section_header "📋  DIP Documentation Audit"

  local tmp_dip
  tmp_dip=$(mktemp)
  local code=0
  spooky_spin "Auditing documentation coverage and matrix..." "$tmp_dip" "$DISPATCHER" dip || code=$?

  tail -n 14 "$tmp_dip"
  if gum confirm --prompt.foreground "$COLOR_AMBER" --affirmative "Inspect" --negative "Done" \
    "Inspect full DIP matrix report in pager?"; then
    gum pager < "$tmp_dip"
  fi
  rm -f "$tmp_dip"
  pause_prompt
}

handle_bump() {
  show_banner
  section_header "🏷️   Semver Version Bump"

  local current_ver
  current_ver=$(tr -d '[:space:]' < "$ROOT_DIR/bones/config/version" 2>/dev/null || echo "unknown")
  gum style --foreground "$COLOR_SLATE" "Current Version: $current_ver"
  echo ""

  local bump_type
  bump_type=$(gum choose --header "Select Bump Increment:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "🔹 Patch Bump   (--patch: bug fixes & minor hygiene)" \
    "🔸 Minor Bump   (--minor: new rituals or major features)" \
    "🔺 Major Bump   (--major: breaking architectural shifts)" \
    "✏️  Custom Semver (--to <version>)" \
    "🔙 Return to Main Menu" || true)

  local -a bump_args=()
  case "$bump_type" in
    "🔹 Patch"*) bump_args=("--patch") ;;
    "🔸 Minor"*) bump_args=("--minor") ;;
    "🔺 Major"*) bump_args=("--major") ;;
    "✏️  Custom"*)
      local to_ver
      to_ver=$(gum input --placeholder "e.g. 0.9.0" --prompt "Target Version > " || true)
      if [[ ! "$to_ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        gum log --level error --prefix "rotatui" --level.foreground "$COLOR_CRIMSON" \
          "Expected semver MAJOR.MINOR.PATCH (got: ${to_ver:-<empty>})."
        pause_prompt
        return 0
      fi
      bump_args=("--to" "$to_ver")
      ;;
    *) return 0 ;;
  esac

  if gum confirm --prompt.foreground "$COLOR_AMBER" --affirmative "Bump" --negative "Cancel" \
    "Execute version bump (${bump_args[*]}) and record changelog?"; then
    run_with_spin "Recording microrelease update..." "$DISPATCHER" bump "${bump_args[@]}"
  fi
  pause_prompt
}

handle_release() {
  show_banner
  section_header "📦  Release Package"

  local current_ver
  current_ver=$(tr -d '[:space:]' < "$ROOT_DIR/bones/config/version" 2>/dev/null || echo "0.8.0")
  current_ver="${current_ver#v}"

  local mode
  mode=$(gum choose --header "Release Packager Actions:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "🔍 Dry-Run Preview        (Simulate packaging and verify allowlists)" \
    "📦 Build Canonical Zip    (Package rotkeeper-$current_ver.zip)" \
    "🔙 Return to Main Menu" || true)

  case "$mode" in
    "🔍 Dry-Run Preview"*)
      run_with_spin "Simulating canonical framework package..." "$DISPATCHER" release "$current_ver" --dry-run
      ;;
    "📦 Build Canonical Zip"*)
      if gum confirm --prompt.foreground "$COLOR_VIOLET" --affirmative "Package" --negative "Cancel" \
        "Package canonical distribution for v$current_ver?"; then
        run_with_spin "Packaging canonical framework zip..." "$DISPATCHER" release "$current_ver"
      fi
      ;;
    *) return 0 ;;
  esac
  pause_prompt
}

handle_test() {
  show_banner
  section_header "🧪  Integration Test Suite"

  local mode
  mode=$(gum choose --header "Integration Test Suite Options:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚡ Dry-Run Regression Tests       (Instant: checks legacy command regressions)" \
    "🏋️ Full Multi-Layout Test Matrix  (Comprehensive: crypt, busy, sterile fixtures)" \
    "🔙 Return to Main Menu" || true)

  local -a args=()
  case "$mode" in
    "⚡ Dry-Run Regression"*)
      args=("--dry-run")
      ;;
    "🏋️ Full Multi-Layout"*)
      args=()
      ;;
    *) return 0 ;;
  esac

  local tmp_test
  tmp_test=$(mktemp)
  local code=0
  spooky_spin "Executing test matrix assertions..." "$tmp_test" "$DISPATCHER" test "${args[@]}" || code=$?

  if [[ $code -eq 0 ]]; then
    panel "$COLOR_GREEN" --foreground "$COLOR_GREEN" "✓ ALL TEST ASSERTIONS COMPLETED SUCCESSFULLY"
  else
    panel "$COLOR_CRIMSON" --foreground "$COLOR_CRIMSON" "❌ TEST ASSERTIONS FAILED (exit code: $code)"
  fi

  echo ""
  tail -n 14 "$tmp_test"

  if gum confirm --prompt.foreground "$COLOR_AMBER" --affirmative "Scroll" --negative "Done" \
    "Scroll full test output in pager?"; then
    gum pager < "$tmp_test"
  fi
  rm -f "$tmp_test"
  pause_prompt
}

handle_init() {
  show_banner
  section_header "⚙️   Initialize Environment"

  local mode
  mode=$(gum choose --header "Initialization Depth:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚡ Full Setup      (init --full: sample content + assets + render + scan)" \
    "🌱 Scaffold Only   (init: create missing directories and sample content)" \
    "🔍 Dry-Run Preview (init --full --dry-run: no writes)" \
    "🔙 Return to Main Menu" || true)

  case "$mode" in
    "⚡ Full Setup"*)
      if gum confirm --prompt.foreground "$COLOR_AMBER" --affirmative "Initialize" --negative "Cancel" \
        "Run full initialization (sample content + assets + render + scan)?"; then
        run_with_spin "Initializing the necropolis..." "$DISPATCHER" init --full
      fi
      ;;
    "🌱 Scaffold Only"*)
      run_with_spin "Scaffolding missing bones..." "$DISPATCHER" init
      ;;
    "🔍 Dry-Run Preview"*)
      run_with_spin "Previewing initialization..." "$DISPATCHER" init --full --dry-run
      ;;
    *) return 0 ;;
  esac
  pause_prompt
}

handle_help() {
  show_banner
  section_header "❓  Ritual Reference"
  "$DISPATCHER" help 2>&1 | gum pager
  pause_prompt
}

# --- Main Event Loop ---

main_menu() {
  show_stack_notice
  while true; do
    show_banner

    local choice
    choice=$(gum filter --placeholder "Type to filter rituals..." \
      --prompt "> " \
      --prompt.foreground "$COLOR_VIOLET" \
      --indicator.foreground "$COLOR_VIOLET" \
      --match.foreground "$COLOR_GREEN" \
      --height 20 \
      "👁️  Peek At A Tomb      (Glow markdown preview from home/content)" \
      "🔨  Render Site         (Compile markdown into HTML tombs)" \
      "📝  New Tomb            (Interactive tomb scaffold wizard)" \
      "⚙️  Initialize Env      (First-run setup: scaffold, assets, render, scan)" \
      "📦  Pack Archive        (Archive rendered output or source into .tar.gz)" \
      "📊  System Status       (Environment health, script checks, token counts)" \
      "🎨  Asset Pipeline      (Audit and copy static theme assets)" \
      "🔗  Link Audit          (Scan rendered HTML for dead links and asset refs)" \
      "♿  Accessibility Audit (Check theme contrast and WCAG compliance)" \
      "🧪  Oliver Preflight    (Verify renderer discovery and smoke test)" \
      "🧭  Navigation Glue     (Generate index navigation for directories)" \
      "🎭  Theme Showcase      (Generate preview showcase pages for all themes)" \
      "📖  Book Binders        (Compile docbook, scriptbook, fsbook, contentbook)" \
      "🔎  Manifest Scan       (Verify disk files against render ledger)" \
      "🩺  Script Autopsy      (Catalog script CLI help and file-write behavior)" \
      "📋  DIP Docs Audit      (Document Improvement Project coverage audit)" \
      "🏷️  Version Bump        (Update semver version: patch/minor/major)" \
      "📦  Release Package     (Package canonical framework distribution zip)" \
      "🧪  Test Suite          (Run integration test matrix: dry-run or full)" \
      "❓  Ritual Help         (Show the dispatcher command reference)" \
      "🚪  Exit                (Leave the necropolis)") || true

    case "$choice" in
      "👁️  Peek At A Tomb"*) handle_peek ;;
      "🔨  Render Site"*) handle_render ;;
      "📝  New Tomb"*) handle_new ;;
      *"Initialize Env"*) handle_init ;;
      "📦  Pack Archive"*) handle_pack ;;
      "📊  System Status"*) handle_status ;;
      "🎨  Asset Pipeline"*) handle_assets ;;
      "🔗  Link Audit"*) handle_links ;;
      "♿  Accessibility Audit"*) handle_a11y ;;
      "🧪  Oliver Preflight"*) handle_preflight ;;
      "🧭  Navigation Glue"*) handle_glue ;;
      "🎭  Theme Showcase"*) handle_showcase ;;
      "📖  Book Binders"*) handle_book ;;
      "🔎  Manifest Scan"*) handle_scan ;;
      "🩺  Script Autopsy"*) handle_autopsy ;;
      "📋  DIP Docs Audit"*) handle_dip ;;
      "🏷️  Version Bump"*) handle_bump ;;
      "📦  Release Package"*) handle_release ;;
      "🧪  Test Suite"*) handle_test ;;
      *"Ritual Help"*) handle_help ;;
      "🚪  Exit"*|"")
        clear 2>/dev/null || true
        gum style --foreground "$COLOR_SLATE" "The tombs fall silent once more. Until next time."
        echo ""
        exit 0
        ;;
    esac || true
  done
}

main_menu
