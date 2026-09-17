#!/usr/bin/env bash
# Assert SKILL.md / README share-vs-watch classification: reports static-share,
# plans/RFCs/drafts watch; type labels are additive; no double-gander of a
# dir-watched tree; save-plan always watches.
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

contains "gander share --silent"
contains "gander watch --silent"
contains "share this"
contains "watch this"
contains "gander: watch"
contains "gander: share"
contains "gander: static"
contains "status: draft"
contains "gander: watch"
contains "reports/draft-rfc.md"
contains "Watch-signal beats static"
contains "If unsure, **watch**"
contains "Path segments"
contains "Filename tokens"
contains "Default → watch"
contains "Do **not** pass \`--label plan\` / \`--label report\`"
contains "--label review"
contains "--no-labels"
contains "POST \`labels\` replaces the whole set"
contains "dir-watched tree"
contains "new reports onboard as static shares labeled \`report\`"
contains "plans, RFCs, and drafts stay live-watched"
contains "s=watch"
contains "Plans always watch"

readme_contains "Share vs watch by doc type"
readme_contains "Type labels"
readme_contains "additive"
readme_contains "status: draft"
readme_contains "gander watch --silent"

if grep -q -F "s shares on gander.md" "$SKILL"; then
  echo "post-save s must watch, not static-share" >&2
  fail=1
fi

if grep -q -F 's) gander share' "$ROOT/.agents/skills/gander/scripts/save-plan.sh"; then
  echo "save-plan.sh s must not static-share" >&2
  fail=1
fi

if grep -q -F -- "--label plan" "$SKILL" && grep -q -F "just to stamp type" "$SKILL"; then
  :
else
  echo "must tell agents not to stamp type labels" >&2
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "ok"
