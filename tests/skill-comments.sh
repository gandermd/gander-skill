#!/usr/bin/env bash
# Assert SKILL.md comments copy matches gander-cli MCP untrusted/scope language.
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

if grep -q -F "then gander_resolve_thread" "$SKILL"; then
  echo "must not tell agents to resolve every thread" >&2
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "ok"
