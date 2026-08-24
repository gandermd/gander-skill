#!/usr/bin/env bash
# scripts/watch-markdown.sh — watch a directory for new .md files; prompt to gander each one.
#
# Usage:
#   scripts/watch-markdown.sh                       # watch current working directory
#   scripts/watch-markdown.sh ~/projects/notes      # watch a specific directory
#   scripts/watch-markdown.sh ~/notes --share       # default to share instead of preview
#   scripts/watch-markdown.sh ~/notes --background  # daemonize; PID + log in $XDG_RUNTIME_DIR (or /tmp)
#   scripts/watch-markdown.sh --stop                # stop the backgrounded watcher
#   scripts/watch-markdown.sh --help
#
# Prompt: y=preview / s=share / N=skip
# Requires: gander CLI; fswatch (macOS: brew install fswatch) or inotifywait (linux: apt install inotify-tools).

set -euo pipefail

ACTION="preview"
DIR=""
BACKGROUND=0
STOP=0

usage() {
  sed -n '2,15p' "$0"
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --share)        ACTION="share"; shift ;;
    --background|-b) BACKGROUND=1; shift ;;
    --stop)         STOP=1; shift ;;
    -h|--help)      usage 0 ;;
    -*) echo "error: unknown flag $1" >&2; usage 2 ;;
    *)
      if [ -z "$DIR" ]; then DIR="$1"; shift
      else echo "error: too many positional args (got '$1')" >&2; usage 2
      fi
      ;;
  esac
done

STATE_DIR="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
PIDFILE="$STATE_DIR/gander-watcher.pid"
LOGFILE="$STATE_DIR/gander-watcher.log"

if [ "$STOP" = 1 ]; then
  if [ ! -f "$PIDFILE" ]; then
    echo "no watcher pidfile at $PIDFILE"
    exit 0
  fi
  pid=$(cat "$PIDFILE" 2>/dev/null || true)
  if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
    echo "no watcher running (stale pidfile $PIDFILE)"
    rm -f "$PIDFILE"
    exit 0
  fi
  kill "$pid"
  rm -f "$PIDFILE"
  echo "stopped watcher (pid $pid)"
  exit 0
fi

DIR="${DIR:-$(pwd)}"
if [ ! -d "$DIR" ]; then
  echo "error: not a directory: $DIR" >&2
  exit 1
fi
DIR="$(cd "$DIR" && pwd)"

if [ "$BACKGROUND" = 1 ]; then
  if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "watcher already running (pid $(cat "$PIDFILE"))" >&2
    exit 1
  fi
  nohup "$0" "$DIR" >"$LOGFILE" 2>&1 &
  echo $! > "$PIDFILE"
  echo "watcher started in background (pid $!)"
  echo "  dir:  $DIR"
  echo "  log:  $LOGFILE"
  echo "  stop: $0 --stop"
  exit 0
fi

if ! command -v gander >/dev/null 2>&1; then
  echo "error: gander CLI not found in PATH" >&2
  echo "install: brew install gander  OR  curl -fsSL https://raw.githubusercontent.com/gandermd/gander-cli/main/install.sh | bash" >&2
  exit 1
fi

if command -v fswatch >/dev/null 2>&1; then
  WATCH=(fswatch --event Created -0 "$DIR")
elif command -v inotifywait >/dev/null 2>&1; then
  WATCH=(inotifywait -m -e create --format '%w%f' "$DIR")
else
  echo "error: install fswatch (macOS: brew install fswatch) or inotifywait (linux: apt install inotify-tools)" >&2
  exit 1
fi

trap 'echo; exit 0' INT TERM
echo "Watching $DIR for new .md files (Ctrl-C to stop)..."

"${WATCH[@]}" | while IFS= read -r -d $'\0' f; do
  case "$f" in
    *.md) ;;
    *) continue ;;
  esac
  [ -f "$f" ] || continue
  printf '\nNew markdown: %s — gander? [y=preview / s=share / N=skip] ' "$f"
  read -r ans
  case "$ans" in
    y|Y) gander "$f" ;;
    s|S) gander share "$f" ;;
    *)   echo "  skipped" ;;
  esac
done