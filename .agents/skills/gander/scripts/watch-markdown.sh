#!/usr/bin/env bash
# scripts/watch-markdown.sh — wrap `gander watch <dir>` (or `gander --watch <dir>`).
#
# Deprecated as a product path: prefer the CLI. The runner persists; this
# script does not start a second fswatch daemon.
#
# Usage:
#   scripts/watch-markdown.sh                       # watch cwd via CLI
#   scripts/watch-markdown.sh ~/projects/notes      # watch a specific directory
#   scripts/watch-markdown.sh ~/notes --share       # hosted watch (requires signup)
#   scripts/watch-markdown.sh ~/notes --existing    # also onboard unmatched .md
#   scripts/watch-markdown.sh ~/notes --no-recursive
#   scripts/watch-markdown.sh ~/notes --glob 'daily-*.md'
#   scripts/watch-markdown.sh --stop ~/notes        # gander stop (adoption only)
#   scripts/watch-markdown.sh --help

set -euo pipefail

SHARE=0
STOP=0
BACKGROUND=0
DIR=""
EXTRA=()

usage() {
  sed -n '2,16p' "$0"
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --share)         SHARE=1; shift ;;
    --existing)      EXTRA+=(--existing); shift ;;
    --no-recursive)  EXTRA+=(--no-recursive); shift ;;
    --yes)           EXTRA+=(--yes); shift ;;
    --glob)
      if [ $# -lt 2 ]; then
        echo "error: --glob requires a pattern" >&2
        usage 2
      fi
      EXTRA+=(--glob "$2")
      shift 2
      ;;
    --glob=*)        EXTRA+=("$1"); shift ;;
    --background|-b) BACKGROUND=1; shift ;;
    --stop)          STOP=1; shift ;;
    -h|--help)       usage 0 ;;
    -*) echo "error: unknown flag $1" >&2; usage 2 ;;
    *)
      if [ -z "$DIR" ]; then DIR="$1"; shift
      else echo "error: too many positional args (got '$1')" >&2; usage 2
      fi
      ;;
  esac
done

if ! command -v gander >/dev/null 2>&1; then
  echo "error: gander CLI not found in PATH" >&2
  echo "install: brew tap gandermd/gander && brew install gander" >&2
  echo "     or: curl -fsSL https://raw.githubusercontent.com/gandermd/gander-cli/main/install.sh | bash" >&2
  exit 1
fi

config_path() {
  if [ -n "${GANDER_CONFIG:-}" ]; then
    printf '%s\n' "${HOME}/.gander.${GANDER_CONFIG}/config.json"
  else
    printf '%s\n' "${HOME}/.gander/config.json"
  fi
}

signed_up() {
  local cfg
  cfg="$(config_path)"
  [ -f "$cfg" ] && grep -Eq '"api_token":[[:space:]]*"[^[:space:]"]+"' "$cfg"
}

if [ "$STOP" = 1 ]; then
  if [ -z "$DIR" ]; then
    echo "error: --stop requires a directory (gander stop <abs-dir>)" >&2
    usage 2
  fi
  if [ ! -d "$DIR" ]; then
    echo "error: not a directory: $DIR" >&2
    exit 1
  fi
  DIR="$(cd "$DIR" && pwd)"
  exec gander stop "$DIR"
fi

DIR="${DIR:-$(pwd)}"
if [ ! -d "$DIR" ]; then
  echo "error: not a directory: $DIR" >&2
  exit 1
fi
DIR="$(cd "$DIR" && pwd)"

if [ "$BACKGROUND" = 1 ]; then
  echo "note: the gander runner persists; --background is a no-op" >&2
fi

echo "note: prefer \`gander watch <dir>\` (or \`gander --watch <dir>\` if not signed up). This script wraps the CLI." >&2

if [ "$SHARE" = 1 ] || signed_up; then
  if [ ${#EXTRA[@]} -gt 0 ]; then
    exec gander watch "${EXTRA[@]}" "$DIR"
  fi
  exec gander watch "$DIR"
fi
if [ ${#EXTRA[@]} -gt 0 ]; then
  exec gander --watch "${EXTRA[@]}" "$DIR"
fi
exec gander --watch "$DIR"
