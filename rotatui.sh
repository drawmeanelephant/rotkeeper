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

show_banner() {
  clear 2>/dev/null || true
  gum style \
    --border double \
    --border-foreground "$COLOR_VIOLET" \
    --foreground "$COLOR_WHITE" \
    --align center \
    --width 72 \
    --margin "0 0" \
    --padding "0 2" \
    "💀  R O T A T U I  💀" \
    "Static Necropolis & Content Terminal"

  local pulse
  pulse=$("$DISPATCHER" status --short 2>/dev/null || echo "Rotkeeper status unavailable")
  gum style \
    --foreground "$COLOR_SLATE" \
    --align center \
    --width 72 \
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

  "$@" > "$log_tmp" 2>&1 &
  local pid=$!

  spin_trap() {
    kill -TERM "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    printf '\r\033[K\033[?25h'
    exit 130
  }
  trap spin_trap INT TERM

  local -a frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  local i=0

  # Hide cursor
  printf '\033[?25l'

  while kill -0 "$pid" 2>/dev/null; do
    local frame="${frames[$((i % ${#frames[@]}))]}"
    printf '\r\033[38;5;%sm%s\033[0m \033[38;5;%sm%s\033[0m\033[K' "$COLOR_VIOLET" "$frame" "$COLOR_WHITE" "$title"
    i=$((i + 1))
    sleep 0.08
  done

  set +e
  wait "$pid" 2>/dev/null
  local exit_code=$?
  set -e

  trap cleanup_tui EXIT
  trap 'cleanup_tui; echo ""; exit 0' INT TERM

  # Clear line and restore cursor
  printf '\r\033[K\033[?25h'
  drain_input
  return "$exit_code"
}

run_with_spin() {
  local title="$1"
  shift
  local log_tmp
  log_tmp=$(mktemp)

  spooky_spin "$title" "$log_tmp" "$@"
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    gum style --foreground "$COLOR_GREEN" --border rounded --border-foreground "$COLOR_GREEN" --padding "0 2" \
      "✓ RITUAL COMPLETE"
    if [[ -s "$log_tmp" ]]; then
      echo ""
      tail -n 12 "$log_tmp"
    fi
  else
    gum style --foreground "$COLOR_CRIMSON" --border rounded --border-foreground "$COLOR_CRIMSON" --padding "0 2" \
      "❌ RITUAL FAILED (exit code: $exit_code)"
    echo ""
    tail -n 15 "$log_tmp"
    if gum confirm --prompt.foreground "$COLOR_AMBER" "Inspect complete log in pager?"; then
      gum pager < "$log_tmp"
    fi
  fi

  rm -f "$log_tmp"
  return $exit_code
}

# --- Action Handlers ---

handle_render() {
  show_banner
  local mode
  mode=$(gum choose --header "Select Render Mode:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚡ Standard Render         (Compile all content to output/)" \
    "🔍 Dry-Run Preview        (Preview render actions without writing)" \
    "📜 Verbose Render         (Detailed execution telemetry)" \
    "🔙 Return to Main Menu")

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
  gum style --foreground "$COLOR_GREEN" --bold "📝 Scaffold New Tomb (Document Wizard)"
  echo ""

  # 1. Slug
  local slug
  slug=$(gum input --placeholder "tomb-filename-or-slug (e.g. cemetery-dispatch)" \
    --prompt.foreground "$COLOR_VIOLET" \
    --prompt "Slug / Filename > " \
    --width 60)
  if [[ -z "$slug" ]]; then
    gum style --foreground "$COLOR_AMBER" "Scaffold cancelled: slug cannot be empty."
    pause_prompt
    return 0
  fi

  # 2. Title
  local title
  title=$(gum input --placeholder "Document Title (Leave blank to auto-derive from slug)" \
    --prompt.foreground "$COLOR_VIOLET" \
    --prompt "Title > " \
    --width 60)

  # 3. Template
  local raw_templates=()
  while IFS= read -r line; do
    [[ "$line" =~ \.html ]] && raw_templates+=("$(echo "$line" | awk '{print $1}')")
  done < <("$DISPATCHER" new --list 2>/dev/null || true)
  if [[ ${#raw_templates[@]} -eq 0 ]]; then
    raw_templates=("theme-spooky-dark.html" "theme-spooky-light.html" "theme-dark.html" "theme-light.html" "rotkeeper-blog.html" "rotkeeper-doc.html")
  fi

  local template
  template=$(gum choose --header "Select HTML Theme Template:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "${raw_templates[@]}")

  # 4. Target Directory
  local target_dir
  target_dir=$(gum choose --header "Choose Content Subdirectory:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "root (home/content)" \
    "docs" \
    "recipes" \
    "journal" \
    "custom...")

  local subdir_arg=""
  if [[ "$target_dir" == "custom..." ]]; then
    local custom_dir
    custom_dir=$(gum input --placeholder "e.g. lore/whispers" \
      --prompt.foreground "$COLOR_VIOLET" \
      --prompt "Subdirectory > ")
    [[ -n "$custom_dir" ]] && subdir_arg="$custom_dir"
  elif [[ "$target_dir" != "root (home/content)" ]]; then
    subdir_arg="$target_dir"
  fi

  # 5. Tags
  local tags
  tags=$(gum input --placeholder "e.g. necropolis, occult, dispatch" \
    --prompt.foreground "$COLOR_VIOLET" \
    --prompt "Tags (comma-separated) > " \
    --width 60)

  # 6. Description
  local desc
  desc=$(gum input --placeholder "Brief frontmatter description / abstract" \
    --prompt.foreground "$COLOR_VIOLET" \
    --prompt "Description > " \
    --width 60)

  # 7. Soul Sidecar
  local soul_flag=()
  if gum confirm --prompt.foreground "$COLOR_AMBER" "Scaffold companion .soul.md sidecar metadata?"; then
    soul_flag=("--soul")
  fi

  # 8. Initial Body Content
  echo ""
  gum style --foreground "$COLOR_SLATE" "Enter starting body content (Ctrl+D to submit, Esc to skip):"
  local body
  body=$(gum write --placeholder "Markdown body content begins here..." \
    --prompt.foreground "$COLOR_VIOLET" \
    --width 72 \
    --height 6)

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
  if gum confirm --prompt.foreground "$COLOR_GREEN" "Create new tomb '$slug'?"; then
    run_with_spin "Engraving tomb into home/content/..." "${cmd[@]}"
  else
    gum style --foreground "$COLOR_AMBER" "Scaffold aborted."
  fi
  pause_prompt
}

handle_pack() {
  show_banner
  local mode
  mode=$(gum choose --header "Select Pack Archive Target:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚰️  Output Tomb Archive   (Pack rendered HTML into bones/archive/tomb-*.tar.gz)" \
    "📜 Source Content Only    (--content: archive markdown/textile/cook source)" \
    "🏰 Full System Bundle     (--self: archive complete Rotkeeper framework)" \
    "🔍 Dry-Run Preview        (--dry-run: simulate archive packaging)" \
    "🔙 Return to Main Menu")

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
  gum style --foreground "$COLOR_GREEN" --bold "📊 Necropolis State & Health Dashboard"
  echo ""

  # Fetch JSON status
  local json_raw
  json_raw=$("$DISPATCHER" status --json 2>/dev/null || true)

  if [[ -n "$json_raw" ]] && command -v jq >/dev/null 2>&1; then
    local version branch commit total_md total_textile total_cook html_fresh
    version=$(echo "$json_raw" | jq -r '.environment.canonical_version // "unknown"')
    branch=$(echo "$json_raw" | jq -r '.environment.branch // "unknown"')
    commit=$(echo "$json_raw" | jq -r '.environment.commit // "unknown"')
    total_md=$(echo "$json_raw" | jq -r '.content_pulse.total_md // 0')
    total_textile=$(echo "$json_raw" | jq -r '.content_pulse.total_textile // 0')
    total_cook=$(echo "$json_raw" | jq -r '.content_pulse.total_cook // 0')
    html_fresh=$(echo "$json_raw" | jq -r '.render_freshness.message // "unknown"')

    gum style --border rounded --border-foreground "$COLOR_VIOLET" --padding "0 2" --width 70 \
      "Environment : v$version ($branch @ $commit)" \
      "Pulse       : $total_md markdown • $total_textile textile • $total_cook cook" \
      "Freshness   : $html_fresh"
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
    "🔙 Return to Main Menu")

  case "$sub_action" in
    "📜 View Full Formatted Status Report"*)
      "$DISPATCHER" status | gum pager
      ;;
    "🩺 Inspect Script Health Table"*)
      if [[ -n "$json_raw" ]] && command -v jq >/dev/null 2>&1; then
        local table_data="Script,Version,Status\n"
        while IFS= read -r row; do
          table_data+="$row\n"
        done < <(echo "$json_raw" | jq -r '.script_health.scripts[] | "\(.script),\(.version),\(if .matches_canonical then "MATCH" else "DRIFT" end)"')
        printf '%b' "$table_data" | gum table --print --border rounded --border.foreground "$COLOR_VIOLET" --header.foreground "$COLOR_GREEN"
        pause_prompt
      else
        "$DISPATCHER" status | grep -A 25 "Script Health" | gum pager
      fi
      ;;
    *) return 0 ;;
  esac
}

handle_assets() {
  show_banner
  local mode
  mode=$(gum choose --header "Asset Pipeline Actions:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚡ Sync Assets & Generate Manifest  (assets)" \
    "🔍 Dry-Run Preview                 (assets --dry-run)" \
    "🔙 Return to Main Menu")

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
  local mode
  mode=$(gum choose --header "Link & Asset Audit Actions:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚡ Audit Rendered HTML Links       (links)" \
    "🔍 Dry-Run Preview                 (links --dry-run)" \
    "🔙 Return to Main Menu")

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
  gum style --foreground "$COLOR_GREEN" --bold "♿ Theme Accessibility Audit"
  echo ""

  local tmp_a11y
  tmp_a11y=$(mktemp)

  spooky_spin "Auditing theme WCAG contrast and focus states..." "$tmp_a11y" "$DISPATCHER" a11y
  local code=$?

  if [[ $code -eq 0 ]]; then
    gum style --foreground "$COLOR_GREEN" --border rounded --border-foreground "$COLOR_GREEN" --padding "0 2" \
      "✓ ALL THEME CONTRAST & FOCUS CHECKS PASSED"
  else
    gum style --foreground "$COLOR_AMBER" --border rounded --border-foreground "$COLOR_AMBER" --padding "0 2" \
      "⚠️ ACCESSIBILITY WARNINGS DETECTED"
  fi

  echo ""
  tail -n 14 "$tmp_a11y"

  if gum confirm --prompt.foreground "$COLOR_AMBER" "Scroll complete accessibility report in pager?"; then
    gum pager < "$tmp_a11y"
  fi
  rm -f "$tmp_a11y"
  pause_prompt
}

handle_preflight() {
  show_banner
  gum style --foreground "$COLOR_GREEN" --bold "🧪 Oliver Renderer Preflight Check"
  echo ""

  local tmp_pf
  tmp_pf=$(mktemp)
  spooky_spin "Checking Oliver binary & smoke render..." "$tmp_pf" "$DISPATCHER" preflight
  local code=$?

  if [[ $code -eq 0 ]]; then
    gum style --foreground "$COLOR_GREEN" --border rounded --border-foreground "$COLOR_GREEN" --padding "0 2" \
      "✓ OLIVER RENDERER DISCOVERY: PASS"
    echo ""
    cat "$tmp_pf"
  else
    gum style --foreground "$COLOR_CRIMSON" --border rounded --border-foreground "$COLOR_CRIMSON" --padding "0 2" \
      "❌ OLIVER PREFLIGHT FAILED"
    echo ""
    cat "$tmp_pf"
  fi
  rm -f "$tmp_pf"
  pause_prompt
}

handle_glue() {
  show_banner
  local mode
  mode=$(gum choose --header "Navigation Glue Actions:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚡ Generate Navigation Glue         (glue)" \
    "🔍 Dry-Run Preview                 (glue --dry-run)" \
    "🔙 Return to Main Menu")

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
  gum style --foreground "$COLOR_GREEN" --bold "🎭 HTML Template Showcase Generator"
  echo ""
  if gum confirm --prompt.foreground "$COLOR_VIOLET" "Generate preview pages under home/content/showcase/ for all 15 themes?"; then
    run_with_spin "Generating showcase previews..." "$DISPATCHER" showcase
  fi
  pause_prompt
}

handle_book() {
  show_banner
  local target
  target=$(gum choose --header "Select Book Target to Compile:" \
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
    "🔙 Return to Main Menu")

  local flag=""
  case "$target" in
    "📚 All Retrieval"*) flag="--all" ;;
    "📖 Documentation"*) flag="--docbook" ;;
    "🧹 Clean Doc"*) flag="--docbook-clean" ;;
    "📜 Full Active"*) flag="--scriptbook-full" ;;
    "⚙️  Config &"*) flag="--configbook" ;;
    "🗂️  Filesystem"*) flag="--fsbook" ;;
    "📝 Content Pages"*) flag="--contentbook" ;;
    "🧬 Content Meta"*) flag="--contentmeta" ;;
    *) return 0 ;;
  esac

  local tmp_book
  tmp_book=$(mktemp)
  spooky_spin "Binding retrieval volume..." "$tmp_book" "$DISPATCHER" book "$flag"
  local code=$?

  if [[ $code -eq 0 ]]; then
    gum style --foreground "$COLOR_GREEN" --border rounded --border-foreground "$COLOR_GREEN" --padding "0 2" \
      "✓ BOOK BOUND IN bones/book-reports/"
    echo ""
    tail -n 8 "$tmp_book"
    if gum confirm --prompt.foreground "$COLOR_AMBER" "Open bound report in pager?"; then
      gum pager < "$tmp_book"
    fi
  else
    gum style --foreground "$COLOR_CRIMSON" --border rounded --border-foreground "$COLOR_CRIMSON" --padding "0 2" \
      "❌ BINDER FAILED"
    echo ""
    tail -n 12 "$tmp_book"
  fi
  rm -f "$tmp_book"
  pause_prompt
}

handle_scan() {
  show_banner
  local mode
  mode=$(gum choose --header "Manifest Scan Actions:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚡ Full Manifest & Orphan Audit    (scan)" \
    "📜 Manifest Check Only             (scan --manifest-only)" \
    "🔍 Dry-Run Preview                 (scan --dry-run)" \
    "🔙 Return to Main Menu")

  local -a args=()
  case "$mode" in
    "⚡ Full Manifest"*) args=() ;;
    "📜 Manifest Check"*) args=("--manifest-only") ;;
    "🔍 Dry-Run Preview"*) args=("--dry-run") ;;
    *) return 0 ;;
  esac

  local tmp_scan
  tmp_scan=$(mktemp)
  spooky_spin "Scanning render ledger against disk..." "$tmp_scan" "$DISPATCHER" scan "${args[@]}"
  local code=$?

  tail -n 12 "$tmp_scan"
  if gum confirm --prompt.foreground "$COLOR_AMBER" "Inspect full scan audit report in pager?"; then
    gum pager < "$tmp_scan"
  fi
  rm -f "$tmp_scan"
  pause_prompt
}

handle_autopsy() {
  show_banner
  local mode
  mode=$(gum choose --header "Script Autopsy Actions:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚡ Catalog Script Help & Writes    (autopsy)" \
    "🔍 Dry-Run Preview                 (autopsy --dry-run)" \
    "🔙 Return to Main Menu")

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
  gum style --foreground "$COLOR_GREEN" --bold "📋 DIP (Document Improvement Project) Audit"
  echo ""

  local tmp_dip
  tmp_dip=$(mktemp)
  spooky_spin "Auditing documentation coverage and matrix..." "$tmp_dip" "$DISPATCHER" dip
  local code=$?

  tail -n 14 "$tmp_dip"
  if gum confirm --prompt.foreground "$COLOR_AMBER" "Inspect full DIP matrix report in pager?"; then
    gum pager < "$tmp_dip"
  fi
  rm -f "$tmp_dip"
  pause_prompt
}

handle_bump() {
  show_banner
  gum style --foreground "$COLOR_GREEN" --bold "🏷️  Semver Release Version Bump"
  echo ""

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
    "🔙 Return to Main Menu")

  local flag=""
  case "$bump_type" in
    "🔹 Patch"*) flag="--patch" ;;
    "🔸 Minor"*) flag="--minor" ;;
    "🔺 Major"*) flag="--major" ;;
    "✏️  Custom"*)
      local to_ver
      to_ver=$(gum input --placeholder "e.g. 0.9.0" --prompt "Target Version > ")
      [[ -z "$to_ver" ]] && return 0
      flag="--to $to_ver"
      ;;
    *) return 0 ;;
  esac

  if gum confirm --prompt.foreground "$COLOR_AMBER" "Execute version bump ($flag) and record changelog?"; then
    # shellcheck disable=SC2086
    run_with_spin "Recording microrelease update..." "$DISPATCHER" bump $flag
  fi
  pause_prompt
}

handle_release() {
  show_banner
  local current_ver
  current_ver=$(tr -d '[:space:]' < "$ROOT_DIR/bones/config/version" 2>/dev/null || echo "0.8.0")
  current_ver="${current_ver#v}"

  local mode
  mode=$(gum choose --header "Release Packager Actions:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "🔍 Dry-Run Preview        (Simulate packaging and verify allowlists)" \
    "📦 Build Canonical Zip    (Package rotkeeper-$current_ver.zip)" \
    "🔙 Return to Main Menu")

  case "$mode" in
    "🔍 Dry-Run Preview"*)
      run_with_spin "Simulating canonical framework package..." "$DISPATCHER" release "$current_ver" --dry-run
      ;;
    "📦 Build Canonical Zip"*)
      if gum confirm --prompt.foreground "$COLOR_VIOLET" "Package canonical distribution for v$current_ver?"; then
        run_with_spin "Packaging canonical framework zip..." "$DISPATCHER" release "$current_ver"
      fi
      ;;
    *) return 0 ;;
  esac
  pause_prompt
}

handle_test() {
  show_banner
  local mode
  mode=$(gum choose --header "Integration Test Suite Options:" \
    --cursor.foreground "$COLOR_VIOLET" \
    --header.foreground "$COLOR_GREEN" \
    "⚡ Dry-Run Regression Tests       (Instant: checks legacy command regressions)" \
    "🏋️ Full Multi-Layout Test Matrix  (Comprehensive: crypt, busy, sterile fixtures)" \
    "🔙 Return to Main Menu")

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
  spooky_spin "Executing test matrix assertions..." "$tmp_test" "$DISPATCHER" test "${args[@]}"
  local code=$?

  if [[ $code -eq 0 ]]; then
    gum style --foreground "$COLOR_GREEN" --border rounded --border-foreground "$COLOR_GREEN" --padding "0 2" \
      "✓ ALL TEST ASSERTIONS COMPLETED SUCCESSFULLY"
  else
    gum style --foreground "$COLOR_CRIMSON" --border rounded --border-foreground "$COLOR_CRIMSON" --padding "0 2" \
      "❌ TEST ASSERTIONS FAILED (exit code: $code)"
  fi

  echo ""
  tail -n 14 "$tmp_test"

  if gum confirm --prompt.foreground "$COLOR_AMBER" "Scroll full test output in pager?"; then
    gum pager < "$tmp_test"
  fi
  rm -f "$tmp_test"
  pause_prompt
}

# --- Main Event Loop ---

main_menu() {
  while true; do
    show_banner

    local choice
    choice=$(gum choose --header "Select a Ritual or System Audit:" \
      --cursor.foreground "$COLOR_VIOLET" \
      --header.foreground "$COLOR_GREEN" \
      --item.foreground "$COLOR_WHITE" \
      --selected.foreground "$COLOR_VIOLET" \
      "🔨  Render Site         (Compile markdown into HTML tombs)" \
      "📝  New Tomb            (Interactive tomb scaffold wizard)" \
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
      "🏷️   Version Bump        (Update semver version: patch/minor/major)" \
      "📦  Release Package     (Package canonical framework distribution zip)" \
      "🧪  Test Suite          (Run integration test matrix: dry-run or full)" \
      "🚪  Exit                (Leave the necropolis)")

    case "$choice" in
      "🔨  Render Site"*) handle_render ;;
      "📝  New Tomb"*) handle_new ;;
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
      "🏷️   Version Bump"*) handle_bump ;;
      "📦  Release Package"*) handle_release ;;
      "🧪  Test Suite"*) handle_test ;;
      "🚪  Exit"*|"")
        clear 2>/dev/null || true
        gum style --foreground "$COLOR_SLATE" "The tombs fall silent once more. Until next time."
        echo ""
        exit 0
        ;;
    esac
  done
}

main_menu
