# gander-skill

The Gander skill saves agent-produced plans as markdown, offers to watch
them on [gander.md](https://gander.md), and keeps the agent listening for
`@agent` review comments. Use it when the agent finishes a plan and a
human who is not in the IDE needs to review while the file is still
changing.

Works with OpenCode, Claude Code, Codex CLI, Cursor, Grok Build, and any
other runner that loads `SKILL.md` from `.agents/skills/` or `.claude/skills/`.
Needs the [gander CLI](https://github.com/gandermd/gander-cli) on `PATH`.

## What it does

- **Save the agent’s plan** as `./plans/YYYY-MM-DD-<slug>.md`, then offer to gander it.
- **Watch a directory** with `gander watch <dir>` so new `.md` files auto-share (ask once; never silent auto-watch).
- **After a hosted watch**, poll for `@agent` comments (MCP preferred; `gander comments` fallback).
- Also **render, share, and manage** markdown with the `gander` CLI (render locally, share on gander.md, list/remove shares, mint team invites, open the dashboard, sign up, rotate tokens, upgrade).

## Install

```bash
gander skill
```

That downloads this repo into `~/.gander/skill` and symlinks the dests:

- `~/.agents/skills/gander` — picked up by Codex CLI and OpenCode
- `~/.claude/skills/gander` — picked up by Claude Code
- `~/.cursor/skills/gander` — picked up by Cursor

Clone this repo only to hack on `SKILL.md` or the scripts; then `./install.sh` from the checkout. The symlinks then point at the checkout, so edits take effect immediately — no reinstall needed.

## Uninstall

```bash
rm ~/.agents/skills/gander ~/.claude/skills/gander ~/.cursor/skills/gander
```

## Layout

```
gander-skill/
├── README.md                              # this file
├── install.sh                             # symlink installer
└── .agents/skills/gander/                 # the skill itself (source of truth)
    ├── SKILL.md                           # agent instructions (~165 lines)
    └── scripts/
        ├── watch-markdown.sh              # wraps `gander watch <dir>`
        └── save-plan.sh                   # plan → markdown + prompt
```

## Bundled scripts

### `scripts/watch-markdown.sh`

Thin wrapper around `gander watch <dir>` (hosted, if signed up) or
`gander --watch <dir>` (local previews). Prefer the CLI; this script is
not a second fswatch daemon. Directory-adopted files never open a browser.

```bash
gander watch ~/projects/notes                   # hosted directory watch
gander --watch ~/notes                          # local previews if not signed up
gander status                                   # already watching?
gander stop ~/projects/notes                    # stop adoption only

scripts/watch-markdown.sh ~/projects/notes      # same as gander watch / --watch
scripts/watch-markdown.sh ~/notes --share       # force hosted watch
scripts/watch-markdown.sh --stop ~/notes        # gander stop (adoption only)
```

Requires `gander` in `PATH`. Optional CLI flags the wrapper forwards:
`--existing`, `--no-recursive`, `--glob`, `--yes`.

### `scripts/save-plan.sh`

Save an agent-produced plan as a markdown file; offer to gander it.

```bash
cat plan.txt | scripts/save-plan.sh "Add token rotation to gander"
scripts/save-plan.sh "Refactor share rendering" plan.md
PLAN_SOURCE=opencode scripts/save-plan.sh "Plan title here"
```

Saves to `./plans/YYYY-MM-DD-<slug>.md` with a title heading and metadata block. Override the save directory with `PLAN_DIR=/some/path`.

## Editing

Edit `SKILL.md` or any script in place — the symlinks mean changes take effect immediately for every agent that has the skill loaded. No reinstall needed.

If you add new files under `.agents/skills/gander/` (e.g. `references/`, `assets/`), they'll be picked up by agents via the skill directory at `$HOME/.agents/skills/gander` — but only if the new files live inside this repo (since the symlink target is this directory).

## License

MIT.
