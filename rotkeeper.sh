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
#  Version : 0.3.0
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

set -euo pipefail
IFS=$'\n\t'

VERSION="0.2.6-pre"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BONES="$SCRIPT_DIR/bones/scripts"

trap 'echo "Unexpected error on line $LINENO"; exit 1' ERR

command="${1:-}"
[[ $# -gt 0 ]] && shift || true

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

show_help() {
  cat <<EOF
rotkeeper.sh — Rotkeeper CLI v$VERSION

Usage:
  rotkeeper.sh <command> [options]

Commands:
  init        Initialize environment (reseed + assets + render)
                --force    Force rebuild of all files

  render      Convert markdown files into HTML tombs

  pack        Archive rendered HTML into a timestamped tarball

  scan        Verify manifest entries against actual files

  assets      Generate asset manifest (home/assets → bones/asset-manifest.yaml)

  index       Build HTML index and Markdown binder from output/

  sitemap     Build sitemap_pipeline.yaml, nav_partial.html, and generated index pages

  book        Generate documentation outputs
                --scriptbook-full   Generate rotkeeper-scriptbook-full.md
                --docbook           Generate rotkeeper-docbook.md
                --docbook-clean     Generate collapse-friendly docbook variant
                --configbook        Generate rotkeeper-configbook.md
                --collapse          Convert reports into collapsed-content.yaml
                --all               Run all binding rituals

  verify      Check all assets match recorded SHA256 values

  meta        Extract frontmatter YAML from content tombs

  cleanup     Backup and prune bones/ archives and logs
                --days N   Set retention window in days (default: 30)

  reseed      Unpack a .tar.gz archive or resurrect from a bound markdown file
                <archive>        Use a .tar.gz archive
                --input FILE     Use a scriptbook/docbook/configbook

  status      Display latest render/log/archive/git state summary

  test        Run the full rc-*.sh test suite

  help        Show this help message

  --version, -v
              Display version and exit

Examples:
  rotkeeper.sh init --force
  rotkeeper.sh render
  rotkeeper.sh book --all
  rotkeeper.sh cleanup --days 14
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

  render)
    echo "Rendering tombs..."
    bash "$BONES/rc-render.sh" "$@"
    ;;

  pack)
    echo "Packaging output..."
    bash "$BONES/rc-pack.sh" "$@"
    ;;

  scan)
    echo "Scanning manifest integrity..."
    bash "$BONES/rc-scan.sh" "$@"
    ;;

  assets)
    echo "Generating asset manifest..."
    bash "$BONES/rc-assets.sh" "$@"
    ;;

  index)
    echo "Building output index and binder..."
    bash "$BONES/rc-index.sh" "$@"
    ;;

  sitemap)
    echo "Building sitemap..."
    bash "$BONES/rc-sitemap.sh" "$@"
    ;;

  book)
    echo "Binding documentation reports..."
    bash "$BONES/rc-book.sh" "$@"
    ;;

  verify)
    echo "Verifying asset manifest..."
    bash "$BONES/rc-verify.sh" "$@"
    ;;

  meta)
    echo "Extracting content metadata..."
    bash "$BONES/rc-meta.sh" "$@"
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
    echo "Summoning rotkeeper status..."
    bash "$BONES/rc-status.sh" "$@"
    ;;

  test)
    echo "Running full script test suite..."
    bash "$BONES/rc-test.sh" "$@"
    ;;

  *)
    echo "Unknown command: $command"
    echo ""
    show_help
    exit 1
    ;;

esac
