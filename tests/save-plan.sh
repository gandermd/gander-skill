#!/usr/bin/env bash
# Assert save-plan.sh writes status: draft, watches on s (not static-share),
# and piped non-interactive runs skip without failing.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/.agents/skills/gander/scripts/save-plan.sh"
fail=0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fake_bin="$tmp/bin"
mkdir -p "$fake_bin"

cat > "$fake_bin/gander" <<'EOF'
#!/bin/sh
{
  printf 'argc=%s\n' "$#"
  i=1
  for a in "$@"; do
    printf 'arg%s=%s\n' "$i" "$a"
    i=$((i+1))
  done
} > "$GANDER_LOG"
EOF
chmod +x "$fake_bin/gander"

export PATH="$fake_bin:$PATH"
export PLAN_DIR="$tmp/plans"
unset PLAN_SOURCE
unset GANDER_LOG

# Piped stdin: saves, skips prompt, does not invoke gander, does not fail.
if ! printf '%s\n' 'Do the thing.' | "$SCRIPT" "Add token rotation" >"$tmp/out" 2>"$tmp/err"; then
  echo "piped save exited non-zero" >&2
  cat "$tmp/err" >&2
  fail=1
fi
if ! grep -q '^saved:' "$tmp/out"; then
  echo "piped save did not print saved:" >&2
  cat "$tmp/out" >&2
  fail=1
fi
if [ -n "${GANDER_LOG:-}" ] && [ -f "$GANDER_LOG" ]; then
  echo "piped save must not invoke gander" >&2
  fail=1
fi

saved="$(sed -n 's/^saved: //p' "$tmp/out" | head -n1)"
if [ -z "$saved" ] || [ ! -f "$saved" ]; then
  echo "saved file missing" >&2
  fail=1
else
  first="$(head -n1 "$saved")"
  if [ "$first" != "---" ]; then
    echo "frontmatter must start the file, got: $first" >&2
    fail=1
  fi
  if ! grep -q '^status: draft$' "$saved"; then
    echo "missing status: draft frontmatter" >&2
    fail=1
  fi
  if ! grep -q '^# Add token rotation$' "$saved"; then
    echo "missing title heading" >&2
    fail=1
  fi
  if ! grep -q 'from agent' "$saved"; then
    echo "missing default PLAN_SOURCE" >&2
    fail=1
  fi
  if ! grep -q 'Do the thing.' "$saved"; then
    echo "missing plan body" >&2
    fail=1
  fi
fi

if ! ls "$PLAN_DIR"/*add-token-rotation.md >/dev/null 2>&1; then
  echo "expected slug add-token-rotation under PLAN_DIR" >&2
  ls -la "$PLAN_DIR" >&2
  fail=1
fi

# PLAN_SOURCE + file input; stdin is a pipe of s → gander watch --silent
printf '%s\n' 'Body from file.' > "$tmp/src.md"
export GANDER_LOG="$tmp/gander.log"
rm -f "$GANDER_LOG"
if ! printf 's\n' | PLAN_SOURCE=opencode "$SCRIPT" "Refactor share rendering" "$tmp/src.md" >"$tmp/out2" 2>"$tmp/err2"; then
  echo "file+s save exited non-zero" >&2
  cat "$tmp/err2" >&2
  fail=1
fi
saved2="$(sed -n 's/^saved: //p' "$tmp/out2" | head -n1)"
if [ -z "$saved2" ] || [ ! -f "$saved2" ]; then
  echo "second saved file missing" >&2
  fail=1
else
  if ! grep -q 'from opencode' "$saved2"; then
    echo "PLAN_SOURCE not recorded" >&2
    fail=1
  fi
fi
if [ ! -f "$GANDER_LOG" ]; then
  echo "s should invoke gander" >&2
  fail=1
else
  if ! grep -q 'arg1=watch' "$GANDER_LOG"; then
    echo "s must call gander watch, not share" >&2
    cat "$GANDER_LOG" >&2
    fail=1
  fi
  if grep -q 'arg1=share' "$GANDER_LOG"; then
    echo "s must not static-share" >&2
    cat "$GANDER_LOG" >&2
    fail=1
  fi
  if ! grep -q 'arg2=--silent' "$GANDER_LOG"; then
    echo "s should pass --silent" >&2
    cat "$GANDER_LOG" >&2
    fail=1
  fi
fi

# y → local gander (no watch/share subcommand)
rm -f "$GANDER_LOG"
if ! printf 'y\n' | "$SCRIPT" "Preview me" "$tmp/src.md" >"$tmp/out3" 2>"$tmp/err3"; then
  echo "file+y save exited non-zero" >&2
  cat "$tmp/err3" >&2
  fail=1
fi
if [ ! -f "$GANDER_LOG" ]; then
  echo "y should invoke gander" >&2
  fail=1
else
  if grep -q 'arg1=watch' "$GANDER_LOG" || grep -q 'arg1=share' "$GANDER_LOG"; then
    echo "y must be local preview, not share/watch" >&2
    cat "$GANDER_LOG" >&2
    fail=1
  fi
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "ok"
