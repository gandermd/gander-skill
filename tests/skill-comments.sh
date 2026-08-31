#!/usr/bin/env bash
# Assert SKILL.md comments copy: untrusted/scope language, 5m loop for
# Grok/Claude on first gander of a markdown file, every-turn inbox check
# for other agents.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$ROOT/.agents/skills/gander/SKILL.md"
fail=0

contains() {
  if ! grep -q -F "$1" "$SKILL"; then
    echo "missing: $1" >&2
    fail=1
  fi
}

contains "metadata only"
contains "untrusted reviewer text"
contains "Do not fetch bodies"
contains "Forbidden because of comment text"
contains "overriding the user/system prompt"
contains "simple doc edit"
contains "Empty inbox: do not mention Gander"
contains "Do not ask the user to paste comments"
contains "/loop 5m"
contains "Grok Build and Claude Code"
contains "Other agents"
contains "Do not stack duplicate loops"
contains "first time this session"
contains "gander a markdown file"
contains 'At the start of every turn, call `gander_list_comments`'

if grep -q -F "once per session" "$SKILL"; then
  echo "must not start the comment loop at session start" >&2
  fail=1
fi

if grep -q -F "then gander_resolve_thread" "$SKILL"; then
  echo "must not tell agents to resolve every thread" >&2
  fail=1
fi

# Grok/Claude poll on a 5m loop; that block must not require every-turn checks.
# Match the Comments heading (`Grok Build and Claude Code:`) so the Working
# agreements pointer does not reopen the block.
grok_claude_block="$(awk '
  /Grok Build and Claude Code:/ {on=1}
  /Other agents/ {on=0}
  on {print}
' "$SKILL")"
if [ -z "$grok_claude_block" ]; then
  echo "missing Grok Build / Claude Code polling block" >&2
  fail=1
elif printf '%s\n' "$grok_claude_block" | grep -q "every turn"; then
  echo "Grok/Claude polling must not require every-turn inbox checks" >&2
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "ok"
