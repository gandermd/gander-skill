---
name: gander
description: |
  Use this skill when the user wants to preview, share, or manage markdown
  files with the gander CLI, or when saving an agent-produced plan as a
  gander-able markdown file. Triggers on: "gander this file", "preview this
  markdown", "share this on gander.md", "list my gander shares", "remove a
  share", "open my gander dashboard", "sign up for gander", "watch for new
  markdown files", "watch my notes dir", "save this plan", "save my plan",
  "save plan as markdown", "upgrade gander", or any request to run a gander
  subcommand (signup, share, list, remove, manage, auth, --upgrade, --watch).
  Also invoke after the agent produces a plan (plan-mode exit, "plan this",
  "design this") to capture it as markdown via scripts/save-plan.sh.
license: MIT
compatibility: Requires gander CLI in PATH; fswatch (macOS) or inotifywait (linux) for scripts/watch-markdown.sh.
metadata:
  audience: end-users
  tool: gander-cli
---

# Gander (end-user)

A skill for using the [gander](https://github.com/gandermd/gander-cli) CLI to preview, share, and manage markdown files, plus a watcher for new `.md` files and a helper to save agent-produced plans as gander-able markdowns.

## When to use this skill

Invoke when the user wants to:

- **Render** a markdown file: "gander this file", "preview this markdown", "open this in gander"
- **Watch** for new markdown files: "watch for new markdown files", "watch my notes dir"
- **Share** on gander.md: "share this on gander.md", "share my README"
- **Manage shares**: "list my gander shares", "remove this share", "open my gander dashboard"
- **Account**: "sign up for gander", "install my gander token"
- **Save a plan**: "save this plan", "save my plan as markdown", or after the agent itself produces a plan (in plan mode, after "plan this" / "design this" / "architect this")
- **Upgrade**: "upgrade gander"

Also invoke when the user references any gander subcommand (`signup`, `share`, `list`, `remove`, `manage`, `auth`, `--upgrade`, `--watch`, `--version`).

## Install + verify

Pre-flight: confirm `gander` is installed and on `PATH`.

```bash
which gander || command -v gander
```

If missing, install:

```bash
# Homebrew (macOS / Linuxbrew)
brew tap gandermd/gander && brew install gander

# One-liner (any system)
curl -fsSL https://raw.githubusercontent.com/gandermd/gander-cli/main/install.sh | bash
```

Verify after install:

```bash
gander --version
```

## Render locally

Three render modes, all use the markdown file path as a positional argument:

```bash
gander README.md              # render + open in browser (fire-and-forget)
gander --watch README.md      # render + open + hot-reload on save
gander -outfile readme.html README.md  # render to file, no browser
```

> **Gotcha:** Go's `flag` package stops parsing at the first positional argument. **All flags must come before the markdown path.** `gander README.md --watch` does NOT work — use `gander --watch README.md`.

`--watch` starts a small local HTTP server on a free port for SSE hot-reloads. It runs until you press `Ctrl-C`.

`-outfile` and `--watch` are mutually exclusive.

## Share on gander.md

Subcommands appear in `gander --help` only after a successful `signup` (the CLI hides them until an API token is stored in `~/.gander/config.json`).

### Sign up (first-time only)

```bash
gander signup --email you@example.com
```

Opens the signup form in your browser. Submit it; the CLI polls for the API token and writes it to `~/.gander/config.json`.

### Share a file

```bash
gander share README.md             # upload + open https://gander.md/s/<id>
gander share --watch README.md     # upload + push live updates to viewers on save
```

Records the share mapping in `~/.gander/config.json` (path → short ID) so future invocations know it.

### List shares

```bash
gander list
```

Table of all active shares on your account.

### Remove a share

```bash
gander remove README.md            # remove the share recorded for README.md
gander remove https://gander.md/s/xK7m2pQa   # remove by URL
gander remove xK7m2pQa             # remove by short ID
gander remove --all                # remove every share on the account
```

### Open the dashboard

```bash
gander manage
```

Browser handoff to the dashboard: shares, token rotation, account settings.

### Install a rotated token

```bash
gander auth gmd_…   # paste the new token from the dashboard's rotate flow
```

The CLI validates the token against `/api/shares` before overwriting `~/.gander/config.json`.

## Configuration

`~/.gander` is a directory. JSON config lives at `~/.gander/config.json`:

```json
{
  "watch": true,
  "debounce_ms": 150,
  "port": 0,
  "api_url": "https://gander.md",
  "email": "you@example.com",
  "api_token": "gmd_…",
  "shares": {
    "/abs/path/to/README.md": "xK7m2pQa"
  }
}
```

CLI flags always override the config. Pass `--watch=false` (or any explicit value) to override `~/.gander/config.json` for one run.

### Profiles (`GANDER_CONFIG`)

Point at a different endpoint (local dev, staging, self-hosted) without disturbing prod `~/.gander`:

```bash
GANDER_CONFIG=dev gander signup --email dev@example.com    # writes ~/.gander.dev/config.json
GANDER_CONFIG=staging gander list                          # reads ~/.gander.staging/config.json
```

Profile names must be a single path component (no `/`, `\`, `.`, or `..`). The legacy `~/.mdp` fallback only applies when `GANDER_CONFIG` is unset.

## Watching for new markdown files

Bundled `scripts/watch-markdown.sh` monitors a directory for new `.md` files and prompts to gander each one. Defaults to the current working directory.

### Usage

```bash
# Foreground (default): watch cwd, Ctrl-C to stop
scripts/watch-markdown.sh

# Watch a specific directory
scripts/watch-markdown.sh ~/projects/notes

# Default to share on gander.md instead of local preview
scripts/watch-markdown.sh ~/notes --share

# Run in the background; logs + PID written to $XDG_RUNTIME_DIR (or /tmp)
scripts/watch-markdown.sh ~/notes --background
#  → watcher started in background (pid 12345) — log: /tmp/gander-watcher.log
#  → stop with: scripts/watch-markdown.sh --stop

scripts/watch-markdown.sh --stop
```

### Prompt

For each new `.md` file detected:

```
New markdown: /Users/.../foo.md — gander? [y=preview / s=share / N=skip]
```

- `y` (or `Y`) — render locally with `gander <file>` (opens browser)
- `s` (or `S`) — share on gander.md with `gander share <file>` (opens share link)
- Anything else (including just Enter) — skip

### Requirements

The script auto-detects the watcher tool:

- **macOS:** `fswatch` (`brew install fswatch`)
- **Linux:** `inotifywait` (`apt install inotify-tools`)

If neither is installed, the script errors out with install instructions.

## Saving plans as markdown

Bundled `scripts/save-plan.sh` captures agent-produced plans as properly-formatted markdown files in `./plans/`, then offers to gander them. Use it any time you finish producing a plan — especially on plan-mode exit, or after responding to "plan this" / "design this" / "architect this".

### Usage

```bash
# Pipe a plan from stdin
scripts/save-plan.sh "Add token rotation to gander" < plan.txt

# Read a plan from a file
scripts/save-plan.sh "Refactor share rendering" plan.md

# Save the current conversation's plan response
scripts/save-plan.sh "Plan title here"
# (then paste/type the plan content, then Ctrl-D)
```

The plan must be passed as a **single positional title** (required) plus optionally a file path. If no file is given, content is read from stdin.

### Output

Saved to `./plans/YYYY-MM-DD-<slug>.md`. The directory is created if missing. The slug is derived from the title (lowercase, alphanum + hyphens, 60-char cap). Existing files get `-2`, `-3`, … suffixes.

Override the save directory with `PLAN_DIR=/some/path`.

Wrapper format:

```markdown
# <Title>

> Saved YYYY-MM-DD HH:MM from <source>

<plan content>
```

`<source>` defaults to `agent`. Set `PLAN_SOURCE=opencode` (or `claude-code`, `codex`, etc.) before invoking to record which agent produced it:

```bash
PLAN_SOURCE=opencode scripts/save-plan.sh "Add token rotation" < plan.txt
```

### Post-save

After saving, the script prompts:

```
gander it? [y=preview / s=share / N=skip]
```

Same UX as the watcher — `y` previews locally, `s` shares on gander.md, anything else skips.

### Invocation pattern

When you produce a plan in this skill:

1. Pipe the plan body to `scripts/save-plan.sh "<descriptive title>"`
2. Read the script's response — if the user wants to gander it, the script handles it
3. Report the saved path back to the user

## Upgrading

```bash
gander --upgrade
```

Downloads the latest release binary for your OS/arch from GitHub Releases, verifies its SHA256, and atomically replaces the running binary. Set `GITHUB_TOKEN` to raise the GitHub API rate limit on shared networks.

Source-build installs: `git pull && ./install.sh --source` (or rebuild manually).

> **Gotcha:** `--upgrade` requires a release build (one stamped with `-ldflags "-X main.Version=vX.Y.Z"`). Source builds print a clear error directing you to rebuild or download manually.

## Gotchas

- **Flags before the markdown path.** Go's flag parser stops at the first positional arg. `gander README.md --watch` does NOT work.
- **Share/list/remove/manage are hidden until signup.** They don't appear in `gander --help` until `~/.gander/config.json` has an `api_token`.
- **Token rotation is a two-step dance.** Rotate in the dashboard (`gander manage` → rotate), then on every machine run `gander auth <new_token>`. The CLI validates the new token before overwriting `~/.gander/config.json`.
- **`--upgrade` needs a release build.** Dev / source builds print an error and point you at the install script.
- **`~/.mdp` legacy fallback** only applies when `GANDER_CONFIG` is unset. Named profiles (`~/.gander.dev`, etc.) never fall back to `.mdp`.
- **`-outfile` and `--watch` are mutually exclusive.** Choose one.
- **Profile names must be a single path component.** `GANDER_CONFIG=foo/bar` is rejected (path-traversal guard).
- **The watcher's PID/log live in `$XDG_RUNTIME_DIR`** if set, else `/tmp`. Override by editing the script if you want a different location.

## Working agreements

- Always start with `which gander` — if missing, install via Homebrew or the one-liner before doing anything else.
- Never paste API tokens into commands in chat history. Prefer the dashboard rotation flow + `gander auth`.
- For new markdown files detected by the watcher, default to **skip** unless the user explicitly opted in — never auto-gander every file the watcher sees.
- When saving a plan, derive the title from the plan's actual subject, not a generic placeholder.
- Prefer `./plans/` for plan storage — it keeps plans out of source repos unless the user wants them in version control.
- After invoking either bundled script, report the saved path / outcome back to the user.

## Rules

- **Never** commit `~/.gander/` (it contains `api_token`). It must remain gitignored.
- **Never** auto-gander files detected by the watcher — always prompt first.
- **Never** invoke `gander share` against a file the user didn't ask to share.
- **Never** overwrite an existing plan markdown silently — the script disambiguates with `-2`, `-3`, … suffixes for a reason.
- **Always** pipe the full plan body to `scripts/save-plan.sh`, not a summary. The user wants the actual plan on disk.
- **Always** use `scripts/watch-markdown.sh --stop` (or kill the recorded PID) before assuming a watcher has stopped — the process forks on `--background`.
- **Always** respect `GANDER_CONFIG` when present — don't read or write the prod `~/.gander` profile if the user is targeting `dev` / `staging` / a self-hosted instance.