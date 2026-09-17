#!/usr/bin/env bash
# Assert scripts/watch-markdown.sh wraps the CLI and does not start fswatch.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/.agents/skills/gander/scripts/watch-markdown.sh"
fail=0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fake_bin="$tmp/bin"
mkdir -p "$fake_bin" "$tmp/home" "$tmp/notes"

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

cat > "$fake_bin/fswatch" <<'EOF'
#!/bin/sh
echo "fswatch must not be invoked" >&2
exit 99
EOF
chmod +x "$fake_bin/fswatch"

cat > "$fake_bin/inotifywait" <<'EOF'
#!/bin/sh
echo "inotifywait must not be invoked" >&2
exit 99
EOF
chmod +x "$fake_bin/inotifywait"

export PATH="$fake_bin:$PATH"
export HOME="$tmp/home"
export GANDER_LOG="$tmp/gander.log"
unset GANDER_CONFIG

run() {
  rm -f "$GANDER_LOG"
  "$SCRIPT" "$@" >/dev/null 2>"$tmp/script.err"
}

expect() {
  if [ ! -f "$GANDER_LOG" ]; then
    echo "gander was not invoked ($1)" >&2
    fail=1
    return
  fi
  if ! grep -q -F "$1" "$GANDER_LOG"; then
    echo "missing: $1" >&2
    echo "--- gander log ---" >&2
    cat "$GANDER_LOG" >&2
    fail=1
  fi
}

refute() {
  if [ -f "$GANDER_LOG" ] && grep -q -F "$1" "$GANDER_LOG"; then
    echo "must not contain: $1" >&2
    echo "--- gander log ---" >&2
    cat "$GANDER_LOG" >&2
    fail=1
  fi
}

notes="$tmp/notes"
abs_notes="$(cd "$notes" && pwd)"

# No token → local directory watch.
run "$notes"
expect "arg1=--watch"
expect "arg2=$abs_notes"
refute "arg1=watch"

# Signed up → hosted gander watch.
mkdir -p "$HOME/.gander"
printf '%s\n' '{"api_token": "gmd_test"}' > "$HOME/.gander/config.json"
run "$notes"
expect "arg1=watch"
expect "arg2=$abs_notes"
refute "arg1=--watch"

# --share forces hosted even without a token.
rm -f "$HOME/.gander/config.json"
run --share "$notes"
expect "arg1=watch"
expect "arg2=$abs_notes"

# Directory flags pass through before the path.
mkdir -p "$HOME/.gander"
printf '%s\n' '{"api_token": "gmd_test"}' > "$HOME/.gander/config.json"
run "$notes" --existing --no-recursive --glob 'daily-*.md' --yes
expect "arg1=watch"
expect "arg2=--existing"
expect "arg3=--no-recursive"
expect "arg4=--glob"
expect "arg5=daily-*.md"
expect "arg6=--yes"
expect "arg7=$abs_notes"

# --stop requires a dir and calls gander stop (adoption only).
run --stop "$notes"
expect "arg1=stop"
expect "arg2=$abs_notes"

if "$SCRIPT" --stop >/dev/null 2>"$tmp/stop.err"; then
  echo "--stop without a dir should fail" >&2
  fail=1
else
  if ! grep -q "requires a directory" "$tmp/stop.err"; then
    echo "--stop without a dir: unexpected stderr" >&2
    cat "$tmp/stop.err" >&2
    fail=1
  fi
fi

# --background still execs the CLI (runner persists; no fswatch daemon).
run --background "$notes"
expect "arg1=watch"
expect "arg2=$abs_notes"

# GANDER_CONFIG uses the named profile for signup detection.
rm -rf "$HOME/.gander"
mkdir -p "$HOME/.gander.staging"
printf '%s\n' '{"api_token": "gmd_staging"}' > "$HOME/.gander.staging/config.json"
GANDER_CONFIG=staging run "$notes"
expect "arg1=watch"
expect "arg2=$abs_notes"

if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "ok"
