#!/usr/bin/env bash
# install.sh — symlink the gander skill into ~/.agents/skills/ and ~/.claude/skills/.
#
# Run once after cloning or after editing the SKILL.md. Idempotent.
# To uninstall: rm the two symlinks this script prints at the end.

set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/.agents/skills/gander"

if [ ! -d "$SRC" ]; then
  echo "error: skill source not found at $SRC" >&2
  exit 1
fi

mkdir -p "$HOME/.agents/skills" "$HOME/.claude/skills" "$HOME/.cursor/skills"

ln -sfn "$SRC" "$HOME/.agents/skills/gander"
ln -sfn "$SRC" "$HOME/.claude/skills/gander"
ln -sfn "$SRC" "$HOME/.cursor/skills/gander"

echo "Installed gander skill:"
echo "  $HOME/.agents/skills/gander  (Codex + OpenCode)"
echo "  $HOME/.claude/skills/gander  (Claude Code)"
echo "  $HOME/.cursor/skills/gander  (Cursor)"
echo
echo "Symlinked source:"
echo "  $SRC"
echo
echo "Edit SKILL.md or scripts/ in place — the symlinks pick up changes automatically."

if command -v gander >/dev/null 2>&1; then
  if gander mcp install; then
    echo
    echo "gander MCP installed for OpenCode, Claude Code, Cursor, and Codex."
  else
    echo "warning: gander mcp install failed (CLI may be older than comments support)" >&2
  fi
fi