#!/usr/bin/env bash
# Assert SKILL.md directory-watch copy: ask once per dir, not per file;
# check gander status; never silent auto-watch; CLI is the product path.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$ROOT/.agents/skills/gander/SKILL.md"
README="$ROOT/README.md"
fail=0

contains() {
  if ! grep -q -F -- "$1" "$SKILL"; then
    echo "missing: $1" >&2
    fail=1
  fi
}

readme_contains() {
  if ! grep -q -F -- "$1" "$README"; then
    echo "README missing: $1" >&2
    fail=1
  fi
}

contains "track this folder"
contains "watch my notes dir"
contains "gander status"
contains "I created \`<dir>\` and will be adding markdown there. Want Gander to auto-share new \`.md\` files under it (including subfolders) as they appear?"
contains "gander watch <abs-dir>"
contains "gander --watch <abs-dir>"
contains "remember declined for this session"
contains "Already watching"
contains "Do **not** ask on every subsequent"
contains "Never run \`gander watch <dir>\` unless the user said yes"
contains "Never silent auto-watch"
contains "Ask once per directory, not per file"
contains "Directory-adopted files never open a browser"
contains "gander stop <abs-dir>"
contains "stops adoption only"
contains "--existing"
contains "--no-recursive"
contains "--glob"
contains "**/*.md"
contains "--yes"
contains "comment-poll window"
contains "plans/"
contains "reports/"
contains ".git"
contains "node_modules"
contains "scripts/watch-markdown.sh"
contains "not a second fswatch daemon"

readme_contains "gander watch <dir>"
readme_contains "gander --watch <dir>"
readme_contains "gander status"
readme_contains "gander stop"

if grep -q -F "New markdown:" "$SKILL"; then
  echo "must not keep the per-file watcher prompt as the product path" >&2
  fail=1
fi

if grep -q -F "brew install fswatch" "$SKILL"; then
  echo "must not require fswatch as the product path" >&2
  fail=1
fi

if grep -q -F "inotifywait" "$SKILL"; then
  echo "must not require inotifywait as the product path" >&2
  fail=1
fi

if grep -q -F "prompt (preview / hosted watch / skip)" "$README"; then
  echo "README must not describe directory watch as a per-file prompt" >&2
  fail=1
fi

if grep -q -F "plus \`fswatch\`" "$README"; then
  echo "README must not require fswatch" >&2
  fail=1
fi

ask_hits="$(grep -c -F "Want Gander to auto-share new" "$SKILL" || true)"
if [ "$ask_hits" -ne 1 ]; then
  echo "ask text must appear once, got $ask_hits" >&2
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "ok"
