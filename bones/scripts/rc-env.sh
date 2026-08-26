#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  ███████╗███╗   ██╗██╗   ██╗
#  ██╔════╝████╗  ██║██║   ██║
#  █████╗  ██╔██╗ ██║██║   ██║
#  ██╔══╝  ██║╚██╗██║╚██╗ ██╔╝
#  ███████╗██║ ╚████║ ╚████╔╝
#  ╚══════╝╚═╝  ╚═══╝  ╚═══╝
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-env.sh
#  Purpose : Dynamic Environment Bootstrap — Portability Hardening
#  Version : 0.5.1
# ============================================================
# Env assumptions: reads ARCHIVE_DIR, ASSETS_DIR, BONES_DIR, BOOK_REPORT_DIR, CONFIG_DIR, CONTENT_DIR, DOCS_DIR, HELP_DIR, INPUT_FORMAT, LAYOUT_STYLE, LOG_DIR, META_DIR, OUTPUT_DIR, RELEASE_DIR, RENDER_PROFILE, REPORT_DIR, ROOT_DIR, SCRIPT_DIR, TEMPLATE_DIR, TMP_DIR, WEB_DIR (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.
# CWD assumptions: No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.
# Input/Output contracts: CLI args and env vars in; files and stdout/stderr out; respects --dry-run (no writes) and --verbose.


[[ -n "$BASH_VERSION" ]] || {
  echo "[ERROR] rc-env.sh must be sourced in Bash." >&2
  return 1 2>/dev/null || exit 1
}

# Idempotency guard: prevent duplicate evaluation and variable reset, unless forced.
# We also ensure that if the script is run in a different ROOT_DIR context (like in test subshells), it correctly reloads.
current_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ "${ROTKEEPER_ENV_LOADED:-false}" == "true" && "${FORCE_ENV_RELOAD:-false}" != "true" && "${ROOT_DIR:-}" == "$current_root" && -n "${CONFIG_DIR:-}" && -n "${BONES_DIR:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
export ROTKEEPER_ENV_LOADED="true"

# Core structural bounds
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BONES_DIR="$ROOT_DIR/bones"
SCRIPT_DIR="$BONES_DIR/scripts"
CONFIG_DIR="$BONES_DIR/config"
LOG_DIR="$BONES_DIR/logs"
TMP_DIR="$BONES_DIR/tmp"
ARCHIVE_DIR="$BONES_DIR/archive"
RELEASE_DIR="$ARCHIVE_DIR/releases"
REPORT_DIR="$BONES_DIR/reports"
BOOK_REPORT_DIR="$BONES_DIR/book-reports"
META_DIR="$BONES_DIR/meta"

# Dynamic layout parsing before fixing layout-dependent constants
# Looks at bones/config/rotkeeper.yaml first, drops back to root file for flat dist models
CONFIG_TARGET="$CONFIG_DIR/rotkeeper.yaml"
[[ ! -f "$CONFIG_TARGET" && -f "$ROOT_DIR/config/rotkeeper.yaml" ]] && CONFIG_TARGET="$ROOT_DIR/config/rotkeeper.yaml"

# 2. Check for an existing, uncorrupted paths block
HAS_PATHS=false
if [[ -f "$CONFIG_TARGET" ]]; then
    HAS_PATHS=$(yq eval 'has("paths")' "$CONFIG_TARGET" 2>/dev/null || echo "false")

    # RELOCATION HARDENING: Auto-invalidate cache if the repository has been moved
    if [[ "$HAS_PATHS" == "true" ]]; then
        SAVED_ROOT=$(yq eval '.paths.ROOT_DIR' "$CONFIG_TARGET" 2>/dev/null || echo "")
        if [[ "$SAVED_ROOT" != "$ROOT_DIR" ]]; then
            echo "[WARN] Environment relocation detected. Invalidating path cache." >&2
            HAS_PATHS=false
        fi
    fi
fi

# 3. Optimized layout loading pass
if [[ "$HAS_PATHS" == "true" ]]; then
    # Parse the entire key/value block instantly in a single shell loop sweep
    while IFS='=' read -r key val; do
        [[ -z "$key" ]] && continue
        clean_val=$(echo "$val" | sed -E 's/^"//; s/"$//')
        export "$key"="$clean_val"
    done < <(yq eval '.paths | to_entries | .[] | .key + "=" + .value' "$CONFIG_TARGET" 2>/dev/null || true)
else
    # Fallback to standard manual calculations if configuration paths are unseeded
    LAYOUT_STYLE="crypt"
    if [[ -f "$CONFIG_TARGET" ]]; then
      LAYOUT_STYLE=$(grep -E '^layout_style:' "$CONFIG_TARGET" | cut -d'"' -f2 || echo "crypt")
    fi

    case "${LAYOUT_STYLE,,}" in
      "busy")
        TEMPLATE_DIR="$ROOT_DIR/templates"
        ASSETS_DIR="$ROOT_DIR/assets"
        CONTENT_DIR="$ROOT_DIR/home/content"
        OUTPUT_DIR="$ROOT_DIR/output"
        ;;
      "sterile")
        TEMPLATE_DIR="$ROOT_DIR/config/templates"
        ASSETS_DIR="$ROOT_DIR/src/assets"
        CONTENT_DIR="$ROOT_DIR/src/content"
        OUTPUT_DIR="$ROOT_DIR/dist"
        ;;
      "crypt"|*)
        TEMPLATE_DIR="$BONES_DIR/templates"
        ASSETS_DIR="$ROOT_DIR/home/assets"
        CONTENT_DIR="$ROOT_DIR/home/content"
        OUTPUT_DIR="$ROOT_DIR/output"
        ;;
    esac

    DOCS_DIR="$CONTENT_DIR/docs"
    HELP_DIR="$CONTENT_DIR/help"
    WEB_DIR="$OUTPUT_DIR"
fi

# Source format toggle: markdown (default), textile, or cooklang. Oliver's
# CLI gates all three (`oliver render --from <markdown|textile|cooklang>`);
# the adapter and preflight pass this value through on every invocation.
INPUT_FORMAT="markdown"
if [[ -f "$CONFIG_TARGET" ]]; then
    INPUT_FORMAT=$(yq eval '.input_format // "markdown"' "$CONFIG_TARGET" 2>/dev/null | tr -d '\n' || echo "markdown")
fi
case "${INPUT_FORMAT,,}" in
    markdown|textile|cooklang) ;;
    *)
        echo "[WARN] Unsupported input_format '$INPUT_FORMAT' in config; falling back to 'markdown'." >&2
        INPUT_FORMAT="markdown"
        ;;
esac

# Output profile toggle: html (default) or xhtml. Oliver's CLI gates both
# (`oliver render --to <html|xhtml>`); the adapter appends `--to xhtml` only
# when the profile is xhtml, so the default invocation stays byte-identical.
RENDER_PROFILE="html"
if [[ -f "$CONFIG_TARGET" ]]; then
    RENDER_PROFILE=$(yq eval '.render_profile // "html"' "$CONFIG_TARGET" 2>/dev/null | tr -d '\n' || echo "html")
fi
case "${RENDER_PROFILE,,}" in
    html|xhtml) ;;
    *)
        echo "[WARN] Unsupported render_profile '$RENDER_PROFILE' in config; falling back to 'html'." >&2
        RENDER_PROFILE="html"
        ;;
esac

export ROOT_DIR BONES_DIR OUTPUT_DIR CONTENT_DIR ASSETS_DIR DOCS_DIR HELP_DIR
export LOG_DIR TMP_DIR CONFIG_DIR ARCHIVE_DIR RELEASE_DIR REPORT_DIR BOOK_REPORT_DIR SCRIPT_DIR TEMPLATE_DIR META_DIR

export WEB_DIR LAYOUT_STYLE INPUT_FORMAT RENDER_PROFILE
