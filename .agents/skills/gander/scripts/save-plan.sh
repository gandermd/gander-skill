#!/usr/bin/env bash
# scripts/save-plan.sh — save agent-produced plan as a markdown file; offer to watch it.
#
# Usage:
#   scripts/save-plan.sh "<plan title>"               # read plan from stdin
#   scripts/save-plan.sh "<plan title>" <file>        # read plan from a file
#   scripts/save-plan.sh --help
#
# Default save location: ./plans/YYYY-MM-DD-<slug>.md (creates ./plans/ if missing).
# Wrapper format:
#     ---
#     status: draft
#     ---
#
#     # <Title>
#
#     > Saved YYYY-MM-DD HH:MM from <source>
#
#     <plan content>
# After saving, prompts: y=preview / s=watch / N=skip
# Piped / non-interactive runs skip the prompt without failing.
# Env: PLAN_DIR (default ./plans), PLAN_SOURCE (default "agent").

set -euo pipefail

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g' \
    | cut -c1-60
}

usage() {
  sed -n '2,23p' "$0"
  exit "${1:-0}"
}

TITLE=""
SRC=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage 0 ;;
    -*) echo "error: unknown flag $1" >&2; usage 2 ;;
    *)
      if [ -z "$TITLE" ]; then TITLE="$1"
      elif [ -z "$SRC" ]; then SRC="$1"
      else echo "error: too many positional args (got '$1')" >&2; usage 2
      fi
      shift ;;
  esac
done

if [ -z "$TITLE" ]; then
  echo "error: title is required" >&2
  usage 2
fi

if [ -n "$SRC" ]; then
  if [ ! -f "$SRC" ]; then
    echo "error: not a file: $SRC" >&2
    exit 1
  fi
  CONTENT=$(cat "$SRC")
else
  CONTENT=$(cat)
fi

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
SLUG=$(slugify "$TITLE")
[ -z "$SLUG" ] && SLUG="plan"

DIR="${PLAN_DIR:-./plans}"
mkdir -p "$DIR"
DEST="$DIR/$DATE-$SLUG.md"
i=2
while [ -e "$DEST" ]; do
  DEST="$DIR/$DATE-$SLUG-$i.md"
  i=$((i+1))
done

SOURCE="${PLAN_SOURCE:-agent}"

{
  printf '%s\n' '---'
  printf '%s\n' 'status: draft'
  printf '%s\n' '---'
  printf '\n'
  printf '# %s\n\n' "$TITLE"
  printf '> Saved %s %s from %s\n\n' "$DATE" "$TIME" "$SOURCE"
  printf '%s\n' "$CONTENT"
} > "$DEST"

echo "saved: $DEST"

ans=""
# Content from a file leaves stdin free for the prompt. Piped plan bodies
# consume stdin — skip instead of hanging or exiting non-zero.
if [ -n "$SRC" ] || [ -t 0 ]; then
  printf 'gander it? [y=preview / s=watch / N=skip] '
  read -r ans || true
fi
case "$ans" in
  y|Y) gander "$DEST" ;;
  s|S) gander watch --silent "$DEST" ;;
  *)   echo "  skipped" ;;
esac
