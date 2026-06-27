#!/usr/bin/env bash
# ============================================================
#  ██████╗  ██████╗ ████████╗██╗  ██╗███████╗███████╗██████╗
#  ██╔══██╗██╔═══██╗╚══██╔══╝██║ ██╔╝██╔════╝██╔════╝██╔══██╗
#  ██████╔╝██║   ██║   ██║   █████╔╝ █████╗  █████╗  ██████╔╝
#  ██╔══██╗██║   ██║   ██║   ██╔═██╗ ██╔══╝  ██╔══╝  ██╔═══╝
#  ██║  ██║╚██████╔╝   ██║   ██║  ██╗███████╗███████╗██║
#  ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rotkeeper.sh
#  Purpose : CLI dispatcher for all Rotkeeper rituals
#  Version : 0.4.0
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

set -euo pipefail
IFS=$'\n\t'

VERSION="0.4.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BONES="$SCRIPT_DIR/bones/scripts"

trap 'echo "Unexpected error on line $LINENO"; exit 1' ERR

command="${1:-}"
if [[ $# -gt 0 ]]; then shift; fi

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

show_help() {
  cat <<EOF
rotkeeper.sh — Rotkeeper CLI v$VERSION

Usage:
  rotkeeper.sh <command> [options]

Quickstart:
  ./rotkeeper.sh init
  ./rotkeeper.sh new my-first-page
  ./rotkeeper.sh render
  ./rotkeeper.sh pack --content

Commands:
  init        Initialize environment (minimal by default)
                --with-sample    Generate sample file
                --with-render    Run the render ritual
                --full           Full initialization (reseed, sample, assets, render, scan)
                --force          Force rebuild of all files

  new <file>  Scaffold a new markdown file with required YAML frontmatter

  render      Convert all markdown files (from home/content/) into HTML tombs (in output/)
              Note: This builds the entire site at once; target files cannot be specified.
              (This also creates a timestamped backup archive in bones/archive/)

  pack        Archive rendered HTML into a versioned tarball with embedded JSON metadata
              (Use pack to create shareable tomb releases; render just creates backups)

  autopsy     Dissect scripts and map outputs

  release     Package the project into 'lite' and 'full' distribution zip files

  smoke       Alias for 'test' — Run the integration test harness

  scan        Verify manifest entries against actual files

  assets      Generate asset manifest (home/assets → bones/asset-manifest.yaml)

  glue        Auto-generate index.md navigation glue for unindexed content directories

  templates   List all available HTML templates in the bones/templates/ directory

  ingest      Unpack and safely merge .tar.gz payloads from messages-from-my-friends/

  sync-inbox  Automate the AI documentation ingestion loop (scan, ingest, dip, render)

  dip         Audit documentation coverage, stub missing files, and whisk obsolete docs.

  book        Generate documentation outputs
                --scriptbook-full   Generate rotkeeper-scriptbook-full.md
                --docbook           Generate rotkeeper-docbook.md
                --docbook-clean     Generate collapse-friendly docbook variant
                --configbook        Generate rotkeeper-configbook.md
                --fsbook            Generate rotkeeper-files.md catalog
                --collapse          Convert reports into collapsed-content.yaml
                --all               Run all binding rituals

  cleanup     Backup and prune bones/ archives and logs
                --days N   Set retention window in days (default: 30)

  reseed      Unpack a .tar.gz archive or resurrect from a bound markdown file
                <archive>        Use a .tar.gz archive
                --input FILE     Use a scriptbook/docbook/configbook

  status      Display latest render/log/archive/git state summary
                --json     Output as minified JSON for agent consumption

  showcase    Generate markdown showcase files for all available HTML templates

  agent-handoff Generate books and package a tombkit for AI delegates

  snapshot    Instantly run render, pack, and scan to freeze the current state

  test        Run the integration test harness against the rotkeeper scripts

  bump        Log a micro-update, bump the version, and commit changes

  help        Show this help message

  --version, -v
              Display version and exit

Examples:
  rotkeeper.sh init --force
  rotkeeper.sh render
  rotkeeper.sh book --all
  rotkeeper.sh cleanup --days 14

Note: The 'bones/' directory is an internal system directory. Do not edit it unless you are familiar with Rotkeeper's internals.
EOF
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

case "$command" in

  --version|-v)
    echo "rotkeeper v$VERSION"
    ;;

  --help|-h|help|"")
    show_help
    ;;

  init)
    echo "Starting full initialization..."
    bash "$BONES/rc-init.sh" --force "$@"
    ;;

  new)
    echo "Scaffolding new file..."
    bash "$BONES/rc-new.sh" "$@"
    ;;

  render)
    echo "Rendering tombs..."
    bash "$BONES/rc-render.sh" "$@"
    ;;

  pack)
    echo "Packaging output..."
    bash "$BONES/rc-pack.sh" "$@"
    ;;

  release)
    echo "Creating release distributions..."
    bash "$BONES/rc-release.sh" "$VERSION" "$@"
    ;;

  smoke)
    echo "Running smoke test..."
    bash "$BONES/rc-test.sh" "$@" || true
    ;;

  scan)
    echo "Scanning manifest integrity..."
    bash "$BONES/rc-scan.sh" "$@"
    ;;

  assets)
    echo "Generating asset manifest..."
    bash "$BONES/rc-assets.sh" "$@"
    ;;

  glue)
    echo "Applying navigation glue to unindexed directories..."
    bash "$BONES/rc-glue.sh" "$@"
    ;;

  ingest)
    echo "Ingesting new messages..."
    bash "$BONES/rc-ingest.sh" "$@"
    ;;

  sync-inbox)
    echo "Running Inbox Autopilot..."
    bash "$BONES/rc-sync-inbox.sh" "$@"
    ;;

  dip)
    echo "Running Document Improvement Project (DIP) audit..."
    bash "$BONES/rc-dip.sh" "$@"
    ;;

  templates)
    echo "🎨 Available Templates:"
    echo "   (Declare your chosen template in your markdown YAML frontmatter)"
    echo "   Example:"
    echo "   ---"
    echo "   template: rotkeeper-blog.html"
    echo "   ---"
    echo ""
    if [[ -d "$SCRIPT_DIR/bones/templates" ]]; then
      for t in "$SCRIPT_DIR/bones/templates"/*.html; do
        [[ -f "$t" ]] && echo "   - $(basename "$t")"
      done
    else
      echo "   No templates found."
    fi
    ;;

  book)
    echo "Binding documentation reports..."
    bash "$BONES/rc-book.sh" "$@"
    ;;

  cleanup)
    echo "Cleaning up bones/..."
    bash "$BONES/rc-cleanup-bones.sh" "$@"
    ;;

  reseed)
    if [[ $# -eq 0 ]]; then
      echo "Missing argument. Usage:"
      echo "  rotkeeper.sh reseed <archive.tar.gz>"
      echo "  rotkeeper.sh reseed --input FILE"
      exit 1
    fi
    echo "Reseeding from archive..."
    bash "$BONES/rc-reseed.sh" "$@"
    ;;

  status)
    bash "$BONES/rc-status.sh" "$@"
    ;;

  showcase)
    echo "Generating showcase files..."
    bash "$BONES/rc-showcase.sh" "$@"
    ;;

  bump)
    echo "Logging microupdate and bumping version..."
    bash "$BONES/rc-bump.sh" "$@"
    ;;

  test)
    echo "Running Rotkeeper test harness..."
    bash "$BONES/rc-test.sh" "$@" || true
    ;;

  agent-handoff)
    echo "Initiating Agent Handoff..."
    bash "$BONES/rc-book.sh" --all
    bash "$BONES/rc-pack.sh" --self
    echo ""
    echo "Tombkit generated. Hand the latest tombkit-*.tar.gz from bones/archive/ to the agent."
    ;;

  snapshot)
    echo "Creating a point-in-time snapshot..."
    bash "$BONES/rc-render.sh" "$@"
    bash "$BONES/rc-pack.sh" "$@"
    bash "$BONES/rc-scan.sh" "$@"
    echo "Snapshot complete."
    ;;

  autopsy)
    echo "Running autopsy audit..."
    bash "$BONES/rc-autopsy.sh" "$@"
    ;;

  *)
    echo "Unknown command: $command"
    echo ""
    show_help
    exit 1
    ;;

esac
