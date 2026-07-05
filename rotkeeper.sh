#!/usr/bin/env bash
# ============================================================
#  ██████╗  ██████╗ ████████╗██╗  ██╗███████╗███████╗██████╗
#  ██╔══██╗██╔═══██╗╚══██╔══╝██║ ██╔╝██╔════╝██╔════╝██╔══██╗
#  ██████╔╝██║   ██║   ██║   █████╔╝ █████╗  █████╗  ██████╔╝
#  ██╔══██╗██║   ██║   ██║   ██╔═██╗ ██╔══╝  ██╔══╝  ██╔═══╝
#  ██║  ██║╚██████╔╝   ██║   ██║  ██╗███████╗███████╗██║
#  ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝
# ============================================================
# ============================================================
#  Project : Rotkeeper
#  Script  : rotkeeper.sh
#  Purpose : CLI dispatcher for all active Rotkeeper rituals
#  Version : 0.4.0.3
#  Updated : 2026-07-02
# ============================================================

set -euo pipefail
IFS=$'\n\t'

VERSION="0.4.0.3"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BONES="$SCRIPT_DIR/bones/scripts"

trap 'echo "Unexpected error on line $LINENO"; exit 1' ERR

command="${1:-}"
if [[ $# -gt 0 ]]; then shift; fi

show_help() {
  cat <<EOF
rotkeeper.sh — Rotkeeper CLI v$VERSION

Usage:
  rotkeeper.sh <command> [options]

Quickstart:
  ./rotkeeper.sh init
  ./rotkeeper.sh new my-first-page
  ./rotkeeper.sh render

Commands:
  showcase    Generate markdown showcase files for all available HTML templates
  init        Initialize environment (minimal by default)
                --with-sample    Generate sample file
                --with-render    Run the render ritual
                --full           Full initialization (sample, assets, render, scan)
                --force          Force rebuild of all files

  new <file>  Scaffold a new markdown file with required YAML frontmatter

  render      Convert all markdown files (from home/content/) into HTML tombs (in output/)
              Note: This builds the entire site at once; target files cannot be specified.

  release     Package the project into 'lite' and 'full' distribution zip files

  smoke       Alias for 'test' — Run the integration test harness

  scan        Verify manifest entries against actual files

  assets      Generate asset manifest (home/assets → bones/asset-manifest.yaml)

  glue        Auto-generate index.md navigation glue for unindexed content directories

  templates   List all available HTML templates in the bones/templates/ directory

  dip         Audit documentation coverage, stub missing files, and whisk obsolete docs.

  book        Generate documentation outputs
                --scriptbook-full   Generate rotkeeper-scriptbook-full.md
                --docbook           Generate rotkeeper-docbook.md
                --docbook-clean     Generate collapse-friendly docbook variant
                --configbook        Generate rotkeeper-configbook.md
                --fsbook            Generate rotkeeper-files.md catalog
                --collapse          Convert reports into collapsed-content.yaml
                --all               Run all binding rituals

  status      Display latest render/log/archive/git state summary
                --json     Output as minified JSON for agent consumption

  test        Run the integration test harness against the rotkeeper scripts

  bump        Log a micro-update, bump the version, and commit changes

  help        Show this help message

  --version, -v
              Display version and exit

Examples:
  rotkeeper.sh init --force
  rotkeeper.sh render
  rotkeeper.sh book --all
EOF
}

case "$command" in
  showcase)
    echo "Generating showcase files..."
    bash "$BONES/rc-showcase.sh" "$@"
    ;;

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

  status)
    bash "$BONES/rc-status.sh" "$@"
    ;;

  bump)
    echo "Logging microupdate and bumping version..."
    bash "$BONES/rc-bump.sh" "$@"
    ;;

  test)
    echo "Running Rotkeeper test harness..."
    bash "$BONES/rc-test.sh" "$@" || true
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