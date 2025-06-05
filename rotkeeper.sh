#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rotkeeper.sh
# Purpose: CLI dispatcher for all Rotkeeper rituals
# Version: 0.2.1
# Updated: 2025-05-29
# -----------------------------------------

# --- LOGGING SETUP ---
# (Optional) Redirect stdout/stderr to a Rotkeeper log file:
# LOGFILE="bones/logs/rotkeeper-$(date +%Y%m%d_%H%M%S).log"
# exec > >(tee -a "$LOGFILE") 2>&1

# --- ERROR TRAP ---
# Catch any unexpected errors and report the line number.
# trap 'echo "🚨 Unexpected error on line $LINENO"; exit 1' ERR

# Update this VERSION string with each release of rotkeeper.sh!
VERSION="0.2.1"
#
#
# Workflow overview:
# 1. Initialize environment:
#    There once was a setup so grand,
#    Directories rose on command.
#    With init in its core,
#    It prepared every door,
#    So rotkeeper’s rites wouldn’t unhand.
#    - Run rc-init.sh to set up directories, stub files, and initial render.
# 2. Expand content:
#    The expander would merrily grow,
#    Markdown rooms all in a row.
#    From BOM it would feed,
#    Each skeleton seed,
#    And fill them with text in a show.
#    - Execute rc-expand.sh to generate markdown tombdocs, config stubs, templates skeletons, and assets.
# 3. Render content:
#    A renderer fine took the stage,
#    Converting each tomb-page with sage.
#    With pandoc’s design,
#    It formed HTML fine,
#    From Markdown’s austere little cage.
#    - Invoke rc-render.sh to convert markdown files into HTML tombs.
# 4. Package output:
#    Then packer would tar every file,
#    With timestamp and manifest style.
#    A tomb in a tar,
#    Ready for war,
#    It archived each artifact’s dial.
#    - Call rc-pack.sh to archive rendered HTML into timestamped tarball and update manifest.
# 5. Audit and verify:
#    An auditor keen did inspect,
#    Every entry the manifest checked.
#    No missing remains,
#    No phantom domains,
#    Each file by its path was correct.
#    - Use rc-scan.sh to check manifest entries against actual files.
# 6. Asset manifest:
#    Assets were gathered in YAML lines,
#    From icons to fonts in confines.
#    The manifest grew,
#    With paths that were true,
#    A record of all design signs.
#    - Execute rc-assets.sh to catalog home/assets into bones/asset-manifest.yaml.
# 8. Help and usage:
#    And help was a guide in the dark,
#    A beacon, a bright little spark.
#    With usage in hand,
#    You’d summon the band,
#    To perform any command or mark.
#    - Display usage message for available commands.
## Usage:
#   rotkeeper.sh {init|render|pack|scan|assets|help}

# --- ENTRY CHECK ---
# Capture the subcommand or default to empty.

command=${1:-}
shift || true
# Delegate help flags to the subcommand
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
  exec "./bones/scripts/rc-${command}.sh" "--help"
  exit 0
fi

# --- PREREQUISITES CHECK ---
# Ensure required tools are installed: yq, pandoc, sha256sum, jq, etc.

if [[ "$command" == "--version" ]] || [[ "$command" == "-v" ]]; then
  echo "rotkeeper v$VERSION"
  exit 0
fi
if [[ "$command" == "init" ]]; then
  echo "🔄 Starting full initialization..."
  # Force expand and render in one step
  bash ./bones/scripts/rc-init.sh --force
  exit 0
fi
# === INIT SECTION START ===
 # --- INIT SECTION ---
 # Initialize the Rotkeeper environment: directories, stub files, and initial render.
# === INIT SECTION END ===


 # --- RENDER SECTION ---
 # Convert generated markdown into HTML tomb pages using Pandoc.
# === RENDER SECTION START ===
if [[ "$command" == "render" ]]; then
  echo "🖋 Rendering tombs..."
  bash ./bones/scripts/rc-render.sh
  exit 0
fi
# === RENDER SECTION END ===

 # --- PACK SECTION ---
 # Bundle the rendered tomb pages into a timestamped tarball and update manifest.
# === PACK SECTION START ===
if [[ "$command" == "pack" ]]; then
  echo "📦 Packaging output..."
  bash ./bones/scripts/rc-pack.sh
  exit 0
fi
# === PACK SECTION END ===

 # --- SCAN SECTION ---
 # Audit file integrity: compare manifest entries against disk contents.
# === SCAN SECTION START ===
if [[ "$command" == "scan" ]]; then
  echo "🔍 Scanning manifest integrity..."
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  bash "$SCRIPT_DIR/bones/scripts/rc-scan.sh" && exit 0
fi
# === SCAN SECTION END ===

 # --- ASSETS SECTION ---
 # Catalog static assets into the YAML asset manifest.
# === ASSETS SECTION START ===
if [[ "$command" == "assets" ]]; then
  echo "🗂 Generating asset manifest..."
  bash ./bones/scripts/rc-assets.sh
  exit 0
fi
# === ASSETS SECTION END ===



# === BOOK SECTION START ===
if [[ "$command" == "book" ]]; then
  echo "📚 Binding documentation reports..."
  bash ./bones/scripts/rc-book.sh "$@"
  exit 0
fi
# === BOOK SECTION END ===

# === VERIFY SECTION START ===
if [[ "$command" == "verify" ]]; then
  echo "🔍 Verifying asset manifest..."
  bash ./bones/scripts/rc-verify.sh
  exit 0
fi
# === VERIFY SECTION END ===

# === RESEED SECTION START ===
if [[ "$command" == "reseed" ]]; then
  if [[ -z "${2:-}" ]]; then
    echo "❌ Missing archive path. Usage:"
    echo "   rotkeeper.sh reseed <archive.tar.gz>"
    exit 1
  fi
  echo "🪦 Unpacking tomb archive..."
  bash ./bones/scripts/rc-reseed.sh "$2"
  exit 0
fi
# === RESEED SECTION END ===

# === STATUS SECTION START ===
if [[ "$command" == "status" ]]; then
  echo "🩺 Summoning rotkeeper status..."
  bash ./bones/scripts/rc-status.sh
  exit 0
fi
# === STATUS SECTION END ===

# === TEST SECTION START ===
if [[ "$command" == "test" ]]; then
  echo "🧪 Running full script test suite..."
  bash ./bones/scripts/rc-test.sh
  exit 0
fi
# === TEST SECTION END ===

 # --- HELP SECTION ---
 # Display usage information and list available commands.
# === HELP SECTION START ===
show_help() {
  cat << EOF
rotkeeper.sh — Rotkeeper CLI v$VERSION

Usage:
  rotkeeper.sh <command> [options]

Commands:
  init       Initialize everything (expand + render)
    --force      Force rebuild of all files

  render     Convert markdown files into HTML tombs

  pack       Archive rendered HTML into a timestamped tarball

  scan       Verify manifest entries against actual files

  assets     Generate asset manifest from home/assets into bones/asset-manifest.yaml


  book       Generate documentation outputs (scriptbook, docbook, webbook)
    --scriptbook     Generate rotkeeper-scriptbook.md
    --docbook        Generate rotkeeper-docbook.md
    --docbook-clean  Generate a collapse-friendly docbook variant
    --webbook        Generate rotkeeper-webbook.md
    --collapse       Convert reports into collapsed-content.yaml
    --all            Run all binding rituals

  verify     Check all assets match recorded SHA256 values

  reseed     Unpack archive and rehydrate tomb into working directory

  status     Display latest render/log/archive/git state summary

  test       Run the full rc-*.sh test suite and report results

  help       Show this help message

  --version, -v
             Display version and exit

Examples:
  rotkeeper.sh init --force
  rotkeeper.sh render
  rotkeeper.sh pack

EOF
}

if [[ "$command" == "help" ]] || [[ -z "$command" ]]; then
  show_help
  exit 0
fi
# === HELP SECTION END ===

# --- INVALID COMMAND HANDLER ---
# Handle any unrecognized subcommands.
echo "❌ Unknown command: $command"
show_help
exit 1
