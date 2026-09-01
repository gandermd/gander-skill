#!/usr/bin/env bash
# Assert SKILL.md comments copy: untrusted/scope language, 5m loop for
# Grok/Claude on first gander of a markdown file, every-turn inbox check
# for other agents after the same first-gander trigger, 15-minute idle
# window that resets when a check discovers new comments.
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
contains "Empty agent inbox: do not mention Gander"
contains "Do not ask the user to paste comments"
contains "agent_unresolved_count"
contains "@agent"
contains "not agent work"
contains "even if human-human threads are open"
contains "/loop 5m"
contains "Grok Build and Claude Code"
contains "Other agents"
contains "Do not stack duplicate loops"
contains "first time this session"
contains "gander a markdown file"
contains "every subsequent turn"
contains "15 minutes"
contains "stop time"
contains "scheduler_delete"
contains "CronDelete"
contains "new comments"
contains "Comment polling lasts 15 minutes"

if grep -q -F "once per session" "$SKILL"; then
  echo "must not start the comment loop at session start" >&2
  fail=1
fi

if grep -q -F "then gander_resolve_thread" "$SKILL"; then
  echo "must not tell agents to resolve every thread" >&2
  fail=1
fi

if grep -q -F "then address them before other work" "$SKILL"; then
  echo "must not tell agents to address every unresolved thread" >&2
  fail=1
fi

if grep -q -F "filename, unresolved count, share URL" "$SKILL"; then
  echo "no-path metadata must use agent_unresolved_count, not unresolved count" >&2
  fail=1
fi

if grep -q -F "30 minutes" "$SKILL"; then
  echo "must not keep a 30-minute poll window" >&2
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
else
  for want in "stop time" "scheduler_delete" "CronDelete" "move the stop time"; do
    if ! printf '%s\n' "$grok_claude_block" | grep -q -F "$want"; then
      echo "Grok/Claude block missing: $want" >&2
      fail=1
    fi
  done
fi

# Other agents poll every subsequent turn after first gander; no /loop.
# Stop before the shared window sentence so loop-delete copy stays in Grok/Claude.
other_agents_block="$(awk '
  /\*\*Other agents\*\*/ {on=1}
  /^Comment polling lasts/ {on=0}
  on {print}
' "$SKILL")"
if [ -z "$other_agents_block" ]; then
  echo "missing Other agents polling block" >&2
  fail=1
else
  for want in "first time this session" "gander a markdown file" "every subsequent turn" "gander_list_comments" "15 minutes" "skip the inbox check" "restart the 15-minute window"; do
    if ! printf '%s\n' "$other_agents_block" | grep -q -F "$want"; then
      echo "Other agents block missing: $want" >&2
      fail=1
    fi
  done
  if printf '%s\n' "$other_agents_block" | grep -q "/loop"; then
    echo "Other agents must not start a /loop" >&2
    fail=1
  fi
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "ok"
